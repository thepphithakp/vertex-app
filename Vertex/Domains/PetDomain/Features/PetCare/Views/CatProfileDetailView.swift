import SwiftUI
import SwiftData

struct CatProfileDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var petStore: PetStore
    
    @Bindable var pet: Pet
    @State private var isShowingEdit = false
    @State private var isShowingDeleteConfirm = false
    @State private var isDeleting = false
    
    private var isOwner: Bool {
        guard let currentUserId = AuthService.shared.currentUser?.id.lowercased() else { return false }
        return pet.ownerId?.uuidString.lowercased() == currentUserId
    }
    
    private var currentCaregiver: PetCaregiver? {
        guard let currentUserId = AuthService.shared.currentUser?.id.lowercased() else { return nil }
        return pet.caregivers.first { $0.userId.uuidString.lowercased() == currentUserId }
    }
    
    private var canEditProfile: Bool {
        return isOwner || (currentCaregiver?.canEditProfile ?? false)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Avatar
                if let data = pet.avatarData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 5, y: 5)
                } else {
                    Image(systemName: "pawprint.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(30)
                        .frame(width: 140, height: 140)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                        .foregroundColor(.gray.opacity(0.5))
                }
                
                // Name & Basic Info
                VStack(spacing: 4) {
                    Text(pet.name)
                        .font(.largeTitle)
                        .bold()
                    
                    Text("\(pet.breed) • \(pet.gender)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    // ปุ่มตั้งค่า Active Pet จาก Store
                    Button(action: {
                        petStore.selectPet(pet)
                    }) {
                        HStack {
                            Image(systemName: petStore.activePet?.id == pet.id ? "star.fill" : "star")
                            Text(petStore.activePet?.id == pet.id ? "Active Pet" : "Set as Active")
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(petStore.activePet?.id == pet.id ? Color.yellow.opacity(0.2) : Color.blue.opacity(0.1))
                        .foregroundColor(petStore.activePet?.id == pet.id ? .orange : .blue)
                        .cornerRadius(20)
                    }
                    .padding(.top, 4)
                }
                
                // Info Cards
                HStack(spacing: 15) {
                    InfoCard(title: "อายุ", value: pet.ageString, icon: "calendar")
                    InfoCard(title: "น้ำหนัก", value: pet.currentWeight != nil ? String(format: "%.1f kg", pet.currentWeight!) : "-", icon: "scalemass")
                }
                .padding(.horizontal)
                
                // Detailed Stats
                VStack(alignment: .leading, spacing: 15) {
                    Text("รายละเอียด")
                        .font(.headline)
                        .padding(.bottom, 5)
                    
                    DetailRow(title: "วันเกิด", value: pet.birthDate.formatted(date: .abbreviated, time: .omitted))
                    DetailRow(title: "ทำหมัน", value: pet.isSpayedNeutered ? "ทำแล้ว" : "ยังไม่ทำ")
                    DetailRow(title: "กรุ๊ปเลือด", value: pet.bloodType ?? "ไม่ระบุ")
                    DetailRow(title: "อาการแพ้", value: pet.allergies ?? "ไม่มีข้อมูล")
                    DetailRow(title: "ลักษณะนิสัย", value: pet.personality ?? "ไม่มีข้อมูล")
                    DetailRow(title: "Microchip", value: pet.microchipId ?? "-")
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Co-Caregiver Settings Link (Owner Only)
                if isOwner {
                    NavigationLink(destination: CaregiverManagementView(pet: pet)) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.purple)
                            Text("Manage Co-Caregivers")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                // Delete Button (Owner Only)
                if isOwner {
                    Button(action: {
                        isShowingDeleteConfirm = true
                    }) {
                        HStack {
                            if isDeleting {
                                ProgressView().tint(.red)
                            } else {
                                Image(systemName: "trash")
                                Text("Delete Pet")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .disabled(isDeleting)
                }
                
                Spacer()
            }
            .padding(.top)
        }
        .tabBarAware()
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if canEditProfile {
                    Button("Edit") {
                        isShowingEdit = true
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingEdit) {
            AddPetView(petToEdit: pet)
        }
        .alert("Delete \(pet.name)?", isPresented: $isShowingDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePet()
            }
        } message: {
            Text("Are you sure you want to delete this pet? This action cannot be undone and will also clear all related data such as weight logs and medical records.")
        }
    }
    
    private func deletePet() {
        isDeleting = true
        Task {
            do {
                // 1. Delete from Backend Remote
                let repository = RemotePetRepository()
                try await repository.deletePet(pet)
                
                // 2. Clear Active Pet Selection if it's the one being deleted
                if petStore.activePet?.id == pet.id {
                    petStore.clearSelection()
                }
                
                // 3. Delete from Local SwiftData (This will auto-cascade delete related tables)
                modelContext.delete(pet)
                
                // 4. Dismiss View
                dismiss()
            } catch {
                print("Failed to delete pet: \(error)")
                isDeleting = false
            }
        }
    }
}

// UI Components for the Profile
struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.headline)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
        Divider()
    }
}
