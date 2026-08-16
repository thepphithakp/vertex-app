import Foundation
import SwiftData

enum MedicalRecordType: String, Codable {
    case vaccine
    case deworming
    case treatment
    case checkup
}

@Model
final class MedicalRecord {
    var id: UUID
    var type: MedicalRecordType
    var title: String
    var administeredDate: Date
    var nextDueDate: Date?
    var notes: String?
    
    var pet: Pet?
    
    init(id: UUID = UUID(), type: MedicalRecordType, title: String, administeredDate: Date, nextDueDate: Date? = nil, notes: String? = nil) {
        self.id = id
        self.type = type
        self.title = title
        self.administeredDate = administeredDate
        self.nextDueDate = nextDueDate
        self.notes = notes
    }
}
