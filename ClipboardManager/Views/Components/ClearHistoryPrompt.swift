import AppKit

enum ClearHistoryPrompt {
    static func present(service: PasteboardService) {
        let count = service.clipboardItems.count
        let alert = NSAlert()
        alert.messageText = "Clear Clipboard History?"
        alert.informativeText = count == 1
            ? "This will permanently remove the only item in your history."
            : "This will permanently remove all \(count) items from your history."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear History").hasDestructiveAction = true
        alert.addButton(withTitle: "Cancel")

        if let window = NSApp.keyWindow {
            alert.beginSheetModal(for: window) { response in
                if response == .alertFirstButtonReturn {
                    service.clearAll()
                }
            }
        } else {
            NSApp.activate(ignoringOtherApps: true)
            if alert.runModal() == .alertFirstButtonReturn {
                service.clearAll()
            }
        }
    }
}
