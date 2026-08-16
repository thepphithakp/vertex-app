import SwiftUI
import Combine

/// PetStore (Domain State)
/// ใช้สำหรับเก็บ State ที่แชร์กัน "ภายใน Pet Domain" เท่านั้น
/// เช่น แมวตัวไหนที่กำลังเป็น "ตัวที่ถูกเลือก (Active)" เพื่อให้หน้า Shop และหน้า Booking ดึงไปใช้ต่อได้ทันที
@MainActor
final class PetStore: ObservableObject {
    @Published var activePet: Pet? = nil
    @Published var allPets: [Pet] = []
    @Published var isLoading: Bool = false
    @Published var fetchProgress: Double = 0.0
    
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
        
        self.isLoading = true
        self.fetchProgress = 0.0
        
        let progressTask = Task {
            for i in 1...90 {
                try? await Task.sleep(nanoseconds: 10_000_000) // 10ms per step
                if Task.isCancelled { break }
                await MainActor.run { self.fetchProgress = Double(i) / 100.0 }
            }
        }
        
        do {
            let repository = RemotePetRepository()
            let fetchedPets = try await repository.fetchPets()
            
            progressTask.cancel()
            self.fetchProgress = 1.0
            try? await Task.sleep(nanoseconds: 200_000_000) // slight delay to show 100%
            
            self.updatePets(fetchedPets)
            self.lastFetchTime = Date()
        } catch {
            progressTask.cancel()
            print("Failed to load pets globally: \(error)")
        }
        
        withAnimation {
            self.isLoading = false
        }
    }
}
