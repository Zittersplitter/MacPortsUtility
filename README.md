# MacPorts Utility

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS_14+-blue" alt="Platform: macOS 14+">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/SwiftUI-Native-green" alt="SwiftUI">
</p>

A native macOS application for managing [MacPorts](https://www.macports.org/) packages with a modern, Platinum-grey–tinted interface. Search, install, update, and manage your ports without touching the command line.

![MacPorts Utility Screenshot](screenshot.png)

## Features

### Search & Discover
- **Real-time Search** — find ports by name with instant results
- **Category Filtering** — browse 15 categories (devel, net, python, ruby, databases, security, and more) from a dedicated dropdown
- **Rich Port Details** — view version, categories, description, and full port info loaded automatically
- **Drag & Drop** — drag port names from search results

### Package Management
- **One-click Install** — install ports with a single admin authentication prompt
- **Install Queue** — select multiple ports across searches and install them all at once with drag-to-reorder support
- **Uninstall** — remove individual ports or batch-uninstall selected ones
- **Installed Ports Browser** — filter by name, sort by name or version, see update badges at a glance

### Updates
- **Outdated Port Detection** — see which ports have newer versions available
- **Selective Updates** — update individual ports or a batch selection
- **Update All** — one-click update for every outdated port
- **Visual Badges** — sidebar and list badges show the number of available updates

### User Experience
- **Native macOS Design** — built with SwiftUI using a three-column `NavigationSplitView`
- **Platinum Grey Light Mode** — warm grey surfaces inspired by classic Mac aesthetics
- **Dark Mode** — full dark-mode support with automatic or manual switching (System / Light / Dark)
- **Built-in Console** — toggleable panel showing live operation output (capped at 50 KB)
- **Status Bar** — persistent indicator of the current operation state
- **Keyboard Shortcuts** — common actions accessible from the menu bar
- **Caching** — search results, category listings, and port info are cached with a 5-minute TTL; caches auto-invalidate after installs, uninstalls, updates, or syncs

## Requirements

- **macOS 14.0 (Sonoma)** or later
- **[MacPorts](https://www.macports.org/install.php)** installed at `/opt/local/bin/port`
- **Xcode 15+** (for building from source)

## Installation

### From Source

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/MacPortsUtility.git
   cd MacPortsUtility
   ```

2. Open in Xcode and build:
   ```bash
   open MacPortsUtility.xcodeproj
   ```

3. Press **⌘R** to build and run.

If MacPorts is not installed, the app displays an overlay with a link to the official download page.

## Architecture

```
MacPortsUtility/
├── MacPortsUtilityApp.swift    # App entry point, AppearanceMode enum, menu commands
├── ContentView.swift           # Three-column NavigationSplitView, console, status bar
├── AppIconView.swift           # Custom app-icon view
├── Models/
│   └── Port.swift              # Port model, PortCategory, PortOperationState enums
├── Services/
│   ├── PortsManager.swift      # Core service — search, install, update, cache, shell execution
│   └── SearchState.swift       # Per-window search state with client-side category filtering
├── Views/
│   ├── SearchView.swift        # Search interface with category dropdown & install queue
│   ├── InstalledView.swift     # Installed ports list with filter, sort, multi-select
│   ├── UpdatesView.swift       # Outdated ports list with batch & individual updates
│   ├── PortDetailView.swift    # Port info panel with auto-loaded details
│   ├── PortRowView.swift       # Reusable port list-row component
│   └── AboutView.swift         # About dialog with version & author info
├── Theme/
│   └── AppTheme.swift          # Design system — colours, gradients, button styles, card modifier
└── Assets.xcassets/            # App icons & accent colour
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘R` | Refresh installed ports |
| `⇧⌘S` | Sync port tree (`port selfupdate`) |
| `⇧⌘I` | Open MacPorts download page |

## How It Works

MacPorts Utility wraps the `port` CLI at `/opt/local/bin/port`. It parses command output with compiled regular expressions to populate the UI.

Privileged operations (install, uninstall, update, sync) use **AppleScript** to request admin credentials via the system dialog, consolidating batch operations into a single password prompt. Port names are validated and shell-quoted before execution to prevent injection.

### Key Operations

| Operation | Command |
|-----------|---------|
| Search | `port search --name --glob "*query*"` |
| List Installed | `port installed` |
| Check Updates | `port outdated` |
| Install | `port install <portname>` |
| Uninstall | `port uninstall <portname>` |
| Update | `port upgrade <portname>` |
| Sync | `port selfupdate` |
| Port Info | `port info <portname>` |

## Theming

The app features a custom color palette inspired by enterprise software aesthetics with full dark mode support:

- **Brand Primary**: Professional blue (#2C5AA0)
- **Brand Accent**: Vibrant orange (#E76F2E) for actions and highlights
- **Adaptive Surfaces**: Automatically adjusts to system appearance

Toggle between Light, Dark, and System appearance modes via the sidebar footer or the app menu.

## License

This project is licensed under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Acknowledgments

- [MacPorts Project](https://www.macports.org/) for the incredible package management system i use for more than 15 years now!


## Disclaimer

This is an unofficial third-party application and is not affiliated with or endorsed by the MacPorts Project. Use at your own risk.
