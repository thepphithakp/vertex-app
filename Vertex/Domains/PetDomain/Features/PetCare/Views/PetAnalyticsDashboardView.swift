import SwiftUI
import Charts
import SwiftData

struct PetAnalyticsDashboardView: View {
    @EnvironmentObject private var petStore: PetStore
    
    @StateObject private var viewModel = PetAnalyticsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // 1. Header & Selectors
                VStack(spacing: 16) {
                    // เลือกแมวแบบใหม่ (Carousel)
                    if !petStore.allPets.isEmpty {
                        CatSelectorCarousel(pets: petStore.allPets, selectedPet: $viewModel.selectedPet)
                    }
                    
                    // เลือกช่วงเวลา (1W, 1M, 3M)
                    Picker("Timeframe", selection: $viewModel.selectedTimeframe) {
                        ForEach(AnalyticsTimeframe.allCases, id: \.self) { tf in
                            Text(tf.rawValue).tag(tf)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)
                .onChange(of: viewModel.selectedPet) { _, _ in viewModel.loadData() }
                .onChange(of: viewModel.selectedTimeframe) { _, _ in viewModel.loadData() }
                
                if viewModel.selectedPet == nil {
                    Text("Please select a cat to view analytics.")
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                } else {
                    
                    // 2. Summary KPI Cards
                    HStack(spacing: 12) {
                        AnalyticsKPICard(
                            title: "อึเฉลี่ย/วัน",
                            value: String(format: "%.1f", viewModel.avgPoopPerDay),
                            unit: "ก้อน",
                            icon: "pawprint.fill",
                            color: .brown
                        )
                        
                        AnalyticsKPICard(
                            title: "ฉี่เฉลี่ย/วัน",
                            value: String(format: "%.1f", viewModel.avgPeePerDay),
                            unit: "ครั้ง",
                            icon: "drop.fill",
                            color: .orange
                        )
                        
                        AnalyticsKPICard(
                            title: "การเปลี่ยนแปลง นน.",
                            value: String(format: "%+.1f", viewModel.weightChange),
                            unit: "kg",
                            icon: "scalemass",
                            color: viewModel.weightChange > 0 ? .red : (viewModel.weightChange < 0 ? .green : .blue)
                        )
                    }
                    .padding(.horizontal)
                    
                    // 3. กราฟกระบะทราย (Stacked Bar Chart)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Litter Habits (พฤติกรรมขับถ่าย)")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if viewModel.litterStats.isEmpty {
                            Text("No litter data for this period.")
                                .foregroundColor(.secondary)
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                        } else {
                            Chart {
                                ForEach(viewModel.litterStats) { stat in
                                    BarMark(
                                        x: .value("Date", stat.date, unit: .day),
                                        y: .value("Count", stat.amount)
                                    )
                                    .foregroundStyle(by: .value("Type", stat.type == "Poop" ? "อึ" : "ฉี่"))
                                    .cornerRadius(4)
                                }
                            }
                            .chartForegroundStyleScale([
                                "อึ": Color.brown,
                                "ฉี่": Color.yellow
                            ])
                            .frame(height: 250)
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                    }
                    
                    // 4. กราฟน้ำหนัก (Line Chart)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Weight Trend (แนวโน้มน้ำหนัก)")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart {
                            ForEach(viewModel.weightLogs) { log in
                                LineMark(
                                    x: .value("Date", log.dateRecorded, unit: .day),
                                    y: .value("Weight", log.weight)
                                )
                                .interpolationMethod(.catmullRom) // ทำให้เส้นกราฟโค้งมนสวยงาม
                                .foregroundStyle(Color.blue)
                                .symbol(Circle().strokeBorder(lineWidth: 2))
                                
                                AreaMark(
                                    x: .value("Date", log.dateRecorded, unit: .day),
                                    yStart: .value("Min", log.weight - 0.5), // แรเงาใต้กราฟ
                                    yEnd: .value("Max", log.weight)
                                )
                                .interpolationMethod(.catmullRom)
                                .foregroundStyle(LinearGradient(colors: [Color.blue.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
                            }
                        }
                        // ไม่ต้องให้กราฟเริ่มที่ 0 กิโล เพราะเส้นกราฟจะแบนเกินไป ให้กราฟซูมที่ช่วงน้ำหนักจริง
                        .chartYScale(domain: .automatic(includesZero: false))
                        .frame(height: 250)
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // AI / Smart Insights
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("AI Health Insights")
                                .font(.headline)
                        }
                        
                        Text(generateInsight())
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 90) }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Analytics")
        .onAppear {
            if viewModel.selectedPet == nil {
                viewModel.selectedPet = petStore.activePet ?? petStore.allPets.first
                viewModel.loadData()
            }
        }
    }
    
    private func generateInsight() -> String {
        let poop = viewModel.avgPoopPerDay
        if poop < 0.5 && poop > 0 {
            return "น้องอาจจะมีอาการท้องผูก เนื่องจากจำนวนอึเฉลี่ยน้อยกว่า 1 ก้อนต่อวัน แนะนำให้กระตุ้นการกินน้ำ"
        } else if poop > 3 {
            return "น้องขับถ่ายบ่อยกว่าปกติ สังเกตลักษณะอึว่าเหลวหรือไม่ หากเหลวควรพาไปพบแพทย์"
        } else if poop == 0 {
            return "ยังไม่มีข้อมูลเพียงพอสำหรับประมวลผล ลองบันทึกข้อมูลทุกวันดูนะ!"
        } else {
            return "สุขภาพการขับถ่ายอยู่ในเกณฑ์ดีเยี่ยม! 🌟 น้ำหนักของน้องมีแนวโน้มคงที่ แนะนำให้รักษาระดับการกินอาหารในปริมาณปัจจุบัน"
        }
    }
}

struct AnalyticsKPICard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
    }
}

#Preview {
    NavigationStack {
        PetAnalyticsDashboardView()
    }
    .modelContainer(DatabaseProvider.shared.container)
    .environmentObject(AppStore())
    .environmentObject(PetStore())
}
