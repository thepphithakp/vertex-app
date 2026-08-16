import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    // ขออนุญาตผู้ใช้เพื่อส่ง Notification
    func requestPermission() async throws -> Bool {
        return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
    }
    
    // ตั้งค่าเวลาเตือนความจำ (เตือนล่วงหน้า 1 วัน)
    func scheduleAppointmentReminder(for appointment: PetAppointment, petName: String) {
        guard appointment.isReminderSet else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "ถึงเวลานัดหมายของ \(petName)"
        content.body = "พรุ่งนี้มีนัดหมาย: \(appointment.title)"
        content.sound = .default
        
        // เตือนล่วงหน้า 1 วัน
        let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: appointment.date) ?? appointment.date
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: appointment.id.uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            } else {
                print("Notification scheduled for \(reminderDate)")
            }
        }
    }
    
    func cancelReminder(for appointmentId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [appointmentId.uuidString])
    }
}
