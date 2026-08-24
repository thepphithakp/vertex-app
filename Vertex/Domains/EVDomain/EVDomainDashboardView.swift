import SwiftUI
import WidgetKit
import ActivityKit

struct EVDomainDashboardView: View {
    enum LocationType: String, CaseIterable {
        case condo = "Condo"
        case mall = "Mall / Office"
    }
    
    @AppStorage("parkedFloor", store: SharedUserDefaults.shared) private var parkedFloor: String = ""
    @AppStorage("parkedZone", store: SharedUserDefaults.shared) private var parkedZone: String = ""
    @AppStorage("parkedDate", store: SharedUserDefaults.shared) private var parkedDateDouble: Double = 0
    @AppStorage("parkedNotes", store: SharedUserDefaults.shared) private var parkedNotes: String = ""
    @AppStorage("lastLocationType", store: SharedUserDefaults.shared) private var lastLocationTypeRaw: String = LocationType.condo.rawValue
    @AppStorage("isDoubleParked", store: SharedUserDefaults.shared) private var isDoubleParked: Bool = false
    
    @State private var isEditing: Bool = false
    
    @State private var inputFloor: String = "1"
    @State private var inputZone: String = ""
    @State private var inputNotes: String = ""
    @State private var inputIsDoubleParked: Bool = false
    @State private var editLocationType: LocationType = .condo
    
    // Swipe to clear state
    @State private var dragOffset: CGSize = .zero
    
    let condoFloors = ["B5", "B4", "B3", "B2", "B1", "G", "M"] + (1...100).map { "\($0)" }
    
    var isParked: Bool {
        !parkedFloor.isEmpty || !parkedZone.isEmpty
    }
    
    var parkedDate: Date? {
        parkedDateDouble == 0 ? nil : Date(timeIntervalSince1970: parkedDateDouble)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // Header
                HStack {
                    Text("EV Management")
                        .font(.largeTitle)
                        .bold()
                    Spacer()
                }
                .padding(.horizontal)
                
                // Parking Tracker Widget
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "car.fill")
                            .font(.title2)
                        Text("Parking Tracker")
                            .font(.headline)
                        Spacer()
                    }
                    .foregroundColor(isParked ? .white : .primary)
                    
                    if isEditing {
                        // Edit Mode
                        VStack(spacing: 12) {
                            Picker("Location Type", selection: $editLocationType) {
                                ForEach(LocationType.allCases, id: \.self) { type in
                                    Text(type.rawValue).tag(type)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.bottom, 8)
                            
                            HStack {
                                Text("Floor")
                                    .frame(width: 60, alignment: .leading)
                                
                                if editLocationType == .condo {
                                    Picker("Select Floor", selection: $inputFloor) {
                                        ForEach(condoFloors, id: \.self) { floor in
                                            Text(floor).tag(floor)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 100)
                                    .clipped()
                                } else {
                                    TextField("e.g. 2A, B1", text: $inputFloor)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                            HStack {
                                Text("Zone")
                                    .frame(width: 60, alignment: .leading)
                                TextField("e.g. Pillar D05", text: $inputZone)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            HStack {
                                Text("Note")
                                    .frame(width: 60, alignment: .leading)
                                TextField("e.g. Near lift 3", text: $inputNotes)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            if editLocationType == .condo {
                                Toggle(isOn: $inputIsDoubleParked) {
                                    Text("Double Parked (จอดซ้อนคัน)")
                                        .foregroundColor(.orange)
                                }
                                .padding(.vertical, 4)
                            }
                            
                            Button(action: saveParking) {
                                Text("Save Location")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            .padding(.top, 8)
                            
                            Button("Cancel") {
                                withAnimation { isEditing = false }
                            }
                            .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                    } else if isParked {
                        // Display Mode (Cool Digital Ticket)
                        VStack(spacing: 20) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("FLOOR")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.7))
                                    Text(parkedFloor.isEmpty ? "-" : parkedFloor)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                }
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text("ZONE / PILLAR")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.7))
                                    Text(parkedZone.isEmpty ? "-" : parkedZone)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                }
                            }
                            
                            if !parkedNotes.isEmpty {
                                HStack {
                                    Image(systemName: "note.text")
                                        .foregroundColor(.white.opacity(0.7))
                                    Text(parkedNotes)
                                        .font(.subheadline)
                                    Spacer()
                                }
                                .padding(10)
                                .background(Color.black.opacity(0.2))
                                .cornerRadius(8)
                            }
                            
                            if isDoubleParked && lastLocationTypeRaw == LocationType.condo.rawValue {
                                HStack(alignment: .top) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.yellow)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("⚠️ จอดซ้อนคัน")
                                            .font(.headline)
                                            .foregroundColor(.yellow)
                                        Text("กรุณาเลื่อนรถก่อนเวลา 13:00 น. เพื่อหลีกเลี่ยงค่าปรับ 1,000 บาท")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(12)
                                .shadow(color: .red.opacity(0.5), radius: 5, y: 3)
                            }
                            
                            if let date = parkedDate {
                                Text("Parked at \(date.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(20)
                        .shadow(color: .purple.opacity(0.3), radius: 10, y: 5)
                        .offset(x: dragOffset.width)
                        .opacity(isParked ? Double(1.0 - abs(dragOffset.width) / 200.0) : 1.0)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    // อนุญาตให้ swipe ไปทางซ้ายเท่านั้น
                                    if value.translation.width < 0 {
                                        dragOffset = value.translation
                                    }
                                }
                                .onEnded { value in
                                    if value.translation.width < -120 {
                                        // Swipe สำเร็จ
                                        clearParking()
                                        // Reset แบบไม่ animate (เพราะข้อมูลโดนลบและ view หายไปแล้ว)
                                        dragOffset = .zero
                                    } else {
                                        // ปล่อยก่อนถึงจุดที่กำหนด เด้งกลับ
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            dragOffset = .zero
                                        }
                                    }
                                }
                        )
                        .onTapGesture {
                            openEditMode()
                        }
                        
                        Text("👈 Swipe left to clear")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    } else {
                        // Empty State
                        Button(action: openEditMode) {
                            VStack(spacing: 12) {
                                Image(systemName: "location.viewfinder")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                Text("Save Parking Location")
                                    .font(.headline)
                                Text("Tap to remember your floor and zone")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
                        }
                    }
                }
                .padding(.horizontal)
                
            }
            .padding(.top)
        }
        .compactsTabBarOnScroll()
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }
    
    private func openEditMode() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        generator.impactOccurred()
        
        inputFloor = parkedFloor
        inputZone = parkedZone
        inputNotes = parkedNotes
        inputIsDoubleParked = isDoubleParked
        
        if let type = LocationType(rawValue: lastLocationTypeRaw) {
            editLocationType = type
        }
        
        // Default to a sane value if wheel picker is about to show empty
        if editLocationType == .condo && inputFloor.isEmpty {
            inputFloor = "1"
        }
        
        withAnimation(.spring()) {
            isEditing = true
        }
    }
    
    private func saveParking() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        
        parkedFloor = inputFloor
        parkedZone = inputZone
        parkedNotes = inputNotes
        parkedDateDouble = Date().timeIntervalSince1970
        lastLocationTypeRaw = editLocationType.rawValue
        isDoubleParked = editLocationType == .condo ? inputIsDoubleParked : false
        
        if isDoubleParked {
            Task {
                _ = try? await NotificationManager.shared.requestPermission()
                NotificationManager.shared.scheduleDoubleParkingReminder()
            }
        } else {
            NotificationManager.shared.cancelDoubleParkingReminder()
        }
        
        updateLiveActivity()
        WidgetCenter.shared.reloadAllTimelines()
        
        withAnimation(.spring()) {
            isEditing = false
        }
    }
    
    private func clearParking() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        NotificationManager.shared.cancelDoubleParkingReminder()
        
        withAnimation(.spring()) {
            parkedFloor = ""
            parkedZone = ""
            parkedNotes = ""
            parkedDateDouble = 0
            isDoubleParked = false
            isEditing = false
        }
        updateLiveActivity()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func updateLiveActivity() {
        Task {
            if isParked {
                let state = ParkingAttributes.ContentState(isDoubleParked: isDoubleParked, floor: parkedFloor, zone: parkedZone)
                let content = ActivityContent(state: state, staleDate: nil)
                
                if let currentActivity = Activity<ParkingAttributes>.activities.first {
                    await currentActivity.update(content)
                } else if ActivityAuthorizationInfo().areActivitiesEnabled {
                    let attributes = ParkingAttributes()
                    do {
                        _ = try Activity.request(attributes: attributes, content: content)
                    } catch {
                        print("Error starting Live Activity: \(error)")
                    }
                }
            } else {
                for activity in Activity<ParkingAttributes>.activities {
                    let state = ParkingAttributes.ContentState(isDoubleParked: false, floor: "", zone: "")
                    let content = ActivityContent(state: state, staleDate: nil)
                    await activity.end(content, dismissalPolicy: .immediate)
                }
            }
        }
    }
}

#Preview {
    EVDomainDashboardView()
}
