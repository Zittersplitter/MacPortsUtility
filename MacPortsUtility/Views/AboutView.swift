import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.8.1"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // App Icon
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 128, height: 128)
                .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
            
            // App Name
            Text("MacPorts Utility")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color.textPrimary)
            
            // Version
            Text("Version \(appVersion) (\(buildNumber))")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
            
            Divider()
                .frame(width: 200)
            
            // Author
            VStack(spacing: 4) {
                Text("Created by")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
                Text("Marcel Hartmann")
                    .font(.headline)
                    .foregroundStyle(Color.textPrimary)
            }
            
            // Description
            Text("A modern GUI for managing MacPorts packages on macOS")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
            
            // GitHub Link
            Button {
                if let url = URL(string: "https://github.com/Zittersplitter/MacPortsUtility") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "link")
                    Text("View on GitHub")
                }
                .font(.subheadline)
            }
            .buttonStyle(.link)
            
            Spacer()
            
            // Copyright
            Text("Copyright © 2026 Marcel Hartmann. All rights reserved.")
                .font(.caption2)
                .foregroundStyle(Color.textTertiary)
        }
        .padding(30)
        .frame(width: 350, height: 420)
        .background(Color.surfacePrimary)
    }
}

#Preview {
    AboutView()
}
