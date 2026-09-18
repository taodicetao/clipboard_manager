import AppKit
import Carbon

enum PanelCommand: Equatable {
    case moveUp
    case moveDown
    case confirm
    case dismiss
    case deleteSelected
    case select(Int)
    case typeToSearch(String)
}

enum PanelKeyRouter {
    static func command(for event: NSEvent, searchFocused: Bool, searchEmpty: Bool, hasMarkedText: Bool) -> PanelCommand? {
        guard !hasMarkedText else { return nil }
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let characters = event.charactersIgnoringModifiers ?? ""
        let keyCode = Int(event.keyCode)

        if flags == .command {
            if let digit = Int(characters), (1...9).contains(digit), !event.isARepeat {
                return .select(digit - 1)
            }
            if keyCode == kVK_Delete {
                return .deleteSelected
            }
            return nil
        }

        guard flags.isSubset(of: [.function, .numericPad, .shift]) else { return nil }
        switch keyCode {
        case kVK_UpArrow: return .moveUp
        case kVK_DownArrow: return .moveDown
        case kVK_Return, kVK_ANSI_KeypadEnter: return .confirm
        case kVK_Escape: return .dismiss
        case kVK_Delete where searchEmpty: return .deleteSelected
        default: break
        }

        guard !searchFocused,
              !flags.contains(.function),
              !characters.isEmpty,
              characters.unicodeScalars.allSatisfy({ !CharacterSet.controlCharacters.contains($0) }),
              !(searchEmpty && characters.trimmingCharacters(in: .whitespaces).isEmpty) else { return nil }
        return .typeToSearch(characters)
    }
}
