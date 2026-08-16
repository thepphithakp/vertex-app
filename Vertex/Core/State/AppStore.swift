import SwiftUI
import Combine

/// AppStore (Global State)
/// ใช้สำหรับเก็บ State ที่ใช้ร่วมกัน "ทั้งแอป" (ข้าม Domain) 
/// เช่น ข้อมูล User ที่ล็อกอิน, Theme, หรือ Domain ปัจจุบันที่กำลังใช้งานอยู่
@MainActor
final class AppStore: ObservableObject {
    @Published var userName: String = "John Doe"
    @Published var activeDomain: String? = nil
    
    // สามารถใส่ Logic ส่วนกลางได้ที่นี่
    func logout() {
        userName = "Guest"
    }
}
