import Foundation
import SwiftData

protocol LitterRepository {
    func fetchLogs(for pet: Pet, on date: Date) async throws -> [LitterLog]
    func saveLog(_ log: LitterLog) async throws
    func deleteLog(_ log: LitterLog) async throws
}

@MainActor
final class LocalLitterRepository: LitterRepository {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func fetchLogs(for pet: Pet, on date: Date) async throws -> [LitterLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // กรองหา Log ที่ตรงกับวันนั้นๆ ใน Memory ป้องกันบั๊ก Predicate ของ SwiftData กับ Relationship
        return pet.litterLogs.filter { log in
            log.date >= startOfDay && log.date < endOfDay
        }.sorted { $0.date > $1.date } // เรียงลำดับจากใหม่ไปเก่า
    }
    
    func saveLog(_ log: LitterLog) async throws {
        context.insert(log)
        try context.save()
    }
    
    func deleteLog(_ log: LitterLog) async throws {
        context.delete(log)
        try context.save()
    }
}

// MARK: - Remote & Sync Implementation

@MainActor
final class SyncLitterRepository: LitterRepository {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    /// ดึงบันทึกของวันเดียวผ่าน GraphQL (VT-102)
    ///
    /// เดิมเรียก `GET /pets/{id}/litter-logs` ที่คืนประวัติทั้งหมดตั้งแต่ต้น
    /// แล้วมากรองเหลือวันเดียวในเครื่อง แปลว่ายิ่งใช้นานหน้านี้ยิ่งช้าลงเรื่อยๆ
    /// ทั้งที่แสดงข้อมูลเท่าเดิม
    ///
    /// ฝั่งเขียนยังเป็น REST + `LitterSyncManager` เหมือนเดิม เพราะเป็น offline-first
    /// ที่เขียนลงเครื่องก่อนแล้ว sync แบบ debounce — ย้ายทีหลังเป็นอีกก้าว
    func fetchLogs(for pet: Pet, on date: Date) async throws -> [LitterLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        do {
            let data = try await VertexGraphQL.fetch(
                VertexAPI.LitterDayQuery(
                    petId: pet.id.uuidString,
                    from: VertexAPI.dateTime(from: startOfDay),
                    to: VertexAPI.dateTime(from: endOfDay)
                )
            )

            if let remote = data.pet?.litterLogs.edges.map(\.node) {
                var seen = Set<UUID>()
                for node in remote {
                    guard let uuid = UUID(uuidString: node.id),
                          let logDate = VertexAPI.date(from: node.date) else { continue }
                    seen.insert(uuid)

                    if let existing = pet.litterLogs.first(where: { $0.id == uuid }) {
                        existing.amount = node.amount
                        existing.type = node.type
                        existing.date = logDate
                    } else {
                        let newLog = LitterLog(date: logDate, type: node.type, amount: node.amount)
                        newLog.id = uuid
                        newLog.pet = pet
                        context.insert(newLog)
                    }
                }

                // ลบของที่หายไปจาก server แล้ว
                //
                // ตอนที่ดึงประวัติทั้งก้อนมาก็ไม่เคยลบ ทำให้บันทึกที่คนอื่นลบไป
                // ยังค้างอยู่บนเครื่องนี้ตลอด ตอนนี้รู้แน่ว่า server มีอะไรบ้างในวันนั้น
                // จึงตัดของที่ไม่มีแล้วออกได้อย่างปลอดภัย
                for local in pet.litterLogs where local.date >= startOfDay && local.date < endOfDay {
                    if !seen.contains(local.id) {
                        context.delete(local)
                    }
                }
            }
            try? context.save()
        } catch {
            // อ่านจากเครื่องต่อได้ ไม่ต้องทำให้ทั้งหน้าพัง — error เด้ง dialog ไปแล้ว
            print("Failed to fetch remote logs: \(error)")
        }

        return pet.litterLogs
            .filter { $0.date >= startOfDay && $0.date < endOfDay }
            .sorted { $0.date > $1.date }
    }
    
    func saveLog(_ log: LitterLog) async throws {
        // 1. Save locally for instant UI update
        context.insert(log)
        try context.save()
        
        // 2. Queue for background remote sync (Debounced)
        LitterSyncManager.shared.enqueue(log)
    }
    
    func deleteLog(_ log: LitterLog) async throws {
        // 1. Delete Remote API
        if let petId = log.pet?.id {
            do {
                let _: EmptyResponse = try await NetworkManager.shared.request(
                    endpoint: "/pets/\(petId.uuidString)/litter-logs/\(log.id.uuidString)",
                    method: "DELETE"
                )
            } catch {
                print("Failed to delete remote litter log: \(error)")
            }
        }
        
        // 2. Delete Locally
        context.delete(log)
        try context.save()
    }
}

struct LitterLogDTO: Codable {
    let id: String
    let petId: String
    let date: Date
    let type: String
    let amount: Int
    
    init(from log: LitterLog, petId: UUID) {
        self.id = log.id.uuidString
        self.petId = petId.uuidString
        self.date = log.date
        self.type = log.type
        self.amount = log.amount
    }
}

// MARK: - Water Log

protocol WaterRepository {
    func fetchLogs(for pet: Pet, on date: Date) async throws -> [WaterLog]
    func saveLog(_ log: WaterLog) async throws
    func deleteLog(_ log: WaterLog) async throws
}

struct WaterLogDTO: Codable {
    let id: String
    let petId: String
    let date: Date
    let amount: Int
}

@MainActor
final class SyncWaterRepository: WaterRepository {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    /// ดึงบันทึกน้ำของวันเดียวผ่าน GraphQL (VT-102) — เหตุผลเดียวกับฝั่งทราย
    func fetchLogs(for pet: Pet, on date: Date) async throws -> [WaterLog] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        do {
            let data = try await VertexGraphQL.fetch(
                VertexAPI.WaterDayQuery(
                    petId: pet.id.uuidString,
                    from: VertexAPI.dateTime(from: startOfDay),
                    to: VertexAPI.dateTime(from: endOfDay)
                )
            )

            if let remote = data.pet?.waterLogs.edges.map(\.node) {
                var seen = Set<UUID>()
                for node in remote {
                    guard let uuid = UUID(uuidString: node.id),
                          let logDate = VertexAPI.date(from: node.date) else { continue }
                    seen.insert(uuid)

                    if let existing = pet.waterLogs.first(where: { $0.id == uuid }) {
                        existing.amount = node.amount
                        existing.date = logDate
                    } else {
                        let newLog = WaterLog(date: logDate, amount: node.amount)
                        newLog.id = uuid
                        newLog.pet = pet
                        context.insert(newLog)
                    }
                }

                for local in pet.waterLogs where local.date >= startOfDay && local.date < endOfDay {
                    if !seen.contains(local.id) {
                        context.delete(local)
                    }
                }
            }
            try? context.save()
        } catch {
            print("Failed to fetch remote water logs: \(error)")
        }

        return pet.waterLogs
            .filter { $0.date >= startOfDay && $0.date < endOfDay }
            .sorted { $0.date > $1.date }
    }
    
    func saveLog(_ log: WaterLog) async throws {
        context.insert(log)
        try context.save()
        
        if let petId = log.pet?.id {
            do {
                let dto = WaterLogDTO(id: log.id.uuidString, petId: petId.uuidString, date: log.date, amount: log.amount)
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let bodyData = try encoder.encode(dto)
                let _: WaterLogDTO = try await NetworkManager.shared.request(endpoint: "/pets/\(petId.uuidString)/water-logs", method: "POST", body: bodyData)
            } catch {
                print("Failed to sync water log: \(error)")
            }
        }
    }
    
    func deleteLog(_ log: WaterLog) async throws {
        if let petId = log.pet?.id {
            do {
                let _: EmptyResponse = try await NetworkManager.shared.request(endpoint: "/pets/\(petId.uuidString)/water-logs/\(log.id.uuidString)", method: "DELETE")
            } catch {
                print("Failed to delete remote water log: \(error)")
            }
        }
        context.delete(log)
        try context.save()
    }
}
