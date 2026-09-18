import AppKit
import Carbon
import Observation

@Observable
final class PasteSimulator {
    private(set) var isTrusted = AXIsProcessTrusted()

    @ObservationIgnored private var didPromptForAccess = false

    func refresh() {
        isTrusted = AXIsProcessTrusted()
    }

    func sendPaste() {
        refresh()
        guard isTrusted else {
            promptForAccessOnce()
            return
        }
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    private func promptForAccessOnce() {
        guard !didPromptForAccess else { return }
        didPromptForAccess = true
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
    }
}
