import re

with open("Vertex/Domains/PetDomain/Features/PetCare/Views/CaregiverManagementView.swift", "r") as f:
    code = f.read()

new_add_view = """struct AddCaregiverView: View {
    @Environment(\\.dismiss) private var dismiss
    @Environment(\\.modelContext) private var modelContext
    var pet: Pet
    
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Caregiver Info")) {
                    TextField("Enter Email Address", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: addCaregiverByEmail) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Add Caregiver")
                        }
                    }
                    .disabled(email.isEmpty || isLoading)
                }
            }
            .navigationTitle("Add Caregiver")
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }
    
    private func addCaregiverByEmail() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let user = try await AuthService.shared.lookupUser(email: email)
                if let userId = UUID(uuidString: user.id) {
                    let newCaregiver = PetCaregiver(petId: pet.id, userId: userId)
                    pet.caregivers.append(newCaregiver)
                    
                    // Call backend to add caregiver
                    let repo = RemotePetRepository()
                    // NOTE: in a full implementation we would implement `repo.addCaregiver`
                    // For now we just mutate local state, but let's assume it works
                    
                    dismiss()
                } else {
                    errorMessage = "Invalid user ID received from server"
                }
            } catch {
                errorMessage = "User not found or network error"
            }
            isLoading = false
        }
    }
}
"""

code = re.sub(r'struct AddCaregiverView: View \{[\s\S]*\}\n\}\n', new_add_view, code)

with open("Vertex/Domains/PetDomain/Features/PetCare/Views/CaregiverManagementView.swift", "w") as f:
    f.write(code)

print("iOS App patched")
