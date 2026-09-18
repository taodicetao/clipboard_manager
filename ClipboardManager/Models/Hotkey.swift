import Carbon

struct Hotkey: Codable, Hashable {
    var keyCode: UInt32
    var carbonModifiers: UInt32

    static let `default` = Hotkey(keyCode: UInt32(kVK_ANSI_Semicolon), carbonModifiers: UInt32(cmdKey))
}
