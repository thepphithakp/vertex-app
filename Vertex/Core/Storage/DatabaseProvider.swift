import Foundation
import SwiftData

@MainActor
final class DatabaseProvider {
    static let shared = DatabaseProvider()
    
    let container: ModelContainer
    
    private init() {
        // Register all Data Models for the Super App here
        let schema = Schema([
            Pet.self,
            WeightLog.self,
            MedicalRecord.self,
            DailyTask.self,
            PetAppointment.self,
            LitterLog.self,
            WaterLog.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not initialize DatabaseProvider: \(error)")
        }
    }
}
