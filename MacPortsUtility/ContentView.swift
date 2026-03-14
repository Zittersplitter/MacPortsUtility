import SwiftUI

struct ContentView: View {
    @EnvironmentObject var portsManager: PortsManager
    @State private var selectedNavItem: NavigationItem = .search
    @State private var showingConsole = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedItem: $selectedNavItem)
        } detail: {
            VStack(spacing: 0) {
                // Main content
                Group {
                    switch selectedNavItem {
                    case .search:
                        SearchView()
                    case .installed:
                        InstalledView()
                    case .updates:
                        UpdatesView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Console panel
                if showingConsole {
                    ConsoleView()
                        .frame(height: 200)
                        .transition(.move(edge: .bottom))
                }
                
                // Status bar
                StatusBarView(showingConsole: $showingConsole)
            }
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if !portsManager.isMacPortsInstalled {
                    Button {
                        if let url = URL(string: "https://www.macports.org/install.php") {
                            NSWorkspace.shared.open(url)
                        }
                    } label: {
                        Label("Install MacPorts", systemImage: "arrow.down.circle")
                    }
                    .tint(.orange)
                    .accessibilityLabel("Download and install MacPorts")
                }
                
                Button {
                    Task {
                        await portsManager.syncPortTree()
                    }
                } label: {
                    Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(portsManager.state.isLoading || !portsManager.isMacPortsInstalled)
                .accessibilityLabel("Sync port tree")
                .accessibilityHint("Updates the MacPorts port list")
            }
        }
        .overlay {
            if !portsManager.isMacPortsInstalled {
                MacPortsNotInstalledView()
            }
        }
        .alert("Error", isPresented: Binding(
            get: { portsManager.lastError != nil },
            set: { if !$0 { portsManager.lastError = nil } }
        )) {
            Button("OK", role: .cancel) {
                portsManager.lastError = nil
            }
        } message: {
            Text(portsManager.lastError ?? "")
        }
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @Binding var selectedItem: NavigationItem
    @EnvironmentObject var portsManager: PortsManager
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    
    var body: some View {
        List(selection: $selectedItem) {
            Section("Library") {
                ForEach(NavigationItem.allCases) { item in
                    NavigationLink(value: item) {
                        Label {
                            HStack {
                                Text(item.rawValue)
                                Spacer()
                                if item == .updates && !portsManager.outdatedPorts.isEmpty {
                                    Text("\(portsManager.outdatedPorts.count)")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.brandAccent)
                                        .foregroundStyle(Color.textOnAccent)
                                        .clipShape(Capsule())
                                }
                                if item == .installed {
                                    Text("\(portsManager.installedPorts.count)")
                                        .font(.caption2)
                                        .foregroundStyle(Color.textSecondary)
                                }
                            }
                        } icon: {
                            Image(systemName: item.icon)
                                .foregroundStyle(item == .updates && !portsManager.outdatedPorts.isEmpty ? Color.brandAccent : Color.brandPrimary)
                        }
                    }
                }
            }
            
            if portsManager.isMacPortsInstalled {
                Section("Info") {
                    Label {
                        VStack(alignment: .leading) {
                            Text("MacPorts")
                                .font(.caption)
                                .foregroundStyle(Color.textPrimary)
                            Text(portsManager.macPortsVersion.replacingOccurrences(of: "Version: ", with: ""))
                                .font(.caption2)
                                .foregroundStyle(Color.textSecondary)
                        }
                    } icon: {
                        Image(systemName: "shippingbox.fill")
                            .foregroundStyle(Color.brandAmber)
                    }
                }
                
                // Global Install Queue section
                if !portsManager.installQueue.isEmpty {
                    Section("Install Queue") {
                        ForEach(portsManager.installQueue) { port in
                            HStack {
                                Text(port.name)
                                    .font(.caption)
                                    .foregroundStyle(Color.textPrimary)
                                Spacer()
                                Button {
                                    portsManager.removeFromInstallQueue([port])
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.textTertiary)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Remove \(port.name) from queue")
                            }
                            .draggable(port.name)
                        }
                        .onMove { source, destination in
                            portsManager.installQueue.move(fromOffsets: source, toOffset: destination)
                        }
                        
                        HStack(spacing: 8) {
                            Button("Clear") {
                                portsManager.clearInstallQueue()
                            }
                            .buttonStyle(.plain)
                            .font(.caption)
                            .foregroundStyle(Color.textTertiary)
                            .accessibilityLabel("Clear install queue")
                            
                            Spacer()
                            
                            Button {
                                Task {
                                    await portsManager.installQueuedPorts()
                                }
                            } label: {
                                Label("Install \(portsManager.installQueue.count)", systemImage: "arrow.down.circle.fill")
                                    .font(.caption)
                            }
                            .buttonStyle(.themePrimary)
                            .disabled(portsManager.state.isLoading)
                            .accessibilityLabel("Install \(portsManager.installQueue.count) queued ports")
                        }
                        .padding(.top, 4)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                Divider()
                HStack {
                    Image(systemName: appearanceMode.icon)
                        .foregroundStyle(Color.brandPrimary)
                    Picker("Theme", selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.surfaceSecondary.opacity(0.5))
            }
        }
    }
}

// MARK: - Status Bar View

struct StatusBarView: View {
    @EnvironmentObject var portsManager: PortsManager
    @Binding var showingConsole: Bool
    
    var body: some View {
        HStack {
            // Status indicator
            HStack(spacing: 8) {
                if portsManager.state.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 14, height: 14)
                        .accessibilityLabel("Operation in progress")
                } else {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                        .shadow(color: statusColor.opacity(0.5), radius: 3)
                        .accessibilityLabel(portsManager.state == .idle ? "Ready" : "Error")
                }
                
                Text(portsManager.state.statusMessage)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.textSecondary)
            }
            
            Spacer()
            
            // Console toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showingConsole.toggle()
                }
            } label: {
                Label("Console", systemImage: showingConsole ? "chevron.down" : "chevron.up")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.textSecondary)
            .accessibilityLabel(showingConsole ? "Hide Console" : "Show Console")
            .accessibilityHint("Toggles the console output panel")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(LinearGradient.toolbarGradient)
    }
    
    private var statusColor: Color {
        switch portsManager.state {
        case .idle:
            return Color.statusSuccess
        case .error:
            return Color.statusError
        default:
            return Color.brandAmber
        }
    }
}

// MARK: - Console View

struct ConsoleView: View {
    @EnvironmentObject var portsManager: PortsManager
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.surfaceSecondary)
                .frame(height: 1)
            
            HStack {
                Text("Console")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                
                Spacer()
                
                Button {
                    portsManager.clearConsole()
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.textSecondary)
                .accessibilityLabel("Clear Console")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(LinearGradient.toolbarGradient)
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        Text(portsManager.consoleOutput)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Color.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .padding(12)
                        
                        Color.clear
                            .frame(height: 1)
                            .id("console-bottom")
                    }
                }
                .background(Color.surfaceElevated)
                .onChange(of: portsManager.consoleOutput) { _, _ in
                    proxy.scrollTo("console-bottom", anchor: .bottom)
                }
            }
        }
    }
}

// MARK: - MacPorts Not Installed View

struct MacPortsNotInstalledView: View {
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(LinearGradient.brandGradient)
                    .frame(width: 88, height: 88)
                
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.textOnPrimary)
            }
            .shadow(color: Color.brandPrimary.opacity(0.3), radius: 12, y: 4)
            
            Text("MacPorts Not Installed")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color.textPrimary)
            
            Text("MacPorts is required to use this app.\nClick below to download and install it.")
                .font(.body)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                if let url = URL(string: "https://www.macports.org/install.php") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label("Download MacPorts", systemImage: "arrow.down.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.themePrimary)
        }
        .padding(48)
        .background(
            Color.surfaceElevated
                .clipShape(RoundedRectangle(cornerRadius: 24))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.surfaceSecondary, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 30, x: 0, y: 10)
    }
}

#Preview {
    ContentView()
        .environmentObject(PortsManager())
        .frame(width: 900, height: 600)
}
