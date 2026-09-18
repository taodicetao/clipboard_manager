import AppKit
import Carbon
import Observation

@Observable
final class GlobalHotkeyManager {
    private(set) var isRegistered = false
    private(set) var lastRejectedHotkey: Hotkey?
    var isSuspended = false {
        didSet {
            if isSuspended {
                lastRejectedHotkey = nil
            }
            register(settings.hotkey)
        }
    }

    @ObservationIgnored var onHotkeyPressed: (() -> Void)?

    private static let signature: OSType = 0x434C_504D
    private static let modifierMask = UInt32(cmdKey | optionKey | controlKey | shiftKey)

    @ObservationIgnored private let settings: AppSettings
    @ObservationIgnored private var hotkeyRef: EventHotKeyRef?
    @ObservationIgnored private var eventHandler: EventHandlerRef?

    init(settings: AppSettings) {
        self.settings = settings
    }

    func start() {
        guard eventHandler == nil else { return }
        installEventHandler()
        observeChanges({ [settings] in settings.hotkey }) { [weak self] in self?.register($0) }
    }

    deinit {
        unregister()
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }

    func register(_ hotkey: Hotkey) {
        unregister()
        guard !isSuspended else { return }
        var ref: EventHotKeyRef?
        let hotkeyID = EventHotKeyID(signature: Self.signature, id: 1)
        let status = RegisterEventHotKey(hotkey.keyCode, hotkey.carbonModifiers, hotkeyID, GetApplicationEventTarget(), 0, &ref)
        hotkeyRef = ref
        isRegistered = status == noErr
    }

    func isAcceptable(_ hotkey: Hotkey) -> Bool {
        let reserved = Self.isReservedBySystem(hotkey)
        lastRejectedHotkey = reserved ? hotkey : nil
        return !reserved
    }

    func unregister() {
        if let hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
        }
        hotkeyRef = nil
        isRegistered = false
    }

    private static func isReservedBySystem(_ hotkey: Hotkey) -> Bool {
        var array: Unmanaged<CFArray>?
        guard CopySymbolicHotKeys(&array) == noErr,
              let entries = array?.takeRetainedValue() as? [[String: Any]] else { return false }
        return entries.contains { entry in
            entry[kHISymbolicHotKeyEnabled as String] as? Bool == true
                && (entry[kHISymbolicHotKeyCode as String] as? Int).map(UInt32.init) == hotkey.keyCode
                && (entry[kHISymbolicHotKeyModifiers as String] as? Int).map { UInt32($0) & modifierMask } == hotkey.carbonModifiers & modifierMask
        }
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
    }
}

private func hotkeyHandler(nextHandler: EventHandlerCallRef?, event: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus {
    guard let userData else { return noErr }
    let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
    DispatchQueue.main.async {
        manager.onHotkeyPressed?()
    }
    return noErr
}
