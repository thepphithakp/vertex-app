import Foundation
import SwiftUI

class SharedUserDefaults {
    static let suiteName = "group.com.vertex.app"
    static var shared: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }
}
