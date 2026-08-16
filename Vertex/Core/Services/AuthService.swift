import Foundation
import Combine

struct AuthResponse: Decodable {
    let token: String
    let user: UserProfile
}

struct UserProfile: Codable, Identifiable {
    let id: String
    let email: String
    let fullName: String
}

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentToken: String? {
        didSet {
            if let token = currentToken {
                UserDefaults.standard.set(token, forKey: "jwt_token")
            } else {
                UserDefaults.standard.removeObject(forKey: "jwt_token")
            }
        }
    }
    
    @Published var currentUser: UserProfile? {
        didSet {
            if let user = currentUser, let data = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(data, forKey: "current_user")
            } else {
                UserDefaults.standard.removeObject(forKey: "current_user")
            }
        }
    }
    
    private init() {
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            if JWTDecoder.isExpired(jwtToken: token) {
                // Token expired, clear it
                self.currentToken = nil
                UserDefaults.standard.removeObject(forKey: "jwt_token")
            } else {
                self.currentToken = token
                if let userData = UserDefaults.standard.data(forKey: "current_user"),
                   let user = try? JSONDecoder().decode(UserProfile.self, from: userData) {
                    self.currentUser = user
                }
            }
        }
    }
    
    func signup(email: String, password: String, fullName: String) async throws {
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "fullName": fullName
        ]
        
        let data = try JSONSerialization.data(withJSONObject: body)
        let response: AuthResponse = try await NetworkManager.shared.request(endpoint: "/auth/signup", method: "POST", body: data)
        
        self.currentToken = response.token
        self.currentUser = response.user
    }
    
    func login(email: String, password: String) async throws {
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        
        let data = try JSONSerialization.data(withJSONObject: body)
        let response: AuthResponse = try await NetworkManager.shared.request(endpoint: "/auth/login", method: "POST", body: data)
        
        self.currentToken = response.token
        self.currentUser = response.user
    }
    
    func loginWithGoogle(idToken: String, email: String, fullName: String) async throws {
        let body: [String: Any] = [
            "idToken": idToken,
            "email": email,
            "fullName": fullName
        ]
        
        let data = try JSONSerialization.data(withJSONObject: body)
        let response: AuthResponse = try await NetworkManager.shared.request(endpoint: "/auth/google", method: "POST", body: data)
        
        self.currentToken = response.token
        self.currentUser = response.user
    }
    
    func fetchCurrentUser() async throws {
        guard currentToken != nil else { return }
        
        // request จะแนบ token อัตโนมัติอยู่แล้วใน NetworkManager
        let user: UserProfile = try await NetworkManager.shared.request(endpoint: "/auth/me", method: "GET")
        self.currentUser = user
    }
    
    func lookupUser(email: String) async throws -> UserProfile {
        let endpoint = "/auth/lookup?email=\(email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email)"
        let user: UserProfile = try await NetworkManager.shared.request(endpoint: endpoint, method: "GET")
        return user
    }
    
    func getAllUsers() async throws -> [UserProfile] {
        let users: [UserProfile] = try await NetworkManager.shared.request(endpoint: "/auth/users", method: "GET")
        return users
    }
    
    func logout() {
        self.currentToken = nil
        self.currentUser = nil
    }
}
