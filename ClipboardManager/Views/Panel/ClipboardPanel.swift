import AppKit
import SwiftUI

enum PanelMetrics {
    static let width: CGFloat = 420
    static let cornerRadius: CGFloat = 16
    static let headerHeight: CGFloat = 44
    static let searchFieldHeight: CGFloat = 28
    static let searchFieldLeading: CGFloat = 36
    static let rowHeight: CGFloat = 60
    static let rowSpacing: CGFloat = 2
    static let listPadding: CGFloat = 8
    static let footerHeight: CGFloat = 30
    static let emptyStateHeight: CGFloat = 180
    static let maxVisibleRows = 7

    static func height(forItemCount count: Int) -> CGFloat {
        let content: CGFloat
        if count == 0 {
            content = emptyStateHeight
        } else {
            let rows = CGFloat(min(count, maxVisibleRows))
            content = rows * rowHeight + (rows - 1) * rowSpacing + listPadding * 2
        }
        return headerHeight + content + footerHeight
    }
}

final class ClipboardPanel: NSPanel {
    private let backdrop: PanelBackdropView

    init<Content: View>(rootView: Content) {
        let hostingView = NSHostingView(rootView: rootView)
        hostingView.sizingOptions = []
        backdrop = PanelBackdropView(cornerRadius: PanelMetrics.cornerRadius, content: hostingView)
        let size = NSSize(width: PanelMetrics.width, height: PanelMetrics.height(forItemCount: 0))
        super.init(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        isMovableByWindowBackground = true
        title = "Clipboard"
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        titlebarSeparatorStyle = .none
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
        addTitlebarAccessoryViewController(Self.makeTitleBarSpacer(height: PanelMetrics.headerHeight))
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        contentView = backdrop
    }

    private static func makeTitleBarSpacer(height: CGFloat) -> NSTitlebarAccessoryViewController {
        let controller = NSTitlebarAccessoryViewController()
        controller.view = NSView(frame: NSRect(x: 0, y: 0, width: 0, height: height))
        controller.layoutAttribute = .right
        return controller
    }

    override var canBecomeKey: Bool {
        true
    }

    func resize(toItemCount count: Int) {
        setContentSize(NSSize(width: PanelMetrics.width, height: PanelMetrics.height(forItemCount: count)))
        invalidateShadow()
    }
}
