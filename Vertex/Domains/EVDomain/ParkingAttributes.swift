import Foundation
import ActivityKit

// =============================================================================
// state ที่ Live Activity กับ widget ใช้ร่วมกัน
// =============================================================================
// ⚠️ ไฟล์นี้มีสองชุด (VertexWidget/ กับ Vertex/Domains/EVDomain/) เพราะทั้งสอง
//    target เป็น file system synchronized group แก้ที่เดียวไม่พอ ต้องแก้ให้ตรงกัน
// =============================================================================

public struct ParkingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var isDoubleParked: Bool
        public var floor: String
        public var zone: String

        // สามตัวล่างเพิ่มทีหลัง จงใจทำเป็น optional
        // Codable ที่สังเคราะห์ให้จะยอมให้ key หายได้เฉพาะ field ที่เป็น optional
        // ถ้าประกาศเป็น non-optional แล้วผู้ใช้อัปเดตแอปทั้งที่การ์ดยังค้างบน
        // lock screen อยู่ state เก่าจะ decode ไม่ผ่านและการ์ดจะค้างแบบแก้ไม่ได้
        public var parkedAt: Date?
        public var moveBy: Date?
        public var note: String?

        public init(
            isDoubleParked: Bool,
            floor: String,
            zone: String,
            parkedAt: Date? = nil,
            moveBy: Date? = nil,
            note: String? = nil
        ) {
            self.isDoubleParked = isDoubleParked
            self.floor = floor
            self.zone = zone
            self.parkedAt = parkedAt
            self.moveBy = moveBy
            self.note = note
        }

        /// ช่วงเวลาที่เอาไปป้อน ProgressView / Text แบบ timerInterval ได้
        /// nil เมื่อไม่มี deadline หรือเป็น state เก่าที่ยังไม่มีวันเวลาติดมา
        public var deadlineWindow: ClosedRange<Date>? {
            guard isDoubleParked, let parkedAt, let moveBy, parkedAt < moveBy else { return nil }
            return parkedAt...moveBy
        }
    }

    public init() {}
}

// MARK: - deadline

public enum ParkingDeadline {
    /// เวลาที่ต้องเลื่อนรถออกจากช่องจอดซ้อน
    /// ต้องตรงกับรอบเตือนใน NotificationManager.scheduleDoubleParkingReminder()
    public static let hour = 13
    public static let fineText = "฿1,000"

    /// 13:00 ครั้งถัดไปนับจากเวลาที่ให้มา — จอดตอนบ่ายสองจะได้ 13:00 ของพรุ่งนี้
    /// ตรงกับพฤติกรรมของ UNCalendarNotificationTrigger ที่ตั้ง repeats: false
    public static func next(after date: Date, calendar: Calendar = .current) -> Date {
        calendar.nextDate(
            after: date,
            matching: DateComponents(hour: hour, minute: 0, second: 0),
            matchingPolicy: .nextTime
        ) ?? date.addingTimeInterval(60 * 60)
    }
}

// MARK: - ระดับความเร่งด่วน

public enum ParkingUrgency {
    case relaxed
    case soon
    case urgent
    case overdue

    public static func at(_ now: Date, deadline: Date) -> ParkingUrgency {
        let left = deadline.timeIntervalSince(now)
        switch left {
        case ..<0:           return .overdue
        case ..<(15 * 60):   return .urgent
        case ..<(60 * 60):   return .soon
        default:             return .relaxed
        }
    }
}

// MARK: - ข้อความบอกจุดจอด

public enum ParkingSpot {
    public static func describe(floor: String, zone: String) -> String {
        let parts = [
            floor.isEmpty ? nil : "Floor \(floor)",
            zone.isEmpty ? nil : zone
        ].compactMap { $0 }
        return parts.isEmpty ? "Saved spot" : parts.joined(separator: " · ")
    }
}
