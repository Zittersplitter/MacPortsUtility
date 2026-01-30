import SwiftUI

struct SearchView: View {
    @EnvironmentObject var portsManager: PortsManager
    @State private var searchText = ""
    @State private var selectedPorts: Set<String> = []
    @State private var selectedPort: Port?
    @State private var isSearching = false
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left: Search results list
                VStack(spacing: 0) {
                    // Search bar
                    SearchBarView(searchText: $searchText) {
                        performSearch()
                    }
                    
                    Divider()
                        .background(Color(nsColor: .separatorColor))
                    
                    // Results list
                    if portsManager.state == .searching {
                        VStack {
                            Spacer()
                            ProgressView("Searching...")
                                .progressViewStyle(.circular)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.surfacePrimary)
                    } else if portsManager.searchResults.isEmpty && !searchText.isEmpty {
                        ContentUnavailableView {
                            Label("No Results", systemImage: "magnifyingglass")
                        } description: {
                            Text("No ports found matching '\(searchText)'")
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.surfacePrimary)
                    } else if portsManager.searchResults.isEmpty {
                        ContentUnavailableView {
                            Label("Search Ports", systemImage: "magnifyingglass")
                        } description: {
                            Text("Enter a search term to find available ports")
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.surfacePrimary)
                    } else {
                        List(selection: $selectedPort) {
                            ForEach(portsManager.searchResults) { port in
                                PortRowView(
                                    port: port,
                                    isSelected: selectedPorts.contains(port.id),
                                    showCheckbox: true,
                                    onToggle: { toggleSelection(port) }
                                )
                                .tag(port)
                            }
                        }
                        .listStyle(.inset(alternatesRowBackgrounds: true))
                        .scrollContentBackground(.hidden)
                        .background(Color.surfacePrimary)
                    }
                    
                    // Install selected button
                    if !selectedPorts.isEmpty {
                        Rectangle()
                            .fill(Color.surfaceSecondary)
                            .frame(height: 1)
                        InstallSelectedBar(
                            count: selectedPorts.count,
                            onInstall: installSelected,
                            onClear: { selectedPorts.removeAll() }
                        )
                    }
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
        .navigationTitle("Search Ports")
    }
    
    private func performSearch() {
        Task {
            await portsManager.searchPorts(query: searchText)
        }
    }
    
    private func toggleSelection(_ port: Port) {
        if selectedPorts.contains(port.id) {
            selectedPorts.remove(port.id)
        } else {
            selectedPorts.insert(port.id)
        }
    }
    
    private func installSelected() {
        let portsToInstall = portsManager.searchResults.filter { selectedPorts.contains($0.id) }
        Task {
            await portsManager.installPorts(portsToInstall)
            selectedPorts.removeAll()
        }
    }
}

// MARK: - Search Bar View

struct SearchBarView: View {
    @Binding var searchText: String
    var onSearch: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.textSecondary)
                
                TextField("Search ports...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .onSubmit {
                        onSearch()
                    }
                
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
            
            Button("Search") {
                onSearch()
            }
            .buttonStyle(.themePrimary)
            .disabled(searchText.isEmpty)
        }
        .padding(16)
        .background(LinearGradient.toolbarGradient)
    }
}

// MARK: - Install Selected Bar

struct InstallSelectedBar: View {
    let count: Int
    let onInstall: () -> Void
    let onClear: () -> Void
    
    var body: some View {
        HStack {
            Label("\(count) port\(count == 1 ? "" : "s") selected", systemImage: "checkmark.circle.fill")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.textSecondary)
            
            Spacer()
            
            Button("Clear") {
                onClear()
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.textTertiary)
            
            Button {
                onInstall()
            } label: {
                Label("Install Selected", systemImage: "arrow.down.circle.fill")
            }
            .buttonStyle(.themePrimary)
        }
        .padding(16)
        .background(LinearGradient.toolbarGradient)
    }
}

#Preview {
    SearchView()
        .environmentObject(PortsManager())
        .frame(width: 800, height: 500)
}
