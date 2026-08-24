import SwiftUI

// หน้าแรกของ super app — รวมสถานะจากทุก domain ไว้ที่เดียว
// หลักการ: การ์ดแต่ละใบต้องบอก "สถานะจริงตอนนี้" ไม่ใช่แค่ปุ่มลัด
// ถ้ายังไม่มีข้อมูล ให้บอกว่าต้องทำอะไรต่อ
struct HomeDashboardView: View {
    @Binding var selectedTab: AppTab

    @EnvironmentObject private var appStore: AppStore
    @EnvironmentObject private var petStore: PetStore
    @ObservedObject private var auth = AuthService.shared

    // อ่านสถานะที่จอดรถจาก App Group เดียวกับที่ EV domain และ widget ใช้
    @AppStorage("parkedFloor", store: SharedUserDefaults.shared) private var parkedFloor: String = ""
    @AppStorage("parkedZone", store: SharedUserDefaults.shared) private var parkedZone: String = ""
    @AppStorage("parkedDate", store: SharedUserDefaults.shared) private var parkedDateDouble: Double = 0

    private var displayName: String {
        auth.currentUser?.fullName ?? appStore.userName
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default: return "Good night"
        }
    }

    private var isParked: Bool {
        !parkedFloor.isEmpty || !parkedZone.isEmpty
    }

    private var parkedSummary: String {
        var parts: [String] = []
        if !parkedFloor.isEmpty { parts.append("ชั้น \(parkedFloor)") }
        if !parkedZone.isEmpty { parts.append("โซน \(parkedZone)") }
        return parts.joined(separator: " · ")
    }

    private var parkedSince: String? {
        guard parkedDateDouble > 0 else { return nil }
        let date = Date(timeIntervalSince1970: parkedDateDouble)
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "th_TH")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Services")
                        .font(.headline)
                        .padding(.horizontal)

                    petCard
                    evCard
                    financeCard
                }
            }
            .padding(.top)
        }
        .tabBarAware()
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .refreshable {
            await petStore.loadAllPets(force: true)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(displayName)
                    .font(.largeTitle)
                    .bold()
                    .lineLimit(1)
            }
            Spacer()
            Button {
                selectedTab = .profile
            } label: {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Profile")
        }
        .padding(.horizontal)
    }

    private var petCard: some View {
        DomainCard(
            icon: "pawprint.fill",
            title: "Pet",
            tint: .pink,
            action: { selectedTab = .pet }
        ) {
            if petStore.isLoading && petStore.allPets.isEmpty {
                Text("กำลังโหลดข้อมูลแมว…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if petStore.allPets.isEmpty {
                Text("ยังไม่มีแมวในระบบ — เพิ่มตัวแรกเพื่อเริ่มติดตามสุขภาพ")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 6) {
                    Text("\(petStore.allPets.count)")
                        .font(.title2)
                        .bold()
                    Text(petStore.allPets.count == 1 ? "ตัว" : "ตัว")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let active = petStore.activePet {
                        Text("· กำลังดู \(active.name)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private var evCard: some View {
        DomainCard(
            icon: "car.fill",
            title: "EV",
            tint: .blue,
            action: { selectedTab = .ev }
        ) {
            if isParked {
                VStack(alignment: .leading, spacing: 2) {
                    Text(parkedSummary)
                        .font(.title3)
                        .bold()
                    if let since = parkedSince {
                        Text("จอดเมื่อ \(since)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("ยังไม่ได้บันทึกที่จอดรถ")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var financeCard: some View {
        DomainCard(
            icon: "chart.pie.fill",
            title: "Finance",
            tint: .green,
            action: { selectedTab = .finance }
        ) {
            Text("กำลังพัฒนา")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// การ์ดสรุปหนึ่ง domain: ไอคอนสี + ชื่อ + เนื้อหาสถานะที่ caller ส่งเข้ามา
private struct DomainCard<Content: View>: View {
    let icon: String
    let title: String
    let tint: Color
    let action: () -> Void
    @ViewBuilder var content: Content

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(tint)
                    .frame(width: 48, height: 48)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    content
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

// หน้าว่างมาตรฐานสำหรับ domain ที่ยังไม่เปิดใช้งาน
struct ComingSoonView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.title2)
                .bold()
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }
}
