import Foundation
import SwiftUI

/// Per-window search state - each window gets its own instance
/// This allows independent search sessions across multiple tabs/windows
@MainActor
class SearchState: ObservableObject {
    @Published var searchText: String = ""
    @Published var searchResults: [Port] = []
    @Published var selectedPorts: Set<String> = []
    @Published var selectedPort: Port?
    @Published var isSearching: Bool = false
    @Published var errorMessage: String?
    
    private weak var portsManager: PortsManager?
    
    init(portsManager: PortsManager? = nil) {
        self.portsManager = portsManager
    }
    
    func setPortsManager(_ manager: PortsManager) {
        self.portsManager = manager
    }
    
    // MARK: - Search
    
    func performSearch() async {
        guard let portsManager = portsManager else { return }
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        errorMessage = nil
        
        // Perform the search and get results locally
        let results = await portsManager.searchPortsReturningResults(query: searchText)
        
        // Update local state with the results
        searchResults = results
        isSearching = false
    }
    
    // MARK: - Selection Management
    
    func toggleSelection(_ port: Port) {
        if selectedPorts.contains(port.id) {
            selectedPorts.remove(port.id)
        } else {
            selectedPorts.insert(port.id)
        }
    }
    
    func clearSelection() {
        selectedPorts.removeAll()
    }
    
    /// Add selected ports to the global install queue
    func addSelectedToInstallQueue() {
        guard let portsManager = portsManager else { return }
        let portsToAdd = searchResults.filter { selectedPorts.contains($0.id) }
        portsManager.addToInstallQueue(portsToAdd)
    }
    
    /// Install selected ports directly (from this window's selection)
    func installSelected() async {
        guard let portsManager = portsManager else { return }
        let portsToInstall = searchResults.filter { selectedPorts.contains($0.id) }
        await portsManager.installPorts(portsToInstall)
        selectedPorts.removeAll()
        
        // Refresh search results to update installed status
        await performSearch()
    }
}
