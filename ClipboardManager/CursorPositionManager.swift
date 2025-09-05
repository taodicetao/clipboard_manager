import Foundation
import AppKit
import Carbon

class CursorPositionManager {
    static let shared = CursorPositionManager()
    
    private var lastKnownTextCursorPosition: CGPoint?
    private var lastUpdateTime: Date?
    
    // Accessibility constants as CFString
    private static let kAXFocusedUIElement = kAXFocusedUIElementAttribute as CFString
    private static let kAXSelectedTextRange = kAXSelectedTextRangeAttribute as CFString
    private static let kAXBoundsForRange = kAXBoundsForRangeParameterizedAttribute as CFString
    private static let kAXInsertionPointLineNumber = kAXInsertionPointLineNumberAttribute as CFString
    
    private init() {
        // Monitor for text cursor changes
        startMonitoring()
    }
    
    private func startMonitoring() {
        // สำหรับ monitor text cursor changes (optional - เพื่อเก็บ last position)
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(applicationDidActivate),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }
    
    @objc private func applicationDidActivate() {
        // Update text cursor position when application changes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateTextCursorPosition()
        }
    }
    
    func getCurrentBestPosition() -> CGPoint {
        // 1. Try to get current text cursor position
        if let textCursorPos = getCurrentTextCursorPosition() {
            lastKnownTextCursorPosition = textCursorPos
            lastUpdateTime = Date()
            return textCursorPos
        }
        
        // 2. Use last known text cursor position (if recent)
        if let lastPos = lastKnownTextCursorPosition,
           let lastUpdate = lastUpdateTime,
           Date().timeIntervalSince(lastUpdate) < 30 { // Within 30 secounds
            return lastPos
        }
        
        // 3. Fallback to mouse cursor position
        let mousePos = NSEvent.mouseLocation
        return mousePos
    }
    
    private func getCurrentTextCursorPosition() -> CGPoint? {
        // Method 1: Try current app's focused text field
        if let appPosition = getCurrentAppTextCursorPosition() {
            return appPosition
        }
        
        // Method 2: Try Accessibility API
        if let accessibilityPosition = getAccessibilityTextCursorPosition() {
            return accessibilityPosition
        }
        
        // Method 3: Try focused window approach
        if let focusedPosition = getFocusedWindowTextCursor() {
            return focusedPosition
        }
        
        return nil
    }
    
    private func getFocusedWindowTextCursor() -> CGPoint? {
        // Get all running applications
        let runningApps = NSWorkspace.shared.runningApplications
        
        for app in runningApps {
            if app.isActive {
                // Try to get cursor position from active app
                if let position = getTextCursorFromApp(app) {
                    return position
                }
            }
        }
        
        return nil
    }
    
    private func getTextCursorFromApp(_ app: NSRunningApplication) -> CGPoint? {
        guard let pid = app.processIdentifier as pid_t? else { return nil }
        
        let appElement = AXUIElementCreateApplication(pid)
        var focusedWindow: CFTypeRef?
        
        let windowResult = AXUIElementCopyAttributeValue(appElement,
                                                        kAXFocusedWindowAttribute as CFString,
                                                        &focusedWindow)
        
        guard windowResult == .success,
              let window = focusedWindow else {
            return nil
        }
        
        // Try to get text cursor from focused window
        return getPositionFromSelectedRange(window as! AXUIElement)
    }
    
    private func getPositionFromSelectedRange(_ element: AXUIElement) -> CGPoint? {
        var selectedTextRange: CFTypeRef?
        let rangeResult = AXUIElementCopyAttributeValue(element,
                                                       Self.kAXSelectedTextRange,
                                                       &selectedTextRange)
        
        guard rangeResult == .success,
              let range = selectedTextRange else {
            return nil
        }
        
        var boundsValue: CFTypeRef?
        let boundsResult = AXUIElementCopyParameterizedAttributeValue(element,
                                                                     Self.kAXBoundsForRange,
                                                                     range,
                                                                     &boundsValue)
        
        guard boundsResult == .success,
              let bounds = boundsValue else {
            return nil
        }
        
        var rect = CGRect.zero
        if AXValueGetValue(bounds as! AXValue, .cgRect, &rect) {
            // Convert screen coordinates (macOS uses bottom-left origin)
            return CGPoint(x: rect.minX, y: NSScreen.main?.frame.height ?? 0 - rect.minY)
        }
        
        return nil
    }
    
    private func getPositionFromInsertionPoint(_ element: AXUIElement) -> CGPoint? {
        // Try to get insertion point line number and work from there
        var insertionPoint: CFTypeRef?
        let insertionResult = AXUIElementCopyAttributeValue(element,
                                                           Self.kAXInsertionPointLineNumber,
                                                           &insertionPoint)
        
        if insertionResult == .success {
            // This approach would need more work to get actual position
            // For now, return nil to try other methods
            return nil
        }
        
        return nil
    }
    
    private func getCurrentAppTextCursorPosition() -> CGPoint? {
        guard let keyWindow = NSApp.keyWindow,
              let firstResponder = keyWindow.firstResponder else {
            return nil
        }
        
        if let textView = firstResponder as? NSTextView {
            return getTextViewCursorPosition(textView)
        } else if let textField = firstResponder as? NSTextField {
            return getTextFieldCursorPosition(textField)
        }
        
        return nil
    }
    
    private func getAccessibilityTextCursorPosition() -> CGPoint? {
        var systemWide: AXUIElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?
        
        let result = AXUIElementCopyAttributeValue(systemWide,
                                                  Self.kAXFocusedUIElement,
                                                  &focusedElement)
        
        guard result == .success,
              let element = focusedElement else {
            return nil
        }
        
        let focusedUIElement = element as! AXUIElement
        
        // Try different approaches to get cursor position
        
        // Approach 1: Selected text range
        if let position = getPositionFromSelectedRange(focusedUIElement) {
            return position
        }
        
        // Approach 2: Insertion point
        if let position = getPositionFromInsertionPoint(focusedUIElement) {
            return position
        }
        
        return nil
    }
    
    private func getFocusedTextFieldCursorPosition() -> CGPoint? {
        // Try to get cursor position from currently focused text field
        guard let app = NSApp.keyWindow,
              let firstResponder = app.firstResponder else {
            return nil
        }
        
        // Check if it's a text view or text field
        if let textView = firstResponder as? NSTextView {
            return getTextViewCursorPosition(textView)
        } else if let textField = firstResponder as? NSTextField {
            return getTextFieldCursorPosition(textField)
        }
        
        return nil
    }
    
    private func getTextViewCursorPosition(_ textView: NSTextView) -> CGPoint? {
        let selectedRange = textView.selectedRange()
        
        guard selectedRange.location != NSNotFound else { return nil }
        
        let rect = textView.firstRect(forCharacterRange: selectedRange, actualRange: nil)
        
        if rect != .zero {
            return CGPoint(x: rect.minX, y: rect.minY)
        }
        
        return nil
    }
    
    private func getTextFieldCursorPosition(_ textField: NSTextField) -> CGPoint? {
        guard let window = textField.window,
              let fieldEditor = window.fieldEditor(true, for: textField) as? NSTextView else {
            return nil
        }
        
        return getTextViewCursorPosition(fieldEditor)
    }
    
    private func updateTextCursorPosition() {
        if let position = getCurrentTextCursorPosition() {
            lastKnownTextCursorPosition = position
            lastUpdateTime = Date()
        }
    }
}
