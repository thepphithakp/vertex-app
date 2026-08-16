import Foundation
import SwiftData

@MainActor
final class LocalPetRepository: PetRepository {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func fetchPets() async throws -> [Pet] {
        let descriptor = FetchDescriptor<Pet>(sortBy: [SortDescriptor(\.name)])
        return try context.fetch(descriptor)
    }
    
    func getPet(by id: UUID) async throws -> Pet? {
        let descriptor = FetchDescriptor<Pet>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }
    
    func savePet(_ pet: Pet) async throws {
        context.insert(pet)
        try context.save()
    }
    
    func updatePet(_ pet: Pet) async throws {
        // For SwiftData, the model is already updated in memory, just save context
        try context.save()
    }
    
    func deletePet(_ pet: Pet) async throws {
        context.delete(pet)
        try context.save()
    }
    
    // Caregiver Operations
    func addCaregiver(_ caregiver: PetCaregiver, to petId: UUID) async throws {}
    func removeCaregiver(_ caregiver: PetCaregiver, from petId: UUID) async throws {}
    
    func fetchWeightLogs(for petId: UUID) async throws -> [WeightLog] { return [] }
    func saveWeightLog(_ log: WeightLog, for petId: UUID) async throws {}
    
    func fetchMedicalRecords(for petId: UUID) async throws -> [MedicalRecord] { return [] }
    func saveMedicalRecord(_ record: MedicalRecord, for petId: UUID) async throws {}
    
    func fetchDailyTasks(for petId: UUID) async throws -> [DailyTask] { return [] }
    func saveDailyTask(_ task: DailyTask, for petId: UUID) async throws {}
}
