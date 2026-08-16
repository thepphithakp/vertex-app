import Foundation
import SwiftData

@Model
final class PetCaregiver {
    var id: UUID
    var petId: UUID
    var userId: UUID
    
    // Permissions
    var canEditProfile: Bool
    var canAddMedical: Bool
    var canAddWeight: Bool
    var canManageTasks: Bool
    var canManageLitter: Bool
    
    // Relationship
    var pet: Pet?
    
    init(id: UUID = UUID(), petId: UUID, userId: UUID, canEditProfile: Bool = false, canAddMedical: Bool = false, canAddWeight: Bool = false, canManageTasks: Bool = false, canManageLitter: Bool = false) {
        self.id = id
        self.petId = petId
        self.userId = userId
        self.canEditProfile = canEditProfile
        self.canAddMedical = canAddMedical
        self.canAddWeight = canAddWeight
        self.canManageTasks = canManageTasks
        self.canManageLitter = canManageLitter
    }
}
