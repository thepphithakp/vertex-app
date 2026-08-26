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

struct DailyWaterStat: Identifiable {
    let id = UUID()
    let date: Date
    let amount: Int
}

/// สรุปข้อมูลสำหรับหน้า Analytics — ดึงจาก BFF ผ่าน GraphQL (VT-102)
///
/// เดิมหน้านี้อ่าน `pet.litterLogs` / `pet.waterLogs` ที่ sync ลง SwiftData แล้ว
/// group เองในเครื่อง ซึ่งมีสองปัญหา:
///
/// 1. ต้องดึง log ทั้งหมดตั้งแต่ต้นมาก่อนทุกครั้ง เพื่อจะดูแค่ช่วง 7 วัน
/// 2. เมื่อไม่มีข้อมูลน้ำเลย มันจะ **สุ่มตัวเลขขึ้นมาแสดง** แล้วเอาไปออกคำแนะนำ
///    สุขภาพต่อ ซึ่งเป็นข้อมูลสุขภาพสัตว์เลี้ยงที่ไม่จริง อันตรายกว่าการไม่แสดงอะไร
///
/// ตอนนี้ตัวเลขทั้งหมดมาจาก server และไม่มีการเติมค่าปลอมที่ไหนอีก
@MainActor
final class PetAnalyticsViewModel: ObservableObject {
    @Published var selectedTimeframe: AnalyticsTimeframe = .week
    @Published var selectedPet: Pet?
    
    // Processed Data for Charts
    @Published var litterStats: [DailyLitterStat] = []
    @Published var waterStats: [DailyWaterStat] = []

    // Summary Metrics
    @Published var avgPoopPerDay: Double = 0.0
    @Published var avgPeePerDay: Double = 0.0
    @Published var avgWaterPerDay: Double = 0.0

    /// เป้าหมายการกินน้ำต่อวันที่ server คำนวณจากน้ำหนักจริง
    /// nil = ยังไม่มีน้ำหนักบันทึกไว้ ห้ามเดาแทน
    @Published var dailyTargetMl: Int?

    @Published var isLoading: Bool = false
    
    func loadData() async {
        guard let pet = selectedPet else {
            clearData()
            return
        }

        let calendar = Calendar.current
        let to = Date()
        let from = calendar.startOfDay(
            for: calendar.date(byAdding: .day, value: -(selectedTimeframe.days - 1), to: to)!
        )

        isLoading = true
        defer { isLoading = false }

        do {
            let data = try await VertexGraphQL.fetch(
                VertexAPI.PetAnalyticsQuery(
                    petId: pet.id.uuidString,
                    from: VertexAPI.dateTime(from: from),
                    to: VertexAPI.dateTime(from: to)
                )
            )

            guard let summary = data.pet else {
                clearData()
                return
            }

            // เซิร์ฟเวอร์เติมวันที่ไม่มีข้อมูลเป็น 0 มาให้ครบแล้ว
            // ฝั่งแอปจึงไม่ต้องวนเติมวันเองเหมือนเดิม
            litterStats = summary.litterSummary.daily.flatMap { bucket -> [DailyLitterStat] in
                guard let date = VertexAPI.date(from: bucket.date) else { return [] }
                return [
                    DailyLitterStat(date: date, type: "Poop", amount: bucket.poop),
                    DailyLitterStat(date: date, type: "Pee", amount: bucket.pee),
                ]
            }
            avgPoopPerDay = summary.litterSummary.avgPoopPerDay
            avgPeePerDay = summary.litterSummary.avgPeePerDay

            waterStats = summary.waterSummary.daily.compactMap { bucket in
                guard let date = VertexAPI.date(from: bucket.date) else { return nil }
                return DailyWaterStat(date: date, amount: bucket.ml)
            }
            avgWaterPerDay = summary.waterSummary.avgMlPerDay
            dailyTargetMl = summary.waterSummary.dailyTargetMl

        } catch {
            // error เด้ง dialog ให้แล้วใน VertexGraphQL — ที่นี่แค่อย่าค้างข้อมูลเก่าไว้
            clearData()
        }
    }
    
    private func clearData() {
        litterStats = []
        waterStats = []
        avgPoopPerDay = 0
        avgPeePerDay = 0
        avgWaterPerDay = 0
        dailyTargetMl = nil
    }
}
