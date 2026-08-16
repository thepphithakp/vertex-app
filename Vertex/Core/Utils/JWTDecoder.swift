import Foundation

struct JWTDecoder {
    static func decode(jwtToken jwt: String) -> [String: Any]? {
        let segments = jwt.components(separatedBy: ".")
        guard segments.count > 1 else { return nil }
        
        var base64String = segments[1]
        
        // Base64Url decode to Base64
        base64String = base64String.replacingOccurrences(of: "-", with: "+")
        base64String = base64String.replacingOccurrences(of: "_", with: "/")
        
        // Pad with "="
        let length = Double(base64String.lengthOfBytes(using: .utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = Int(requiredLength - length)
        if paddingLength > 0 {
            let padding = String(repeating: "=", count: paddingLength)
            base64String += padding
        }
        
        guard let data = Data(base64Encoded: base64String, options: .ignoreUnknownCharacters) else {
            return nil
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            return json as? [String: Any]
        } catch {
            return nil
        }
    }
    
    static func isExpired(jwtToken jwt: String) -> Bool {
        guard let payload = decode(jwtToken: jwt),
              let exp = payload["exp"] as? TimeInterval else {
            return true // If we can't parse it, consider it expired
        }
        
        let expirationDate = Date(timeIntervalSince1970: exp)
        return Date() >= expirationDate
    }
}
