import SwiftUI
import SwiftData

struct PetManagementMainView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var petStore: PetStore
    @StateObject private var viewModel = PetListViewModel()
    @State private var isShowingAddPet = false
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading Pets...")
            } else if viewModel.pets.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "pawprint.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.gray.opacity(0.3))
                    Text("No Cats Yet")
                        .font(.title2)
                        .bold()
                    Text("Add your first cat to start tracking their health, tasks, and more.")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: { isShowingAddPet = true }) {
                        Text("Add Cat")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: 200)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                }
            } else {
                List {
                    ForEach(viewModel.pets) { pet in
                        NavigationLink(destination: CatProfileDetailView(pet: pet)) {
                            HStack(spacing: 16) {
                                if let data = pet.avatarData, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "pawprint.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(15)
                                        .frame(width: 60, height: 60)
                                        .background(Color.gray.opacity(0.2))
                                        .clipShape(Circle())
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(pet.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("\(pet.breed) • อายุ \(pet.ageString)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { indexSet in
                        Task {
                            await viewModel.deletePet(at: indexSet, repository: RemotePetRepository())
                        }
                    }
                }
                .compactsTabBarOnScroll()
                .refreshable {
                    await petStore.loadAllPets(force: true)
                    viewModel.pets = petStore.allPets
                }
            }
        }
        .navigationTitle("My Cats")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { isShowingAddPet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingAddPet) {
            AddPetWizardView()
                .onDisappear {
                    Task { 
                        await petStore.loadAllPets(force: true)
                        viewModel.pets = petStore.allPets
                    }
                }
        }
        .task {
            // PetStore handles TTL and caching internally
            await petStore.loadAllPets()
            viewModel.pets = petStore.allPets
            viewModel.isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        PetManagementMainView()
    }
    .modelContainer(DatabaseProvider.shared.container)
    .environmentObject(AppStore())
    .environmentObject(PetStore())
}
