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
    
    func scheduleDoubleParkingReminder() {
        // Schedule multiple reminders
        let reminderTimes = [
            (hour: 9, minute: 0),
            (hour: 10, minute: 0),
            (hour: 11, minute: 0),
            (hour: 12, minute: 0),
            (hour: 12, minute: 45) // Final warning
        ]
        
        for time in reminderTimes {
            let identifier = "doubleParkingReminder_\(time.hour)_\(time.minute)"
            
            let content = UNMutableNotificationContent()
            content.title = "⚠️ แจ้งเตือนจอดซ้อนคัน!"
            
            if time.hour == 12 && time.minute == 45 {
                content.body = "เหลือเวลาอีก 15 นาทีถึง 13:00 น.! รีบไปเลื่อนรถด่วนเพื่อเลี่ยงค่าปรับ 1,000 บาท"
            } else {
                content.body = "คุณจอดรถซ้อนคันอยู่ อย่าลืมไปเลื่อนรถเข้าช่องจอดก่อน 13:00 น. นะครับ (ค่าปรับ 1,000 บาท)"
            }
            
            content.sound = .default
            
            var components = DateComponents()
            components.hour = time.hour
            components.minute = time.minute
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Failed to schedule double parking notification for \(time.hour):\(time.minute): \(error)")
                }
            }
        }
    }
    
    func cancelDoubleParkingReminder() {
        let identifiers = [
            "doubleParkingReminder_9_0",
            "doubleParkingReminder_10_0",
            "doubleParkingReminder_11_0",
            "doubleParkingReminder_12_0",
            "doubleParkingReminder_12_45"
        ]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
