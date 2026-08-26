import Foundation

extension Pet {

    /// สร้าง `Pet` จากผลของ GraphQL
    ///
    /// โยน error แทนที่จะใส่ค่าแทนเงียบๆ เมื่อ id หรือวันเกิดอ่านไม่ออก
    /// เพราะทั้งสองอย่างเป็น non-null ในสเปก ถ้าอ่านไม่ออกแปลว่าฝั่ง server ผิด
    /// และการกลบด้วยค่าเริ่มต้นจะทำให้เห็นเป็นแค่ "อายุแปลกๆ" ที่ไล่หาสาเหตุยาก
    convenience init(graphQL pet: VertexAPI.PetCoreFields) throws {
        guard let id = UUID(uuidString: pet.id) else {
            throw APIError(message: "id ของสัตว์เลี้ยงจากเซิร์ฟเวอร์ไม่ใช่ UUID: \(pet.id)", requestId: nil)
        }
        guard let birthDate = VertexAPI.date(from: pet.birthDate) else {
            throw APIError(message: "วันเกิดของ \(pet.name) อ่านไม่ออก: \(pet.birthDate)", requestId: nil)
        }

        self.init(
            id: id,
            ownerId: UUID(uuidString: pet.owner.id),
            name: pet.name,
            species: pet.species,
            breed: pet.breed,
            colorCode: pet.colorCode,
            birthDate: birthDate,
            gender: pet.gender,
            // รูปไม่ได้มากับ GraphQL โดยตั้งใจ — เติมทีหลังจาก PetAvatarStore
            avatarData: nil,
            currentWeight: pet.currentWeight,
            microchipId: pet.microchipId,
            isSpayedNeutered: pet.isSpayedNeutered,
            bloodType: pet.bloodType,
            allergies: pet.allergies,
            personality: pet.personality
        )
    }
}
