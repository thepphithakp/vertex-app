import SwiftUI
import SwiftData

struct CatSelectorCarousel: View {
    let pets: [Pet]
    @Binding var selectedPet: Pet?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(pets) { pet in
                    VStack(spacing: 8) {
                        // Avatar
                        ZStack {
                            if let data = pet.avatarData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "pawprint.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(16)
                                    .frame(width: 64, height: 64)
                                    .background(Color.gray.opacity(0.15))
                                    .foregroundColor(.gray.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            
                            // กรอบสีน้ำเงินเวลาถูกเลือก (สไตล์คล้ายๆ Instagram Story)
                            Circle()
                                .stroke(selectedPet == pet ? Color.blue : Color.clear, lineWidth: 3)
                                .frame(width: 72, height: 72)
                        }
                        
                        Text(pet.name)
                            .font(.caption)
                            .fontWeight(selectedPet == pet ? .bold : .medium)
                            .foregroundColor(selectedPet == pet ? .blue : .primary)
                    }
                    .onTapGesture {
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
                        
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedPet = pet
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
}
