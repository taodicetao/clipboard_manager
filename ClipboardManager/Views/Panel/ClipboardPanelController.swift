import AppKit
import SwiftUI

final class ClipboardPanelController: NSObject, NSWindowDelegate {
    private static let showDuration: TimeInterval = 0.2
    private static let hideDuration: TimeInterval = 0.15
    private static let pasteDelay: TimeInterval = 0.2

    private let service: PasteboardService
    private let settings: AppSettings
    private let appInfo: AppInfoCache
    private let pasteSimulator: PasteSimulator
    private let state: PanelState
    private var keyMonitor: Any?

    private lazy var panel: ClipboardPanel = {
        let actions = PanelActions(
            select: { [weak self] in self?.select($0) },
            paste: { [weak self] in self?.paste($0) },
            copy: { [weak self] in self?.copy($0) },
            delete: { [weak self] in self?.delete($0) }
        )
        let panel = ClipboardPanel(rootView: PanelView(state: state, settings: settings, appInfo: appInfo, actions: actions))
        panel.delegate = self
        return panel
    }()

    init(service: PasteboardService, settings: AppSettings, appInfo: AppInfoCache, pasteSimulator: PasteSimulator) {
        self.service = service
        self.settings = settings
        self.appInfo = appInfo
        self.pasteSimulator = pasteSimulator
        state = PanelState(service: service)
        super.init()
    }

    func show() {
        state.prepareForPresentation()
        panel.resize(toItemCount: service.clipboardItems.count)
        let origin = PanelPlacement.origin(for: panel.frame.size, position: settings.panelPosition, pointer: NSEvent.mouseLocation)
        panel.setFrameOrigin(origin)
        installKeyMonitor()
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Self.showDuration
            panel.animator().alphaValue = 1
        }
    }

    func hide() {
        removeKeyMonitor()
        let panel = self.panel
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = Self.hideDuration
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
        })
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        hide()
        return false
    }

    private func select(_ item: ClipboardItem) {
        if settings.pasteOnSelect {
            paste(item)
        } else {
            copy(item)
        }
    }

    private func paste(_ item: ClipboardItem) {
        copy(item)
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.pasteDelay) { [pasteSimulator] in
            pasteSimulator.sendPaste()
        }
    }

    private func copy(_ item: ClipboardItem) {
        service.copyToClipboard(item)
        hide()
    }

    private func delete(_ item: ClipboardItem) {
        service.removeItem(item)
        state.clampSelection()
    }

    private func installKeyMonitor() {
        removeKeyMonitor()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window === self.panel else { return event }
            let firstResponder = self.panel.firstResponder as? NSTextView
            let command = PanelKeyRouter.command(
                for: event,
                searchFocused: firstResponder != nil,
                searchEmpty: self.state.searchText.isEmpty,
                hasMarkedText: firstResponder?.hasMarkedText() ?? false
            )
            guard let command else { return event }
            self.handle(command)
            return nil
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
        }
        keyMonitor = nil
    }

    private func handle(_ command: PanelCommand) {
        switch command {
        case .moveUp:
            state.moveUp()
        case .moveDown:
            state.moveDown()
        case .confirm:
            if let item = state.selectedItem {
                select(item)
            }
        case .dismiss:
            if state.searchText.isEmpty {
                hide()
            } else {
                state.searchText = ""
            }
        case .deleteSelected:
            if let item = state.selectedItem {
                delete(item)
            }
        case .select(let index):
            let items = state.filteredItems
            if items.indices.contains(index) {
                select(items[index])
            }
        case .typeToSearch(let text):
            state.searchText += text
            state.isSearchFocused = true
        }
    }
}

private enum PanelPlacement {
    private static let pointerOffset: CGFloat = 20
    private static let edgeMargin: CGFloat = 10

    static func origin(for size: NSSize, position: PanelPosition, pointer: NSPoint) -> NSPoint {
        let screen = NSScreen.screens.first { NSMouseInRect(pointer, $0.frame, false) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return pointer }
        switch position {
        case .screenCenter:
            let top = visible.midY + size.height * 0.25
            return NSPoint(x: visible.midX - size.width / 2, y: top - size.height)
        case .atCursor:
            var x = pointer.x
            x = min(x, visible.maxX - size.width - edgeMargin)
            x = max(x, visible.minX + edgeMargin)
            let above = pointer.y + pointerOffset
            let below = pointer.y - size.height - edgeMargin
            let y: CGFloat
            if above + size.height <= visible.maxY {
                y = above
            } else if below >= visible.minY {
                y = below
            } else {
                y = visible.maxY - size.height - edgeMargin
            }
            return NSPoint(x: x, y: y)
        }
    }
}
