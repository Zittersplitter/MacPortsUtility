import SwiftUI

/// App Icon generator view - Use the preview to export the icon
/// In Xcode Preview, right-click and "Export..." as PNG at 1024x1024
struct AppIconView: View {
    let size: CGFloat
    
    init(size: CGFloat = 1024) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background with rounded rect (macOS icon shape)
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0x3A6DB5), // Lighter brand blue
                            Color(hex: 0x2C5AA0), // Brand primary
                            Color(hex: 0x1E4380)  // Darker brand blue
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Subtle inner glow/highlight
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.white.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: size * 0.01
                )
                .padding(size * 0.005)
            
            // Decorative shipping box outline (subtle)
            VStack(spacing: 0) {
                // Box top
                BoxTopShape()
                    .stroke(Color.white.opacity(0.15), lineWidth: size * 0.012)
                    .frame(width: size * 0.55, height: size * 0.15)
                
                // Box body
                RoundedRectangle(cornerRadius: size * 0.03)
                    .stroke(Color.white.opacity(0.15), lineWidth: size * 0.012)
                    .frame(width: size * 0.55, height: size * 0.35)
                    .offset(y: -size * 0.01)
            }
            .offset(y: -size * 0.08)
            
            // "MPU" Text
            Text("MPU")
                .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.white.opacity(0.9)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.black.opacity(0.3), radius: size * 0.02, x: 0, y: size * 0.01)
                .offset(y: size * 0.05)
            
            // Subtle port/connector dots at bottom
            HStack(spacing: size * 0.06) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: size * 0.04, height: size * 0.04)
                }
            }
            .offset(y: size * 0.32)
        }
        .frame(width: size, height: size)
    }
}

// Custom shape for box top flaps
struct BoxTopShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let w = rect.width
        let h = rect.height
        
        // Left flap
        path.move(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: w * 0.15, y: 0))
        path.addLine(to: CGPoint(x: w * 0.35, y: 0))
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.7))
        
        // Right flap
        path.move(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: w * 0.85, y: 0))
        path.addLine(to: CGPoint(x: w * 0.65, y: 0))
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.7))
        
        return path
    }
}

// Alternative simpler icon design
struct AppIconSimpleView: View {
    let size: CGFloat
    
    init(size: CGFloat = 1024) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: 0x4A7DC4),
                            Color(hex: 0x2C5AA0),
                            Color(hex: 0x1A4080)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Inner shadow/depth
            RoundedRectangle(cornerRadius: size * 0.20, style: .continuous)
                .stroke(Color.white.opacity(0.2), lineWidth: size * 0.008)
                .padding(size * 0.02)
            
            // Central circle accent
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.4
                    )
                )
                .frame(width: size * 0.8, height: size * 0.8)
                .offset(y: -size * 0.05)
            
            // MPU text with modern styling
            VStack(spacing: size * 0.02) {
                Text("MPU")
                    .font(.system(size: size * 0.32, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: Color.black.opacity(0.25), radius: size * 0.015, x: 0, y: size * 0.008)
                
                // Subtle tagline bar
                RoundedRectangle(cornerRadius: size * 0.01)
                    .fill(Color.white.opacity(0.4))
                    .frame(width: size * 0.35, height: size * 0.025)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview("App Icon 1024") {
    AppIconView(size: 1024)
        .frame(width: 1024, height: 1024)
}

#Preview("App Icon Simple 1024") {
    AppIconSimpleView(size: 1024)
        .frame(width: 1024, height: 1024)
}

#Preview("App Icon 512") {
    AppIconView(size: 512)
        .frame(width: 512, height: 512)
}

#Preview("App Icon 256") {
    AppIconView(size: 256)
        .frame(width: 256, height: 256)
}

#Preview("App Icon 128") {
    AppIconView(size: 128)
        .frame(width: 128, height: 128)
}

#Preview("App Icon 64") {
    AppIconView(size: 64)
        .frame(width: 64, height: 64)
}

#Preview("App Icon 32") {
    AppIconView(size: 32)
        .frame(width: 32, height: 32)
}

#Preview("App Icon 16") {
    AppIconView(size: 16)
        .frame(width: 16, height: 16)
}
