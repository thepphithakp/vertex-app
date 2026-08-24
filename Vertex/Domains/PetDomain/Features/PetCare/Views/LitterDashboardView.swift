import SwiftUI
import SwiftData

struct LitterDashboardView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var petStore: PetStore
    
    @StateObject private var viewModel = LitterViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // 1. ตัวเลือกแมว (ใช้ Carousel สไตล์ IG Story)
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
                    CatSelectorCarousel(pets: petStore.allPets, selectedPet: $viewModel.selectedPet)
                    .onChange(of: viewModel.selectedPet) { _, _ in
                        Task { await viewModel.loadLogs(repository: SyncLitterRepository(context: context)) }
                    }
                }
                
                if !petStore.allPets.isEmpty {
                    // 2. เลือกวันที่
                    DatePicker("Date", selection: $viewModel.selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .font(.headline)
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .onChange(of: viewModel.selectedDate) { _, _ in
                            Task { await viewModel.loadLogs(repository: SyncLitterRepository(context: context)) }
                        }
                    
                    // 3. สรุปยอดรวม (Summary Dashboard)
                    HStack(spacing: 16) {
                        LitterStatCard(title: "อึ (ก้อน)", count: viewModel.totalPoop, color: .brown, icon: "pawprint.fill")
                        LitterStatCard(title: "ฉี่ (ครั้ง)", count: viewModel.totalPee, color: .yellow, icon: "drop.fill")
                    }
                    .padding(.horizontal)
                
                    // 4. ปุ่มบันทึกด่วน (+1)
                    HStack(spacing: 16) {
                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            
                            Task { await viewModel.addLog(type: "Poop", amount: 1, repository: SyncLitterRepository(context: context)) }
                        }) {
                            QuickActionButton(title: "+1 อึ", icon: "plus.circle.fill", color: .brown)
                        }
                        
                        Button(action: {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            
                            Task { await viewModel.addLog(type: "Pee", amount: 1, repository: SyncLitterRepository(context: context)) }
                        }) {
                            QuickActionButton(title: "+1 ฉี่", icon: "plus.circle.fill", color: .orange)
                        }
                    }
                .padding(.horizontal)
                .disabled(viewModel.selectedPet == nil)
                .opacity(viewModel.selectedPet == nil ? 0.5 : 1.0)
                
                    // 5. ประวัติการขับถ่ายของวันนี้
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's History")
                            .font(.title3)
                            .bold()
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        if viewModel.logs.isEmpty {
                            Text("ยังไม่มีการขับถ่ายในวันนี้")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 40)
                        } else {
                            ForEach(viewModel.logs) { log in
                                HStack(spacing: 16) {
                                    Image(systemName: log.type == "Poop" ? "pawprint.fill" : "drop.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(log.type == "Poop" ? .brown : .orange)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(log.type == "Poop" ? "อึ" : "ฉี่")
                                            .font(.headline)
                                        Text(log.date.formatted(date: .omitted, time: .shortened))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("+ \(log.amount)")
                                        .font(.title2)
                                        .bold()
                                        .foregroundColor(log.type == "Poop" ? .brown : .orange)
                                    
                                    // ปุ่มลบแบบเห็นได้ชัดเจน เผื่อกดผิด
                                    Button(action: {
                                        Task { await viewModel.deleteLog(log, repository: SyncLitterRepository(context: context)) }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.red.opacity(0.7))
                                            .padding(.leading, 8)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(16)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .tabBarAware()
        .refreshable {
            if viewModel.selectedPet != nil {
                await viewModel.loadLogs(repository: SyncLitterRepository(context: context))
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Litter Box")
        .onAppear {
            if viewModel.selectedPet == nil {
                viewModel.selectedPet = petStore.activePet ?? petStore.allPets.first
                if viewModel.selectedPet != nil {
                    Task { await viewModel.loadLogs(repository: SyncLitterRepository(context: context)) }
                }
            }
        }
    }
}

// Component สำหรับแสดงยอดรวม (Dashboard Card)
struct LitterStatCard: View {
    let title: String
    let count: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                if icon == "poop" {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 28))
                        .foregroundColor(color)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(color)
                }
            }
            
            Text("\(count)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
            Text(title)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(16)
    }
}

#Preview {
    NavigationStack {
        LitterDashboardView()
    }
    .modelContainer(DatabaseProvider.shared.container)
    .environmentObject(AppStore())
    .environmentObject(PetStore())
}
