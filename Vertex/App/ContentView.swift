import SwiftUI
import SwiftData

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

struct ContentView: View {
    @EnvironmentObject private var appStore: AppStore
    @EnvironmentObject private var petStore: PetStore
    @State private var selectedTab: AppTab = .pet
    
    // ซ่อน TabBar ดั้งเดิมตอนที่ถูกดันไปหน้าลึกๆ
    @State private var isTabBarHidden = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // โซนเนื้อหาหลัก
            TabView(selection: $selectedTab) {
                // 1. Home (Placeholder)
                NavigationStack {
                    Text("Vertex Super App")
                        .font(.largeTitle).bold()
                        .navigationTitle("Home")
                }
                .tag(AppTab.home)
                .toolbar(.hidden, for: .tabBar) // ต้องซ่อนจากข้างใน Tab
                
                // 2. Pet Domain (ที่เราทำกันไว้)
                NavigationStack {
                    PetDomainDashboardView()
                }
                .tag(AppTab.pet)
                .toolbar(.hidden, for: .tabBar)
                
                // 3. Finance (Placeholder)
                NavigationStack {
                    Text("Finance Hub")
                        .font(.largeTitle).bold()
                        .navigationTitle("Finance")
                }
                .tag(AppTab.finance)
                .toolbar(.hidden, for: .tabBar)
                
                // 4. EV
                NavigationStack {
                    EVDomainDashboardView()
                }
                .tag(AppTab.ev)
                .toolbar(.hidden, for: .tabBar)
                
                // 5. Profile
                NavigationStack {
                    ProfileView()
                }
                .tag(AppTab.profile)
                .toolbar(.hidden, for: .tabBar)
            }
            // (เอา toolbar .hidden ของเก่าตรงนี้ออก เพราะมันไม่ทำงานในระดับ TabView)
            
            // โซน Custom Floating TabBar
            VStack {
                Spacer()
                FloatingTabBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(.keyboard) // ป้องกัน TabBar ลอยขึ้นมาตอนพิมพ์คีย์บอร์ด
        }
        .task {
            await petStore.loadAllPets()
        }
    }
}

// Custom Component: Floating Tab Bar แบบกระจก (Glassmorphism)
struct FloatingTabBar: View {
    @Binding var selectedTab: AppTab
    @Namespace private var tabAnimation
    @State private var tabTaps: [AppTab: Int] = [
        .home: 0, .pet: 0, .finance: 0, .ev: 0, .profile: 0
    ]
    
    var body: some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            let tabWidth = totalWidth / CGFloat(AppTab.allCases.count)
            
            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    VStack(spacing: 4) {
                        Image(systemName: tab.rawValue)
                            .font(.system(size: 22))
                            // เอฟเฟกต์กระตุกเบาๆ เฉพาะไอคอนที่เพิ่งโดนกด
                            .symbolEffect(.bounce, value: tabTaps[tab])
                            // ขยายขนาดไอคอนที่ถูกเลือก
                            .scaleEffect(selectedTab == tab ? 1.15 : 1.0)
                        
                        Text(tab.title)
                            .font(.system(size: 10, weight: selectedTab == tab ? .bold : .medium))
                    }
                    .foregroundColor(selectedTab == tab ? .primary : .gray)
                    .frame(width: tabWidth)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            if selectedTab == tab {
                                GlassPillView()
                                    .matchedGeometryEffect(id: "ACTIVETAB", in: tabAnimation)
                            }
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        tabTaps[tab, default: 0] += 1
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            selectedTab = tab
                        }
                    }
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let location = value.location.x
                        let index = Int(location / tabWidth)
                        let safeIndex = max(0, min(index, AppTab.allCases.count - 1))
                        let newTab = AppTab.allCases[safeIndex]
                        
                        if selectedTab != newTab {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                selectedTab = newTab
                            }
                            tabTaps[newTab, default: 0] += 1
                        }
                    }
            )
        }
        .frame(height: 60) // GeometryReader needs a defined height
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        // Liquid Glass (iOS 26 Style)
        .background(
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)
                Capsule()
                    .fill(Color(UIColor.secondarySystemGroupedBackground).opacity(0.8))
            }
        )
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .clear, .white.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 10)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
}

#Preview {
    ContentView()
        .modelContainer(DatabaseProvider.shared.container)
        .environmentObject(AppStore())
        .environmentObject(PetStore())
}
