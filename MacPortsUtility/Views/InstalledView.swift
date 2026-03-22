import SwiftUI

struct InstalledView: View {
    @EnvironmentObject var portsManager: PortsManager
    @State private var searchText = ""
    @State private var selectedPort: Port?
    @State private var selectedPorts: Set<String> = []
    @State private var sortOrder: SortOrder = .name
    
    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case version = "Version"
    }
    
    var filteredPorts: [Port] {
        var ports = portsManager.installedPorts
        
        if !searchText.isEmpty {
            ports = ports.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        switch sortOrder {
        case .name:
            ports.sort { $0.name < $1.name }
        case .version:
            ports.sort { $0.version.compare($1.version, options: .numeric) == .orderedDescending }
        }
        
        return ports
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left: Installed ports list
                VStack(spacing: 0) {
                    // Filter bar
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(Color.textSecondary)
                            
                            TextField("Filter installed ports...", text: $searchText)
                                .textFieldStyle(.plain)
                                .font(.body)
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(Color.textTertiary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(10)
                        .background(Color.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.surfaceSecondary, lineWidth: 1)
                        )
                        
                        Picker("Sort", selection: $sortOrder) {
                            ForEach(SortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 110)
                        
                        Button {
                            Task {
                                await portsManager.refreshInstalledPorts()
                            }
                        } label: {
                            Label("Refresh Ports", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.themeSecondary)
                        .disabled(portsManager.state.isLoading)
                        .accessibilityLabel("Refresh installed ports list")
                    }
                    .padding(16)
                    .background(LinearGradient.toolbarGradient)
                    
                    Rectangle()
                        .fill(Color.surfaceSecondary)
                        .frame(height: 1)
                    
                    // Ports list
                    if portsManager.installedPorts.isEmpty {
                        ContentUnavailableView {
                            Label("No Installed Ports", systemImage: "shippingbox")
                        } description: {
                            Text("You haven't installed any ports yet.\nUse the Search tab to find and install ports.")
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.surfacePrimary)
                    } else if filteredPorts.isEmpty {
                        ContentUnavailableView {
                            Label("No Matches", systemImage: "magnifyingglass")
                        } description: {
                            Text("No installed ports match '\(searchText)'")
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.surfacePrimary)
                    } else {
                        List(selection: $selectedPort) {
                            // Select all toggle
                            HStack {
                                Button {
                                    if selectedPorts.count == filteredPorts.count {
                                        selectedPorts.removeAll()
                                    } else {
                                        selectedPorts = Set(filteredPorts.map { $0.id })
                                    }
                                } label: {
                                    Image(systemName: selectedPorts.count == filteredPorts.count && !filteredPorts.isEmpty ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(selectedPorts.count == filteredPorts.count && !filteredPorts.isEmpty ? Color.brandPrimary : Color.textTertiary)
                                }
                                .buttonStyle(.plain)
                                
                                Text("Select All")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.textSecondary)
                                
                                Spacer()
                            }
                            .padding(.vertical, 6)
                            
                            ForEach(filteredPorts) { port in
                                PortRowView(
                                    port: port,
                                    isSelected: selectedPorts.contains(port.id),
                                    showCheckbox: true,
                                    showUpdateBadge: true,
                                    onToggle: { toggleSelection(port) },
                                    onAction: port.hasUpdate ? {
                                        Task {
                                            await portsManager.updatePort(port)
                                        }
                                    } : nil,
                                    actionLabel: "Update",
                                    actionIcon: "arrow.triangle.2.circlepath"
                                )
                                .tag(port)
                                .contextMenu {
                                    Button {
                                        Task {
                                            await portsManager.uninstallPort(port)
                                        }
                                    } label: {
                                        Label("Uninstall", systemImage: "trash")
                                    }
                                    
                                    if port.hasUpdate {
                                        Button {
                                            Task {
                                                await portsManager.updatePort(port)
                                            }
                                        } label: {
                                            Label("Update", systemImage: "arrow.triangle.2.circlepath")
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.inset(alternatesRowBackgrounds: true))
                        .scrollContentBackground(.hidden)
                        .background(Color.surfacePrimary)
                    }
                    
                    // Uninstall selected bar (shows when ports are selected)
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
                                uninstallSelected()
                            } label: {
                                Label("Uninstall Selected", systemImage: "trash")
                            }
                            .buttonStyle(.themeSecondary)
                            .disabled(portsManager.state.isLoading)
                        }
                        .padding(16)
                        .background(Color.surfacePrimary)
                    }
                    
                    // Summary bar
                    HStack {
                        Text("\(filteredPorts.count) of \(portsManager.installedPorts.count) ports")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.textSecondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(LinearGradient.toolbarGradient)
                }
                .frame(width: max(350, geometry.size.width * 0.45))
                .background(Color.surfacePrimary)
                
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
        .navigationTitle("Installed Ports")
    }
    
    private func toggleSelection(_ port: Port) {
        if selectedPorts.contains(port.id) {
            selectedPorts.remove(port.id)
        } else {
            selectedPorts.insert(port.id)
        }
    }
    
    private func uninstallSelected() {
        let portsToUninstall = portsManager.installedPorts.filter { selectedPorts.contains($0.id) }
        Task {
            await portsManager.uninstallPorts(portsToUninstall)
            selectedPorts.removeAll()
        }
    }
}

#Preview {
    InstalledView()
        .environmentObject(PortsManager())
        .frame(width: 800, height: 500)
}
