// ClipboardManagerApp.swift
import SwiftUI

@main
struct ClipboardManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var pasteboardService = PasteboardService.shared
    private let hotkeyManager = GlobalHotkeyManager.shared
    private var floatingPanel: FloatingClipboardPanel?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // ขั้นตอน 1: ตั้งเป็น background app
        NSApp.setActivationPolicy(.accessory)
        
        // ขั้นตอน 2: สร้าง status bar แบบ simple
        DispatchQueue.main.async {
            self.createStatusBar()
        }
        
        // ขั้นตอน 3: Setup อื่นๆ
        setupGlobalHotkey()
        requestAccessibilityPermissions()
        
        // ขั้นตอน 4: ปิด windows
        for window in NSApp.windows {
            window.close()
        }
        
        print("🚀 Clipboard Manager ready")
    }
    
    private func createStatusBar() {
        print("🔧 Creating status bar...")
        
        // สร้าง status item แบบ standard
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        guard let button = statusItem?.button else {
            print("❌ Failed to create status bar button")
            return
        }
        
        // ตั้ง icon
        if let image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard Manager") {
            image.size = NSSize(width: 18, height: 18)
            image.isTemplate = true
            button.image = image
            print("✅ Status bar icon set")
        } else {
            button.title = "📋"
            print("✅ Status bar text set")
        }
        
        button.toolTip = "Clipboard Manager"
        
        // สร้าง menu
        let menu = NSMenu()
        menu.addItem(withTitle: "📋 Open Clipboard (Cmd+;)", action: #selector(openClipboard), keyEquivalent: ";")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "🗑️ Clear All History", action: #selector(clearAllHistory), keyEquivalent: "")
        menu.addItem(withTitle: "ℹ️ About", action: #selector(showAbout), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "⚡ Quit", action: #selector(quitApplication), keyEquivalent: "q")
        
        // ตั้ง target สำหรับทุก menu item
        for item in menu.items {
            item.target = self
        }
        
        // กำหนด key modifiers
        menu.item(withTitle: "📋 Open Clipboard (Cmd+;)")?.keyEquivalentModifierMask = .command
        menu.item(withTitle: "⚡ Quit")?.keyEquivalentModifierMask = .command
        
        // กำหนด menu ให้ status item
        statusItem?.menu = menu
        
        print("✅ Status bar created successfully")
        
        // Debug info
        print("   - Status bar length: \(statusItem?.length ?? 0)")
        print("   - Button frame: \(button.frame)")
        print("   - Menu items: \(menu.items.count)")
    }
    
    // MARK: - Menu Actions
    @objc func openClipboard() {
        floatingPanel?.hide()
        
        floatingPanel = FloatingClipboardPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [],
            backing: .buffered,
            defer: true
        )
        
        floatingPanel?.showAtBestPosition()
    }
    
    private func createAlert(title: String, message: String, style: NSAlert.Style) -> NSAlert {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = style
        
        if let appIcon = NSApp.applicationIconImage {
            // ลองใช้ขนาด 48x48 (ขนาดมาตรฐานของ alert)
            let iconCopy = appIcon.copy() as! NSImage
            iconCopy.size = NSSize(width: 48, height: 48)
            
            // Set icon หลังจาก set style
            alert.icon = iconCopy
            
            // Force set อีกครั้งหลัง delay เล็กน้อย
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                alert.icon = iconCopy
                print("🔄 Force re-applied icon")
            }
            
            print("✅ Alert icon applied (48x48)")
        }
        
        return alert
    }
    
    @objc func clearAllHistory() {
        let itemCount = pasteboardService.clipboardItems.count
        print("🗑️ Clear all requested for \(itemCount) items")
        
        // เปลี่ยนจาก .warning เป็น .informational
        let alert = createAlert(
            title: "Clear All Clipboard History?",
            message: "This will permanently delete all \(itemCount) clipboard items.",
            style: .informational  // <-- เปลี่ยนตรงนี้
        )
        
        alert.addButton(withTitle: "Clear All")
        alert.addButton(withTitle: "Cancel")
        
        // ทำให้ปุ่ม Clear All เป็นสี destructive
        if let clearButton = alert.buttons.first {
            clearButton.hasDestructiveAction = true
        }
        
        print("🚨 About to show informational alert with icon")
        
        if alert.runModal() == .alertFirstButtonReturn {
            print("🗑️ User confirmed clear all")
            pasteboardService.clearAll()
        }
    }
    
    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Clipboard Manager v1.0"
        alert.informativeText = "Simple clipboard manager for macOS\n\n• Cmd+; to open\n• Stores 10 items\n• Works across all screens"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc func quitApplication() {
        NSApp.terminate(self)
    }
    
    // MARK: - Setup
    private func setupGlobalHotkey() {
        hotkeyManager.onHotkeyPressed = { [weak self] in
            self?.openClipboard()
        }
        hotkeyManager.registerHotkey()
    }
    
    private func requestAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options)
    }
    
    // MARK: - App Lifecycle
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        return .terminateNow
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.unregisterHotkey()
    }
}
