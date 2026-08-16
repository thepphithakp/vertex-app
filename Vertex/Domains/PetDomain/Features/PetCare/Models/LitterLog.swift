import Foundation
import SwiftData

@Model
final class LitterLog {
    var id: UUID
    var date: Date
    var type: String // "Poop" หรือ "Pee"
    var amount: Int // จำนวนก้อน หรือจำนวนครั้ง
    
    // Relationship: เชื่อมกลับไปที่แมว
    var pet: Pet?
    
    init(id: UUID = UUID(), date: Date = Date(), type: String, amount: Int = 1) {
        self.id = id
        self.date = date
        self.type = type
        self.amount = amount
    }
}

@Model
final class WaterLog {
    var id: UUID
    var date: Date
    var amount: Int // amount in ml
    
    // Relationship: Link back to Pet
    var pet: Pet?
    
    init(id: UUID = UUID(), date: Date = Date(), amount: Int) {
        self.id = id
        self.date = date
        self.amount = amount
    }
}
