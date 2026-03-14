import Foundation
import SwiftUI
import OSLog

/// Manages all MacPorts operations
@MainActor
class PortsManager: ObservableObject {
    // MARK: - Shared State (across all windows)
    @Published var installedPorts: [Port] = []
    @Published var outdatedPorts: [Port] = []
    @Published var state: PortOperationState = .idle
    @Published var consoleOutput: String = ""
    @Published var isMacPortsInstalled: Bool
    @Published var macPortsVersion: String = ""
    
    /// Global install queue - ports marked for installation from any window
    @Published var installQueue: [Port] = [] {
        didSet { persistInstallQueue() }
    }
    
    /// Last error message for user-facing alert
    @Published var lastError: String?
    
    private let portCommand = "/opt/local/bin/port"
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.mhartmann.MacPortsUtility", category: "PortsManager")
    private static let installQueueKey = "persistedInstallQueue"
    private static let maxConsoleLength = 50_000
    
    /// Validates that a port name contains only safe characters (alphanumeric, dot, hyphen, underscore, plus)
    private static func isValidPortName(_ name: String) -> Bool {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-+"))
        return !name.isEmpty && name.unicodeScalars.allSatisfy { allowed.contains($0) }
    }
    
    /// Escapes a string for safe use inside an AppleScript double-quoted string
    private func shellQuoted(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        return escaped
    }
    
    init() {
        // Check synchronously to avoid UI flash
        isMacPortsInstalled = FileManager.default.fileExists(atPath: portCommand)
        
        // Restore persisted install queue
        if let names = UserDefaults.standard.stringArray(forKey: Self.installQueueKey) {
            installQueue = names.map { Port(name: $0) }
        }
        
        Task {
            if isMacPortsInstalled {
                await fetchMacPortsVersion()
                await refreshInstalledPorts()
            }
        }
    }
    
    private func persistInstallQueue() {
        let names = installQueue.map { $0.name }
        UserDefaults.standard.set(names, forKey: Self.installQueueKey)
    }
    
    // MARK: - MacPorts Installation Check
    
    func checkMacPortsInstallation() async {
        let fileManager = FileManager.default
        isMacPortsInstalled = fileManager.fileExists(atPath: portCommand)
        
        if isMacPortsInstalled {
            await fetchMacPortsVersion()
        }
    }
    
    private func fetchMacPortsVersion() async {
        let (output, _) = await runCommand([portCommand, "version"])
        macPortsVersion = output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Install Queue Management
    
    /// Add ports to the global install queue
    func addToInstallQueue(_ ports: [Port]) {
        for port in ports {
            if !installQueue.contains(where: { $0.id == port.id }) && !port.isInstalled {
                installQueue.append(port)
            }
        }
        appendToConsole("Added \(ports.count) port(s) to install queue. Total: \(installQueue.count)")
    }
    
    /// Remove ports from the install queue
    func removeFromInstallQueue(_ ports: [Port]) {
        let idsToRemove = Set(ports.map { $0.id })
        installQueue.removeAll { idsToRemove.contains($0.id) }
    }
    
    /// Clear the entire install queue
    func clearInstallQueue() {
        installQueue.removeAll()
    }
    
    /// Install all ports in the queue
    func installQueuedPorts() async {
        guard !installQueue.isEmpty else { return }
        guard !state.isLoading else {
            lastError = "Another operation is in progress. Please wait."
            return
        }
        let portsToInstall = installQueue
        await installPorts(portsToInstall)
        // Remove only successfully installed ports from queue
        let installedNames = Set(installedPorts.map { $0.name })
        installQueue.removeAll { installedNames.contains($0.name) }
    }
    
    // MARK: - Search
    
    /// Search all ports in a given category
    func searchPortsByCategory(_ category: String) async -> [Port] {
        appendToConsole("Loading ports in category '\(category)'...")
        
        let (output, error) = await runCommand([portCommand, "search", "--category", "--glob", category])
        
        if !error.isEmpty && !error.contains("Warning") {
            appendToConsole("Error: \(error)")
            return []
        }
        
        var ports: [Port] = []
        let lines = output.components(separatedBy: "\n")
        
        for line in lines {
            if let port = parseSearchResult(line) {
                ports.append(port)
            }
        }
        
        let installedNames = Set(installedPorts.map { $0.name })
        ports = ports.map { port in
            var p = port
            p.isInstalled = installedNames.contains(port.name)
            return p
        }
        
        appendToConsole("Found \(ports.count) ports in category '\(category)'")
        return ports
    }
    
    /// Search ports and return results (for per-window state)
    /// This does NOT modify the shared searchResults property
    func searchPortsReturningResults(query: String) async -> [Port] {
        guard !query.isEmpty else {
            return []
        }
        
        appendToConsole("Searching for '\(query)'...")
        
        // Search for ports matching the query
        let (output, error) = await runCommand([portCommand, "search", "--name", "--glob", "*\(query)*"])
        
        if !error.isEmpty && !error.contains("Warning") {
            appendToConsole("Error: \(error)")
            return []
        }
        
        var ports: [Port] = []
        let lines = output.components(separatedBy: "\n")
        
        for line in lines {
            if let port = parseSearchResult(line) {
                ports.append(port)
            }
        }
        
        // Check which ones are installed
        let installedNames = Set(installedPorts.map { $0.name })
        ports = ports.map { port in
            var p = port
            p.isInstalled = installedNames.contains(port.name)
            return p
        }
        
        appendToConsole("Found \(ports.count) ports matching '\(query)'")
        return ports
    }
    
    private func parseSearchResult(_ line: String) -> Port? {
        // Format: "portname @version (categories)"
        // Description on same or next line
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        
        // Match pattern: name @version (categories)
        // Name restricted to safe characters: alphanumeric, dot, hyphen, underscore, plus
        let pattern = #"^([a-zA-Z0-9._+\-]+)\s+@(\S+)\s+\(([^)]+)\)(?:\s+(.+))?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(trimmed.startIndex..., in: trimmed)) else {
            return nil
        }
        
        guard let nameRange = Range(match.range(at: 1), in: trimmed),
              let versionRange = Range(match.range(at: 2), in: trimmed),
              let categoriesRange = Range(match.range(at: 3), in: trimmed) else {
            return nil
        }
        
        let name = String(trimmed[nameRange])
        let version = String(trimmed[versionRange])
        let categoriesStr = String(trimmed[categoriesRange])
        let categories = categoriesStr.components(separatedBy: ", ")
        
        var summary = ""
        if match.range(at: 4).location != NSNotFound,
           let range = Range(match.range(at: 4), in: trimmed) {
            summary = String(trimmed[range])
        }
        
        return Port(
            name: name,
            version: version,
            summary: summary,
            categories: categories
        )
    }
    
    // MARK: - Installed Ports
    
    func refreshInstalledPorts() async {
        appendToConsole("Refreshing installed ports...")
        
        let (output, _) = await runCommand([portCommand, "installed"])
        
        var ports: [Port] = []
        let lines = output.components(separatedBy: "\n")
        
        for line in lines {
            if let port = parseInstalledPort(line) {
                ports.append(port)
            }
        }
        
        installedPorts = ports
        appendToConsole("Found \(ports.count) installed ports")
        
        // Also check for updates
        await checkForUpdates()
    }
    
    private func parseInstalledPort(_ line: String) -> Port? {
        // Format: "  portname @version_revision+variants (active)"
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("The following") else { return nil }
        
        let pattern = #"^(\S+)\s+@(\S+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(trimmed.startIndex..., in: trimmed)) else {
            return nil
        }
        
        guard let nameRange = Range(match.range(at: 1), in: trimmed),
              let versionRange = Range(match.range(at: 2), in: trimmed) else {
            return nil
        }
        
        let name = String(trimmed[nameRange])
        let version = String(trimmed[versionRange])
        
        return Port(
            name: name,
            version: version,
            isInstalled: true,
            installedVersion: version
        )
    }
    
    // MARK: - Updates
    
    func checkForUpdates() async {
        state = .checkingUpdates
        appendToConsole("Checking for outdated ports...")
        
        let (output, _) = await runCommand([portCommand, "outdated"])
        
        var ports: [Port] = []
        let lines = output.components(separatedBy: "\n")
        
        for line in lines {
            if let port = parseOutdatedPort(line) {
                ports.append(port)
            }
        }
        
        outdatedPorts = ports
        state = .idle
        appendToConsole("Found \(ports.count) outdated ports")
    }
    
    private func parseOutdatedPort(_ line: String) -> Port? {
        // Format: "portname                       currentversion < newversion"
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("No") else { return nil }
        
        let components = trimmed.split(separator: " ").map { String($0) }
        guard components.count >= 3 else { return nil }
        
        let name = components[0]
        let currentVersion = components[1]
        let newVersion = components.last ?? ""
        
        return Port(
            name: name,
            version: newVersion,
            isInstalled: true,
            installedVersion: currentVersion,
            hasUpdate: true
        )
    }
    
    // MARK: - Install/Uninstall/Update
    
    /// Install multiple ports with a single password prompt
    func installPorts(_ ports: [Port]) async {
        guard !ports.isEmpty else { return }
        guard !state.isLoading else {
            lastError = "Another operation is in progress. Please wait."
            Self.logger.warning("installPorts blocked: another operation is in progress")
            return
        }
        
        let portNames = ports.map { $0.name }
        let invalidNames = portNames.filter { !Self.isValidPortName($0) }
        if !invalidNames.isEmpty {
            state = .error(message: "Invalid port name(s): \(invalidNames.joined(separator: ", "))")
            appendToConsole("Rejected install — invalid port name(s): \(invalidNames.joined(separator: ", "))")
            return
        }
        
        state = .installing(portName: portNames.joined(separator: ", "))
        appendToConsole("Installing \(portNames.count) port(s): \(portNames.joined(separator: ", "))...")
        
        // Build a single command using quoted form of each port name
        let commands = portNames.map { "\(portCommand) install " + "'" + shellQuoted($0) + "'" }.joined(separator: " && ")
        let script = """
        do shell script "\(shellQuoted(commands))" with administrator privileges
        """
        
        let (output, error) = await runAppleScript(script)
        
        if !error.isEmpty {
            state = .error(message: error)
            lastError = "Failed to install port(s): \(error)"
            appendToConsole("Error installing ports: \(error)")
            Self.logger.error("Install failed: \(error)")
        } else {
            appendToConsole("Successfully installed \(portNames.count) port(s)")
            appendToConsole(output)
            state = .idle
        }
        
        // Refresh to detect partial success
        await refreshInstalledPorts()
        
        // Report partial failures
        let installedNames = Set(installedPorts.map { $0.name })
        let failedNames = portNames.filter { !installedNames.contains($0) }
        if !failedNames.isEmpty && error.isEmpty {
            let msg = "Partial install: \(failedNames.joined(separator: ", ")) may not have installed successfully."
            appendToConsole(msg)
            lastError = msg
            Self.logger.warning("\(msg)")
        }
    }
    
    func installPort(_ port: Port) async {
        await installPorts([port])
    }
    
    /// Uninstall multiple ports with a single password prompt
    func uninstallPorts(_ ports: [Port]) async {
        guard !ports.isEmpty else { return }
        guard !state.isLoading else {
            lastError = "Another operation is in progress. Please wait."
            Self.logger.warning("uninstallPorts blocked: another operation is in progress")
            return
        }
        
        let portNames = ports.map { $0.name }
        let invalidNames = portNames.filter { !Self.isValidPortName($0) }
        if !invalidNames.isEmpty {
            state = .error(message: "Invalid port name(s): \(invalidNames.joined(separator: ", "))")
            appendToConsole("Rejected uninstall — invalid port name(s): \(invalidNames.joined(separator: ", "))")
            return
        }
        
        state = .uninstalling(portName: portNames.joined(separator: ", "))
        appendToConsole("Uninstalling \(portNames.count) port(s): \(portNames.joined(separator: ", "))...")
        
        let commands = portNames.map { "\(portCommand) uninstall " + "'" + shellQuoted($0) + "'" }.joined(separator: " && ")
        let script = """
        do shell script "\(shellQuoted(commands))" with administrator privileges
        """
        
        let (output, error) = await runAppleScript(script)
        
        if !error.isEmpty {
            state = .error(message: error)
            lastError = "Failed to uninstall port(s): \(error)"
            appendToConsole("Error uninstalling ports: \(error)")
            Self.logger.error("Uninstall failed: \(error)")
        } else {
            appendToConsole("Successfully uninstalled \(portNames.count) port(s)")
            appendToConsole(output)
            state = .idle
        }
        
        // Refresh to detect partial success
        await refreshInstalledPorts()
        
        let installedNames = Set(installedPorts.map { $0.name })
        let stillInstalled = portNames.filter { installedNames.contains($0) }
        if !stillInstalled.isEmpty && error.isEmpty {
            let msg = "Partial uninstall: \(stillInstalled.joined(separator: ", ")) may still be installed."
            appendToConsole(msg)
            lastError = msg
            Self.logger.warning("\(msg)")
        }
    }
    
    func uninstallPort(_ port: Port) async {
        await uninstallPorts([port])
    }
    
    /// Update multiple ports with a single password prompt
    func updatePorts(_ ports: [Port]) async {
        guard !ports.isEmpty else { return }
        guard !state.isLoading else {
            lastError = "Another operation is in progress. Please wait."
            Self.logger.warning("updatePorts blocked: another operation is in progress")
            return
        }
        
        let portNames = ports.map { $0.name }
        let invalidNames = portNames.filter { !Self.isValidPortName($0) }
        if !invalidNames.isEmpty {
            state = .error(message: "Invalid port name(s): \(invalidNames.joined(separator: ", "))")
            appendToConsole("Rejected update — invalid port name(s): \(invalidNames.joined(separator: ", "))")
            return
        }
        
        state = .updating(portName: portNames.joined(separator: ", "))
        appendToConsole("Updating \(portNames.count) port(s): \(portNames.joined(separator: ", "))...")
        
        let commands = portNames.map { "\(portCommand) upgrade " + "'" + shellQuoted($0) + "'" }.joined(separator: " && ")
        let script = """
        do shell script "\(shellQuoted(commands))" with administrator privileges
        """
        
        let (output, error) = await runAppleScript(script)
        
        if !error.isEmpty {
            state = .error(message: error)
            lastError = "Failed to update port(s): \(error)"
            appendToConsole("Error updating ports: \(error)")
            Self.logger.error("Update failed: \(error)")
        } else {
            appendToConsole("Successfully updated \(portNames.count) port(s)")
            appendToConsole(output)
            state = .idle
        }
        
        await refreshInstalledPorts()
    }
    
    func updatePort(_ port: Port) async {
        await updatePorts([port])
    }
    
    func updateAllPorts() async {
        guard !state.isLoading else {
            lastError = "Another operation is in progress. Please wait."
            return
        }
        state = .updating(portName: "all outdated")
        appendToConsole("Updating all outdated ports...")
        
        let script = """
        do shell script "\(shellQuoted(portCommand)) upgrade outdated" with administrator privileges
        """
        
        let (output, error) = await runAppleScript(script)
        
        if !error.isEmpty {
            state = .error(message: error)
            lastError = "Failed to update all ports: \(error)"
            appendToConsole("Error updating ports: \(error)")
            Self.logger.error("Update all failed: \(error)")
        } else {
            appendToConsole("Successfully updated all ports")
            appendToConsole(output)
            state = .idle
        }
        
        await refreshInstalledPorts()
    }
    
    // MARK: - Sync
    
    func syncPortTree() async {
        guard !state.isLoading else {
            lastError = "Another operation is in progress. Please wait."
            return
        }
        state = .syncing
        appendToConsole("Syncing port tree...")
        
        let script = """
        do shell script "\(shellQuoted(portCommand)) selfupdate" with administrator privileges
        """
        
        let (output, error) = await runAppleScript(script)
        
        if !error.isEmpty {
            state = .error(message: error)
            lastError = "Failed to sync port tree: \(error)"
            appendToConsole("Error syncing: \(error)")
            Self.logger.error("Sync failed: \(error)")
        } else {
            appendToConsole("Successfully synced port tree")
            appendToConsole(output)
            state = .idle
        }
        
        await checkForUpdates()
    }
    
    // MARK: - Port Info
    
    func getPortInfo(name: String) async -> String {
        guard Self.isValidPortName(name) else {
            appendToConsole("Rejected port info request — invalid port name: \(name)")
            return ""
        }
        let (output, _) = await runCommand([portCommand, "info", name])
        return output
    }
    
    // MARK: - Helper Methods
    
    private func runCommand(_ arguments: [String]) async -> (output: String, error: String) {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let task = Process()
                let outputPipe = Pipe()
                let errorPipe = Pipe()
                
                task.executableURL = URL(fileURLWithPath: arguments[0])
                task.arguments = Array(arguments.dropFirst())
                task.standardOutput = outputPipe
                task.standardError = errorPipe
                
                do {
                    try task.run()
                    task.waitUntilExit()
                    
                    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                    let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    
                    let output = String(data: outputData, encoding: .utf8) ?? ""
                    let error = String(data: errorData, encoding: .utf8) ?? ""
                    
                    continuation.resume(returning: (output, error))
                } catch {
                    continuation.resume(returning: ("", error.localizedDescription))
                }
            }
        }
    }
    
    private func runAppleScript(_ script: String) async -> (output: String, error: String) {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var errorInfo: NSDictionary?
                let appleScript = NSAppleScript(source: script)
                let result = appleScript?.executeAndReturnError(&errorInfo)
                
                let output = result?.stringValue ?? ""
                let error = (errorInfo?[NSAppleScript.errorMessage] as? String) ?? ""
                
                continuation.resume(returning: (output, error))
            }
        }
    }
    
    private func appendToConsole(_ text: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let line = "[\(timestamp)] \(text)\n"
        consoleOutput += line
        Self.logger.info("\(text)")
        
        // Cap console output to prevent unbounded memory growth
        if consoleOutput.count > Self.maxConsoleLength {
            let overflow = consoleOutput.count - Self.maxConsoleLength
            if let newlineIndex = consoleOutput[consoleOutput.index(consoleOutput.startIndex, offsetBy: overflow)...].firstIndex(of: "\n") {
                consoleOutput = String(consoleOutput[consoleOutput.index(after: newlineIndex)...])
            } else {
                consoleOutput = String(consoleOutput.suffix(Self.maxConsoleLength))
            }
        }
    }
    
    func clearConsole() {
        consoleOutput = ""
    }
}
