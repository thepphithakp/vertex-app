import Foundation

@MainActor
class RemotePetRepository: PetRepository {
    
    // MARK: - Pet Operations
    
    /// ดึงแมวทั้งหมดผ่าน GraphQL (VT-102)
    ///
    /// ขนาด response พอๆ กับ `GET /pets` เพราะเซิร์ฟเวอร์เลิกส่ง `avatarData`
    /// ไปกับรายการแล้ว ที่ได้จริงคือ bloodType / allergies / personality
    /// ซึ่ง REST ส่งมาอยู่แล้วแต่ `PetDTO` ไม่ได้ decode หน้าโปรไฟล์เลยขึ้น
    /// "ไม่ระบุ" มาตลอด — ตรงนี้ schema บังคับให้ครบ เพิ่ม field แล้วลืมรับไม่ได้
    func fetchPets() async throws -> [Pet] {
        let data = try await VertexGraphQL.fetch(VertexAPI.MyCatsQuery())
        let fragments = data.viewer.pets.map { $0.fragments.petCoreFields }
        let pets = try fragments.map { try Pet(graphQL: $0) }
        await Self.attachAvatars(to: pets, hasAvatar: fragments.map(\.hasAvatar))
        return pets
    }

    func getPet(by id: UUID) async throws -> Pet? {
        let data = try await VertexGraphQL.fetch(VertexAPI.CatProfileQuery(petId: id.uuidString))
        // null แปลว่าไม่มีตัวนี้ หรือผู้เรียกไม่มีสิทธิ์ดู — ทั้งสองกรณีคือ "ไม่เจอ"
        guard let petData = data.pet else { return nil }

        let fragment = petData.fragments.petCoreFields
        let pet = try Pet(graphQL: fragment)
        await Self.attachAvatars(to: [pet], hasAvatar: [fragment.hasAvatar])
        return pet
    }

    /// เติม `avatarData` ให้ตัวที่เซิร์ฟเวอร์บอกว่ามีรูป
    ///
    /// GraphQL ไม่ส่งตัวรูปมาให้เลยโดยตั้งใจ (ดู VT-98) รูปยังอยู่ที่ REST เดิม
    /// ที่มี ETag อยู่แล้ว ครั้งแรกโหลดจริง ครั้งต่อไปได้ 304 ที่แทบไม่มีข้อมูล
    ///
    /// จอที่แสดงรูปยังอ่านจาก `pet.avatarData` เหมือนเดิม ไม่ต้องแก้อะไร
    /// `Pet` เป็น `@Model` class จึงแก้ผ่าน reference ได้เลย ไม่ต้องรับเป็น inout
    private static func attachAvatars(to pets: [Pet], hasAvatar: [Bool]) async {
        guard pets.count == hasAvatar.count else { return }

        let needsAvatar = pets.indices.filter { hasAvatar[$0] }
        guard !needsAvatar.isEmpty else { return }

        let store = PetAvatarStore.shared

        // ดึงพร้อมกันเพื่อไม่ให้หน้ารายการรอเป็นทอดๆ
        await withTaskGroup(of: (Int, Data?).self) { group in
            for index in needsAvatar {
                let petId = pets[index].id
                group.addTask {
                    // รูปโหลดไม่ได้ไม่ควรทำให้ทั้งหน้าล้ม — แสดง placeholder แทน
                    let data = try? await store.avatar(for: petId)
                    return (index, data)
                }
            }
            for await (index, data) in group where data != nil {
                pets[index].avatarData = data
            }
        }
    }

    func savePet(_ pet: Pet) async throws {
        let dto = PetDTO(from: pet)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(dto)
        
        let _: PetDTO = try await NetworkManager.shared.request(
            endpoint: "/pets",
            method: "POST",
            body: data
        )
    }
    
    func updatePet(_ pet: Pet) async throws {
        let dto = PetDTO(from: pet)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(dto)
        
        let _: PetDTO = try await NetworkManager.shared.request(
            endpoint: "/pets/\(pet.id.uuidString)",
            method: "PUT",
            body: data
        )

        // อัปเดต cache ให้ตรงกับรูปใหม่ทันที ไม่ต้องรอรอบ fetch ถัดไป
        if let avatar = pet.avatarData {
            await PetAvatarStore.shared.store(avatar, for: pet.id)
        } else {
            await PetAvatarStore.shared.remove(for: pet.id)
        }
    }
    
    func deletePet(_ pet: Pet) async throws {
        let _: EmptyResponse = try await NetworkManager.shared.request(
            endpoint: "/pets/\(pet.id.uuidString)",
            method: "DELETE"
        )
        // ลบรูปที่ cache ไว้ด้วย ไม่งั้นค้างกินพื้นที่ไปเรื่อยๆ
        await PetAvatarStore.shared.remove(for: pet.id)
    }
    
    // MARK: - Caregiver Operations
    
    func addCaregiver(_ caregiver: PetCaregiver, to petId: UUID) async throws {
        let dto = CaregiverDTO(from: caregiver)
        let encoder = JSONEncoder()
        
        let data = try encoder.encode(dto)
        let _: CaregiverDTO = try await NetworkManager.shared.request(
            endpoint: "/pets/\(petId.uuidString)/caregivers",
            method: "POST",
            body: data
        )
    }
    
    func removeCaregiver(_ caregiver: PetCaregiver, from petId: UUID) async throws {
        let _: EmptyResponse = try await NetworkManager.shared.request(
            endpoint: "/pets/\(petId.uuidString)/caregivers/\(caregiver.id.uuidString)",
            method: "DELETE"
        )
    }
    
    // MARK: - Unimplemented Sub-domain Operations (Mocked)
    
    func fetchWeightLogs(for petId: UUID) async throws -> [WeightLog] { return [] }
    func saveWeightLog(_ log: WeightLog, for petId: UUID) async throws {}
    func fetchMedicalRecords(for petId: UUID) async throws -> [MedicalRecord] { return [] }
    func saveMedicalRecord(_ record: MedicalRecord, for petId: UUID) async throws {}
    func fetchDailyTasks(for petId: UUID) async throws -> [DailyTask] { return [] }
    func saveDailyTask(_ task: DailyTask, for petId: UUID) async throws {}
}

// MARK: - DTO (Data Transfer Object)
// Keeps the network model decoupled from the SwiftData @Model domain model
fileprivate struct PetDTO: Codable {
    let id: String
    let ownerId: String?
    let name: String
    let species: String
    let breed: String
    let colorCode: String
    let birthDate: Date
    let gender: String
    let currentWeight: Double?
    let microchipId: String?
    let isSpayedNeutered: Bool

    /// เซิร์ฟเวอร์ส่งมาเฉพาะตอนที่ไม่ได้แนบรูปมาด้วย (โหมดใหม่)
    /// optional เพื่อให้ decode ได้ทั้งกับเซิร์ฟเวอร์เก่าและใหม่
    let avatarData: Data?
    let hasAvatar: Bool?

    func toDomain() -> Pet {
        return Pet(
            id: UUID(uuidString: id) ?? UUID(),
            ownerId: UUID(uuidString: ownerId ?? "") ?? nil,
            name: name,
            species: species,
            breed: breed,
            colorCode: colorCode,
            birthDate: birthDate,
            gender: gender,
            avatarData: avatarData,
            currentWeight: currentWeight,
            microchipId: microchipId,
            isSpayedNeutered: isSpayedNeutered
        )
    }
    
    init(from pet: Pet) {
        self.id = pet.id.uuidString
        self.ownerId = pet.ownerId?.uuidString
        self.name = pet.name
        self.species = pet.species
        self.breed = pet.breed
        self.colorCode = pet.colorCode
        self.birthDate = pet.birthDate
        self.gender = pet.gender
        self.currentWeight = pet.currentWeight
        self.microchipId = pet.microchipId
        self.isSpayedNeutered = pet.isSpayedNeutered
        self.avatarData = pet.avatarData
        // ฝั่งเซิร์ฟเวอร์ไม่ได้อ่านค่านี้ตอนสร้าง/แก้ไข ใส่ไว้ให้ครบรูปแบบเท่านั้น
        self.hasAvatar = pet.avatarData != nil
    }
}

fileprivate struct CaregiverDTO: Codable {
    let id: String
    let petId: String
    let userId: String
    
    init(from caregiver: PetCaregiver) {
        self.id = caregiver.id.uuidString
        self.petId = caregiver.petId.uuidString
        self.userId = caregiver.userId.uuidString
    }
}
