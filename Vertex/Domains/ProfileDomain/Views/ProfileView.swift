import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var themeManager: ThemeManager
    
    @State private var showingImagePicker = false
    @State private var uiImage: UIImage? = nil
    @State private var avatarImage: Image? = Image(systemName: "person.circle.fill")
    
    @State private var isEditingName = false
    @State private var editNameText = ""
    @Namespace private var themeAnimation
    
    var body: some View {
        ZStack {
            // Animated Mesh / Liquid Background
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3), Color.cyan.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header Card (Liquid Glass)
                    VStack(spacing: 16) {
                        Button(action: {
                            showingImagePicker = true
                        }) {
                            ZStack(alignment: .bottomTrailing) {
                                avatarImage?
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 2))
                                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 32, height: 32)
                                    .overlay(Image(systemName: "camera.fill").foregroundColor(.white).font(.system(size: 14)))
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .offset(x: -5, y: -5)
                            }
                        }
                        .sheet(isPresented: $showingImagePicker) {
                            ImagePicker(image: $uiImage, isPresented: $showingImagePicker)
                        }
                        .onChange(of: uiImage) { _, newImage in
                            if let image = newImage {
                                avatarImage = Image(uiImage: image)
                                // TODO: Sync compressed image data to backend
                                // let compressedData = image.jpegData(compressionQuality: 0.5)
                            }
                        }
                        
                        VStack(spacing: 4) {
                            if isEditingName {
                                TextField("Display Name", text: $editNameText, onCommit: {
                                    isEditingName = false
                                    // TODO: Sync name to backend
                                })
                                .font(.title2.bold())
                                .multilineTextAlignment(.center)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(maxWidth: 250)
                            } else {
                                HStack {
                                    Text(editNameText.isEmpty ? (authService.currentUser?.fullName ?? "Vertex User") : editNameText)
                                        .font(.title2)
                                        .bold()
                                    
                                    Button(action: {
                                        editNameText = authService.currentUser?.fullName ?? "Vertex User"
                                        isEditingName = true
                                    }) {
                                        Image(systemName: "pencil.circle.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Text(authService.currentUser?.email ?? "Email not provided")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 30)
                    .frame(maxWidth: .infinity)
                    .liquidGlass(cornerRadius: 30)
                    .padding(.horizontal)
                    
                    // Settings Section
                    VStack(spacing: 0) {
                        settingRow(icon: "lock.shield", title: "Security & Password", color: .green)
                        Divider().padding(.leading, 50)
                        settingRow(icon: "bell", title: "Notifications", color: .orange)
                    }
                    .liquidGlass()
                    .padding(.horizontal)
                    
                    // Theme Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Appearance")
                            .font(.headline)
                            .padding(.leading, 10)
                        
                        GeometryReader { proxy in
                            let totalWidth = proxy.size.width
                            let tabWidth = totalWidth / CGFloat(AppTheme.allCases.count)
                            
                            HStack(spacing: 0) {
                                ForEach(AppTheme.allCases) { theme in
                                    Text(theme.rawValue)
                                        .font(.system(size: 14, weight: themeManager.selectedTheme == theme ? .bold : .medium))
                                        .foregroundColor(themeManager.selectedTheme == theme ? .primary : .secondary)
                                        .frame(width: tabWidth)
                                        .padding(.vertical, 8)
                                        .background(
                                            ZStack {
                                                if themeManager.selectedTheme == theme {
                                                    GlassPillView()
                                                        .matchedGeometryEffect(id: "ACTIVETHEME", in: themeAnimation)
                                                }
                                            }
                                        )
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                themeManager.selectedTheme = theme
                                            }
                                        }
                                }
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let location = value.location.x
                                        let index = Int(location / tabWidth)
                                        let safeIndex = max(0, min(index, AppTheme.allCases.count - 1))
                                        let newTheme = AppTheme.allCases[safeIndex]
                                        
                                        if themeManager.selectedTheme != newTheme {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                themeManager.selectedTheme = newTheme
                                            }
                                        }
                                    }
                            )
                        }
                        .frame(height: 36)
                        .background(Capsule().fill(Color(UIColor.tertiarySystemFill)))
                    }
                    .padding()
                    .liquidGlass()
                    .padding(.horizontal)
                    
                    Button(action: {
                        authService.logout()
                    }) {
                        Text("Log Out")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(16)
                            .shadow(color: .red.opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                }
                .padding(.top, 20)
            }
            .compactsTabBarOnScroll()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if editNameText.isEmpty {
                editNameText = authService.currentUser?.fullName ?? ""
            }
        }
    }
    
    @ViewBuilder
    private func settingRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(color)
            }
            Text(title)
                .font(.body)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.system(size: 14, weight: .semibold))
        }
        .padding()
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AuthService.shared)
            .environmentObject(ThemeManager.shared)
    }
}
