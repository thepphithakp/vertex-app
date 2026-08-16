import Foundation
import SwiftData

@Model
final class DailyTask {
    var id: UUID
    var taskName: String
    var scheduledTime: Date
    var completedAt: Date?
    var completedBy: String?
    
    var pet: Pet?
    
    init(id: UUID = UUID(), taskName: String, scheduledTime: Date, completedAt: Date? = nil, completedBy: String? = nil) {
        self.id = id
        self.taskName = taskName
        self.scheduledTime = scheduledTime
        self.completedAt = completedAt
        self.completedBy = completedBy
    }
}
