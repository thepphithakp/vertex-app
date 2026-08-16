import Foundation

enum AppEnvironment {
    case development
    case staging
    case production
}

struct AppConfig {
    static let shared = AppConfig()
    
    // Change this to switch environments
    var currentEnvironment: AppEnvironment = .development
    
    var baseURL: URL {
        switch currentEnvironment {
        case .development:
            // Return the TrueDDNS Server URL
            return URL(string: "https://thepphithakp.trueddns.com:22371/api/v1")!
        case .staging:
            return URL(string: "https://staging.vertex.app/api")!
        case .production:
            return URL(string: "https://api.vertex.app/api")!
        }
    }
}
