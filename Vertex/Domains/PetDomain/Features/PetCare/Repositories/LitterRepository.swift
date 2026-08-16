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
    
    func fetchLogs(for pet: Pet, on date: Date) async throws -> [LitterLog] {
        // Fetch from API
        do {
            let dtos: [LitterLogDTO] = try await NetworkManager.shared.request(endpoint: "/pets/\(pet.id.uuidString)/litter-logs")
            
            // Sync logic: Merge remote data into SwiftData
            for dto in dtos {
                guard let uuid = UUID(uuidString: dto.id) else { continue }
                if let existing = pet.litterLogs.first(where: { $0.id == uuid }) {
                    // Update existing
                    existing.amount = dto.amount
                    existing.type = dto.type
                    existing.date = dto.date
                } else {
                    // Insert new
                    let newLog = LitterLog(date: dto.date, type: dto.type, amount: dto.amount)
                    newLog.id = uuid
                    newLog.pet = pet
                    context.insert(newLog)
                }
            }
            try? context.save()
            
            print("Fetched and synced \(dtos.count) remote litter logs")
        } catch {
            print("Failed to fetch remote logs: \(error)")
        }
        
        // Return local data for instant UI
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return pet.litterLogs.filter { log in
            log.date >= startOfDay && log.date < endOfDay
        }.sorted { $0.date > $1.date }
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
    
    func fetchLogs(for pet: Pet, on date: Date) async throws -> [WaterLog] {
        do {
            let dtos: [WaterLogDTO] = try await NetworkManager.shared.request(endpoint: "/pets/\(pet.id.uuidString)/water-logs")
            
            for dto in dtos {
                guard let uuid = UUID(uuidString: dto.id) else { continue }
                if let existing = pet.waterLogs.first(where: { $0.id == uuid }) {
                    existing.amount = dto.amount
                    existing.date = dto.date
                } else {
                    let newLog = WaterLog(date: dto.date, amount: dto.amount)
                    newLog.id = uuid
                    newLog.pet = pet
                    context.insert(newLog)
                }
            }
            try? context.save()
        } catch {
            print("Failed to fetch remote water logs: \(error)")
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return pet.waterLogs.filter { log in
            log.date >= startOfDay && log.date < endOfDay
        }.sorted { $0.date > $1.date }
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
