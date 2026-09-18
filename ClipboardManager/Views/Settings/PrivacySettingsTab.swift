import SwiftUI
import UniformTypeIdentifiers

struct PrivacySettingsTab: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.appInfo) private var appInfo

    var body: some View {
        Form {
            Section {
                if settings.excludedBundleIdentifiers.isEmpty {
                    Text("No excluded apps")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                ForEach(settings.excludedBundleIdentifiers, id: \.self) { bundleIdentifier in
                    HStack(spacing: 8) {
                        SourceAppIconView(bundleIdentifier: bundleIdentifier, appInfo: appInfo, size: 20)
                        Text(appInfo.name(for: bundleIdentifier) ?? bundleIdentifier)
                        Spacer()
                        Button {
                            settings.excludedBundleIdentifiers.removeAll { $0 == bundleIdentifier }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Remove from excluded apps")
                    }
                }
                Button("Add Application…", action: addApplications)
            } header: {
                Text("Excluded Apps")
            } footer: {
                Text("Content copied from excluded apps is not recorded. Passwords and other concealed or transient clipboard content is never recorded.")
            }
        }
        .formStyle(.grouped)
    }

    private func addApplications() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.prompt = "Exclude"
        let complete: (NSApplication.ModalResponse) -> Void = { response in
            guard response == .OK else { return }
            let identifiers = panel.urls.compactMap { Bundle(url: $0)?.bundleIdentifier }
            for identifier in identifiers where !settings.excludedBundleIdentifiers.contains(identifier) {
                settings.excludedBundleIdentifiers.append(identifier)
            }
        }
        if let window = NSApp.keyWindow {
            panel.beginSheetModal(for: window, completionHandler: complete)
        } else {
            complete(panel.runModal())
        }
    }
}
