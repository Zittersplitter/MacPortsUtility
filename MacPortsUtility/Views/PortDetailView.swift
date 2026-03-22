import SwiftUI

struct PortDetailView: View {
    let port: Port
    @EnvironmentObject var portsManager: PortsManager
    @State private var portInfo: String = ""
    @State private var isLoadingInfo = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient.brandGradient)
                            .frame(width: 72, height: 72)
                            .shadow(color: Color.brandPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.textOnPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(port.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.textPrimary)
                            
                            if port.isInstalled {
                                Label("Installed", systemImage: "checkmark.seal.fill")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.statusSuccess)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.statusSuccess.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        if !port.version.isEmpty {
                            Text("Version \(port.version)")
                                .font(.body)
                                .foregroundStyle(Color.textSecondary)
                        }
                        
                        if let installedVersion = port.installedVersion, port.hasUpdate {
                            Text("Installed: \(installedVersion) → \(port.version)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.brandAccent)
                        }
                    }
                    
                    Spacer()
                }
                
                // Categories
                if !port.categories.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Categories")
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(port.categories, id: \.self) { category in
                                Text(category)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.brandPrimary.opacity(0.12))
                                    .foregroundStyle(Color.brandPrimary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                
                // Summary
                if !port.summary.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Description")
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        
                        Text(port.summary)
                            .font(.body)
                            .foregroundStyle(Color.textSecondary)
                            .lineSpacing(4)
                    }
                }
                
                Rectangle()
                    .fill(Color.surfaceSecondary)
                    .frame(height: 1)
                
                // Detailed info from port command
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Port Information")
                            .font(.headline)
                            .foregroundStyle(Color.textPrimary)
                        
                        Spacer()
                        
                        if isLoadingInfo {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                    
                    if portInfo.isEmpty && !isLoadingInfo {
                        Text("No information available")
                            .font(.subheadline)
                            .foregroundStyle(Color.textTertiary)
                    } else if portInfo.isEmpty {
                        ProgressView("Loading details...")
                            .font(.subheadline)
                    } else {
                        Text(portInfo)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Color.textPrimary)
                            .textSelection(.enabled)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.surfaceSecondary, lineWidth: 1)
                            )
                    }
                }
                
                Rectangle()
                    .fill(Color.surfaceSecondary)
                    .frame(height: 1)
                
                // Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Actions")
                        .font(.headline)
                        .foregroundStyle(Color.textPrimary)
                    
                    HStack(spacing: 12) {
                        if port.isInstalled {
                            if port.hasUpdate {
                                Button {
                                    Task {
                                        await portsManager.updatePort(port)
                                    }
                                } label: {
                                    Label("Update", systemImage: "arrow.triangle.2.circlepath")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.themeAccent)
                                .disabled(portsManager.state.isLoading)
                                .accessibilityLabel("Update \(port.name)")
                            }
                            
                            Button {
                                Task {
                                    await portsManager.uninstallPort(port)
                                }
                            } label: {
                                Label("Uninstall", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.themeSecondary)
                            .disabled(portsManager.state.isLoading)
                            .accessibilityLabel("Uninstall \(port.name)")
                        } else {
                            Button {
                                Task {
                                    await portsManager.installPort(port)
                                }
                            } label: {
                                Label("Install", systemImage: "arrow.down.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.themePrimary)
                            .disabled(portsManager.state.isLoading)
                            .accessibilityLabel("Install \(port.name)")
                        }
                    }
                }
                
                Spacer()
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surfacePrimary)
        .onChange(of: port) { _, _ in
            portInfo = ""
        }
        .task(id: port.name) {
            loadPortInfo()
        }
    }
    
    private func loadPortInfo() {
        isLoadingInfo = true
        Task {
            portInfo = await portsManager.getPortInfo(name: port.name)
            isLoadingInfo = false
        }
    }
}

// MARK: - Flow Layout for categories

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
                
                self.size.width = max(self.size.width, currentX - spacing)
            }
            
            self.size.height = currentY + lineHeight
        }
    }
}

#Preview {
    PortDetailView(
        port: Port(
            name: "python311",
            version: "3.11.6",
            summary: "An interpreted, object-oriented programming language with dynamic semantics",
            categories: ["python", "devel", "lang"],
            isInstalled: true,
            installedVersion: "3.11.5",
            hasUpdate: true
        )
    )
    .environmentObject(PortsManager())
    .frame(width: 400, height: 600)
}
