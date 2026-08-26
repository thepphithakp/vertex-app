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
                .onChange(of: viewModel.selectedPet) { _, _ in Task { await viewModel.loadData() } }
                .onChange(of: viewModel.selectedTimeframe) { _, _ in Task { await viewModel.loadData() } }
                
                if viewModel.selectedPet == nil {
                    Text("Please select a cat to view analytics.")
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                } else {
                    
                    // 2. Summary KPI Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
                            title: "น้ำเฉลี่ย/วัน",
                            value: String(format: "%.0f", viewModel.avgWaterPerDay),
                            unit: "ml",
                            icon: "drop.circle.fill",
                            color: .cyan
                        )
                        
                        // เดิมการ์ดนี้แสดง "การเปลี่ยนแปลงน้ำหนัก" ที่คำนวณจากน้ำหนักที่สุ่มขึ้นมา
                        // ยังไม่มี endpoint บันทึกน้ำหนักรายวัน จึงเปลี่ยนมาแสดงเป้าหมายการกินน้ำ
                        // ที่ server คำนวณจากน้ำหนักจริง และบอกตรงๆ เมื่อยังไม่รู้
                        AnalyticsKPICard(
                            title: "เป้าหมายน้ำ/วัน",
                            value: viewModel.dailyTargetMl.map(String.init) ?? "—",
                            unit: viewModel.dailyTargetMl == nil ? "ยังไม่มีน้ำหนัก" : "ml",
                            icon: "target",
                            color: .blue
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
                    
                    // 5. กราฟการกินน้ำ (Area/Bar Chart)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Water Intake (ปริมาณการกินน้ำ)")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if viewModel.waterStats.isEmpty {
                            Text("No water data for this period.")
                                .foregroundColor(.secondary)
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                        } else {
                            Chart {
                                ForEach(viewModel.waterStats) { stat in
                                    BarMark(
                                        x: .value("Date", stat.date, unit: .day),
                                        y: .value("Amount", stat.amount)
                                    )
                                    .foregroundStyle(Color.cyan.gradient)
                                    .cornerRadius(4)
                                }
                            }
                            .frame(height: 250)
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
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
        .tabBarAware()
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Analytics")
        .onAppear {
            if viewModel.selectedPet == nil {
                viewModel.selectedPet = petStore.activePet ?? petStore.allPets.first
                Task { await viewModel.loadData() }
            }
        }
    }
    
    private func generateInsight() -> String {
        let poop = viewModel.avgPoopPerDay
        let water = viewModel.avgWaterPerDay
        // เป้าหมายมาจาก server ที่คำนวณจากน้ำหนักจริง — nil แปลว่ายังไม่มีน้ำหนักบันทึกไว้
        // เดิมตรงนี้เดาเป็น 4 กก. แล้วออกคำแนะนำสุขภาพจากค่าเดา
        let targetWater = viewModel.dailyTargetMl.map(Double.init)
        
        var insights: [String] = []
        
        if poop < 0.5 && poop > 0 {
            insights.append("น้องอาจจะมีอาการท้องผูก เนื่องจากจำนวนอึเฉลี่ยน้อยกว่า 1 ก้อนต่อวัน แนะนำให้สังเกตและกระตุ้นการกินน้ำ")
        } else if poop > 3 {
            insights.append("น้องขับถ่ายบ่อยกว่าปกติ สังเกตลักษณะอึว่าเหลวหรือไม่ หากเหลวควรพาไปพบแพทย์")
        } else if poop > 0 {
            insights.append("สุขภาพการขับถ่ายอยู่ในเกณฑ์ดีเยี่ยม! 🌟")
        }
        
        if water > 0, let targetWater {
            if water < (targetWater * 0.7) {
                insights.append("น้องกินน้ำน้อยกว่าเกณฑ์ (ควรได้ประมาณ \(Int(targetWater)) ml/วัน) เสี่ยงต่อโรคไตและนิ่ว แนะนำให้ตั้งน้ำหลายๆ จุด 💧")
            } else if water <= (targetWater * 1.3) {
                insights.append("ปริมาณการกินน้ำเฉลี่ยเหมาะสมดีมาก ช่วยให้ระบบปัสสาวะแข็งแรง 🚰")
            } else {
                insights.append("น้องกินน้ำเยอะกว่าปกติ สังเกตว่าฉี่บ่อยผิดปกติหรือไม่ อาจเป็นสัญญาณเตือนโรคไตหรือเบาหวาน 🚨")
            }
        } else if water > 0 {
            insights.append("ยังบอกไม่ได้ว่าน้องกินน้ำพอไหม เพราะยังไม่ได้บันทึกน้ำหนัก — เกณฑ์คิดจากน้ำหนักตัว")
        }
        
        if insights.isEmpty {
            return "ยังไม่มีข้อมูลเพียงพอสำหรับประมวลผล ลองบันทึกข้อมูลและคอยสังเกตพฤติกรรมน้องต่อไปนะ!"
        } else {
            return insights.joined(separator: "\n\n")
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
