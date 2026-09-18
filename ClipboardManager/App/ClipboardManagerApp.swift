import SwiftUI

@main
struct ClipboardManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("ClipboardManager", systemImage: "doc.on.clipboard") {
            StatusMenu(showPanel: delegate.showPanel)
                .environment(delegate.settings)
                .environment(delegate.pasteboardService)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environment(delegate.settings)
                .environment(delegate.pasteboardService)
                .environment(delegate.loginItems)
                .environment(delegate.hotkeyManager)
                .environment(delegate.pasteSimulator)
                .environment(\.appInfo, delegate.appInfo)
        }
    }
}
