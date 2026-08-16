import Foundation
import UIKit
import SwiftUI
import Combine

class NetworkManager {
    static let shared = NetworkManager()
    
    private let urlSession: URLSession
    private let sessionDelegate = InsecureSessionDelegate()
    
    private init() {
        let config = URLSessionConfiguration.default
        self.urlSession = URLSession(configuration: config, delegate: sessionDelegate, delegateQueue: nil)
    }
    
    // Default headers for Distributed Tracing (ELK, Datadog, etc.)
    private var defaultHeaders: [String: String] {
        return [
            "Content-Type": "application/json",
            "X-Source-System": "ios-app",
            "X-Device-Id": UIDevice.current.identifierForVendor?.uuidString ?? "unknown-device"
        ]
    }
    
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(AppConfig.shared.baseURL)\(endpoint)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        
        // Inject Tracing Headers
        for (key, value) in defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Inject Authorization Header
        if let token = UserDefaults.standard.string(forKey: "jwt_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Inject Request ID per request
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-Id")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if !(200...299).contains(httpResponse.statusCode) {
            let decoder = JSONDecoder()
            var errorToThrow: APIError
            if let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) {
                errorToThrow = APIError(message: errorResponse.error, requestId: errorResponse.requestId ?? request.value(forHTTPHeaderField: "X-Request-Id"))
            } else {
                errorToThrow = APIError(message: "Unknown server error (Status \(httpResponse.statusCode))", requestId: request.value(forHTTPHeaderField: "X-Request-Id"))
            }
            Task { @MainActor in
                GlobalErrorManager.shared.handleError(errorToThrow)
            }
            throw errorToThrow
        }
        
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        
        let decoder = JSONDecoder()
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let fractionalFormatter = ISO8601DateFormatter()
            fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            let standardFormatter = ISO8601DateFormatter()
            standardFormatter.formatOptions = [.withInternetDateTime]
            
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            if let date = fractionalFormatter.date(from: dateString) {
                return date
            }
            if let date = standardFormatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        
        return try decoder.decode(T.self, from: data)
    }
}

// Helper for endpoints that return 204 No Content
struct EmptyResponse: Decodable {}

struct APIErrorResponse: Decodable {
    let error: String
    let requestId: String?
}

struct APIError: Error, LocalizedError {
    let message: String
    let requestId: String?
    
    var errorDescription: String? {
        if let reqId = requestId {
            return "\(message) [ReqID: \(reqId.prefix(8))]" // Show short ID for UX
        }
        return message
    }
}

// MARK: - Insecure SSL Delegate for Dev
class InsecureSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Bypass SSL check for development server
        if let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
import SwiftUI
import Combine

@MainActor
class GlobalErrorManager: ObservableObject {
    static let shared = GlobalErrorManager()
    
    @Published var currentError: APIError?
    @Published var showDialog: Bool = false
    
    private init() {}
    
    func handleError(_ error: Error) {
        if let apiError = error as? APIError {
            self.currentError = apiError
        } else {
            self.currentError = APIError(message: error.localizedDescription, requestId: nil)
        }
        self.showDialog = true
    }
}

struct GlobalErrorModifier: ViewModifier {
    @ObservedObject var errorManager = GlobalErrorManager.shared
    
    func body(content: Content) -> some View {
        content
            .alert("Oops, an error occurred", isPresented: $errorManager.showDialog, presenting: errorManager.currentError) { error in
                Button("OK", role: .cancel) { }
                if let reqId = error.requestId {
                    Button("Copy Request ID") {
                        UIPasteboard.general.string = reqId
                    }
                }
            } message: { error in
                Text(error.message)
            }
    }
}

extension View {
    func withGlobalErrorHandler() -> some View {
        self.modifier(GlobalErrorModifier())
    }
}
