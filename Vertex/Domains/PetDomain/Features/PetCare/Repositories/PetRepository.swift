import Foundation

@MainActor
protocol PetRepository {
    // Pet Operations
    func fetchPets() async throws -> [Pet]
    func getPet(by id: UUID) async throws -> Pet?
    func savePet(_ pet: Pet) async throws
    func updatePet(_ pet: Pet) async throws
    func deletePet(_ pet: Pet) async throws
    
    // Caregiver Operations
    func addCaregiver(_ caregiver: PetCaregiver, to petId: UUID) async throws
    func removeCaregiver(_ caregiver: PetCaregiver, from petId: UUID) async throws
    
    // WeightLog Operations
    func fetchWeightLogs(for petId: UUID) async throws -> [WeightLog]
    func saveWeightLog(_ log: WeightLog, for petId: UUID) async throws
    
    // MedicalRecord Operations
    func fetchMedicalRecords(for petId: UUID) async throws -> [MedicalRecord]
    func saveMedicalRecord(_ record: MedicalRecord, for petId: UUID) async throws
    
    // DailyTask Operations
    func fetchDailyTasks(for petId: UUID) async throws -> [DailyTask]
    func saveDailyTask(_ task: DailyTask, for petId: UUID) async throws
}
