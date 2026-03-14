import SwiftUI

struct SearchView: View {
    @EnvironmentObject var portsManager: PortsManager
    @StateObject private var searchState = SearchState()
    @State private var selectedPort: Port?
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left: Search results list
                VStack(spacing: 0) {
                    // Search bar
                    SearchBarView(searchText: $searchState.searchText, selectedCategory: $searchState.selectedCategory) {
                        performSearch()
                    }
                    
                    Divider()
                        .background(Color(nsColor: .separatorColor))
                    
                    // Results list
                    if searchState.isSearching {
                        VStack {
                            Spacer()
                            ProgressView("Searching...")
                                .progressViewStyle(.circular)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.surfacePrimary)
                    } else if searchState.searchResults.isEmpty && (!searchState.searchText.isEmpty || searchState.selectedCategory != .all) {
                        ContentUnavailableView {
                            Label("No Results", systemImage: "magnifyingglass")
                        } description: {
                            if searchState.selectedCategory != .all && !searchState.searchText.isEmpty {
                                Text("No ports starting with '\(searchState.searchText)' in \(searchState.selectedCategory.displayName)")
                            } else if searchState.selectedCategory != .all {
                                Text("No ports found in \(searchState.selectedCategory.displayName)")
                            } else {
                                Text("No ports found matching '\(searchState.searchText)'")
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.surfacePrimary)
                    } else if searchState.searchResults.isEmpty {
                        ContentUnavailableView {
                            Label("Search Ports", systemImage: "magnifyingglass")
                        } description: {
                            Text("Select a category or enter a search term")
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.surfacePrimary)
                    } else {
                        List(selection: $selectedPort) {
                            ForEach(searchState.searchResults) { port in
                                PortRowView(
                                    port: port,
                                    isSelected: portsManager.installQueue.contains(where: { $0.id == port.id }),
                                    showCheckbox: true,
                                    onToggle: { togglePortInQueue(port) }
                                )
                                .tag(port)
                                .draggable(port.name)
                            }
                        }
                        .listStyle(.inset(alternatesRowBackgrounds: true))
                        .scrollContentBackground(.hidden)
                        .background(Color.surfacePrimary)
                    }
                    
                    // Global install queue bar (shows selections from ALL tabs)
                    if !portsManager.installQueue.isEmpty {
                        Rectangle()
                            .fill(Color.surfaceSecondary)
                            .frame(height: 1)
                        GlobalInstallQueueBar(
                            ports: portsManager.installQueue,
                            onInstall: installQueued,
                            onClear: { portsManager.clearInstallQueue() },
                            onRemovePort: { port in portsManager.removeFromInstallQueue([port]) }
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
        .onAppear {
            // Connect the search state to the ports manager
            searchState.setPortsManager(portsManager)
        }
        .onChange(of: searchState.selectedCategory) { _, _ in
            Task {
                await searchState.onCategoryChanged()
            }
        }
        .onChange(of: searchState.searchText) { _, _ in
            Task {
                await searchState.onSearchTextChanged()
            }
        }
    }
    
    private func performSearch() {
        Task {
            await searchState.performSearch()
        }
    }
    
    private func togglePortInQueue(_ port: Port) {
        if portsManager.installQueue.contains(where: { $0.id == port.id }) {
            portsManager.removeFromInstallQueue([port])
        } else {
            portsManager.addToInstallQueue([port])
        }
    }
    
    private func installQueued() {
        Task {
            await portsManager.installQueuedPorts()
            // Refresh search results to update installed status
            await searchState.performSearch()
        }
    }
}

// MARK: - Search Bar View

struct SearchBarView: View {
    @Binding var searchText: String
    @Binding var selectedCategory: PortCategory
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
            
            Picker(selection: $selectedCategory) {
                ForEach(PortCategory.allCases) { category in
                    Label(category.displayName, systemImage: category.icon)
                        .tag(category)
                }
            } label: {
                EmptyView()
            }
            .pickerStyle(.menu)
            .frame(width: 170)
            .padding(6)
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

// MARK: - Global Install Queue Bar

struct GlobalInstallQueueBar: View {
    let ports: [Port]
    let onInstall: () -> Void
    let onClear: () -> Void
    let onRemovePort: (Port) -> Void
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Expandable port list
            if isExpanded && ports.count > 1 {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(ports) { port in
                            HStack {
                                Text(port.name)
                                    .font(.caption)
                                    .foregroundStyle(Color.textPrimary)
                                
                                if !port.version.isEmpty {
                                    Text("@\(port.version)")
                                        .font(.caption2)
                                        .foregroundStyle(Color.textTertiary)
                                }
                                
                                Spacer()
                                
                                Button {
                                    onRemovePort(port)
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(Color.textTertiary)
                                }
                                .buttonStyle(.plain)
                                .help("Remove from queue")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: 120)
                .background(Color.surfacePrimary)
                
                Rectangle()
                    .fill(Color.surfaceSecondary)
                    .frame(height: 1)
            }
            
            // Main bar
            HStack {
                // Toggle expand button & count
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption2)
                        
                        Label("\(ports.count) port\(ports.count == 1 ? "" : "s") queued for install", systemImage: "tray.and.arrow.down.fill")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(Color.textSecondary)
                }
                .buttonStyle(.plain)
                .disabled(ports.count <= 1)
                
                // Show first few port names inline when collapsed
                if !isExpanded {
                    Text("·")
                        .foregroundStyle(Color.textTertiary)
                    
                    Text(portNamesPreview)
                        .font(.caption)
                        .foregroundStyle(Color.textTertiary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                Spacer()
                
                Button("Clear All") {
                    onClear()
                }
                .buttonStyle(.plain)
                .font(.subheadline)
                .foregroundStyle(Color.textTertiary)
                .accessibilityLabel("Clear install queue")
                
                Button {
                    onInstall()
                } label: {
                    Label("Install \(ports.count)", systemImage: "arrow.down.circle.fill")
                }
                .buttonStyle(.themePrimary)
                .accessibilityLabel("Install \(ports.count) queued port\(ports.count == 1 ? "" : "s")")
            }
            .padding(16)
            .background(LinearGradient.toolbarGradient)
        }
    }
    
    private var portNamesPreview: String {
        let names = ports.prefix(3).map { $0.name }
        if ports.count > 3 {
            return names.joined(separator: ", ") + " +\(ports.count - 3) more"
        }
        return names.joined(separator: ", ")
    }
}

#Preview {
    SearchView()
        .environmentObject(PortsManager())
        .frame(width: 800, height: 500)
}
