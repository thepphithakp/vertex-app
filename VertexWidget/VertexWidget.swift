import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    
    // Shared UserDefaults (MUST match App Group in Main App)
    let sharedDefaults = UserDefaults(suiteName: "group.com.vertex.app") ?? .standard
    
    func placeholder(in context: Context) -> ParkingEntry {
        ParkingEntry(date: Date(), floor: "3", zone: "F4", isParked: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (ParkingEntry) -> ()) {
        let entry = currentParkingEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = currentParkingEntry()
        
        // This timeline doesn't expire automatically because parking is static
        // It relies on the main app calling WidgetCenter.shared.reloadAllTimelines()
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
    
    private func currentParkingEntry() -> ParkingEntry {
        let floor = sharedDefaults.string(forKey: "parkedFloor") ?? ""
        let zone = sharedDefaults.string(forKey: "parkedZone") ?? ""
        let isParked = !floor.isEmpty || !zone.isEmpty
        
        return ParkingEntry(date: Date(), floor: floor, zone: zone, isParked: isParked)
    }
}

struct ParkingEntry: TimelineEntry {
    let date: Date
    let floor: String
    let zone: String
    let isParked: Bool
}

struct VertexWidgetEntryView : View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            // Widget Background
            LinearGradient(
                colors: entry.isParked ? [Color.blue.opacity(0.8), Color.purple.opacity(0.8)] : [Color(UIColor.secondarySystemGroupedBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            if entry.isParked {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "car.fill")
                            .foregroundColor(.white)
                        Text("Parked")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("FLOOR")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            Text(entry.floor.isEmpty ? "-" : entry.floor)
                                .font(.system(size: family == .systemSmall ? 28 : 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.8)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("ZONE")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                            Text(entry.zone.isEmpty ? "-" : entry.zone)
                                .font(.system(size: family == .systemSmall ? 28 : 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .minimumScaleFactor(0.8)
                        }
                    }
                }
                .padding(family == .systemSmall ? 12 : 16)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "location.viewfinder")
                        .font(.title)
                        .foregroundColor(.blue)
                    Text("No Parking")
                        .font(.headline)
                    Text("Save location in app")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
    }
}

@main
struct VertexWidget: Widget {
    let kind: String = "VertexWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            VertexWidgetEntryView(entry: entry)
                .containerBackground(Color.black, for: .widget) // Required for iOS 17+
        }
        .configurationDisplayName("EV Parking Tracker")
        .description("Keep your parking location on your home screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
