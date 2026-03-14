import SwiftUI

enum AppearanceMode: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

@main
struct MacPortsUtilityApp: App {
    @StateObject private var portsManager = PortsManager()
    @State private var showingInstallMacPorts = false
    @State private var showingAbout = false
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(portsManager)
                .frame(minWidth: 900, minHeight: 600)
                .preferredColorScheme(appearanceMode.colorScheme)
                .sheet(isPresented: $showingAbout) {
                    AboutView()
                }
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .commands {
            // Replace default About menu item
            CommandGroup(replacing: .appInfo) {
                Button("About MacPorts Utility") {
                    showingAbout = true
                }
            }
            
            // Remove Show Tab Bar from View menu
            CommandGroup(replacing: .toolbar) { }
            
            CommandGroup(after: .appInfo) {
                Divider()
                Button("Install MacPorts...") {
                    openMacPortsDownload()
                }
                .keyboardShortcut("I", modifiers: [.command, .shift])
                
                Divider()
                
                Menu("Appearance") {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Button {
                            appearanceMode = mode
                        } label: {
                            HStack {
                                if appearanceMode == mode {
                                    Image(systemName: "checkmark")
                                }
                                Text(mode.rawValue)
                            }
                        }
                    }
                }
            }
            
            CommandGroup(replacing: .help) {
                Button("MacPorts Guide") {
                    if let url = URL(string: "https://guide.macports.org/") {
                        NSWorkspace.shared.open(url)
                    }
                }
                Button("MacPorts Website") {
                    if let url = URL(string: "https://www.macports.org/") {
                        NSWorkspace.shared.open(url)
                    }
                }
                Divider()
                Button("GitHub Repository") {
                    if let url = URL(string: "https://github.com/Zittersplitter/MacPortsUtility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            
            CommandGroup(after: .sidebar) {
                Divider()
                Button("Refresh Ports") {
                    Task {
                        await portsManager.refreshInstalledPorts()
                    }
                }
                .keyboardShortcut("R", modifiers: .command)
                
                Button("Sync Port Tree") {
                    Task {
                        await portsManager.syncPortTree()
                    }
                }
                .keyboardShortcut("S", modifiers: [.command, .shift])
                
                Divider()
                Button("Clear Console") {
                    portsManager.clearConsole()
                }
                .keyboardShortcut("K", modifiers: .command)
            }
        }
    }
    
    private func openMacPortsDownload() {
        if let url = URL(string: "https://www.macports.org/install.php") {
            NSWorkspace.shared.open(url)
        }
    }
}
