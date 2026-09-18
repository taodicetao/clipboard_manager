import AppKit
import Carbon
import Testing
@testable import ClipboardManager

@Suite struct HotkeyTests {
    @Test func defaultIsCommandSemicolon() {
        #expect(Hotkey.default.keyCode == UInt32(kVK_ANSI_Semicolon))
        #expect(Hotkey.default.carbonModifiers == UInt32(cmdKey))
        #expect(Hotkey.default.displayString == "⌘;")
    }

    @Test func eventWithCommandModifierIsRecorded() {
        let hotkey = Hotkey(event: keyEvent(kVK_ANSI_K, characters: "k", flags: [.command, .shift]))
        #expect(hotkey?.keyCode == UInt32(kVK_ANSI_K))
        #expect(hotkey?.carbonModifiers == UInt32(cmdKey | shiftKey))
    }

    @Test func eventsWithoutPrimaryModifierAreRejected() {
        #expect(Hotkey(event: keyEvent(kVK_ANSI_K, characters: "k")) == nil)
        #expect(Hotkey(event: keyEvent(kVK_ANSI_K, characters: "K", flags: .shift)) == nil)
    }

    @Test func displayOrdersModifiersAndNamesSpecialKeys() {
        let hotkey = Hotkey(keyCode: UInt32(kVK_Return), carbonModifiers: UInt32(cmdKey | optionKey | controlKey | shiftKey))
        #expect(hotkey.displayString == "⌃⌥⇧⌘↩")
        #expect(Hotkey(keyCode: UInt32(kVK_F5), carbonModifiers: UInt32(controlKey)).displayString == "⌃F5")
    }

    @Test func keyboardShortcutExistsForCharacterKeysOnly() {
        #expect(Hotkey.default.keyboardShortcut != nil)
        #expect(Hotkey(keyCode: UInt32(kVK_F5), carbonModifiers: UInt32(cmdKey)).keyboardShortcut == nil)
    }

    @Test func roundTripsThroughJSON() throws {
        let original = Hotkey(keyCode: 40, carbonModifiers: UInt32(cmdKey | optionKey))
        let decoded = try JSONDecoder().decode(Hotkey.self, from: JSONEncoder().encode(original))
        #expect(decoded == original)
    }
}
