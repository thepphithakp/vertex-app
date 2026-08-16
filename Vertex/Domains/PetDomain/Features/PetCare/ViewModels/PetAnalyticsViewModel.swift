import SwiftUI
import Combine

enum AnalyticsTimeframe: String, CaseIterable {
    case week = "1 Week"
    case month = "1 Month"
    case threeMonths = "3 Months"
    
    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        }
    }
}

// Model สำหรับรวมข้อมูลรายวันไปวาดกราฟ
struct DailyLitterStat: Identifiable {
    let id = UUID()
    let date: Date
    let type: String
    let amount: Int
}

@MainActor
final class PetAnalyticsViewModel: ObservableObject {
    @Published var selectedTimeframe: AnalyticsTimeframe = .week
    @Published var selectedPet: Pet?
    
    // Processed Data for Charts
    @Published var litterStats: [DailyLitterStat] = []
    @Published var weightLogs: [WeightLog] = []
    
    // Summary Metrics
    @Published var avgPoopPerDay: Double = 0.0
    @Published var avgPeePerDay: Double = 0.0
    @Published var weightChange: Double = 0.0
    
    func loadData() {
        guard let pet = selectedPet else {
            clearData()
            return
        }
        
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -selectedTimeframe.days, to: Date())!
        
        // 1. กรองและจัดกลุ่มข้อมูล Litter Logs
        let filteredLitter = pet.litterLogs.filter { $0.date >= startDate }
        
        // เราจะรวมยอดรายวันเพื่อไม่ให้กราฟซ้อนกัน
        var dailyDict: [String: [String: Int]] = [:] // ["YYYY-MM-DD": ["Poop": 2, "Pee": 3]]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var totalPoop = 0
        var totalPee = 0
        
        for log in filteredLitter {
            let dateString = formatter.string(from: log.date)
            if dailyDict[dateString] == nil { dailyDict[dateString] = ["Poop": 0, "Pee": 0] }
            dailyDict[dateString]?[log.type, default: 0] += log.amount
            
            if log.type == "Poop" { totalPoop += log.amount }
            else if log.type == "Pee" { totalPee += log.amount }
        }
        
        // แปลงกลับเป็น Array สำหรับ SwiftUI Charts
        var stats: [DailyLitterStat] = []
        for (dateStr, counts) in dailyDict {
            let date = formatter.date(from: dateStr) ?? Date()
            if let poopCount = counts["Poop"], poopCount > 0 {
                stats.append(DailyLitterStat(date: date, type: "Poop", amount: poopCount))
            }
            if let peeCount = counts["Pee"], peeCount > 0 {
                stats.append(DailyLitterStat(date: date, type: "Pee", amount: peeCount))
            }
        }
        self.litterStats = stats.sorted(by: { $0.date < $1.date })
        
        // คำนวณค่าเฉลี่ย
        let daysCount = Double(selectedTimeframe.days)
        self.avgPoopPerDay = Double(totalPoop) / daysCount
        self.avgPeePerDay = Double(totalPee) / daysCount
        
        // 2. กรองข้อมูล น้ำหนัก
        // เนื่องจากโครงสร้าง WeightLog อาจจะผูกกับ Pet ไว้ แต่ใน Schema เรายังไม่ได้ผูก Relationship ในฝั่ง Pet
        // เดี๋ยวผมจะจำลองข้อมูลให้ดูก่อนถ้าไม่มีข้อมูล
        
        // สร้าง Dummy Data ของน้ำหนักเพื่อให้เห็นกราฟชัดเจน (เนื่องจากปัจจุบันเรายังไม่มีหน้าบันทึกน้ำหนักรายวัน)
        var dummyWeights: [WeightLog] = []
        for i in 0..<selectedTimeframe.days {
            let date = calendar.date(byAdding: .day, value: -i, to: Date())!
            // สุ่มน้ำหนักแกว่งไปมาทีละนิด
            let baseWeight = pet.currentWeight ?? 5.0
            let randomDiff = Double.random(in: -0.2...0.2)
            dummyWeights.append(WeightLog(weight: baseWeight + randomDiff, dateRecorded: date))
        }
        self.weightLogs = dummyWeights.sorted(by: { $0.dateRecorded < $1.dateRecorded })
        
        if let first = self.weightLogs.first, let last = self.weightLogs.last {
            self.weightChange = last.weight - first.weight
        }
    }
    
    private func clearData() {
        litterStats = []
        weightLogs = []
        avgPoopPerDay = 0
        avgPeePerDay = 0
        weightChange = 0
    }
}
