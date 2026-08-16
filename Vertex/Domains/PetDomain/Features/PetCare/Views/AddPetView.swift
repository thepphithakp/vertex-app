import SwiftUI
import PhotosUI
import SwiftData

struct AddPetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    var petToEdit: Pet?
    
    @State private var name = ""
    @State private var breed = ""
    @State private var colorCode = "#000000"
    @State private var birthDate = Date()
    @State private var gender = "Male"
    @State private var currentWeight: Double? = nil
    @State private var isSpayedNeutered = false
    @State private var microchipId = ""
    
    @State private var bloodType = "Unknown"
    @State private var allergies = ""
    @State private var personality = ""
    
    @State private var showingImagePicker = false
    @State private var uiImage: UIImage? = nil
    @State private var avatarImage: Image? = nil
    @State private var avatarData: Data? = nil
    
    // Error Handling
    @State private var showingErrorAlert = false
    @State private var apiError: APIError? = nil
    @State private var isSaving = false
    
    // Master Data States
    @State private var catBreeds: [String] = []
    @State private var bloodTypes: [String] = []
    @State private var isLoadingMasterData = true
    
    private let masterDataRepo: MasterDataRepository = LocalMasterDataRepository()
    
    init(petToEdit: Pet? = nil) {
        self.petToEdit = petToEdit
        if let pet = petToEdit {
            _name = State(initialValue: pet.name)
            _breed = State(initialValue: pet.breed)
            _birthDate = State(initialValue: pet.birthDate)
            _gender = State(initialValue: pet.gender)
            _currentWeight = State(initialValue: pet.currentWeight)
            _isSpayedNeutered = State(initialValue: pet.isSpayedNeutered)
            _microchipId = State(initialValue: pet.microchipId ?? "")
            _bloodType = State(initialValue: pet.bloodType ?? "Unknown")
            _allergies = State(initialValue: pet.allergies ?? "")
            _personality = State(initialValue: pet.personality ?? "")
            _avatarData = State(initialValue: pet.avatarData)
            
            if let data = pet.avatarData, let uiImage = UIImage(data: data) {
                _avatarImage = State(initialValue: Image(uiImage: uiImage))
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoadingMasterData {
                    VStack {
                        ProgressView("Loading Master Data...")
                    }
                } else {
                    Form {
                        Section(header: Text("Cat Photo").font(.subheadline)) {
                            HStack {
                                Spacer()
                                Button(action: {
                                    showingImagePicker = true
                                }) {
                                    if let avatarImage {
                                        avatarImage
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.blue.opacity(0.5), lineWidth: 2))
                                    } else {
                                        VStack {
                                            Image(systemName: "camera.circle.fill")
                                                .resizable()
                                                .frame(width: 80, height: 80)
                                                .foregroundColor(.gray.opacity(0.5))
                                            Text("Add Photo")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                }
                                .sheet(isPresented: $showingImagePicker) {
                                    ImagePicker(image: $uiImage, isPresented: $showingImagePicker)
                                }
                                .onChange(of: uiImage) { _, newImage in
                                    if let image = newImage {
                                        avatarImage = Image(uiImage: image)
                                        avatarData = image.jpegData(compressionQuality: 0.5)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                        
                        Section(header: Text("Basic Information")) {
                            TextField("Name (e.g. Luna)", text: $name)
                            
                            Picker("Breed", selection: $breed) {
                                ForEach(catBreeds, id: \.self) { breedName in
                                    Text(breedName).tag(breedName)
                                }
                            }
                            
                            Picker("Gender", selection: $gender) {
                                Text("Male").tag("Male")
                                Text("Female").tag("Female")
                            }
                            .pickerStyle(.segmented)
                            
                            DatePicker("Birth Date", selection: $birthDate, displayedComponents: .date)
                        }
                        
                        Section(header: Text("Health & Details")) {
                            Toggle("Spayed / Neutered (ทำหมันแล้ว)", isOn: $isSpayedNeutered)
                            
                            TextField("Current Weight in kg (e.g. 4.5)", value: $currentWeight, format: .number)
                                .keyboardType(.decimalPad)
                            
                            Picker("Blood Type", selection: $bloodType) {
                                ForEach(bloodTypes, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            
                            TextField("Microchip ID (Optional)", text: $microchipId)
                        }
                        
                        Section(header: Text("Additional Info")) {
                            TextField("Allergies (e.g. อาหารทะเล, ไก่)", text: $allergies)
                            TextField("Personality (e.g. ขี้อ้อน, หวงตัว)", text: $personality)
                        }
                    }
                }
            }
            .navigationTitle(petToEdit == nil ? "New Cat Profile" : "Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: savePet) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(name.isEmpty || isLoadingMasterData || isSaving)
                }
            }
            .task {
                await loadMasterData()
            }
            .alert("Error Saving Pet", isPresented: $showingErrorAlert, presenting: apiError) { error in
                if error.requestId != nil {
                    Button("Copy Request ID") {
                        UIPasteboard.general.string = error.requestId
                    }
                }
                Button("OK", role: .cancel) { }
            } message: { error in
                Text("\(error.message)\n\nRequest ID: \(error.requestId ?? "N/A")")
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
    
    private func loadMasterData() async {
        do {
            // โหลด Master Data แบบขนานกัน (Parallel) เพื่อความรวดเร็ว
            async let fetchBreeds = masterDataRepo.fetchCatBreeds()
            async let fetchBloodTypes = masterDataRepo.fetchBloodTypes()
            
            let (breedsResult, bloodTypesResult) = try await (fetchBreeds, fetchBloodTypes)
            
            self.catBreeds = breedsResult
            self.bloodTypes = bloodTypesResult
            
            // ตั้งค่า Default ถ้ายกเปิดหน้าสร้างใหม่และยังไม่ได้เลือก
            if petToEdit == nil {
                self.breed = breedsResult.first ?? "Unknown"
                self.bloodType = bloodTypesResult.first ?? "Unknown"
            }
            
            isLoadingMasterData = false
        } catch {
            print("Failed to load master data: \(error)")
            isLoadingMasterData = false
        }
    }
    
    private func savePet() {
        guard !isSaving else { return }
        isSaving = true
        let repo = RemotePetRepository()
        
        Task {
            do {
                if let pet = petToEdit {
                    pet.name = name
                    pet.breed = breed
                    pet.gender = gender
                    pet.birthDate = birthDate
                    pet.avatarData = avatarData
                    pet.currentWeight = currentWeight
                    pet.isSpayedNeutered = isSpayedNeutered
                    pet.microchipId = microchipId.isEmpty ? nil : microchipId
                    pet.bloodType = bloodType == "Unknown" ? nil : bloodType
                    pet.allergies = allergies.isEmpty ? nil : allergies
                    pet.personality = personality.isEmpty ? nil : personality
                    try await repo.updatePet(pet)
                } else {
                    let newPet = Pet(name: name, species: "Cat", breed: breed, colorCode: colorCode, birthDate: birthDate, gender: gender, avatarData: avatarData, currentWeight: currentWeight, microchipId: microchipId.isEmpty ? nil : microchipId, isSpayedNeutered: isSpayedNeutered, bloodType: bloodType == "Unknown" ? nil : bloodType, allergies: allergies.isEmpty ? nil : allergies, personality: personality.isEmpty ? nil : personality)
                    try await repo.savePet(newPet)
                }
                isSaving = false
                dismiss()
            } catch let error as APIError {
                self.apiError = error
                self.showingErrorAlert = true
                self.isSaving = false
            } catch {
                self.apiError = APIError(message: error.localizedDescription, requestId: nil)
                self.showingErrorAlert = true
                self.isSaving = false
            }
        }
    }
}

#Preview {
    AddPetView()
        .modelContainer(DatabaseProvider.shared.container)
}
