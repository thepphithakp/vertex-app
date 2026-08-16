import Foundation
import SwiftData

@Model
final class PetAppointment {
    var id: UUID
    var title: String
    var appointmentType: String // เช่น "Vaccine", "Checkup", "Grooming"
    var date: Date
    var notes: String
    var isReminderSet: Bool
    
    // Relationship: เชื่อมว่าการนัดหมายนี้เป็นของแมวตัวไหน
    var pet: Pet?
    
    init(id: UUID = UUID(), title: String, appointmentType: String, date: Date, notes: String, isReminderSet: Bool) {
        self.id = id
        self.title = title
        self.appointmentType = appointmentType
        self.date = date
        self.notes = notes
        self.isReminderSet = isReminderSet
    }
}
