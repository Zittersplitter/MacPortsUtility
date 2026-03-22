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
    @Published var selectedCategory: PortCategory = .all
    
    /// All results fetched from the port command (before text filtering)
    private var allFetchedResults: [Port] = []
    
    private weak var portsManager: PortsManager?
    
    init(portsManager: PortsManager? = nil) {
        self.portsManager = portsManager
    }
    
    func setPortsManager(_ manager: PortsManager) {
        self.portsManager = manager
    }
    
    // MARK: - Search
    
    /// Called when category changes — fetches all ports for that category
    func onCategoryChanged() async {
        guard let portsManager = portsManager else { return }
        
        if selectedCategory == .all {
            // "All" with no text → clear; with text → name search
            if searchText.isEmpty {
                allFetchedResults = []
                searchResults = []
                return
            } else {
                await performSearch()
                return
            }
        }
        
        isSearching = true
        errorMessage = nil
        
        let results = await portsManager.searchPortsByCategory(selectedCategory.rawValue)
        allFetchedResults = results
        applyTextFilter()
        isSearching = false
    }
    
    /// Called when the user submits a search or text changes
    func performSearch() async {
        guard let portsManager = portsManager else { return }
        
        if selectedCategory != .all {
            // Category is active — filter already-fetched category results client-side
            // If category results haven't been loaded yet, load them first
            if allFetchedResults.isEmpty {
                await onCategoryChanged()
            } else {
                applyTextFilter()
            }
            return
        }
        
        // "All Categories" mode — search by name via port command
        guard !searchText.isEmpty else {
            allFetchedResults = []
            searchResults = []
            return
        }
        
        isSearching = true
        errorMessage = nil
        
        let results = await portsManager.searchPortsReturningResults(query: searchText)
        allFetchedResults = results
        searchResults = results
        isSearching = false
    }
    
    /// Called as the user types — live filtering
    func onSearchTextChanged() async {
        if selectedCategory != .all {
            // Category active: filter fetched results client-side
            applyTextFilter()
        } else {
            // All categories: only show results if user has searched
            // Don't re-fetch on every keystroke in "All" mode
            if searchText.isEmpty {
                allFetchedResults = []
                searchResults = []
            }
        }
    }
    
    private func applyTextFilter() {
        if searchText.isEmpty {
            searchResults = allFetchedResults
        } else {
            let query = searchText.lowercased()
            searchResults = allFetchedResults.filter { port in
                port.name.lowercased().contains(query)
            }
        }
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
