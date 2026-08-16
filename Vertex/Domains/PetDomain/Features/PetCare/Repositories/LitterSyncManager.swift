import Foundation
import UIKit
import SwiftData

@MainActor
final class LitterSyncManager {
    static let shared = LitterSyncManager()
    
    private var pendingLogs: [UUID: LitterLog] = [:]
    private var syncTask: Task<Void, Never>?
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // ตั้งค่าเวลา delay ในการส่งข้อมูล (เช่น 5 วินาที หลังจากการกดครั้งสุดท้าย)
    private let debounceDelayNanoseconds: UInt64 = 5_000_000_000
    
    private init() {}
    
    func enqueue(_ log: LitterLog) {
        pendingLogs[log.id] = log
        
        // 1. ยกเลิก timer ตัวเก่าทิ้ง
        syncTask?.cancel()
        
        // 2. ขอสิทธิ์ทำงานต่อใน Background เผื่อผู้ใช้กดปิดแอปหรือสลับแอป
        if backgroundTaskID == .invalid {
            backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "LitterLogSyncTask") {
                self.endBackgroundTask()
            }
        }
        
        // 3. เริ่มจับเวลาใหม่
        syncTask = Task {
            do {
                try await Task.sleep(nanoseconds: debounceDelayNanoseconds)
                if !Task.isCancelled {
                    await syncNow()
                }
            } catch {
                // Task ถูกยกเลิกเพราะมีการกด + อีกครั้ง
            }
        }
    }
    
    private func syncNow() async {
        guard !pendingLogs.isEmpty else {
            endBackgroundTask()
            return
        }
        
        let logsToSync = Array(pendingLogs.values)
        pendingLogs.removeAll() // เคลียร์ queue เตรียมรับของใหม่
        
        // จัดกลุ่มตาม PetID เพราะ API รองรับแบบ 1 Pet ต่อ 1 Request
        let grouped = Dictionary(grouping: logsToSync) { $0.pet?.id }
        
        for (petId, logs) in grouped {
            guard let petId = petId else { continue }
            
            let dtos = logs.map { LitterLogDTO(from: $0, petId: petId) }
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            do {
                let data = try encoder.encode(dtos)
                let _: [LitterLogDTO] = try await NetworkManager.shared.request(
                    endpoint: "/pets/\(petId.uuidString)/litter-logs/batch",
                    method: "POST",
                    body: data
                )
                print("Successfully batched and synced \(dtos.count) logs for pet \(petId)")
            } catch {
                print("Failed to push batched litter logs to remote: \(error)")
                // ในระบบจริงถ้ายิงไม่ผ่าน อาจจะต้องเอาใส่กลับเข้าไปใน queue
                // แต่เพื่อความเรียบง่ายในตอนนี้ เราจะทิ้งไปก่อนเพราะข้อมูลอยู่ใน SwiftData แล้ว
            }
        }
        
        endBackgroundTask()
    }
    
    private func endBackgroundTask() {
        if backgroundTaskID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskID)
            backgroundTaskID = .invalid
        }
    }
}
