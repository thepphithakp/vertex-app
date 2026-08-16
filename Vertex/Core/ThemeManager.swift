import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { self.rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage("selectedAppTheme") var selectedTheme: AppTheme = .system {
        didSet {
            objectWillChange.send()
        }
    }
}

// Glassmorphism (Liquid Glass) ViewModifier for iOS 26 style
struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.8
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color(UIColor.secondarySystemGroupedBackground).opacity(opacity))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .clear, .white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 8)
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 20, opacity: Double = 0.8) -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: cornerRadius, opacity: opacity))
    }
}

// Custom Glass Pill for Active Tabs and Segmented Controls
struct GlassPillView: View {
    var body: some View {
        Capsule()
            .fill(Color.white.opacity(0.3)) // Inner translucent fill
            .background(Capsule().fill(.ultraThinMaterial))
            .overlay(
                Capsule()
                    .stroke(
                        AngularGradient(
                            colors: [.red, .yellow, .green, .blue, .purple, .red],
                            center: .center,
                            angle: .degrees(0)
                        ),
                        lineWidth: 2
                    )
                    .blur(radius: 4)
                    .mask(
                        Capsule()
                            .stroke(lineWidth: 4)
                    )
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [.white, .clear, .white.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 3)
    }
}
