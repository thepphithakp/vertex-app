import Foundation
import ActivityKit

public struct ParkingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var isDoubleParked: Bool
        public var floor: String
        public var zone: String
        
        public init(isDoubleParked: Bool, floor: String, zone: String) {
            self.isDoubleParked = isDoubleParked
            self.floor = floor
            self.zone = zone
        }
    }
    public init() {}
}
