import SwiftUI
import SwiftData

// สไตล์การ์ดแบบเรียบง่าย คงที่ดีไซน์สวยงามไว้ แต่ตัดอนิเมชันทุกอย่างออกเพื่อความเสถียร 100%
struct StaticCardStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.top, 24)
            .padding(.bottom, 24)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [color.opacity(0.15), color.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .foregroundColor(color)
            .cornerRadius(24)
            .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
            // เอา effect และ animation ของการกดออกทั้งหมด
    }
}

struct PetDomainDashboardView: View {
    @EnvironmentObject private var appStore: AppStore
    @EnvironmentObject private var petStore: PetStore
    @ObservedObject private var auth = AuthService.shared
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hello, \(auth.currentUser?.fullName ?? appStore.userName) 👋")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Pet Services")
                            .font(.title2)
                            .bold()
                    }
                    Spacer()
                    if let activePet = petStore.activePet {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Active Pet")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            Text(activePet.name)
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
                
                // เมนูหลัก (ใช้ NavigationLink ธรรมดา ไม่มีการหน่วงเวลาใดๆ ทั้งสิ้น)
                LazyVGrid(columns: columns, spacing: 16) {
                    // 1. Pet Care
                    NavigationLink(destination: PetManagementMainView()) {
                        VStack(spacing: 12) {
                            Image(systemName: "heart.text.square.fill")
                                .font(.system(size: 38))
                            Text("My Cats")
                                .font(.headline)
                        }
                    }
                    .buttonStyle(StaticCardStyle(color: .pink))
                    

                    // 3. Pet Booking
                    NavigationLink(destination: AppointmentListView()) {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 38))
                            Text("Booking")
                                .font(.headline)
                        }
                    }
                    .buttonStyle(StaticCardStyle(color: .teal))
                    
                    // 4. Litter Box
                    NavigationLink(destination: LitterDashboardView()) {
                        VStack(spacing: 12) {
                            Image(systemName: "tray.full.fill")
                                .font(.system(size: 38))
                            Text("Litter Box")
                                .font(.headline)
                        }
                    }
                    .buttonStyle(StaticCardStyle(color: .brown))

                    // 5. Water Tracker
                    NavigationLink(destination: WaterDashboardView()) {
                        VStack(spacing: 12) {
                            Image(systemName: "drop.fill")
                                .font(.system(size: 38))
                            Text("Water")
                                .font(.headline)
                        }
                    }
                    .buttonStyle(StaticCardStyle(color: .cyan))
                    
                    // 5. Analytics & Dashboard
                    NavigationLink(destination: PetAnalyticsDashboardView()) {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.system(size: 38))
                            Text("Analytics")
                                .font(.headline)
                        }
                    }
                    .buttonStyle(StaticCardStyle(color: .indigo))
                }
                .padding(.horizontal)
            }
            .padding(.top)
            .padding(.bottom, 100) // เว้นระยะด้านล่างไม่ให้โดน Floating TabBar บัง
        }
        .refreshable {
            // Pull to refresh fetches explicitly, bypassing TTL
            await petStore.loadAllPets(force: true)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Pet Hub")
        .onAppear {
            Task {
                // PetStore will automatically check TTL and cache
                await petStore.loadAllPets()
            }
        }
    }
}

#Preview {
    NavigationStack {
        PetDomainDashboardView()
    }
    .modelContainer(DatabaseProvider.shared.container)
    .environmentObject(AppStore())
    .environmentObject(PetStore())
}

struct WaterDashboardView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var petStore: PetStore
    
    @State private var selectedPet: Pet?
    @State private var logs: [WaterLog] = []
    @State private var currentIntake: Int = 0
    @State private var isSaving: Bool = false
    @State private var selectedDate = Date()
    @State private var lastUpdated: Date? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var logToDelete: WaterLog? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                
                // 1. Cat Selector
                if petStore.allPets.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "cat.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("Please add a cat first")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                } else {
                    CatSelectorCarousel(pets: petStore.allPets, selectedPet: $selectedPet)
                        .onChange(of: selectedPet) {
                            Task { await loadLogs() }
                        }
                }
                
                if !petStore.allPets.isEmpty {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Daily Water Intake")
                                .font(.title2)
                                .bold()
                            Spacer()
                            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                .labelsHidden()
                                .onChange(of: selectedDate) {
                                    Task { await loadLogs() }
                                }
                        }
                        
                        if let lastUpdated = lastUpdated {
                            Text("Last updated: \(lastUpdated.formatted(date: .omitted, time: .standard))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                
                // Aggregator Circle & Progress
                VStack(spacing: 12) {
                    let targetIntake = (selectedPet?.currentWeight ?? 4.0) * 50.0
                    let todaySaved = logs.reduce(0) { $0 + $1.amount }
                    let totalToday = todaySaved + currentIntake
                    let progress = min(CGFloat(totalToday) / CGFloat(targetIntake), 1.0)
                    let remaining = max(Int(targetIntake) - totalToday, 0)
                    
                    ZStack {
                        Circle()
                            .stroke(Color.cyan.opacity(0.2), lineWidth: 24)
                            .frame(width: 220, height: 220)
                        
                        Circle()
                            .trim(from: 0.0, to: progress)
                            .stroke(Color.cyan, style: StrokeStyle(lineWidth: 24, lineCap: .round))
                            .frame(width: 220, height: 220)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.8, dampingFraction: 0.6), value: progress)
                        
                        VStack(spacing: 8) {
                            Text("\(totalToday)")
                                .font(.system(size: 56, weight: .bold, design: .rounded))
                                .foregroundColor(progress >= 1.0 ? .green : .cyan)
                                .contentTransition(.numericText())
                                .animation(.spring(), value: totalToday)
                            
                            Text("/ \(Int(targetIntake)) ml")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 10)
                    
                    // Motivation Message
                    if progress >= 1.0 {
                        HStack(spacing: 6) {
                            Image(systemName: "party.popper.fill")
                                .foregroundColor(.yellow)
                            Text("เก่งมาก! วันนี้กินน้ำครบแล้ว 🎉")
                                .font(.headline)
                                .foregroundColor(.green)
                            Image(systemName: "party.popper.fill")
                                .foregroundColor(.yellow)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                        .scaleEffect(progress >= 1.0 ? 1.05 : 1.0)
                        .animation(.interpolatingSpring(stiffness: 100, damping: 10).repeatForever(autoreverses: true), value: progress >= 1.0)
                    } else {
                        Text("ยังขาดอีก \(remaining) ml สู้ๆ นะคะ ✌️")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    // AI Analysis Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            Text("AI Analysis")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.purple)
                        }
                        
                        Text(aiAnalysisText(for: progress))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.purple.opacity(0.05))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                .padding(.vertical, 10)
                
                // Hourly Intake Info
                let hourlyStats = hourlyIntakeStatus
                if hourlyStats.maxIntake > 0 && Calendar.current.isDateInToday(selectedDate) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text("1 ชม. ล่าสุด: \(hourlyStats.recentTotal) ml")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("รับได้อีก: \(hourlyStats.remaining) ml")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(hourlyStats.remaining > 0 ? .green : .red)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Buttons
                HStack(spacing: 20) {
                    WaterAddButton(amount: 5, action: { currentIntake += 5 })
                    WaterAddButton(amount: 10, action: { currentIntake += 10 })
                    WaterAddButton(amount: 20, action: { currentIntake += 20 })
                }
                
                // Overfeeding Warning
                if let warning = overfeedingWarning {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.title3)
                        Text(warning)
                            .font(.footnote)
                            .foregroundColor(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Action Buttons
                HStack(spacing: 16) {
                    Button(action: { currentIntake = 0 }) {
                        Text("Reset")
                            .font(.headline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        Task { await saveIntake() }
                    }) {
                        if isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.cyan)
                                .cornerRadius(12)
                        } else {
                            Text("Save")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(currentIntake > 0 ? Color.cyan : Color.gray)
                                .cornerRadius(12)
                        }
                    }
                    .disabled(currentIntake == 0 || isSaving)
                }
                .padding(.horizontal)
                
                Divider().padding(.vertical)
                
                // History List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Logs")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if logs.isEmpty {
                        Text("No water logs for today.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        ForEach(logs, id: \.id) { log in
                            HStack {
                                Image(systemName: "drop.fill")
                                    .foregroundColor(.cyan)
                                    .font(.title3)
                                VStack(alignment: .leading) {
                                    Text("\(log.amount) ml")
                                        .font(.headline)
                                    Text(log.date.formatted(date: .omitted, time: .shortened))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button(action: { 
                                    logToDelete = log
                                    showDeleteConfirmation = true
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                    }
                }
            }
            .padding(.vertical)
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 100)
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Water Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .alert("ลบรายการ?", isPresented: $showDeleteConfirmation, presenting: logToDelete) { log in
            Button("ลบทิ้ง", role: .destructive) {
                Task { await deleteLog(log) }
            }
            Button("ยกเลิก", role: .cancel) { }
        } message: { log in
            Text("คุณแน่ใจหรือไม่ที่จะลบรายการป้อนน้ำ \(log.amount) ml นี้?")
        }
        .onAppear {
            if selectedPet == nil {
                selectedPet = petStore.activePet ?? petStore.allPets.first
            }
            Task { await loadLogs() }
        }
    }
    
    private func loadLogs() async {
        guard let pet = selectedPet else { return }
        let repo = SyncWaterRepository(context: context)
        do {
            logs = try await repo.fetchLogs(for: pet, on: selectedDate)
            lastUpdated = Date()
        } catch {
            print("Failed to load water logs: \(error)")
        }
    }
    
    private func saveIntake() async {
        guard let pet = selectedPet, currentIntake > 0 else { return }
        isSaving = true
        let repo = SyncWaterRepository(context: context)
        let log = WaterLog(date: Date(), amount: currentIntake)
        log.pet = pet
        
        do {
            try await repo.saveLog(log)
            currentIntake = 0
            await loadLogs()
        } catch {
            print("Failed to save water log: \(error)")
        }
        isSaving = false
    }
    
    private func deleteLog(_ log: WaterLog) async {
        let repo = SyncWaterRepository(context: context)
        do {
            try await repo.deleteLog(log)
            await loadLogs()
        } catch {
            print("Failed to delete water log: \(error)")
        }
    }
    
    private func aiAnalysisText(for progress: CGFloat) -> String {
        guard let pet = selectedPet else { return "กำลังวิเคราะห์ข้อมูล..." }
        
        if progress == 0 {
            return "ร่างกายน้อง \(pet.name) ขาดน้ำ อาจทำให้ไตทำงานหนักและเสี่ยงต่อโรคนิ่ว ควรป้อนน้ำทันที"
        } else if progress < 0.3 {
            return "ปริมาณน้ำยังน้อยเกินไป เลือดจะเริ่มหนืดตัว การขับของเสียทางปัสสาวะจะทำได้ไม่ดีเท่าที่ควร"
        } else if progress < 0.7 {
            return "ร่างกายน้อง \(pet.name) เริ่มได้รับความชุ่มชื้น ระบบย่อยอาหารและการไหลเวียนเลือดทำงานได้ดีขึ้น แต่ยังต้องการน้ำเพิ่มอีกนิด"
        } else if progress < 1.0 {
            return "ใกล้ถึงเป้าหมายแล้ว! เซลล์ในร่างกายทำงานได้อย่างสมบูรณ์ ผิวหนังและขนของน้อง \(pet.name) จะสุขภาพดีและเงางาม"
        } else {
            return "ยอดเยี่ยมมาก! ไตทำงานได้อย่างมีประสิทธิภาพสุดๆ สารพิษถูกขับออกอย่างสมบูรณ์ ลดความเสี่ยงโรคทางเดินปัสสาวะได้ดีมาก"
        }
    }
    
    private var hourlyIntakeStatus: (recentTotal: Int, maxIntake: Int, remaining: Int) {
        guard let pet = selectedPet else { return (0, 0, 0) }
        let weight = pet.currentWeight ?? 4.0
        let maxIntake = Int(weight * 15.0)
        
        let oneHourAgo = Date().addingTimeInterval(-3600)
        let recentLogs = logs.filter { $0.date >= oneHourAgo }
        let recentTotal = recentLogs.reduce(0) { $0 + $1.amount } + currentIntake
        let remaining = max(maxIntake - recentTotal, 0)
        
        return (recentTotal, maxIntake, remaining)
    }
    
    private var overfeedingWarning: String? {
        guard let pet = selectedPet else { return nil }
        guard Calendar.current.isDateInToday(selectedDate) else { return nil }
        
        let weight = pet.currentWeight ?? 4.0
        let maxIntake = Int(weight * 15.0) // Safe limit 15ml per kg per hour
        let oneHourAgo = Date().addingTimeInterval(-3600)
        let recentLogs = logs.filter { $0.date >= oneHourAgo }
        let recentTotal = recentLogs.reduce(0) { $0 + $1.amount } + currentIntake
        
        if recentTotal > maxIntake {
            let oldestLogDate = recentLogs.map { $0.date }.min() ?? Date()
            let expirationDate = oldestLogDate.addingTimeInterval(3600)
            let waitTimeMinutes = max(0, Int(expirationDate.timeIntervalSinceNow / 60))
            
            return "ใน 1 ชม.ที่ผ่านมา น้องกินน้ำถี่เกินไป (\(recentTotal)/\(maxIntake) ml) ควรเว้นช่วงประมาณ \(waitTimeMinutes == 0 ? 1 : waitTimeMinutes) นาที ค่อยป้อนใหม่ เพื่อป้องกันการสำลักหรืออาเจียน"
        }
        return nil
    }
}

struct WaterAddButton: View {
    let amount: Int
    let action: () -> Void
    
    private var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        if amount <= 5 {
            return .light
        } else if amount <= 10 {
            return .medium
        } else {
            return .heavy
        }
    }
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: feedbackStyle)
            generator.prepare()
            generator.impactOccurred()
            action()
        }) {
            VStack {
                Text("+\(amount)")
                    .font(.title2)
                    .bold()
                Text("ml")
                    .font(.caption)
            }
            .foregroundColor(.white)
            .frame(width: 80, height: 80)
            .background(Color.cyan)
            .clipShape(Circle())
            .shadow(color: .cyan.opacity(0.3), radius: 5, y: 5)
        }
    }
}
