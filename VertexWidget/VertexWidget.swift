import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    
    let sharedDefaults = UserDefaults(suiteName: "group.com.vertex.Vertex8999") ?? .standard
    
    func placeholder(in context: Context) -> ParkingEntry {
        ParkingEntry(date: Date(), floor: "3", zone: "F4", isParked: true, isDoubleParked: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (ParkingEntry) -> ()) {
        completion(currentParkingEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        completion(Timeline(entries: [currentParkingEntry()], policy: .never))
    }
    
    private func currentParkingEntry() -> ParkingEntry {
        let floor = sharedDefaults.string(forKey: "parkedFloor") ?? ""
        let zone = sharedDefaults.string(forKey: "parkedZone") ?? ""
        let isDoubleParked = sharedDefaults.bool(forKey: "isDoubleParked")
        let isParked = !floor.isEmpty || !zone.isEmpty
        
        return ParkingEntry(date: Date(), floor: floor, zone: zone, isParked: isParked, isDoubleParked: isDoubleParked)
    }
}

struct ParkingEntry: TimelineEntry {
    let date: Date
    let floor: String
    let zone: String
    let isParked: Bool
    let isDoubleParked: Bool
}

struct VertexWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if entry.isParked {
                // Header
                HStack(alignment: .center) {
                    Image(systemName: entry.isDoubleParked ? "exclamationmark.triangle.fill" : "car.circle.fill")
                        .font(.title2)
                        .foregroundColor(entry.isDoubleParked ? .yellow : .white)
                        .symbolRenderingMode(.hierarchical)
                    
                    Text(entry.isDoubleParked ? (family == .systemSmall ? "DOUBLE" : "DOUBLE PARKED") : "PARKED")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundColor(entry.isDoubleParked ? .yellow : .white.opacity(0.9))
                        .tracking(1.5)
                    Spacer()
                }
                .padding(.bottom, family == .systemSmall ? 8 : 16)
                
                Spacer(minLength: 0)
                
                // Content
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FLOOR")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(entry.floor.isEmpty ? "-" : entry.floor)
                            .font(.system(size: family == .systemSmall ? 34 : 44, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("ZONE")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(entry.zone.isEmpty ? "-" : entry.zone)
                            .font(.system(size: family == .systemSmall ? 34 : 44, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                }
            } else {
                // Empty State
                VStack(alignment: .center, spacing: 12) {
                    Spacer()
                    Image(systemName: "location.viewfinder")
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(.blue.opacity(0.8))
                        .symbolEffect(.pulse, isActive: true)
                    
                    Text("No Parking")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Tap to save location")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .widgetURL(URL(string: "vertex://ev-parking"))
    }
}

import ActivityKit

struct ParkingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParkingAttributes.self) { context in
            // Lock screen/banner UI
            VStack {
                HStack {
                    Image(systemName: context.state.isDoubleParked ? "exclamationmark.triangle.fill" : "car.circle.fill")
                        .foregroundColor(context.state.isDoubleParked ? .yellow : .blue)
                    Text(context.state.isDoubleParked ? "DOUBLE PARKED" : "PARKED")
                        .font(.headline)
                        .foregroundColor(context.state.isDoubleParked ? .yellow : .white)
                    Spacer()
                    Text("\(context.state.floor) - \(context.state.zone)")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
                if context.state.isDoubleParked {
                    Text("Please move car before 13:00")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding()
            .background(context.state.isDoubleParked ? Color.red.opacity(0.8) : Color.blue.opacity(0.8))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.isDoubleParked ? "exclamationmark.triangle.fill" : "car.circle.fill")
                        .foregroundColor(context.state.isDoubleParked ? .yellow : .blue)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.floor)-\(context.state.zone)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if context.state.isDoubleParked {
                        Text("⚠️ Double Parked! Move before 13:00")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    } else {
                        Text("Parked Safely")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.isDoubleParked ? "exclamationmark.triangle.fill" : "car.circle.fill")
                    .foregroundColor(context.state.isDoubleParked ? .yellow : .blue)
            } compactTrailing: {
                Text(context.state.floor)
                    .foregroundColor(.white)
            } minimal: {
                Image(systemName: "car.circle.fill")
                    .foregroundColor(context.state.isDoubleParked ? .yellow : .blue)
            }
        }
    }
}

@main
struct VertexWidgetBundle: WidgetBundle {
    var body: some Widget {
        VertexWidget()
        ParkingLiveActivity()
    }
}

struct VertexWidget: Widget {
    let kind: String = "VertexWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                VertexWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        if entry.isParked {
                            if entry.isDoubleParked {
                                LinearGradient(
                                    colors: [Color.red.opacity(0.8), Color.orange.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                LinearGradient(
                                    colors: [Color(hex: "4facfe"), Color(hex: "00f2fe")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            }
                        } else {
                            Color(UIColor.systemBackground)
                        }
                    }
            } else {
                VertexWidgetEntryView(entry: entry)
                    .padding()
                    .background(
                        entry.isParked ? 
                        (entry.isDoubleParked ? LinearGradient(colors: [Color.red, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing) : LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing)) :
                        LinearGradient(colors: [Color(UIColor.systemBackground)], startPoint: .top, endPoint: .bottom)
                    )
            }
        }
        .configurationDisplayName("EV Parking Tracker")
        .description("Keep your parking location on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// Helper for vivid hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
