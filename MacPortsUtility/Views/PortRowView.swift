import SwiftUI

struct PortRowView: View {
    let port: Port
    var isSelected: Bool = false
    var showCheckbox: Bool = false
    var showUpdateBadge: Bool = false
    var onToggle: (() -> Void)? = nil
    var onAction: (() -> Void)? = nil
    var actionLabel: String = "Install"
    var actionIcon: String = "arrow.down.circle"
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox for selection
            if showCheckbox {
                Button {
                    onToggle?()
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color.brandPrimary : Color.surfaceTertiary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isSelected ? "Deselect \(port.name)" : "Select \(port.name)")
            }
            
            // Port icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(portColor.gradient)
                    .frame(width: 36, height: 36)
                
                Image(systemName: portIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.textOnPrimary)
            }
            
            // Port info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(port.name)
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                    
                    if port.isInstalled {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(Color.statusSuccess)
                    }
                    
                    if showUpdateBadge && port.hasUpdate {
                        Text("Update")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.brandAccent)
                            .foregroundStyle(Color.textOnAccent)
                            .clipShape(Capsule())
                    }
                }
                
                if !port.version.isEmpty {
                    Text("v\(port.version)")
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                }
                
                if !port.summary.isEmpty {
                    Text(port.summary)
                        .font(.subheadline)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(2)
                }
                
                if !port.categories.isEmpty {
                    HStack(spacing: 5) {
                        ForEach(port.categories.prefix(3), id: \.self) { category in
                            Text(category)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.brandPrimary.opacity(0.12))
                                .foregroundStyle(Color.brandPrimary)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 3)
                }
            }
            
            Spacer()
            
            // Action button (shows on hover or always if port needs action)
            if let action = onAction, (isHovering || port.hasUpdate) {
                Button {
                    action()
                } label: {
                    Label(actionLabel, systemImage: actionIcon)
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private var portColor: Color {
        if !port.categories.isEmpty {
            let category = port.categories[0].lowercased()
            switch category {
            case "python": return Color.brandAmber
            case "ruby": return Color(hex: 0xCC3D3D)
            case "perl": return Color.brandPrimary
            case "java": return Color.brandAccent
            case "devel": return Color(hex: 0x6B5B95)
            case "net": return Color.brandLight
            case "databases": return Color(hex: 0x4A6670)
            case "www": return Color.statusSuccess
            case "graphics": return Color(hex: 0xB565A7)
            case "audio", "video": return Color(hex: 0x5B8FA8)
            case "security": return Color.surfaceTertiary
            default: return Color.brandPrimary
            }
        }
        return Color.brandPrimary
    }
    
    private var portIcon: String {
        if !port.categories.isEmpty {
            let category = port.categories[0].lowercased()
            switch category {
            case "python": return "chevron.left.forwardslash.chevron.right"
            case "ruby": return "diamond"
            case "perl": return "p.circle"
            case "java": return "cup.and.saucer"
            case "devel": return "hammer"
            case "net": return "network"
            case "databases": return "cylinder"
            case "www": return "globe"
            case "graphics": return "paintpalette"
            case "audio": return "speaker.wave.3"
            case "video": return "film"
            case "security": return "lock.shield"
            case "sysutils": return "gearshape.2"
            case "textproc": return "doc.text"
            case "editors": return "pencil"
            default: return "shippingbox"
            }
        }
        return "shippingbox"
    }
}

#Preview {
    VStack {
        PortRowView(
            port: Port(
                name: "python311",
                version: "3.11.6",
                summary: "An interpreted, object-oriented programming language",
                categories: ["python", "devel"],
                isInstalled: true
            ),
            showCheckbox: true
        )
        
        PortRowView(
            port: Port(
                name: "git",
                version: "2.42.0",
                summary: "A distributed version control system",
                categories: ["devel"],
                isInstalled: false
            ),
            isSelected: true,
            showCheckbox: true
        )
        
        PortRowView(
            port: Port(
                name: "nodejs20",
                version: "20.9.0",
                summary: "JavaScript runtime built on Chrome's V8 engine",
                categories: ["devel", "www"],
                hasUpdate: true
            ),
            showUpdateBadge: true,
            actionLabel: "Update",
            actionIcon: "arrow.triangle.2.circlepath"
        )
    }
    .padding()
    .frame(width: 400)
}
