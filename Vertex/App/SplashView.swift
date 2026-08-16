import SwiftUI

struct SplashView: View {
    @State private var animateGradients = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    @State private var textOffset: CGFloat = 20
    @State private var textOpacity: Double = 0.0
    @State private var logoRotation: Double = 0.0
    
    // Rotating gradient colors
    let colors: [Color] = [
        Color.blue.opacity(0.8),
        Color.purple.opacity(0.8),
        Color.cyan.opacity(0.8),
        Color.pink.opacity(0.6)
    ]
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle Grid Overlay removed for performance
            // Content
            VStack(spacing: 20) {
                // Glass Logo
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 120, height: 120)
                        .shadow(color: .white.opacity(0.3), radius: 20, x: 0, y: 0)
                    
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white, .clear, .white.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .overlay(
                            Image(systemName: "triangle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                                .rotationEffect(.degrees(180))
                                .offset(y: 15)
                                .blendMode(.overlay)
                        )
                        .rotationEffect(.degrees(logoRotation))
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                // App Title
                VStack(spacing: 8) {
                    Text("Vertex")
                        .font(.system(size: 42, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    Text("SUPER APP")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .tracking(5)
                }
                .offset(y: textOffset)
                .opacity(textOpacity)
            }
        }
        .onAppear {
            animateGradients.toggle()
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.5).delay(0.2)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
                textOffset = 0
                textOpacity = 1.0
            }
        }
    }
}

#Preview {
    SplashView()
}
