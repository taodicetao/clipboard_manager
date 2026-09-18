import SwiftUI

struct StatusMenu: View {
    @Environment(AppSettings.self) private var settings
    @Environment(PasteboardService.self) private var service
    @Environment(\.openSettings) private var openSettings

    let showPanel: () -> Void

    private static let repositoryURL = URL(string: "https://github.com/taodicetao/clipboard_manager")

    var body: some View {
        Button("Show Clipboard History", action: showPanel)
            .keyboardShortcut(settings.hotkey.keyboardShortcut)
        Divider()
        Button("Clear History…") {
            ClearHistoryPrompt.present(service: service)
        }
        .disabled(service.clipboardItems.isEmpty)
        Divider()
        Button("Settings…") {
            openSettings()
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut(",")
        Button("About ClipboardManager", action: showAbout)
        Divider()
        Button("Quit ClipboardManager") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        var attributes: [NSAttributedString.Key: Any] = [.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)]
        if let url = Self.repositoryURL {
            attributes[.link] = url
        }
        let credits = NSAttributedString(string: "View on GitHub", attributes: attributes)
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
    }
}
