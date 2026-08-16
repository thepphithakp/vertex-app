import Foundation
import SwiftUI

class SharedUserDefaults {
    static let suiteName = "group.com.vertex.Vertex8999"
    static var shared: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }
}
