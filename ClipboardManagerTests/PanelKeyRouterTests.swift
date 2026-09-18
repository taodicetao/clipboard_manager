import AppKit
import Carbon
import Testing
@testable import ClipboardManager

@Suite struct PanelKeyRouterTests {
    private func route(_ event: NSEvent, searchFocused: Bool = true, searchEmpty: Bool = true, hasMarkedText: Bool = false) -> PanelCommand? {
        PanelKeyRouter.command(for: event, searchFocused: searchFocused, searchEmpty: searchEmpty, hasMarkedText: hasMarkedText)
    }

    @Test func arrowKeysNavigate() {
        #expect(route(keyEvent(kVK_UpArrow, flags: [.function, .numericPad])) == .moveUp)
        #expect(route(keyEvent(kVK_DownArrow, flags: [.function, .numericPad])) == .moveDown)
    }

    @Test func returnConfirmsAndEscapeDismisses() {
        #expect(route(keyEvent(kVK_Return, characters: "\r")) == .confirm)
        #expect(route(keyEvent(kVK_ANSI_KeypadEnter, characters: "\u{3}", flags: .numericPad)) == .confirm)
        #expect(route(keyEvent(kVK_Escape, characters: "\u{1B}")) == .dismiss)
    }

    @Test func commandDigitsSelectItemsOneToNine() {
        for digit in 1...9 {
            let event = keyEvent(kVK_ANSI_1, characters: "\(digit)", flags: .command)
            #expect(route(event) == .select(digit - 1))
        }
        #expect(route(keyEvent(kVK_ANSI_0, characters: "0", flags: .command)) == nil)
    }

    @Test func repeatedCommandDigitIsIgnored() {
        #expect(route(keyEvent(kVK_ANSI_1, characters: "1", flags: .command, isRepeat: true)) == nil)
    }

    @Test func deleteRemovesSelectionOnlyWhenSearchIsEmpty() {
        #expect(route(keyEvent(kVK_Delete, characters: "\u{7F}"), searchEmpty: true) == .deleteSelected)
        #expect(route(keyEvent(kVK_Delete, characters: "\u{7F}"), searchEmpty: false) == nil)
        #expect(route(keyEvent(kVK_Delete, characters: "\u{7F}", flags: .command), searchEmpty: false) == .deleteSelected)
    }

    @Test func typingWhileSearchUnfocusedStartsSearch() {
        #expect(route(keyEvent(kVK_ANSI_A, characters: "a"), searchFocused: false) == .typeToSearch("a"))
        #expect(route(keyEvent(kVK_ANSI_A, characters: "A", flags: .shift), searchFocused: false) == .typeToSearch("A"))
        #expect(route(keyEvent(kVK_ANSI_A, characters: "a"), searchFocused: true) == nil)
    }

    @Test func leadingWhitespaceDoesNotStartSearch() {
        #expect(route(keyEvent(kVK_Space, characters: " "), searchFocused: false, searchEmpty: true) == nil)
        #expect(route(keyEvent(kVK_Space, characters: " "), searchFocused: false, searchEmpty: false) == .typeToSearch(" "))
    }

    @Test func otherCommandShortcutsPassThrough() {
        #expect(route(keyEvent(kVK_ANSI_C, characters: "c", flags: .command)) == nil)
        #expect(route(keyEvent(kVK_ANSI_A, characters: "a", flags: [.command, .shift])) == nil)
    }

    @Test func inputMethodCompositionPassesThrough() {
        #expect(route(keyEvent(kVK_Return, characters: "\r"), hasMarkedText: true) == nil)
    }
}
