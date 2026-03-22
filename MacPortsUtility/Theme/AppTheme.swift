import SwiftUI
import AppKit

// MARK: - Platinum Grey Color Palette (light mode) + Dark mode support

extension Color {
    
    // MARK: - Brand Colors (same in both modes)
    
    /// Primary brand blue - #2C5AA0
    static let brandPrimary = Color(hex: 0x2C5AA0)
    
    /// Light blue for accents and highlights - #5B8FD9
    static let brandLight = Color(hex: 0x5B8FD9)
    
    /// Accent orange for CTAs and emphasis - #E76F2E
    static let brandAccent = Color(hex: 0xE76F2E)
    
    /// Soft amber for secondary accents - #F2A65A
    static let brandAmber = Color(hex: 0xF2A65A)
    
    // MARK: - Background Colors (adaptive — Platinum grey in light mode)
    
    /// Primary background - Platinum grey in light, dark gray in dark
    static let surfacePrimary = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0)
            : NSColor(red: 0.867, green: 0.867, blue: 0.867, alpha: 1.0)  // #DDDDDD
    })
    
    /// Secondary background - darker Platinum / darker gray
    static let surfaceSecondary = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.18, green: 0.18, blue: 0.20, alpha: 1.0)
            : NSColor(red: 0.780, green: 0.780, blue: 0.796, alpha: 1.0)  // #C7C7CB
    })
    
    /// Card/panel background - elevated surface
    static let surfaceElevated = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.15, green: 0.15, blue: 0.16, alpha: 1.0)
            : NSColor(red: 0.933, green: 0.933, blue: 0.933, alpha: 1.0)  // #EEEEEE
    })
    
    /// Medium gray for borders and dividers
    static let surfaceTertiary = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.35, green: 0.35, blue: 0.38, alpha: 1.0)
            : NSColor(red: 0.604, green: 0.604, blue: 0.624, alpha: 1.0)  // #9A9A9F
    })
    
    // MARK: - Text Colors (adaptive)
    
    /// Primary text - dark slate / light gray
    static let textPrimary = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.93, green: 0.93, blue: 0.94, alpha: 1.0)
            : NSColor(red: 0.173, green: 0.173, blue: 0.200, alpha: 1.0)
    })
    
    /// Secondary text - medium gray
    static let textSecondary = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.68, green: 0.68, blue: 0.70, alpha: 1.0)
            : NSColor(red: 0.361, green: 0.361, blue: 0.400, alpha: 1.0)
    })
    
    /// Tertiary/disabled text
    static let textTertiary = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.50, green: 0.50, blue: 0.53, alpha: 1.0)
            : NSColor(red: 0.604, green: 0.604, blue: 0.643, alpha: 1.0)
    })
    
    /// Text on primary brand color
    static let textOnPrimary = Color.white
    
    /// Text on accent color
    static let textOnAccent = Color.white
    
    // MARK: - Semantic Colors
    
    /// Success state
    static let statusSuccess = Color(hex: 0x4A8F4A)
    
    /// Warning state
    static let statusWarning = Color(hex: 0xE76F2E)
    
    /// Error state
    static let statusError = Color(hex: 0xC44536)
    
    /// Info state
    static let statusInfo = Color(hex: 0x5B8FD9)
    
    // MARK: - Hex Initializer
    
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

// MARK: - Gradients

extension LinearGradient {
    
    /// Primary brand gradient
    static let brandGradient = LinearGradient(
        colors: [Color.brandLight, Color.brandPrimary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Subtle background gradient for panels
    static let surfaceGradient = LinearGradient(
        colors: [Color.surfacePrimary, Color.surfaceSecondary.opacity(0.5)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    /// Accent gradient for CTAs
    static let accentGradient = LinearGradient(
        colors: [Color.brandAmber, Color.brandAccent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Toolbar/header gradient
    static let toolbarGradient = LinearGradient(
        colors: [
            Color.surfacePrimary,
            Color.surfaceSecondary.opacity(0.3)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - App Theme Configuration

struct AppTheme {
    
    // MARK: - Spacing
    
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 24
    static let spacingXXL: CGFloat = 32
    
    // MARK: - Corner Radius
    
    static let radiusSM: CGFloat = 4
    static let radiusMD: CGFloat = 8
    static let radiusLG: CGFloat = 12
    static let radiusXL: CGFloat = 16
    
    // MARK: - Shadows
    
    static let shadowLight = ShadowStyle(
        color: Color.black.opacity(0.08),
        radius: 4,
        x: 0,
        y: 2
    )
    
    static let shadowMedium = ShadowStyle(
        color: Color.black.opacity(0.12),
        radius: 8,
        x: 0,
        y: 4
    )
    
    static let shadowHeavy = ShadowStyle(
        color: Color.black.opacity(0.16),
        radius: 16,
        x: 0,
        y: 8
    )
    
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.textOnPrimary)
            .padding(.horizontal, AppTheme.spacingLG)
            .padding(.vertical, AppTheme.spacingMD)
            .background(
                Group {
                    if isEnabled {
                        LinearGradient.brandGradient
                    } else {
                        Color.surfaceTertiary
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMD))
            .shadow(
                color: isEnabled ? Color.brandPrimary.opacity(0.3) : .clear,
                radius: configuration.isPressed ? 2 : 4,
                y: configuration.isPressed ? 1 : 2
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundStyle(isEnabled ? Color.brandPrimary : Color.textTertiary)
            .padding(.horizontal, AppTheme.spacingLG)
            .padding(.vertical, AppTheme.spacingMD)
            .background(Color.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                    .stroke(isEnabled ? Color.brandPrimary.opacity(0.4) : Color.surfaceTertiary.opacity(0.5), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct AccentButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.textOnAccent)
            .padding(.horizontal, AppTheme.spacingLG)
            .padding(.vertical, AppTheme.spacingMD)
            .background(
                Group {
                    if isEnabled {
                        LinearGradient.accentGradient
                    } else {
                        Color.surfaceTertiary
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusMD))
            .shadow(
                color: isEnabled ? Color.brandAccent.opacity(0.3) : .clear,
                radius: configuration.isPressed ? 2 : 4,
                y: configuration.isPressed ? 1 : 2
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Button Style Extensions

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var themePrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var themeSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == AccentButtonStyle {
    static var themeAccent: AccentButtonStyle { AccentButtonStyle() }
}

// MARK: - Card View Modifier

struct CardStyle: ViewModifier {
    var padding: CGFloat = AppTheme.spacingLG
    var cornerRadius: CGFloat = AppTheme.radiusLG
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.surfaceSecondary, lineWidth: 1)
            )
            .shadow(
                color: AppTheme.shadowLight.color,
                radius: AppTheme.shadowLight.radius,
                x: AppTheme.shadowLight.x,
                y: AppTheme.shadowLight.y
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = AppTheme.spacingLG, cornerRadius: CGFloat = AppTheme.radiusLG) -> some View {
        modifier(CardStyle(padding: padding, cornerRadius: cornerRadius))
    }
}

// MARK: - Panel Header Style

struct PanelHeaderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, AppTheme.spacingLG)
            .padding(.vertical, AppTheme.spacingMD)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient.toolbarGradient)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color.surfaceSecondary)
                    .frame(height: 1)
            }
    }
}

extension View {
    func panelHeaderStyle() -> some View {
        modifier(PanelHeaderStyle())
    }
}

// MARK: - Theme Preview

#Preview("Theme Showcase") {
    ThemeShowcaseView()
}

struct ThemeShowcaseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacingXL) {
                
                // Header with gradient
                VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                    Text("Sun-Inspired Theme")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(Color.textPrimary)
                    
                    Text("Late-2000s enterprise aesthetic with soft contrast")
                        .font(.body)
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(AppTheme.spacingXL)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient.toolbarGradient)
                
                VStack(spacing: AppTheme.spacingXL) {
                    
                    // Color Palette
                    VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                        Text("Color Palette")
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        
                        HStack(spacing: AppTheme.spacingMD) {
                            ColorSwatch(color: Color.brandPrimary, name: "Primary")
                            ColorSwatch(color: Color.brandLight, name: "Light")
                            ColorSwatch(color: Color.brandAccent, name: "Accent")
                            ColorSwatch(color: Color.brandAmber, name: "Amber")
                        }
                    }
                    .cardStyle()
                    
                    // Buttons
                    VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                        Text("Buttons")
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        
                        HStack(spacing: AppTheme.spacingMD) {
                            Button("Primary Action") {}
                                .buttonStyle(.themePrimary)
                            
                            Button("Secondary") {}
                                .buttonStyle(.themeSecondary)
                            
                            Button("Accent") {}
                                .buttonStyle(.themeAccent)
                        }
                    }
                    .cardStyle()
                    
                    // Typography
                    VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                        Text("Typography")
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                            Text("Primary Text - Dark Slate")
                                .font(.body)
                                .foregroundStyle(Color.textPrimary)
                            
                            Text("Secondary Text - Muted for supporting content")
                                .font(.body)
                                .foregroundStyle(Color.textSecondary)
                            
                            Text("Tertiary Text - Disabled or hints")
                                .font(.body)
                                .foregroundStyle(Color.textTertiary)
                        }
                    }
                    .cardStyle()
                    
                    // Status Colors
                    VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                        Text("Status Indicators")
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        
                        HStack(spacing: AppTheme.spacingLG) {
                            StatusBadge(color: Color.statusSuccess, label: "Success")
                            StatusBadge(color: Color.statusWarning, label: "Warning")
                            StatusBadge(color: Color.statusError, label: "Error")
                            StatusBadge(color: Color.statusInfo, label: "Info")
                        }
                    }
                    .cardStyle()
                }
                .padding(.horizontal, AppTheme.spacingXL)
            }
        }
        .background(Color.surfacePrimary)
    }
}

private struct ColorSwatch: View {
    let color: Color
    let name: String
    
    var body: some View {
        VStack(spacing: AppTheme.spacingSM) {
            RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                .fill(color)
                .frame(width: 60, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusMD)
                        .stroke(Color.surfaceTertiary.opacity(0.3), lineWidth: 1)
                )
            
            Text(name)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
    }
}

private struct StatusBadge: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: AppTheme.spacingXS) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, AppTheme.spacingMD)
        .padding(.vertical, AppTheme.spacingSM)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}
