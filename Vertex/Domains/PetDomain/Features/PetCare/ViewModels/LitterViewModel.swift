import SwiftUI
import Combine

@MainActor
final class LitterViewModel: ObservableObject {
    @Published var logs: [LitterLog] = []
    @Published var selectedDate: Date = Date()
    @Published var selectedPet: Pet?
    
    var totalPoop: Int {
        logs.filter { $0.type == "Poop" }.reduce(0) { $0 + $1.amount }
    }
    
    var totalPee: Int {
        logs.filter { $0.type == "Pee" }.reduce(0) { $0 + $1.amount }
    }
    
    func loadLogs(repository: LitterRepository) async {
        guard let pet = selectedPet else {
            logs = []
            return
        }
        do {
            logs = try await repository.fetchLogs(for: pet, on: selectedDate)
        } catch {
            print("Fetch error: \(error)")
        }
    }
    
    func addLog(type: String, amount: Int, repository: LitterRepository) async {
        guard let pet = selectedPet else { return }
        
        // เช็คว่ามี Log ชนิดเดียวกันที่เพิ่งสร้างภายใน 5 นาทีที่ผ่านมาหรือไม่
        if let lastLog = logs.first(where: { $0.type == type && Date().timeIntervalSince($0.date) < 300 }) {
            // ถ้ามี ให้บวกจำนวนเพิ่มเข้าไป แทนที่จะสร้างบรรทัดใหม่
            lastLog.amount += amount
            do {
                try await repository.saveLog(lastLog)
                await loadLogs(repository: repository)
            } catch {
                print("Update error: \(error)")
            }
            return
        }
        
        // ถ้าไม่มี หรือเลย 5 นาทีไปแล้ว ค่อยสร้าง Log ใหม่
        let log = LitterLog(date: Date(), type: type, amount: amount)
        log.pet = pet
        
        do {
            try await repository.saveLog(log)
            // โหลดข้อมูลใหม่เพื่อให้หน้า UI รีเฟรชยอดรวม
            await loadLogs(repository: repository)
        } catch {
            print("Save error: \(error)")
        }
    }
    
    func deleteLog(_ log: LitterLog, repository: LitterRepository) async {
        do {
            try await repository.deleteLog(log)
            await loadLogs(repository: repository)
        } catch {
            print("Delete error: \(error)")
        }
    }
}
