import SwiftUI
import SwiftData
import GoogleSignIn

@main
struct VertexApp: App {
    // ประกาศ Store ที่จุดสูงสุดของแอป
    @StateObject private var appStore = AppStore()
    @StateObject private var petStore = PetStore()
    @StateObject private var authService = AuthService.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    @State private var isSplashScreenActive = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isSplashScreenActive {
                    SplashView()
                        .transition(.opacity) // Fade out effect
                } else {
                    Group {
                        if authService.currentToken != nil {
                            ContentView()
                                .environmentObject(appStore)
                                .environmentObject(petStore)
                                .environmentObject(authService)
                                .task {
                                    try? await authService.fetchCurrentUser()
                                }
                        } else {
                            AuthView()
                                .environmentObject(authService)
                        }
                    }
                    .onOpenURL { url in
                        GIDSignIn.sharedInstance.handle(url)
                    }
                    .transition(.opacity) // Fade in effect
                }
            }
            .animation(.easeInOut(duration: 0.5), value: isSplashScreenActive)
            .environmentObject(themeManager)
            .preferredColorScheme(themeManager.selectedTheme.colorScheme)
            .onAppear {
                // Hide splash screen after 1.2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    isSplashScreenActive = false
                }
            }
            .withGlobalErrorHandler()
        }
        // Inject shared Database Provider
        .modelContainer(DatabaseProvider.shared.container)
    }
}
