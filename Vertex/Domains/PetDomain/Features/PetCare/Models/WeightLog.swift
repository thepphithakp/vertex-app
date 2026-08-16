import Foundation
import SwiftData

@Model
final class WeightLog {
    var id: UUID
    var weight: Double
    var dateRecorded: Date
    
    var pet: Pet?
    
    init(id: UUID = UUID(), weight: Double, dateRecorded: Date) {
        self.id = id
        self.weight = weight
        self.dateRecorded = dateRecorded
    }
}
