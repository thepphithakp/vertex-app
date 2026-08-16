import Foundation
import SwiftData

protocol AppointmentRepository {
    func fetchAppointments() async throws -> [PetAppointment]
    func saveAppointment(_ appointment: PetAppointment) async throws
    func deleteAppointment(_ appointment: PetAppointment) async throws
}

@MainActor
final class LocalAppointmentRepository: AppointmentRepository {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func fetchAppointments() async throws -> [PetAppointment] {
        // ดึงนัดหมายเรียงตามวันที่ใกล้ที่สุด
        let descriptor = FetchDescriptor<PetAppointment>(sortBy: [SortDescriptor(\.date)])
        return try context.fetch(descriptor)
    }
    
    func saveAppointment(_ appointment: PetAppointment) async throws {
        context.insert(appointment)
        try context.save()
    }
    
    func deleteAppointment(_ appointment: PetAppointment) async throws {
        context.delete(appointment)
        try context.save()
    }
}
