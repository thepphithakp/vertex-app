import Foundation
import SwiftUI
import Combine

@MainActor
final class PetListViewModel: ObservableObject {
    @Published var pets: [Pet] = []
    @Published var isLoading = false
    
    func loadPets(repository: PetRepository) async {
        isLoading = true
        do {
            pets = try await repository.fetchPets()
        } catch {
            print("Failed to fetch pets: \(error)")
        }
        isLoading = false
    }
    
    func deletePet(at offsets: IndexSet, repository: PetRepository) async {
        for index in offsets {
            let pet = pets[index]
            do {
                try await repository.deletePet(pet)
            } catch {
                print("Failed to delete pet: \(error)")
            }
        }
        await loadPets(repository: repository)
    }
}
