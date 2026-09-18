import Carbon
import Testing
@testable import ClipboardManager

@Suite struct GlobalHotkeyManagerTests {
    private func makeManager() -> GlobalHotkeyManager {
        GlobalHotkeyManager(settings: AppSettings(defaults: UserDefaults(suiteName: "GlobalHotkeyManagerTests.\(UUID().uuidString)")!))
    }

    @Test func defaultShortcutIsAcceptable() {
        let manager = makeManager()
        #expect(manager.isAcceptable(.default))
        #expect(manager.lastRejectedHotkey == nil)
    }

    @Test func systemShortcutsAreRejectedAndRemembered() {
        let manager = makeManager()
        let spotlight = Hotkey(keyCode: UInt32(kVK_Space), carbonModifiers: UInt32(cmdKey))
        #expect(!manager.isAcceptable(spotlight))
        #expect(manager.lastRejectedHotkey == spotlight)
        #expect(manager.isAcceptable(.default))
        #expect(manager.lastRejectedHotkey == nil)
    }

    @Test func suspendingClearsRejectionAndUnregisters() {
        let manager = makeManager()
        _ = manager.isAcceptable(Hotkey(keyCode: UInt32(kVK_Tab), carbonModifiers: UInt32(cmdKey)))
        manager.isSuspended = true
        #expect(manager.lastRejectedHotkey == nil)
        #expect(!manager.isRegistered)
    }
}
