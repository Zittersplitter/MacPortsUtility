import Foundation
import SwiftUI

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
    @Published var installQueue: [Port] = []
    
    // MARK: - Legacy (deprecated, for backwards compatibility)
    @Published var searchResults: [Port] = []
    
    private let portCommand = "/opt/local/bin/port"
    
    init() {
        // Check synchronously to avoid UI flash
        isMacPortsInstalled = FileManager.default.fileExists(atPath: portCommand)
        
        Task {
            if isMacPortsInstalled {
                await fetchMacPortsVersion()
                await refreshInstalledPorts()
            }
        }
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
        let portsToInstall = installQueue
        await installPorts(portsToInstall)
        installQueue.removeAll()
    }
    
    // MARK: - Search
    
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
    
    /// Legacy search method - updates shared state (deprecated for multi-window use)
    func searchPorts(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        state = .searching
        searchResults = await searchPortsReturningResults(query: query)
        state = .idle
    }
    
    private func parseSearchResult(_ line: String) -> Port? {
        // Format: "portname @version (categories)"
        // Description on same or next line
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        
        // Match pattern: name @version (categories)
        let pattern = #"^(\S+)\s+@(\S+)\s+\(([^)]+)\)(?:\s+(.+))?$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: trimmed, options: [], range: NSRange(trimmed.startIndex..., in: trimmed)) else {
            return nil
        }
        
        let name = String(trimmed[Range(match.range(at: 1), in: trimmed)!])
        let version = String(trimmed[Range(match.range(at: 2), in: trimmed)!])
        let categoriesStr = String(trimmed[Range(match.range(at: 3), in: trimmed)!])
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
        
        let name = String(trimmed[Range(match.range(at: 1), in: trimmed)!])
        let version = String(trimmed[Range(match.range(at: 2), in: trimmed)!])
        
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
        
        let portNames = ports.map { $0.name }
        state = .installing(portName: portNames.joined(separator: ", "))
        appendToConsole("Installing \(portNames.count) port(s): \(portNames.joined(separator: ", "))...")
        
        // Build a single command that installs all ports
        let commands = portNames.map { "/opt/local/bin/port install \($0)" }.joined(separator: " && ")
        let script = """
        do shell script "\(commands)" with administrator privileges
        """
        
        let (output, error) = await runAppleScript(script)
        
        if !error.isEmpty {
            state = .error(message: error)
            appendToConsole("Error installing ports: \(error)")
        } else {
            appendToConsole("Successfully installed \(portNames.count) port(s)")
            appendToConsole(output)
            state = .idle
        }
        
        await refreshInstalledPorts()
    }
    
    func installPort(_ port: Port) async {
        await installPorts([port])
    }
    
    /// Uninstall multiple ports with a single password prompt
    func uninstallPorts(_ ports: [Port]) async {
        guard !ports.isEmpty else { return }
        
        let portNames = ports.map { $0.name }
        state = .uninstalling(portName: portNames.joined(separator: ", "))
        appendToConsole("Uninstalling \(portNames.count) port(s): \(portNames.joined(separator: ", "))...")
        
        let commands = portNames.map { "/opt/local/bin/port uninstall \($0)" }.joined(separator: " && ")
        let script = """
        do shell script "\(commands)" with administrator privileges
        """
        
        let (output, error) = await runAppleScript(script)
        
        if !error.isEmpty {
            state = .error(message: error)
            appendToConsole("Error uninstalling ports: \(error)")
        } else {
            appendToConsole("Successfully uninstalled \(portNames.count) port(s)")
            appendToConsole(output)
            state = .idle
        }
        
        await refreshInstalledPorts()
    }
    
    func uninstallPort(_ port: Port) async {
        await uninstallPorts([port])
    }
    
    /// Update multiple ports with a single password prompt
    func updatePorts(_ ports: [Port]) async {
        guard !ports.isEmpty else { return }
        
        let portNames = ports.map { $0.name }
        state = .updating(portName: portNames.joined(separator: ", "))
        appendToConsole("Updating \(portNames.count) port(s): \(portNames.joined(separator: ", "))...")
        
        let commands = portNames.map { "/opt/local/bin/port upgrade \($0)" }.joined(separator: " && ")
        let script = """
        do shell script "\(commands)" with administrator privileges
        """
        
        let (output, error) = await runAppleScript(script)
        
        if !error.isEmpty {
            state = .error(message: error)
            appendToConsole("Error updating ports: \(error)")
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
        state = .updating(portName: "all outdated")
        appendToConsole("Updating all outdated ports...")
        
        let script = """
        do shell script "/opt/local/bin/port upgrade outdated" with administrator privileges
        """
        
        let (output, error) = await runAppleScript(script)
        
        if !error.isEmpty {
            state = .error(message: error)
            appendToConsole("Error updating ports: \(error)")
        } else {
            appendToConsole("Successfully updated all ports")
            appendToConsole(output)
            state = .idle
        }
        
        await refreshInstalledPorts()
    }
    
    // MARK: - Sync
    
    func syncPortTree() async {
        state = .syncing
        appendToConsole("Syncing port tree...")
        
        let script = """
        do shell script "/opt/local/bin/port selfupdate" with administrator privileges
        """
        
        let (output, error) = await runAppleScript(script)
        
        if !error.isEmpty {
            state = .error(message: error)
            appendToConsole("Error syncing: \(error)")
        } else {
            appendToConsole("Successfully synced port tree")
            appendToConsole(output)
            state = .idle
        }
        
        await checkForUpdates()
    }
    
    // MARK: - Port Info
    
    func getPortInfo(name: String) async -> String {
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
        consoleOutput += "[\(timestamp)] \(text)\n"
    }
    
    func clearConsole() {
        consoleOutput = ""
    }
}
