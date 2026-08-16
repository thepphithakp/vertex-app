import Foundation

protocol MasterDataRepository {
    func fetchCatBreeds() async throws -> [String]
    func fetchBloodTypes() async throws -> [String]
}

final class LocalMasterDataRepository: MasterDataRepository {
    func fetchCatBreeds() async throws -> [String] {
        // จำลองการดึงข้อมูลจาก API (ดีเลย์ 0.5 วินาที)
        try await Task.sleep(nanoseconds: 500_000_000)
        return [
            "Scottish Fold", "British Shorthair", "Persian", 
            "Maine Coon", "Siamese", "Sphynx", "Bengal", 
            "Ragdoll", "American Shorthair", "Exotic Shorthair", 
            "Mixed / Other"
        ]
    }
    
    func fetchBloodTypes() async throws -> [String] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return ["Unknown", "A", "B", "AB"]
    }
}
