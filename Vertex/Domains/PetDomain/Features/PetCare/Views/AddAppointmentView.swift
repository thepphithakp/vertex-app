import SwiftUI
import SwiftData
import UserNotifications

struct AddAppointmentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var petStore: PetStore
    
    var appointmentToEdit: PetAppointment?
    
    @State private var title: String
    @State private var type: String
    @State private var date: Date
    @State private var notes: String
    @State private var isReminderSet: Bool
    @State private var selectedPet: Pet?
    
    @State private var allPets: [Pet] = []
    
    let appointmentTypes = ["Vaccine", "Checkup", "Grooming", "Other"]
    
    init(appointmentToEdit: PetAppointment? = nil) {
        self.appointmentToEdit = appointmentToEdit
        _title = State(initialValue: appointmentToEdit?.title ?? "")
        _type = State(initialValue: appointmentToEdit?.appointmentType ?? "Vaccine")
        _date = State(initialValue: appointmentToEdit?.date ?? Date().addingTimeInterval(86400))
        _notes = State(initialValue: appointmentToEdit?.notes ?? "")
        _isReminderSet = State(initialValue: appointmentToEdit?.isReminderSet ?? true)
        _selectedPet = State(initialValue: appointmentToEdit?.pet)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Pet")) {
                    if allPets.isEmpty {
                        Text("ไม่มีข้อมูลแมว กรุณาเพิ่มแมวก่อนนัดหมาย")
                            .foregroundColor(.red)
                    } else {
                        Picker("Select Cat", selection: $selectedPet) {
                            ForEach(allPets) { pet in
                                Text(pet.name).tag(pet as Pet?)
                            }
                        }
                    }
                }
                
                Section(header: Text("Appointment Details")) {
                    TextField("หัวข้อนัดหมาย (เช่น วัคซีนรวมเข็ม 2)", text: $title)
                    Picker("ประเภทการนัด", selection: $type) {
                        ForEach(appointmentTypes, id: \.self) { t in
                            Text(t).tag(t)
                        }
                    }
                    DatePicker("วันและเวลา", selection: $date, in: Date()...)
                }
                
                Section(header: Text("Notes")) {
                    TextField("บันทึกเพิ่มเติม (ตัวเลือก)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section(header: Text("Reminder"), footer: Text("จะแจ้งเตือนล่วงหน้า 1 วันก่อนถึงเวลานัดหมายจริง")) {
                    Toggle("ตั้งเตือนความจำ", isOn: $isReminderSet)
                }
            }
            .navigationTitle(appointmentToEdit == nil ? "New Appointment" : "Edit Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAppointment()
                    }
                    .disabled(title.isEmpty || selectedPet == nil)
                }
            }
            .task {
                await loadPets()
                _ = try? await NotificationManager.shared.requestPermission()
            }
        }
    }
    
    private func loadPets() async {
        let repo = RemotePetRepository()
        if let pets = try? await repo.fetchPets() {
            self.allPets = pets
            
            // หากเป็นการสร้างใหม่ และยังไม่มีการเลือกแมว ให้เลือกจาก Active Pet
            if appointmentToEdit == nil && selectedPet == nil {
                if let active = petStore.activePet, let match = pets.first(where: { $0.id == active.id }) {
                    self.selectedPet = match
                } else if let first = pets.first {
                    self.selectedPet = first
                }
            }
        }
    }
    
    private func saveAppointment() {
        guard let pet = selectedPet else { return }
        let repo = LocalAppointmentRepository(context: context)
        
        Task {
            do {
                if let appt = appointmentToEdit {
                    appt.title = title
                    appt.appointmentType = type
                    appt.date = date
                    appt.notes = notes
                    appt.pet = pet
                    
                    if isReminderSet {
                        NotificationManager.shared.cancelReminder(for: appt.id)
                        NotificationManager.shared.scheduleAppointmentReminder(for: appt, petName: pet.name)
                    } else {
                        NotificationManager.shared.cancelReminder(for: appt.id)
                    }
                    appt.isReminderSet = isReminderSet
                    
                    try await repo.saveAppointment(appt)
                } else {
                    let newAppt = PetAppointment(title: title, appointmentType: type, date: date, notes: notes, isReminderSet: isReminderSet)
                    newAppt.pet = pet
                    try await repo.saveAppointment(newAppt)
                    
                    if isReminderSet {
                        NotificationManager.shared.scheduleAppointmentReminder(for: newAppt, petName: pet.name)
                    }
                }
                
                dismiss()
            } catch {
                print("Error saving appointment: \(error)")
            }
        }
    }
}
