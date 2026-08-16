import SwiftUI
import Combine

@MainActor
final class AppointmentListViewModel: ObservableObject {
    @Published var appointments: [PetAppointment] = []
    @Published var isLoading = false
    
    func loadAppointments(repository: AppointmentRepository) async {
        isLoading = true
        do {
            appointments = try await repository.fetchAppointments()
        } catch {
            print("Failed to fetch appointments: \(error)")
        }
        isLoading = false
    }
    
    func deleteAppointment(_ appointment: PetAppointment, repository: AppointmentRepository) async {
        do {
            // ถ้ายกเลิกนัด ต้องยกเลิกการเตือน (Notification) ด้วย
            NotificationManager.shared.cancelReminder(for: appointment.id)
            try await repository.deleteAppointment(appointment)
            await loadAppointments(repository: repository)
        } catch {
            print("Failed to delete appointment: \(error)")
        }
    }
}
