import AppKit
import Carbon
import SwiftUI

struct HotkeyRecorderView: NSViewRepresentable {
    @Binding var hotkey: Hotkey
    let validate: (Hotkey) -> Bool
    let onRecordingChanged: (Bool) -> Void

    func makeNSView(context: Context) -> HotkeyRecorderField {
        HotkeyRecorderField()
    }

    func updateNSView(_ field: HotkeyRecorderField, context: Context) {
        field.hotkey = hotkey
        field.onChange = { hotkey = $0 }
        field.validate = validate
        field.onRecordingChanged = onRecordingChanged
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: HotkeyRecorderField, context: Context) -> CGSize? {
        nsView.intrinsicContentSize
    }
}

final class HotkeyRecorderField: NSView {
    var hotkey = Hotkey.default {
        didSet { refresh() }
    }
    var onChange: ((Hotkey) -> Void)?
    var validate: ((Hotkey) -> Bool)?
    var onRecordingChanged: ((Bool) -> Void)?

    private static let size = NSSize(width: 160, height: 24)

    private let label = NSTextField(labelWithString: "")
    private let resetButton = NSButton()
    private var previewModifiers: NSEvent.ModifierFlags = []
    private var rejectionMessage: String?
    private var isArmed = false
    private var windowObservers: [NSObjectProtocol] = []
    private var isRecording = false {
        didSet {
            guard isRecording != oldValue else { return }
            refresh()
            onRecordingChanged?(isRecording)
        }
    }

    init() {
        super.init(frame: NSRect(origin: .zero, size: Self.size))
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.borderWidth = 1
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel("Keyboard shortcut")

        label.alignment = .center
        label.font = .systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false

        resetButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Reset shortcut")
        resetButton.imagePosition = .imageOnly
        resetButton.isBordered = false
        resetButton.contentTintColor = .secondaryLabelColor
        resetButton.target = self
        resetButton.action = #selector(resetToDefault)
        resetButton.translatesAutoresizingMaskIntoConstraints = false

        addSubview(label)
        addSubview(resetButton)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            resetButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            resetButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            resetButton.widthAnchor.constraint(equalToConstant: 14),
            resetButton.heightAnchor.constraint(equalToConstant: 14),
        ])
        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("HotkeyRecorderField does not support NSCoder")
    }

    deinit {
        windowObservers.forEach(NotificationCenter.default.removeObserver)
    }

    override var intrinsicContentSize: NSSize {
        Self.size
    }

    override var acceptsFirstResponder: Bool {
        isArmed
    }

    override func mouseDown(with event: NSEvent) {
        startRecording()
    }

    override func accessibilityPerformPress() -> Bool {
        startRecording()
        return true
    }

    override func becomeFirstResponder() -> Bool {
        guard isArmed else { return false }
        rejectionMessage = nil
        isRecording = true
        return true
    }

    override func resignFirstResponder() -> Bool {
        isArmed = false
        isRecording = false
        previewModifiers = []
        rejectionMessage = nil
        return true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        windowObservers.forEach(NotificationCenter.default.removeObserver)
        windowObservers = []
        guard let window else { return }
        for name in [NSWindow.didResignKeyNotification, NSWindow.willCloseNotification] {
            let observer = NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
                self?.endRecording()
            }
            windowObservers.append(observer)
        }
    }

    override func flagsChanged(with event: NSEvent) {
        previewModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if !previewModifiers.isEmpty {
            rejectionMessage = nil
        }
        refresh()
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard isRecording else { return super.performKeyEquivalent(with: event) }
        handle(event)
        return true
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        handle(event)
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        refresh()
    }

    private func handle(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        switch Int(event.keyCode) {
        case kVK_Escape:
            endRecording()
        case kVK_Delete where flags.isEmpty:
            commit(.default)
        default:
            guard let recorded = Hotkey(event: event) else {
                reject("Add ⌘, ⌥ or ⌃")
                return
            }
            guard validate?(recorded) ?? true else {
                reject("Already in use")
                return
            }
            commit(recorded)
        }
    }

    private func startRecording() {
        isArmed = true
        window?.makeFirstResponder(self)
    }

    private func reject(_ message: String) {
        NSSound.beep()
        rejectionMessage = message
        refresh()
    }

    @objc private func resetToDefault() {
        commit(.default)
    }

    private func commit(_ hotkey: Hotkey) {
        self.hotkey = hotkey
        onChange?(hotkey)
        endRecording()
    }

    private func endRecording() {
        if window?.firstResponder === self {
            window?.makeFirstResponder(nil)
        }
        isArmed = false
        isRecording = false
    }

    private func refresh() {
        if let rejectionMessage, isRecording {
            label.stringValue = rejectionMessage
            label.textColor = .systemRed
        } else if isRecording {
            let preview = Hotkey.modifierSymbols(for: previewModifiers)
            label.stringValue = preview.isEmpty ? "Type shortcut" : preview
            label.textColor = preview.isEmpty ? .secondaryLabelColor : .labelColor
        } else {
            label.stringValue = hotkey.displayString
            label.textColor = .labelColor
        }
        resetButton.isHidden = isRecording || hotkey == .default
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.borderColor = (isRecording ? NSColor.controlAccentColor : NSColor.separatorColor).cgColor
    }
}
