import Foundation
import SwiftData

@Model
final class Pet {
    var id: UUID
    var ownerId: UUID? // ผูกกับ User ที่เป็นเจ้าของ
    var name: String
    var species: String
    var breed: String
    var colorCode: String
    var birthDate: Date
    var gender: String
    var avatarData: Data?
    
    var currentWeight: Double?
    var microchipId: String?
    var isSpayedNeutered: Bool
    
    // ข้อมูลใหม่ที่เพิ่มเข้ามา
    var bloodType: String?
    var allergies: String?
    var personality: String?
    
    @Relationship(deleteRule: .cascade) var weightLogs: [WeightLog] = []
    @Relationship(deleteRule: .cascade) var medicalRecords: [MedicalRecord] = []
    @Relationship(deleteRule: .cascade) var dailyTasks: [DailyTask] = []
    @Relationship(deleteRule: .cascade) var appointments: [PetAppointment] = []
    @Relationship(deleteRule: .cascade) var litterLogs: [LitterLog] = []
    @Relationship(deleteRule: .cascade) var waterLogs: [WaterLog] = []
    @Relationship(deleteRule: .cascade, inverse: \PetCaregiver.pet) var caregivers: [PetCaregiver] = []
    
    init(id: UUID = UUID(), ownerId: UUID? = nil, name: String, species: String, breed: String, colorCode: String, birthDate: Date, gender: String, avatarData: Data? = nil, currentWeight: Double? = nil, microchipId: String? = nil, isSpayedNeutered: Bool = false, bloodType: String? = nil, allergies: String? = nil, personality: String? = nil) {
        self.id = id
        self.ownerId = ownerId
        self.name = name
        self.species = species
        self.breed = breed
        self.colorCode = colorCode
        self.birthDate = birthDate
        self.gender = gender
        self.avatarData = avatarData
        self.currentWeight = currentWeight
        self.microchipId = microchipId
        self.isSpayedNeutered = isSpayedNeutered
        self.bloodType = bloodType
        self.allergies = allergies
        self.personality = personality
    }
}

extension Pet {
    var ageString: String {
        let components = Calendar.current.dateComponents([.year, .month], from: birthDate, to: Date())
        let years = components.year ?? 0
        let months = components.month ?? 0
        
        if years > 0 && months > 0 {
            return "\(years) ปี \(months) เดือน"
        } else if years > 0 {
            return "\(years) ปี"
        } else if months > 0 {
            return "\(months) เดือน"
        } else {
            return "ไม่ถึง 1 เดือน"
        }
    }
}
