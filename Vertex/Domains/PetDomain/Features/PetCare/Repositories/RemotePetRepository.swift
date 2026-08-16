import Foundation

@MainActor
class RemotePetRepository: PetRepository {
    
    // MARK: - Pet Operations
    
    func fetchPets() async throws -> [Pet] {
        let dtos: [PetDTO] = try await NetworkManager.shared.request(endpoint: "/pets")
        return dtos.map { $0.toDomain() }
    }
    
    func getPet(by id: UUID) async throws -> Pet? {
        let dto: PetDTO = try await NetworkManager.shared.request(endpoint: "/pets/\(id.uuidString)")
        return dto.toDomain()
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
    }
    
    func deletePet(_ pet: Pet) async throws {
        let _: EmptyResponse = try await NetworkManager.shared.request(
            endpoint: "/pets/\(pet.id.uuidString)",
            method: "DELETE"
        )
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
    let avatarData: Data?
    
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
