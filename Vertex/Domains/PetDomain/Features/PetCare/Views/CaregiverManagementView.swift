import SwiftUI
import SwiftData

struct CaregiverManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var pet: Pet
    
    @State private var showingAddCaregiver = false
    @State private var allUsers: [UserProfile] = []
    
    var body: some View {
        List {
            Section(header: Text("Owner")) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                    VStack(alignment: .leading) {
                        if isCurrentUserOwner() {
                            Text("You (Owner)")
                                .font(.headline)
                            Text("Full access to all settings")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text(ownerName())
                                .font(.headline)
                            Text("Owner")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                }
            }
            
            Section(header: Text("Co-Caregivers"), footer: Text("Co-caregivers can view and manage this pet based on the permissions you grant them.")) {
                if pet.caregivers.isEmpty {
                    Text("No co-caregivers added yet.")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(pet.caregivers) { caregiver in
                        NavigationLink(destination: CaregiverDetailView(caregiver: caregiver)) {
                            HStack {
                                Image(systemName: "person.2.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.purple)
                                VStack(alignment: .leading) {
                                    Text(caregiverName(for: caregiver.userId))
                                        .font(.headline)
                                    Text("Tap to manage permissions")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteCaregiver)
                }
                
                if isCurrentUserOwner() {
                    Button(action: {
                        showingAddCaregiver = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Co-Caregiver")
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .navigationTitle("Co-Caregivers")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddCaregiver) {
            AddCaregiverView(pet: pet)
        }
        .task {
            do {
                allUsers = try await AuthService.shared.getAllUsers()
            } catch {
                print("Failed to load users for names")
            }
        }
    }
    
    private func caregiverName(for id: UUID) -> String {
        let match = allUsers.first { $0.id.lowercased() == id.uuidString.lowercased() }
        if let match = match {
            return match.fullName.isEmpty ? match.email : match.fullName
        }
        return "Unknown Caregiver"
    }
    
    private func isCurrentUserOwner() -> Bool {
        guard let currentUserId = AuthService.shared.currentUser?.id.lowercased() else { return false }
        return pet.ownerId?.uuidString.lowercased() == currentUserId
    }
    
    private func ownerName() -> String {
        guard let ownerId = pet.ownerId else { return "Unknown Owner" }
        return caregiverName(for: ownerId)
    }
    
    private func deleteCaregiver(at offsets: IndexSet) {
        for index in offsets {
            let caregiver = pet.caregivers[index]
            modelContext.delete(caregiver)
            
            Task {
                do {
                    let repo = RemotePetRepository()
                    try await repo.removeCaregiver(caregiver, from: pet.id)
                } catch {
                    print("Failed to remove caregiver from API")
                }
            }
        }
    }
}

struct CaregiverDetailView: View {
    @Bindable var caregiver: PetCaregiver
    
    var body: some View {
        Form {
            Section(header: Text("Permissions")) {
                Toggle("Edit Profile & Settings", isOn: $caregiver.canEditProfile)
                Toggle("Manage Medical Records", isOn: $caregiver.canAddMedical)
                Toggle("Update Weight Log", isOn: $caregiver.canAddWeight)
                Toggle("Manage Daily Tasks", isOn: $caregiver.canManageTasks)
                Toggle("Record Litter Box (Poop/Pee)", isOn: $caregiver.canManageLitter)
            }
        }
        .navigationTitle("Permissions")
        .navigationBarTitleDisplayMode(.inline)
        // Note: In a real app, you would sync these changes to the backend API `PUT /api/v1/pets/:id/caregivers/:caregiverId` on disappear or save button.
    }
}

struct AddCaregiverView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    var pet: Pet
    
    @State private var users: [UserProfile] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading users...")
                } else if let error = errorMessage {
                    VStack {
                        Text(error)
                            .foregroundColor(.red)
                        Button("Retry") {
                            loadUsers()
                        }
                    }
                } else {
                    List {
                        ForEach(users) { user in
                            Button(action: {
                                addCaregiver(user: user)
                            }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(user.fullName.isEmpty ? "No Name" : user.fullName)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(user.email)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "plus.circle")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Co-Caregiver")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
            .task {
                loadUsers()
            }
        }
    }
    
    private func loadUsers() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let fetchedUsers = try await AuthService.shared.getAllUsers()
                // Filter out current user
                if let currentEmail = AuthService.shared.currentUser?.email {
                    self.users = fetchedUsers.filter { $0.email != currentEmail }
                } else {
                    self.users = fetchedUsers
                }
            } catch {
                errorMessage = "Failed to load users: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    private func addCaregiver(user: UserProfile) {
        if let userId = UUID(uuidString: user.id) {
            let newCaregiver = PetCaregiver(petId: pet.id, userId: userId)
            pet.caregivers.append(newCaregiver)
            
            Task {
                do {
                    let repo = RemotePetRepository()
                    try await repo.addCaregiver(newCaregiver, to: pet.id)
                } catch {
                    print("Failed to add caregiver to API")
                }
            }
            
            dismiss()
        }
    }
}
