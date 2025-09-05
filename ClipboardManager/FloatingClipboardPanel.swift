import SwiftUI
import AppKit
import Combine

// สร้าง state class ที่ observe PasteboardService
final class QuickSelectState: ObservableObject {
    @Published var selectedIndex = 0
    @Published var searchText = ""
    @Published var clipboardItems: [ClipboardItem] = []
    
    private let pasteboardService = PasteboardService.shared
    private var cancellables = Set<AnyCancellable>()
    private var observers: [NSObjectProtocol] = [] // เก็บ observers
    
    init() {
        clipboardItems = pasteboardService.clipboardItems
        print("📱 QuickSelectState init with \(clipboardItems.count) items")
        
        setupNotifications()
    }
    
    private func setupNotifications() {
        // ใช้ addObserver แทน Combine
        let newItemObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("newClipboardItem"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            print("📋 Received new clipboard item notification")
            self?.updateClipboardItems()
        }
        
        let clearAllObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("clearAllClipboard"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            print("🗑️ Received clear all notification")
            self?.handleClearAll()
        }
        
        observers.append(newItemObserver)
        observers.append(clearAllObserver)
        
        print("✅ Notifications setup completed")
    }
    
    private func updateClipboardItems() {
        let oldCount = clipboardItems.count
        clipboardItems = pasteboardService.clipboardItems
        let newCount = clipboardItems.count
        
        print("📋 Items updated: \(oldCount) → \(newCount)")
        
        if selectedIndex >= clipboardItems.count && !clipboardItems.isEmpty {
            selectedIndex = 0
        } else if clipboardItems.isEmpty {
            selectedIndex = 0
        }
    }
    
    private func handleClearAll() {
        print("🗑️ Handling clear all in state")
        
        clipboardItems.removeAll()
        selectedIndex = 0
        searchText = ""
        
        print("✅ State cleared: \(clipboardItems.count) items")
    }
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return Array(clipboardItems.prefix(10))
        } else {
            return clipboardItems.filter {
                $0.content.localizedCaseInsensitiveContains(searchText)
            }.prefix(10).map { $0 }
        }
    }
    
    func navigateUp() {
        if selectedIndex > 0 {
            selectedIndex -= 1
        }
    }
    
    func navigateDown() {
        if selectedIndex < filteredItems.count - 1 {
            selectedIndex += 1
        }
    }
    
    func selectCurrent(onItemSelected: (ClipboardItem) -> Void) {
        if !filteredItems.isEmpty && selectedIndex < filteredItems.count {
            let selectedItem = filteredItems[selectedIndex]
            onItemSelected(selectedItem)
        }
    }
    
    // สำคัญ: cleanup observers
    deinit {
        print("🗑️ QuickSelectState deinit - cleaning up observers")
        
        // ลบ observers ทั้งหมด
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
        
        // Cancel combine subscriptions
        cancellables.removeAll()
    }
}

class FloatingClipboardPanel: NSPanel {
    private var hostingView: NSHostingView<QuickSelectView>?
    private let pasteboardService = PasteboardService.shared
    private var initialLocation: NSPoint = .zero
    private var viewState: QuickSelectState?
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.borderless, .nonactivatingPanel], backing: backingStoreType, defer: flag)
        
        setupPanel()
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    private func setupPanel() {
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        acceptsMouseMovedEvents = true
        
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // สร้าง state object
        let state = QuickSelectState()
        self.viewState = state
        
        // สร้าง view กับ state
        let quickSelectView = QuickSelectView(
            state: state,
            onItemSelected: { [weak self] item in
                print("🎯 Item selected: \(item.content.prefix(50))")
                self?.handleItemSelection(item)
            },
            onCancel: { [weak self] in
                print("🚪 Cancel requested")
                self?.hide()
            }
        )
        
        hostingView = NSHostingView(rootView: quickSelectView)
        contentView = hostingView
        
        // Calculate dynamic height
        let itemCount = pasteboardService.clipboardItems.count
        let maxVisibleItems = 8
        let visibleItems = min(itemCount, maxVisibleItems)
        let itemHeight: CGFloat = 50
        let headerHeight: CGFloat = 100
        let footerHeight: CGFloat = 30
        
        let calculatedHeight = headerHeight + (CGFloat(visibleItems) * itemHeight) + footerHeight
        let finalHeight = max(200, min(500, calculatedHeight))
        
        setContentSize(NSSize(width: 400, height: finalHeight))
    }
    
    // Handle mouse events for smooth dragging
    override func mouseDown(with event: NSEvent) {
        initialLocation = event.locationInWindow
    }
    
    override func mouseDragged(with event: NSEvent) {
        let currentLocation = event.locationInWindow
        let newOrigin = NSPoint(
            x: frame.origin.x + (currentLocation.x - initialLocation.x),
            y: frame.origin.y + (currentLocation.y - initialLocation.y)
        )
        
        setFrameOrigin(newOrigin)
    }
    
    // Handle key events
    override func keyDown(with event: NSEvent) {
        print("🔑 Key pressed: \(event.keyCode)")
        
        switch event.keyCode {
        case 53: // Escape
            print("🔑 Escape key pressed")
            hide()
            
        case 126: // Up arrow
            print("🔑 Up arrow pressed")
            viewState?.navigateUp()
            
        case 125: // Down arrow
            print("🔑 Down arrow pressed")
            viewState?.navigateDown()
            
        case 36: // Return/Enter
            print("🔑 Enter pressed")
            viewState?.selectCurrent { [weak self] item in
                self?.handleItemSelection(item)
            }
            
        default:
            print("🔑 Other key: \(event.keyCode)")
            super.keyDown(with: event)
        }
    }
    
    override func cancelOperation(_ sender: Any?) {
        print("🔑 Cancel operation called")
        hide()
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        print("🔑 performKeyEquivalent: \(event.keyCode)")
        
        switch event.keyCode {
        case 53: // Escape
            hide()
            return true
        case 126: // Up
            viewState?.navigateUp()
            return true
        case 125: // Down
            viewState?.navigateDown()
            return true
        case 36: // Enter
            viewState?.selectCurrent { [weak self] item in
                self?.handleItemSelection(item)
            }
            return true
        default:
            return super.performKeyEquivalent(with: event)
        }
    }
    
    func showAtBestPosition() {
        let position = CursorPositionManager.shared.getCurrentBestPosition()
        showAt(position: position)
    }
    
    private func showAt(position: CGPoint) {
        let panelSize = frame.size
        
        let cursorScreen = NSScreen.screens.first { screen in
            NSPointInRect(position, screen.frame)
        } ?? NSScreen.main ?? NSScreen.screens[0]
        
        let screenFrame = cursorScreen.visibleFrame
        var adjustedPosition = position
        
        if position.x + panelSize.width > screenFrame.maxX {
            adjustedPosition.x = screenFrame.maxX - panelSize.width - 10
        }
        if adjustedPosition.x < screenFrame.minX {
            adjustedPosition.x = screenFrame.minX + 10
        }
        
        let topPosition = position.y + 20
        let bottomPosition = position.y - panelSize.height - 10
        
        if topPosition + panelSize.height <= screenFrame.maxY {
            adjustedPosition.y = topPosition
        } else if bottomPosition >= screenFrame.minY {
            adjustedPosition.y = bottomPosition
        } else {
            if position.y > screenFrame.midY {
                adjustedPosition.y = screenFrame.minY + 20
            } else {
                adjustedPosition.y = screenFrame.maxY - panelSize.height - 20
            }
        }
        
        setFrameOrigin(adjustedPosition)
        
        alphaValue = 0.0
        makeKeyAndOrderFront(nil)
        makeFirstResponder(self)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            animator().alphaValue = 1.0
        }
        
        print("🎯 Panel shown at: \(adjustedPosition)")
        print("📋 Available items: \(pasteboardService.clipboardItems.count)")
    }
    
    func hide() {
        print("🚪 Hiding panel")
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            animator().alphaValue = 0.0
        }) {
            self.orderOut(nil)
            
            // Clean up state เมื่อ hide
            self.viewState = nil
            self.hostingView = nil
        }
    }
    
    deinit {
        print("🗑️ FloatingClipboardPanel deinit")
        viewState = nil
        hostingView = nil
    }
    
    private func handleItemSelection(_ item: ClipboardItem) {
        print("📋 Handling item selection: \(item.content.prefix(50))")
        
        pasteboardService.copyToClipboard(item)
        print("📋 Item copied to clipboard")
        
        hide()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            print("⌨️ Simulating paste...")
            self.simulatePaste()
        }
    }
    
    private func simulatePaste() {
        print("⌨️ Creating paste event...")
        
        let source = CGEventSource(stateID: .hidSystemState)
        
        let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        keyDownEvent?.flags = .maskCommand
        
        let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUpEvent?.flags = .maskCommand
        
        keyDownEvent?.post(tap: .cghidEventTap)
        keyUpEvent?.post(tap: .cghidEventTap)
        
        print("⌨️ Paste events posted")
    }
}
