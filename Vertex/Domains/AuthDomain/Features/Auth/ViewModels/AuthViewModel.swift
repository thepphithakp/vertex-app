import Foundation
import AuthenticationServices
import Combine
import GoogleSignIn

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var fullName = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    
    func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }
        
        isLoading = true
        errorMessage = nil
        do {
            try await AuthService.shared.login(email: email, password: password)
            isAuthenticated = true
        } catch let error as APIError {
            errorMessage = error.message
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func signup() async {
        guard !email.isEmpty, !password.isEmpty, !fullName.isEmpty else {
            errorMessage = "Please fill all fields."
            return
        }
        
        isLoading = true
        errorMessage = nil
        do {
            try await AuthService.shared.signup(email: email, password: password, fullName: fullName)
            isAuthenticated = true
        } catch let error as APIError {
            errorMessage = error.message
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func handleGoogleLogin() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            self.errorMessage = "Unable to find root view controller"
            return
        }
        
        // TODO: Replace with your actual Google Client ID from Google Cloud Console
        let clientID = "565361629384-nm0k3gs5affdnva1gjlfb2b9musj0614.apps.googleusercontent.com"
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        isLoading = true
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] signInResult, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let error = error {
                    self.isLoading = false
                    // Check if user cancelled
                    if (error as NSError).code == GIDSignInError.canceled.rawValue { return }
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let user = signInResult?.user,
                      let idToken = user.idToken?.tokenString else {
                    self.isLoading = false
                    self.errorMessage = "Failed to fetch Google ID Token"
                    return
                }
                
                let email = user.profile?.email ?? ""
                let fullName = user.profile?.name ?? ""
                
                do {
                    try await AuthService.shared.loginWithGoogle(
                        idToken: idToken,
                        email: email,
                        fullName: fullName
                    )
                    self.isAuthenticated = true
                } catch let error as APIError {
                    self.errorMessage = error.message
                } catch {
                    self.errorMessage = error.localizedDescription
                }
                self.isLoading = false
            }
        }
    }
    
    func logout() {
        AuthService.shared.logout()
        isAuthenticated = false
    }
}
