import SwiftUI

struct UpdatesView: View {
    @EnvironmentObject var portsManager: PortsManager
    @State private var selectedPorts: Set<String> = []
    @State private var selectedPort: Port?
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left: Updates list
                VStack(spacing: 0) {
                    // Header bar
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Available Updates")
                                .font(.headline)
                                .foregroundStyle(Color.textPrimary)
                            
                            Text("\(portsManager.outdatedPorts.count) port\(portsManager.outdatedPorts.count == 1 ? "" : "s") can be updated")
                                .font(.subheadline)
                                .foregroundStyle(Color.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            Task {
                                await portsManager.checkForUpdates()
                            }
                        } label: {
                            Label("Check", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.themeSecondary)
                        .disabled(portsManager.state.isLoading)
                        .accessibilityLabel("Check for updates")
                        
                        if !portsManager.outdatedPorts.isEmpty {
                            Button {
                                Task {
                                    await portsManager.updateAllPorts()
                                }
                            } label: {
                                Label("Update All", systemImage: "arrow.triangle.2.circlepath.circle.fill")
                            }
                            .buttonStyle(.themeAccent)
                            .disabled(portsManager.state.isLoading)
                            .accessibilityLabel("Update all \(portsManager.outdatedPorts.count) outdated ports")
                        }
                    }
                    .padding(16)
                    .background(Color.surfacePrimary)
                    
                    Rectangle()
                        .fill(Color.surfaceSecondary)
                        .frame(height: 1)
                    
                    // Updates list
                    if portsManager.state == .checkingUpdates {
                        VStack {
                            Spacer()
                            ProgressView("Checking for updates...")
                                .progressViewStyle(.circular)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.surfaceElevated)
                    } else if portsManager.outdatedPorts.isEmpty {
                        ContentUnavailableView {
                            Label("Up to Date", systemImage: "checkmark.circle.fill")
                        } description: {
                            Text("All installed ports are up to date")
                        } actions: {
                            Button {
                                Task {
                                    await portsManager.checkForUpdates()
                                }
                            } label: {
                                Text("Check Again")
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.surfaceElevated)
                    } else {
                        List(selection: $selectedPort) {
                            // Select all toggle
                            HStack {
                                Button {
                                    if selectedPorts.count == portsManager.outdatedPorts.count {
                                        selectedPorts.removeAll()
                                    } else {
                                        selectedPorts = Set(portsManager.outdatedPorts.map { $0.id })
                                    }
                                } label: {
                                    Image(systemName: selectedPorts.count == portsManager.outdatedPorts.count ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedPorts.count == portsManager.outdatedPorts.count ? Color.brandPrimary : Color.textTertiary)
                                }
                                .buttonStyle(.plain)
                                
                                Text("Select All")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.textSecondary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 6)
                            
                            ForEach(portsManager.outdatedPorts) { port in
                                UpdateRowView(
                                    port: port,
                                    isSelected: selectedPorts.contains(port.id),
                                    onToggle: { toggleSelection(port) },
                                    onUpdate: {
                                        Task {
                                            await portsManager.updatePort(port)
                                        }
                                    }
                                )
                                .tag(port)
                            }
                        }
                        .listStyle(.inset(alternatesRowBackgrounds: true))
                        .scrollContentBackground(.hidden)
                        .background(Color.surfaceElevated)
                    }
                    
                    // Update selected button
                    if !selectedPorts.isEmpty {
                        Rectangle()
                            .fill(Color.surfaceSecondary)
                            .frame(height: 1)
                        HStack {
                            Label("\(selectedPorts.count) port\(selectedPorts.count == 1 ? "" : "s") selected", systemImage: "checkmark.circle.fill")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Color.textSecondary)
                            
                            Spacer()
                            
                            Button("Clear") {
                                selectedPorts.removeAll()
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.textTertiary)
                            
                            Button {
                                updateSelected()
                            } label: {
                                Label("Update Selected", systemImage: "arrow.triangle.2.circlepath")
                            }
                            .buttonStyle(.themeAccent)
                            .disabled(portsManager.state.isLoading)
                        }
                        .padding(16)
                        .background(Color.surfacePrimary)
                    }
                }
                .frame(width: max(400, geometry.size.width * 0.45))
                .background(Color.surfaceElevated)
                
                // Divider between panes
                Rectangle()
                    .fill(Color.surfaceSecondary)
                    .frame(width: 1)
                
                // Right: Port details
                if let port = selectedPort {
                    PortDetailView(port: port)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ContentUnavailableView {
                        Label("No Selection", systemImage: "sidebar.right")
                    } description: {
                        Text("Select a port to view details")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.surfacePrimary)
                }
            }
        }
        .navigationTitle("Updates")
    }
    
    private func toggleSelection(_ port: Port) {
        if selectedPorts.contains(port.id) {
            selectedPorts.remove(port.id)
        } else {
            selectedPorts.insert(port.id)
        }
    }
    
    private func updateSelected() {
        let portsToUpdate = portsManager.outdatedPorts.filter { selectedPorts.contains($0.id) }
        Task {
            await portsManager.updatePorts(portsToUpdate)
            selectedPorts.removeAll()
        }
    }
}

// MARK: - Update Row View

struct UpdateRowView: View {
    let port: Port
    var isSelected: Bool = false
    var onToggle: (() -> Void)? = nil
    var onUpdate: (() -> Void)? = nil
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                onToggle?()
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.brandPrimary : Color.textTertiary)
            }
            .buttonStyle(.plain)
            
            // Port icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.brandAccent.gradient)
                    .frame(width: 44, height: 44)
                    .shadow(color: Color.brandAccent.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            // Port info
            VStack(alignment: .leading, spacing: 5) {
                Text(port.name)
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
                
                HStack(spacing: 6) {
                    Text(port.installedVersion ?? "")
                        .foregroundStyle(Color.textTertiary)
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textTertiary)
                    
                    Text(port.version)
                        .foregroundStyle(Color.brandAccent)
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
            }
            
            Spacer()
            
            // Update button (shows on hover)
            if isHovering {
                Button {
                    onUpdate?()
                } label: {
                    Label("Update", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline)
                }
                .buttonStyle(.themeSecondary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

#Preview {
    UpdatesView()
        .environmentObject(PortsManager())
        .frame(width: 800, height: 500)
}
