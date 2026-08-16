import SwiftUI
import Combine

/// PetStore (Domain State)
/// ใช้สำหรับเก็บ State ที่แชร์กัน "ภายใน Pet Domain" เท่านั้น
/// เช่น แมวตัวไหนที่กำลังเป็น "ตัวที่ถูกเลือก (Active)" เพื่อให้หน้า Shop และหน้า Booking ดึงไปใช้ต่อได้ทันที
@MainActor
final class PetStore: ObservableObject {
    @Published var activePet: Pet? = nil
    @Published var allPets: [Pet] = []
    
    func selectPet(_ pet: Pet) {
        self.activePet = pet
    }
    
    func clearSelection() {
        self.activePet = nil
    }
    
    func updatePets(_ pets: [Pet]) {
        self.allPets = pets
        
        // Auto-select first pet if active is nil and we have pets
        if self.activePet == nil, let first = pets.first {
            self.activePet = first
        }
    }
    
    private var lastFetchTime: Date? = nil
    private let cacheTTL: TimeInterval = 86400 // 1 day (24 hours)
    
    var isCacheExpired: Bool {
        guard let lastFetch = lastFetchTime else { return true }
        return Date().timeIntervalSince(lastFetch) > cacheTTL
    }
    
    func loadAllPets(force: Bool = false) async {
        if !force && !allPets.isEmpty && !isCacheExpired {
            return
        }
        
        do {
            let repository = RemotePetRepository()
            let fetchedPets = try await repository.fetchPets()
            self.updatePets(fetchedPets)
            self.lastFetchTime = Date()
        } catch {
            print("Failed to load pets globally: \(error)")
        }
    }
}
