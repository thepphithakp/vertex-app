import ActivityKit
import SwiftUI
import WidgetKit

// =============================================================================
// Live Activity ของที่จอดรถ
// =============================================================================
// การ์ดนี้มีสองหน้าคนละเรื่องกัน
//
//   จอดซ้อนคัน — มี deadline จริง (13:00) และมีค่าปรับจริง เป็นการนับถอยหลัง
//                 หน้าตาจึงเป็นแถบเวลาที่วิ่งเข้าหาเส้นตาย
//   จอดปกติ    — ไม่มี deadline สิ่งที่คนอยากรู้คือ "จอดไว้ตรงไหน" กับ "นานแค่ไหนแล้ว"
//
// ⚠️ ห้ามใส่ progress bar ให้หน้าจอดปกติ แถบที่ไม่มีปลายทางคือของประดับ
//    คนอ่านจะพยายามตีความว่ามันเต็มแล้วจะเกิดอะไรขึ้น แล้วไม่เจอคำตอบ
//
// ⚠️ ตัวเลขที่คำนวณเองใน body จะแข็งค้างอยู่ที่ค่าตอน render ครั้งสุดท้าย
//    ที่เดินเองได้โดยแอปไม่ต้องตื่นมีแค่ Text แบบ timerInterval / style กับ
//    ProgressView(timerInterval:)
//    สีของแถบจึงเปลี่ยนได้แค่ตอนแอป update หรือตอนเลย staleDate
//    (ตั้งไว้ที่เส้นตายพอดี ดู EVDomainDashboardView)
//
// ⚠️ ไม่ใช้ Text(timerInterval:) ถึงแม้มันจะเดินวินาทีให้เอง เพราะ MM:SS อ่านกำกวม
//    "28:41" แยกไม่ออกว่า 28 นาที 41 วินาที หรือ 28 ชั่วโมง 41 นาที
//    และการ์ดใบนี้สลับไปมากับ "7 hrs, 49 min" อยู่แล้ว ยิ่งทำให้เดาผิดง่าย
//    style .relative ให้ "28 min" / "45 sec" ซึ่งอ่านครั้งเดียวจบและยังเดินเองได้เหมือนกัน
//    ผลพลอยได้อีกอย่างคือตอนจอหรี่ (AOD ลด refresh เหลือ 1Hz) จะไม่เห็นขีดวินาที
//    แบบที่ timerInterval ขึ้นเป็น "28:--"
// =============================================================================

struct ParkingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParkingAttributes.self) { context in
            ParkingLockScreenView(state: context.state, isStale: context.isStale)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .activityBackgroundTint(Color(hex: "0E1116").opacity(0.92))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            let state = context.state
            let window = state.deadlineWindow
            let urgency = state.urgency(isStale: context.isStale)
            let accent = window == nil ? ParkingPalette.resting : urgency.accent

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(state.floor.isEmpty ? "-" : state.floor)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                        Text("FLOOR")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 1) {
                        if let window {
                            CountdownText(window: window, urgency: urgency, size: 22)
                        } else if let parkedAt = state.parkedAt {
                            ElapsedText(since: parkedAt, size: 22)
                        } else {
                            Text(state.zone.isEmpty ? "-" : state.zone)
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        Text(window == nil ? "PARKED FOR"
                                           : (urgency == .overdue ? "OVERDUE BY" : "TIME LEFT"))
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        if let window {
                            DeadlineTrack(window: window, urgency: urgency)
                        }
                        HStack(spacing: 8) {
                            SpotChip(floor: state.floor, zone: state.zone)
                            Spacer(minLength: 4)
                            if window != nil {
                                FineChip()
                            } else if let note = state.note, !note.isEmpty {
                                NoteChip(note: note)
                            }
                        }
                    }
                    .padding(.top, 2)
                }

            } compactLeading: {
                Image(systemName: state.symbol)
                    .foregroundStyle(accent)

            } compactTrailing: {
                if let window {
                    // "7 hrs, 56 min" ยัดลงเกาะไม่ได้ ส่วนเลขที่คำนวณเองจะค้าง
                    // เวลาเส้นตายตรงๆ สั้นกว่าและไม่มีวันผิดไม่ว่าจะ render ตอนไหน
                    Text(window.upperBound,
                         format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(accent)
                } else {
                    Text(state.floor.isEmpty ? "•" : state.floor)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(accent)
                }

            } minimal: {
                Image(systemName: state.symbol)
                    .foregroundStyle(accent)
            }
            .widgetURL(URL(string: "vertex://ev-parking"))
            .keylineTint(accent)
        }
    }
}

// MARK: - lock screen

private struct ParkingLockScreenView: View {
    let state: ParkingAttributes.ContentState
    let isStale: Bool

    var body: some View {
        if let window = state.deadlineWindow {
            DeadlineCard(state: state, window: window, urgency: state.urgency(isStale: isStale))
        } else {
            RestingCard(state: state)
        }
    }
}

/// จอดซ้อนคัน — เส้นตายจริง ค่าปรับจริง
private struct DeadlineCard: View {
    let state: ParkingAttributes.ContentState
    let window: ClosedRange<Date>
    let urgency: ParkingUrgency

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: urgency.symbol)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(urgency.accent)
                    Text(urgency.headline(deadline: window.upperBound))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 0) {
                    CountdownText(window: window, urgency: urgency, size: 30)
                    Text(urgency == .overdue ? "OVERDUE BY" : "LEFT")
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            DeadlineTrack(window: window, urgency: urgency)

            HStack(spacing: 8) {
                SpotChip(floor: state.floor, zone: state.zone)
                    .layoutPriority(2)
                if let note = state.note, !note.isEmpty {
                    NoteChip(note: note)
                        .layoutPriority(0)
                }
                Spacer(minLength: 0)
                FineChip()
                    .layoutPriority(1)
            }
        }
    }
}

/// จอดปกติ — ไม่มีเส้นตาย จุดจอดคือพระเอก เวลาที่ผ่านไปเป็นตัวประกอบที่ขยับได้เอง
private struct RestingCard: View {
    let state: ParkingAttributes.ContentState

    private let accent = ParkingPalette.resting

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "car.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accent)
                Text("Parked")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                Spacer(minLength: 4)
                if let parkedAt = state.parkedAt {
                    ElapsedText(since: parkedAt, size: 17)
                }
            }

            HStack(alignment: .bottom, spacing: 0) {
                Field(label: "FLOOR", value: state.floor, accent: accent)
                Rectangle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 1, height: 30)
                    .padding(.horizontal, 16)
                Field(label: "ZONE", value: state.zone, accent: accent)
                Spacer(minLength: 8)
                if let note = state.note, !note.isEmpty {
                    NoteChip(note: note)
                }
            }
        }
    }

    private struct Field: View {
        let label: String
        let value: String
        let accent: Color

        var body: some View {
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.5))
                Text(value.isEmpty ? "-" : value)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - ชิ้นส่วนที่เดินเองได้

/// แถบเวลาที่วิ่งจากตอนจอดไปหา 13:00
///
/// ใช้ ProgressView แบบ timerInterval ของระบบตรงๆ เพราะเป็นทางเดียวที่แถบจะขยับ
/// ต่อเนื่องโดยแอปไม่ต้องทำงาน — ถ้าใส่ ProgressViewStyle ของตัวเองเมื่อไหร่
/// fractionCompleted จะกลายเป็น nil และแถบจะแข็งค้าง
private struct DeadlineTrack: View {
    let window: ClosedRange<Date>
    let urgency: ParkingUrgency

    var body: some View {
        ProgressView(timerInterval: window, countsDown: false) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .progressViewStyle(.linear)
        .tint(urgency.accent)
        .scaleEffect(x: 1, y: 1.4, anchor: .center)
        .padding(.vertical, 2)
    }
}

private struct CountdownText: View {
    let window: ClosedRange<Date>
    let urgency: ParkingUrgency
    var size: CGFloat

    var body: some View {
        // .relative นับให้ทั้งขาก่อนและหลังเส้นตาย ตอนเลยมาแล้วมันจะนับขึ้นเอง
        Text(window.upperBound, style: .relative)
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(urgency.accent)
            .lineLimit(1)
            // "7 hrs, 49 min" ยาวกว่า "45 sec" เกือบสามเท่า ปล่อยให้ย่อเองแทนที่จะโดนตัด
            // ผลพลอยได้คือยิ่งใกล้เส้นตายข้อความยิ่งสั้น ตัวเลขก็ยิ่งใหญ่ขึ้นเอง
            .minimumScaleFactor(0.55)
            .multilineTextAlignment(.trailing)
    }
}

private struct ElapsedText: View {
    let since: Date
    var size: CGFloat

    var body: some View {
        Text(since, style: .relative)
            .font(.system(size: size, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white.opacity(0.75))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .multilineTextAlignment(.trailing)
    }
}

// MARK: - chip

private struct SpotChip: View {
    let floor: String
    let zone: String

    var body: some View {
        ChipShell(tint: .white.opacity(0.12)) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 10, weight: .bold))
            Text(ParkingSpot.describe(floor: floor, zone: zone))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(.white.opacity(0.88))
    }
}

private struct NoteChip: View {
    let note: String

    var body: some View {
        ChipShell(tint: .white.opacity(0.08)) {
            Image(systemName: "text.alignleft")
                .font(.system(size: 10, weight: .bold))
            Text(note)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(.white.opacity(0.65))
    }
}

private struct FineChip: View {
    // จงใจไม่ผูกสีกับ urgency — ชิป ฿1,000 สีเขียวจะอ่านว่า "เรียบร้อยดี"
    // ทั้งที่มันคือค่าปรับ ซึ่งเป็นค่าคงที่ไม่ใช่สถานะที่เปลี่ยนตามเวลา
    var body: some View {
        ChipShell(tint: Color(hex: "FF453A").opacity(0.16)) {
            Image(systemName: "banknote.fill")
                .font(.system(size: 10, weight: .bold))
            Text(ParkingDeadline.fineText)
                .font(.system(size: 12, weight: .heavy, design: .rounded))
            Text("fine")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .opacity(0.75)
        }
        .foregroundStyle(Color(hex: "FF8A80"))
    }
}

private struct ChipShell<Content: View>: View {
    let tint: Color
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 4) {
            content
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(tint))
    }
}

// MARK: - โทนสีตามความเร่งด่วน

enum ParkingPalette {
    /// จอดปกติ ไม่มีเส้นตาย — ใช้สีเดียวกับ widget บนหน้า home
    static let resting = Color(hex: "38E1FF")
}

private extension ParkingUrgency {
    var accent: Color {
        switch self {
        case .relaxed: Color(hex: "3DDC84")
        case .soon:    Color(hex: "FFD60A")
        case .urgent:  Color(hex: "FF9F0A")
        case .overdue: Color(hex: "FF453A")
        }
    }

    var symbol: String {
        self == .overdue ? "exclamationmark.triangle.fill" : "clock.badge.exclamationmark.fill"
    }

    func headline(deadline: Date) -> String {
        switch self {
        case .overdue: "Move car now"
        default:       "Move car by \(Self.clock(deadline))"
        }
    }

    private static func clock(_ date: Date) -> String {
        date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
    }
}

private extension ParkingAttributes.ContentState {
    var symbol: String {
        isDoubleParked ? "exclamationmark.triangle.fill" : "car.fill"
    }

    func urgency(isStale: Bool) -> ParkingUrgency {
        guard let moveBy, isDoubleParked else { return .relaxed }
        // ตอนเลย staleDate ระบบจะสั่ง render ใหม่ให้เอง ซึ่งเป็นจังหวะเดียวที่การ์ด
        // เปลี่ยนเป็นสีแดงได้โดยแอปไม่ต้องตื่น
        return isStale ? .overdue : ParkingUrgency.at(.now, deadline: moveBy)
    }
}
