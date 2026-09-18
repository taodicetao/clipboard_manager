import AppKit
import Foundation
@testable import ClipboardManager

struct TestEnvironment {
    let settings: AppSettings
    let store: HistoryStore
    let pasteboard: NSPasteboard
    let service: PasteboardService
    let directory: URL
    private let suiteName: String

    init() {
        suiteName = "ClipboardManagerTests.\(UUID().uuidString)"
        settings = AppSettings(defaults: UserDefaults(suiteName: suiteName)!)
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(suiteName, isDirectory: true)
        store = HistoryStore(directory: directory)
        pasteboard = NSPasteboard(name: NSPasteboard.Name(suiteName))
        service = PasteboardService(settings: settings, store: store, pasteboard: pasteboard)
    }

    func copyText(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        service.checkForChanges()
    }

    func copyImage(_ image: NSImage) {
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
        service.checkForChanges()
    }

    func copyFiles(_ paths: [String]) {
        pasteboard.clearContents()
        pasteboard.writeObjects(paths.map { URL(fileURLWithPath: $0) as NSURL })
        service.checkForChanges()
    }

    func tearDown() {
        pasteboard.releaseGlobally()
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        try? FileManager.default.removeItem(at: directory)
    }
}

func makeImage(color: NSColor, size: NSSize = NSSize(width: 24, height: 16)) -> NSImage {
    NSImage(size: size, flipped: false) { rect in
        color.setFill()
        rect.fill()
        return true
    }
}

func keyEvent(_ keyCode: Int, characters: String = "", flags: NSEvent.ModifierFlags = [], isRepeat: Bool = false) -> NSEvent {
    NSEvent.keyEvent(
        with: .keyDown,
        location: .zero,
        modifierFlags: flags,
        timestamp: 0,
        windowNumber: 0,
        context: nil,
        characters: characters,
        charactersIgnoringModifiers: characters,
        isARepeat: isRepeat,
        keyCode: UInt16(keyCode)
    )!
}
