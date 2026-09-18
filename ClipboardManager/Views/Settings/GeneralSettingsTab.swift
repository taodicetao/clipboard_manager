import Combine
import SwiftUI

struct GeneralSettingsTab: View {
    @Environment(AppSettings.self) private var settings
    @Environment(LoginItemService.self) private var loginItems
    @Environment(GlobalHotkeyManager.self) private var hotkeys
    @Environment(PasteSimulator.self) private var pasteSimulator

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: Binding(
                    get: { loginItems.isEnabled },
                    set: { loginItems.setEnabled($0) }
                ))
                if loginItems.status == .requiresApproval {
                    LabeledContent("Status") {
                        Text("Waiting for approval in System Settings")
                    }
                    Button("Open Login Items Settings…") {
                        loginItems.openSystemSettings()
                    }
                }
            }
            Section {
                LabeledContent("Show clipboard history") {
                    HotkeyRecorderView(
                        hotkey: $settings.hotkey,
                        validate: hotkeys.isAcceptable,
                        onRecordingChanged: { hotkeys.isSuspended = $0 }
                    )
                    .fixedSize()
                }
            } header: {
                Text("Keyboard Shortcut")
            } footer: {
                Text(shortcutFooter)
            }
            Section("Panel") {
                Picker("Open panel", selection: $settings.panelPosition) {
                    ForEach(PanelPosition.allCases, id: \.self) { position in
                        Text(position.title)
                    }
                }
                Toggle("Focus search field when opened", isOn: $settings.focusSearchOnOpen)
                Toggle("Paste selected item immediately", isOn: $settings.pasteOnSelect)
                if settings.pasteOnSelect && !pasteSimulator.isTrusted {
                    LabeledContent("Accessibility access is required to paste") {
                        Button("Open Accessibility Settings…") {
                            pasteSimulator.openAccessibilitySettings()
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .alert("Couldn't Change Login Item", isPresented: Binding(
            get: { loginItems.lastError != nil },
            set: { if !$0 { loginItems.lastError = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(loginItems.lastError ?? "")
        }
        .onAppear(perform: refreshStatuses)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshStatuses()
        }
    }

    private var shortcutFooter: String {
        if let rejected = hotkeys.lastRejectedHotkey {
            return "\(rejected.displayString) is used by macOS. Choose another, or change it in System Settings › Keyboard › Keyboard Shortcuts."
        }
        if hotkeys.isSuspended {
            return "Press the new shortcut, or Esc to keep the current one."
        }
        return hotkeys.isRegistered
            ? "Click the field and press a combination that includes ⌘, ⌥ or ⌃. If another app uses the same shortcut, only one of them will receive it."
            : "This shortcut could not be registered. Choose a different combination."
    }

    private func refreshStatuses() {
        loginItems.refresh()
        pasteSimulator.refresh()
    }
}

private extension PanelPosition {
    var title: String {
        switch self {
        case .atCursor: "At Mouse Pointer"
        case .screenCenter: "Center of Screen"
        }
    }
}
