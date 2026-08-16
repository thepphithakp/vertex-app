import SwiftUI
import PhotosUI
import SwiftData

struct AddPetWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var currentStep = 1
    private let totalSteps = 6
    
    // Form Data
    @State private var species = "Cat"
    @State private var breed = "Mix"
    @State private var gender = "Male"
    @State private var isSpayedNeutered = false
    @State private var name = ""
    
    @State private var showingImagePicker = false
    @State private var uiImage: UIImage? = nil
    @State private var avatarData: Data? = nil
    @State private var avatarImage: Image? = nil
    
    @State private var birthDate = Date()
    @State private var currentWeight: Double = 4.0
    
    // API States
    @State private var isSaving = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    // UI States
    @State private var searchText = ""
    @State private var popularCatBreeds: [String] = ["Mix", "British Shorthair", "Scottish Fold", "Scottish Straight (หูตั้ง)", "Tabby Cat", "Ragdoll", "Munchkin", "Persian", "Maine Coon"]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Progress Bar
                HStack(spacing: 8) {
                    Button(action: {
                        if currentStep > 1 {
                            withAnimation { currentStep -= 1 }
                        } else {
                            dismiss()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding(.trailing, 8)
                    }
                    
                    ForEach(1...totalSteps, id: \.self) { step in
                        Rectangle()
                            .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.2))
                            .frame(height: 4)
                            .cornerRadius(2)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Steps Content
                TabView(selection: $currentStep) {
                    step1Species.tag(1)
                    step2Breed.tag(2)
                    step3Gender.tag(3)
                    step4Profile.tag(4)
                    step5Age.tag(5)
                    step6Weight.tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                // Disable swiping to enforce validation
                .simultaneousGesture(DragGesture())
                
                // Bottom Next Button
                Button(action: {
                    if currentStep < totalSteps {
                        withAnimation { currentStep += 1 }
                    } else {
                        savePet()
                    }
                }) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.7))
                            .cornerRadius(30)
                    } else {
                        Text(currentStep == totalSteps ? "Done" : "Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isNextEnabled ? Color.blue : Color.gray.opacity(0.3))
                            .cornerRadius(30)
                    }
                }
                .disabled(!isNextEnabled || isSaving)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationBarHidden(true)
            .background(Color(UIColor.systemBackground).ignoresSafeArea())
            .alert("Error Saving Pet", isPresented: $showingErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .task {
            if let breeds = try? await RemoteMasterDataRepository().fetchCatBreeds(), !breeds.isEmpty {
                self.popularCatBreeds = breeds
                if !breeds.contains(self.breed) {
                    self.breed = breeds.first ?? "Mix"
                }
            }
        }
    }
    
    var isNextEnabled: Bool {
        if currentStep == 4 {
            return !name.isEmpty
        }
        return true
    }
    
    // MARK: - Step 1: Species
    private var step1Species: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Pet breed")
                .font(.system(size: 36, weight: .bold))
            Text("Select your pet species")
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                speciesCard(title: "Cat", icon: "cat.fill", color: .blue, isSelected: species == "Cat") {
                    species = "Cat"
                }
                speciesCard(title: "Dog", icon: "dog.fill", color: .orange, isSelected: species == "Dog") {
                    species = "Dog"
                }
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func speciesCard(title: String, icon: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                HStack {
                    Text(title).font(.title3).bold()
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                }
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
            .frame(height: 140)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(16)
            .opacity(isSelected ? 1.0 : 0.6)
            .shadow(color: color.opacity(isSelected ? 0.4 : 0), radius: 10, y: 5)
        }
    }
    
    // MARK: - Step 2: Breed
    private var step2Breed: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Pet profile")
                .font(.system(size: 32, weight: .bold))
                .padding(.horizontal, 24)
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                TextField("Search", text: $searchText)
            }
            .padding(10)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal, 24)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Popular breed")
                        .font(.headline)
                    
                    WrappingHStack(tags: popularCatBreeds) { breedTag in
                        Button(action: {
                            breed = breedTag
                            withAnimation { currentStep += 1 }
                        }) {
                            Text(breedTag)
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(breed == breedTag ? Color.blue : Color.gray.opacity(0.1))
                                .foregroundColor(breed == breedTag ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Step 3: Gender
    private var step3Gender: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Pet gender")
                .font(.system(size: 36, weight: .bold))
            Text("Select your pet gender")
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    genderCard(title: "Gentlemen", icon: "mustache.fill", color: .blue, isSelected: gender == "Male" && !isSpayedNeutered) {
                        gender = "Male"; isSpayedNeutered = false
                    }
                    genderCard(title: "Lady", icon: "crown.fill", color: .orange, isSelected: gender == "Female" && !isSpayedNeutered) {
                        gender = "Female"; isSpayedNeutered = false
                    }
                }
                HStack(spacing: 16) {
                    genderCard(title: "Neutered", icon: "scissors", color: .yellow, isSelected: gender == "Male" && isSpayedNeutered) {
                        gender = "Male"; isSpayedNeutered = true
                    }
                    genderCard(title: "Spayed", icon: "scissors", color: .teal, isSelected: gender == "Female" && isSpayedNeutered) {
                        gender = "Female"; isSpayedNeutered = true
                    }
                }
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func genderCard(title: String, icon: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                HStack {
                    Text(title).font(.headline).bold()
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                }
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
            .frame(height: 120)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(16)
            .opacity(isSelected ? 1.0 : 0.5)
            .shadow(color: color.opacity(isSelected ? 0.4 : 0), radius: 10, y: 5)
        }
    }
    
    // MARK: - Step 4: Profile Picture & Name
    private var step4Profile: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Profile picture and name")
                .font(.system(size: 32, weight: .bold))
            
            VStack(spacing: 24) {
                Text("Get your pet a new profile picture!")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(20)
                
                Button(action: {
                    showingImagePicker = true
                }) {
                    ZStack(alignment: .bottomTrailing) {
                        if let avatarImage {
                            avatarImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Image(systemName: "pawprint.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray.opacity(0.3))
                                )
                        }
                        
                        Image(systemName: "camera.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.blue)
                            .background(Circle().fill(Color.white))
                            .offset(x: 5, y: 5)
                    }
                }
                .sheet(isPresented: $showingImagePicker) {
                    ImagePicker(image: $uiImage, isPresented: $showingImagePicker)
                }
                .onChange(of: uiImage) { _, newImage in
                    if let image = newImage {
                        avatarImage = Image(uiImage: image)
                        // Compress image to reduce payload size
                        avatarData = image.jpegData(compressionQuality: 0.5)
                    }
                }
                
                HStack {
                    Text("User name")
                        .font(.headline)
                    Spacer()
                    TextField("Please enter a nickname", text: $name)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.primary)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Step 5: Age
    private var step5Age: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Pet age")
                .font(.system(size: 36, weight: .bold))
            
            Spacer()
            
            DatePicker("", selection: $birthDate, displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity, alignment: .center)
            
            let ageString = calculateAge(from: birthDate)
            Text("Your pet is \(ageString)")
                .font(.headline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 20)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func calculateAge(from date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date, to: Date())
        let y = components.year ?? 0
        let m = components.month ?? 0
        let d = components.day ?? 0
        
        if y > 0 { return "\(y)y \(m)m" }
        if m > 0 { return "\(m)m \(d)d" }
        return "\(d)d"
    }
    
    // MARK: - Step 6: Weight
    private var step6Weight: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Pet's weight")
                .font(.system(size: 36, weight: .bold))
            
            Spacer()
            
            VStack(spacing: 8) {
                WeightRulerPicker(weight: $currentWeight)
                
                Text("\(breed)'s normal weight range is:\n3.0kg - 6.0kg")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.top, 30)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func savePet() {
        guard !isSaving else { return }
        isSaving = true
        
        let repo = RemotePetRepository()
        Task {
            let newPet = Pet(
                name: name,
                species: species,
                breed: breed,
                colorCode: "#34C759", // Default green
                birthDate: birthDate,
                gender: gender,
                avatarData: avatarData,
                currentWeight: currentWeight,
                isSpayedNeutered: isSpayedNeutered
            )
            do {
                try await repo.savePet(newPet)
                
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch let apiError as APIError {
                await MainActor.run {
                    isSaving = false
                    errorMessage = apiError.errorDescription ?? apiError.localizedDescription
                    showingErrorAlert = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            }
        }
    }
    }

// Helper view for Wrapping Tags
struct WrappingHStack<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let content: (Data.Element) -> Content

    init(tags: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = tags
        self.content = content
    }

    var body: some View {
        // A simple fallback for wrapping tags. For real wrapping, we'd use FlowLayout.
        // SwiftUI doesn't have a native wrapping stack until iOS 16 (Layout protocol).
        // Since we target iOS 16+, we can use `FlowLayout` or just `LazyVGrid`.
        // I will use a simple Grid for now.
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 10) {
            ForEach(data, id: \.self) { item in
                content(item)
            }
        }
    }
}

#Preview {
    AddPetWizardView()
}
