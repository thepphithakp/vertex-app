import SwiftUI
import SwiftData
import Combine

// กำหนดเมนูหลักของแอป
enum AppTab: String, CaseIterable {
    case home = "house.fill"
    case pet = "pawprint.fill"
    case finance = "chart.pie.fill"
    case ev = "car.fill"
    case profile = "person.fill"

    var title: String {
        switch self {
        case .home: return "Home"
        case .pet: return "Pet"
        case .finance: return "Finance"
        case .ev: return "EV"
        case .profile: return "Profile"
        }
    }
}

// สถานะการหดของ tab bar — แชร์ให้ทุกหน้าที่ scroll ได้สั่งหด/ขยายผ่าน
// compactsTabBarOnScroll() โดยไม่ต้องส่ง binding ทะลุหลายชั้น
@MainActor
final class TabBarChrome: ObservableObject {
    static let shared = TabBarChrome()

    @Published private(set) var isCompact = false

    // กันการสั่น: ต้องเลื่อนเกิน threshold ถึงจะสลับสถานะ
    private let threshold: CGFloat = 6

    func scrollChanged(from oldOffset: CGFloat, to newOffset: CGFloat) {
        // อยู่ใกล้หัว content = ขยายกลับเสมอ (รวม bounce ด้านบน)
        if newOffset <= 0 {
            set(false)
            return
        }
        let delta = newOffset - oldOffset
        if delta > threshold {
            set(true)
        } else if delta < -threshold {
            set(false)
        }
    }

    func reset() { set(false) }

    private func set(_ compact: Bool) {
        guard isCompact != compact else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            isCompact = compact
        }
    }
}

extension View {
    // ติดที่ ScrollView/List เพื่อให้ tab bar หดตอนเลื่อนลงและขยายตอนเลื่อนขึ้น
    func compactsTabBarOnScroll() -> some View {
        onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { oldValue, newValue in
            TabBarChrome.shared.scrollChanged(from: oldValue, to: newValue)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var appStore: AppStore
    @EnvironmentObject private var petStore: PetStore
    @State private var selectedTab: AppTab = .pet
    @ObservedObject private var chrome = TabBarChrome.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. Home (Placeholder)
            Tab(AppTab.home.title, systemImage: AppTab.home.rawValue, value: .home) {
                NavigationStack {
                    Text("Vertex Super App")
                        .font(.largeTitle).bold()
                        .navigationTitle("Home")
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }

            // 2. Pet Domain
            Tab(AppTab.pet.title, systemImage: AppTab.pet.rawValue, value: .pet) {
                NavigationStack {
                    PetDomainDashboardView()
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }

            // 3. Finance (Placeholder)
            Tab(AppTab.finance.title, systemImage: AppTab.finance.rawValue, value: .finance) {
                NavigationStack {
                    Text("Finance Hub")
                        .font(.largeTitle).bold()
                        .navigationTitle("Finance")
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }

            // 4. EV
            Tab(AppTab.ev.title, systemImage: AppTab.ev.rawValue, value: .ev) {
                NavigationStack {
                    EVDomainDashboardView()
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }

            // 5. Profile
            Tab(AppTab.profile.title, systemImage: AppTab.profile.rawValue, value: .profile) {
                NavigationStack {
                    ProfileView()
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        // วาง bar ผ่าน safeAreaInset เพื่อให้ content ทุก tab (รวมหน้า push)
        // ได้ inset ด้านล่างอัตโนมัติ ไม่ต้องเผื่อระยะเองเหมือน overlay แบบเก่า
        .safeAreaInset(edge: .bottom) {
            LiquidGlassTabBar(selectedTab: $selectedTab, isCompact: chrome.isCompact)
        }
        .task {
            await petStore.loadAllPets()
        }
        .onOpenURL { url in
            if url.scheme == "vertex" && url.host == "ev-parking" {
                selectedTab = .ev
            }
        }
        .onChange(of: selectedTab) {
            // เปลี่ยน tab แล้วให้ bar ขยายกลับ ไม่ค้างสถานะหดจาก tab ก่อน
            chrome.reset()
        }
    }
}

// Tab bar แบบ Instagram บน iOS 26: Liquid Glass จริงจาก glassEffect()
// ตอนเลื่อนลง bar หดเตี้ยลง (ซ่อน label, ย่อไอคอน) แต่ยังเห็นครบทุกเมนู
struct LiquidGlassTabBar: View {
    @Binding var selectedTab: AppTab
    var isCompact: Bool
    @Namespace private var tabAnimation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.rawValue)
                            .font(.system(size: isCompact ? 17 : 22))
                        if !isCompact {
                            Text(tab.title)
                                .font(.system(size: 10, weight: selectedTab == tab ? .bold : .medium))
                        }
                    }
                    .foregroundStyle(selectedTab == tab ? Color.accentColor : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, isCompact ? 7 : 10)
                    .background {
                        if selectedTab == tab {
                            Capsule()
                                .fill(Color.accentColor.opacity(0.15))
                                .matchedGeometryEffect(id: "ACTIVETAB", in: tabAnimation)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .glassEffect(.regular, in: Capsule())
        .padding(.horizontal, isCompact ? 64 : 20)
        .padding(.bottom, 4)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isCompact)
    }
}

#Preview {
    ContentView()
        .modelContainer(DatabaseProvider.shared.container)
        .environmentObject(AppStore())
        .environmentObject(PetStore())
}
