import Foundation

class RemoteMasterDataRepository: MasterDataRepository {
    func fetchCatBreeds() async throws -> [String] {
        return try await NetworkManager.shared.request(endpoint: "/master-data/cat-breeds")
    }
    
    func fetchBloodTypes() async throws -> [String] {
        return try await NetworkManager.shared.request(endpoint: "/master-data/blood-types")
    }
}
