import Foundation

/// เก็บรูปสัตว์เลี้ยงไว้ในเครื่องและซิงก์กับเซิร์ฟเวอร์ด้วย ETag
///
/// เหตุผลที่ต้องมี: เดิม `GET /pets` ส่ง `avatarData` ของทุกตัวมาพร้อมรายการ
/// ผู้ใช้ที่มีแมว 3 ตัว (รูปรวมเกือบ 4MB) ต้องโหลดเท่านั้นทุกครั้งที่เปิดหน้ารายการ
/// ฝั่งเซิร์ฟเวอร์จึงแยกรูปออกมาเป็น `GET /pets/{id}/avatar` ที่ cache ได้
///
/// วิธีทำงาน
///   - เก็บรูปกับ ETag ไว้ในโฟลเดอร์ Caches
///   - ขอครั้งถัดไปส่ง `If-None-Match` ไปด้วย ถ้ารูปไม่เปลี่ยนจะได้ 304
///     ที่ไม่มี body เลย แล้วใช้ของเดิมในเครื่อง
///   - ใช้ Caches ไม่ใช่ Documents เพราะระบบลบทิ้งได้เมื่อพื้นที่ไม่พอ
///     รูปเหล่านี้โหลดใหม่ได้เสมอ ไม่ใช่ข้อมูลที่หายแล้วหายเลย
actor PetAvatarStore {
    static let shared = PetAvatarStore()

    private let fileManager = FileManager.default
    private let directory: URL

    /// กันไม่ให้ยิงซ้ำเมื่อหลายจอขอรูปตัวเดียวกันพร้อมกัน
    private var inFlight: [UUID: Task<Data?, Error>] = [:]

    init(directoryName: String = "PetAvatars") {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.directory = caches.appendingPathComponent(directoryName, isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    /// คืนรูปของสัตว์เลี้ยง — ใช้ของใน cache ก่อนแล้วค่อยถามเซิร์ฟเวอร์ว่าเปลี่ยนไหม
    ///
    /// คืน nil เมื่อไม่มีรูป (เซิร์ฟเวอร์ตอบ 404) ซึ่งไม่ใช่ความผิดพลาด
    func avatar(for petId: UUID) async throws -> Data? {
        if let existing = inFlight[petId] {
            return try await existing.value
        }

        let task = Task<Data?, Error> { [weak self] in
            guard let self else { return nil }
            return try await self.fetch(petId: petId)
        }
        inFlight[petId] = task

        defer { inFlight[petId] = nil }
        return try await task.value
    }

    /// เก็บรูปที่ได้มาจากทางอื่นลง cache
    ///
    /// ใช้ตอนผู้ใช้แก้ไขรูป — ต้องเขียนทับของเดิมเสมอ
    ///
    /// ไม่มี ETag เพราะไม่ได้มาจาก endpoint ของรูป — ครั้งหน้าจะขอแบบเต็มหนึ่งครั้ง
    /// แล้วค่อยได้ ETag มาเก็บ
    func store(_ data: Data, for petId: UUID) {
        try? data.write(to: dataURL(petId), options: .atomic)
        try? fileManager.removeItem(at: etagURL(petId))
    }

    /// เก็บลง cache เฉพาะเมื่อยังไม่มีของเดิม
    ///
    /// ใช้ตอนเซิร์ฟเวอร์ยังส่ง `avatarData` มากับรายการอยู่ (ช่วงเปลี่ยนผ่าน)
    /// ถ้าเขียนทับทุกครั้งที่โหลดรายการ จะเขียนดิสก์หลายเมกะไบต์ซ้ำๆ
    /// ทั้งที่รูปไม่ได้เปลี่ยน — เปลืองแบตและอายุ storage โดยไม่ได้อะไร
    ///
    /// รูปที่เปลี่ยนจริงถูกอัปเดตผ่าน `store(_:for:)` ตอนบันทึกอยู่แล้ว
    func storeIfAbsent(_ data: Data, for petId: UUID) {
        guard !fileManager.fileExists(atPath: dataURL(petId).path) else { return }
        store(data, for: petId)
    }

    /// ลบรูปที่เก็บไว้ ใช้ตอนผู้ใช้ลบสัตว์เลี้ยง
    func remove(for petId: UUID) {
        try? fileManager.removeItem(at: dataURL(petId))
        try? fileManager.removeItem(at: etagURL(petId))
    }

    /// ล้างทั้งหมด ใช้ตอน logout
    func clear() {
        try? fileManager.removeItem(at: directory)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    // MARK: - ภายใน

    private func fetch(petId: UUID) async throws -> Data? {
        let cached = try? Data(contentsOf: dataURL(petId))
        let cachedETag = try? String(contentsOf: etagURL(petId), encoding: .utf8)

        let response = try await NetworkManager.shared.requestRawData(
            endpoint: "/pets/\(petId.uuidString)/avatar",
            ifNoneMatch: cached == nil ? nil : cachedETag
        )

        if let fresh = response.data {
            try? fresh.write(to: dataURL(petId), options: .atomic)
            if let etag = response.etag {
                try? etag.write(to: etagURL(petId), atomically: true, encoding: .utf8)
            }
            return fresh
        }

        // 304 → ของเดิมยังใช้ได้
        if response.etag != nil {
            return cached
        }

        // 404 → ไม่มีรูปแล้ว ลบของเก่าทิ้งไม่ให้ค้าง
        remove(for: petId)
        return nil
    }

    private func dataURL(_ petId: UUID) -> URL {
        directory.appendingPathComponent("\(petId.uuidString).bin")
    }

    private func etagURL(_ petId: UUID) -> URL {
        directory.appendingPathComponent("\(petId.uuidString).etag")
    }
}
