import Foundation

/// Represents a MacPorts port
struct Port: Identifiable, Hashable, Equatable {
    let id: String
    let name: String
    let version: String
    let summary: String
    let categories: [String]
    var isInstalled: Bool
    var installedVersion: String?
    var hasUpdate: Bool
    var isSelected: Bool
    
    init(
        name: String,
        version: String = "",
        summary: String = "",
        categories: [String] = [],
        isInstalled: Bool = false,
        installedVersion: String? = nil,
        hasUpdate: Bool = false,
        isSelected: Bool = false
    ) {
        self.id = name
        self.name = name
        self.version = version
        self.summary = summary
        self.categories = categories
        self.isInstalled = isInstalled
        self.installedVersion = installedVersion
        self.hasUpdate = hasUpdate
        self.isSelected = isSelected
    }
    

}

/// Represents the state of a port operation
enum PortOperationState: Equatable {
    case idle
    case searching
    case installing(portName: String)
    case uninstalling(portName: String)
    case updating(portName: String)
    case syncing
    case checkingUpdates
    case error(message: String)
    
    var isLoading: Bool {
        switch self {
        case .idle, .error:
            return false
        default:
            return true
        }
    }
    
    var statusMessage: String {
        switch self {
        case .idle:
            return "Ready"
        case .searching:
            return "Searching..."
        case .installing(let name):
            return "Installing \(name)..."
        case .uninstalling(let name):
            return "Uninstalling \(name)..."
        case .updating(let name):
            return "Updating \(name)..."
        case .syncing:
            return "Syncing port tree..."
        case .checkingUpdates:
            return "Checking for updates..."
        case .error(let message):
            return "Error: \(message)"
        }
    }
}

/// Categories for filtering ports
enum PortCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case devel = "devel"
    case net = "net"
    case python = "python"
    case ruby = "ruby"
    case perl = "perl"
    case java = "java"
    case databases = "databases"
    case www = "www"
    case graphics = "graphics"
    case audio = "audio"
    case video = "video"
    case security = "security"
    case sysutils = "sysutils"
    case textproc = "textproc"
    case editors = "editors"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .all: return "All Categories"
        case .devel: return "Development"
        case .net: return "Networking"
        case .python: return "Python"
        case .ruby: return "Ruby"
        case .perl: return "Perl"
        case .java: return "Java"
        case .databases: return "Databases"
        case .www: return "Web"
        case .graphics: return "Graphics"
        case .audio: return "Audio"
        case .video: return "Video"
        case .security: return "Security"
        case .sysutils: return "System Utilities"
        case .textproc: return "Text Processing"
        case .editors: return "Editors"
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .devel: return "hammer"
        case .net: return "network"
        case .python: return "chevron.left.forwardslash.chevron.right"
        case .ruby: return "diamond"
        case .perl: return "p.circle.fill"
        case .java: return "cup.and.saucer"
        case .databases: return "cylinder"
        case .www: return "globe"
        case .graphics: return "paintpalette"
        case .audio: return "speaker.wave.3"
        case .video: return "film"
        case .security: return "lock.shield"
        case .sysutils: return "gearshape.2"
        case .textproc: return "doc.text"
        case .editors: return "pencil.and.outline"
        }
    }
}

/// Sidebar navigation items
enum NavigationItem: String, CaseIterable, Identifiable {
    case search = "Search"
    case installed = "Installed"
    case updates = "Updates"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .search: return "magnifyingglass"
        case .installed: return "checkmark.circle.fill"
        case .updates: return "arrow.triangle.2.circlepath"
        }
    }
}
