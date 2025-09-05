// PasteboardService.swift
import Foundation
import AppKit
import Combine
import SwiftUI

@Observable
final class PasteboardService {
    static let shared = PasteboardService()
    
    private let pasteboard: NSPasteboard = .general
    private var timer: AnyCancellable?
    private var changeCount = -1
    
    var clipboardItems: [ClipboardItem] = []
    
    // ใช้ Settings class แยกแทน @AppStorage ใน @Observable
    private let settings = ClipboardSettings()
    
    // เปลี่ยนจาก computed properties เป็น fixed values
    var maxItems: Int { 20 } // จำกัด 20 รายการ
    var pollingInterval: Double { settings.pollingInterval }
    var showImages: Bool { settings.showImages }
    var showNotifications: Bool { settings.showNotifications }
    
    private init() { // เปลี่ยนเป็น private
        changeCount = pasteboard.changeCount
        setupTimer()
        
        // Listen for notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: .settingsChanged,
            object: nil
        )
        
        checkClipboardChanges()
    }
    
    deinit {
        timer?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupTimer() {
        timer?.cancel()
        
        timer = Timer.publish(every: settings.pollingInterval, on: .current, in: .default)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkClipboardChanges()
            }
    }
    
    @objc private func settingsDidChange() {
        setupTimer()
        
        // ใช้ maxItems ที่เป็น 20 แทนของ settings
        if clipboardItems.count > maxItems {
            clipboardItems = Array(clipboardItems.prefix(maxItems))
        }
    }
    
    private func checkClipboardChanges() {
        guard pasteboard.changeCount != changeCount else { return }
        changeCount = pasteboard.changeCount
        
        // ลองอ่าน text ก่อน
        if let string = pasteboard.string(forType: .string),
           !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addClipboardItem(content: string, type: .text)
            return
        }
        
        // ลองอ่าน image (ถ้าเปิดใช้งาน)
        if settings.showImages {
            if let imageData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff),
               let image = NSImage(data: imageData) {
                let description = "Image (\(Int(image.size.width))×\(Int(image.size.height)))"
                addClipboardItem(content: description, type: .image, image: image)
                return
            }
        }
        
        // ลองอ่าน file URLs
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] {
            let fileNames = urls.map { $0.lastPathComponent }.joined(separator: ", ")
            addClipboardItem(content: "Files: \(fileNames)", type: .file, urls: urls)
            return
        }
    }
    
    private func addClipboardItem(content: String, type: ClipboardItemType, image: NSImage? = nil, urls: [URL]? = nil) {
        // ไม่เพิ่มถ้าเนื้อหาเหมือนกับ item แรก
        if let first = clipboardItems.first, first.content == content {
            return
        }
        
        let newItem = ClipboardItem(
            id: UUID(),
            content: content,
            type: type,
            image: image,
            urls: urls,
            timestamp: Date()
        )
        
        clipboardItems.insert(newItem, at: 0)
        
        // จำกัดจำนวนรายการเป็น 20
        if clipboardItems.count > maxItems {
            clipboardItems = Array(clipboardItems.prefix(maxItems))
        }
        
        // แสดง notification (แบบง่ายๆ)
        if settings.showNotifications {
            showNotification(for: content)
        }
        
        // **สำคัญ: ส่ง notification ทุกครั้งที่มี item ใหม่**
        // ส่ง notification ด้วย error handling
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name("newClipboardItem"),
                object: newItem
            )
            print("📋 New item notification sent")
        }
    }
    
    func copyToClipboard(_ item: ClipboardItem) {
        pasteboard.clearContents()
        
        var success = false
        
        switch item.type {
        case .text:
            success = pasteboard.setString(item.content, forType: .string)
            
        case .image:
            if let image = item.image {
                // ปรับปรุงการ copy image
                success = pasteboard.writeObjects([image])
                print("📸 Image copied to clipboard: \(success)")
            }
            
        case .file:
            if let urls = item.urls {
                success = pasteboard.writeObjects(urls as [NSURL])
            }
        }
        
        if success {
            changeCount = pasteboard.changeCount
            print("✅ Item copied successfully: \(item.type)")
        } else {
            print("❌ Failed to copy item: \(item.type)")
        }
    }
    
    func removeItem(_ item: ClipboardItem) {
        clipboardItems.removeAll { $0.id == item.id }
    }
    
    @objc func clearAllItems() {
        clipboardItems.removeAll()
    }
    
    func clearAll() {
        print("🗑️ Clearing all clipboard items...")
        
        clipboardItems.removeAll()
        print("✅ Clipboard items array cleared")
        
        // ส่ง notification (แต่ตัวเองไม่ listen แล้ว)
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name("clearAllClipboard"),
                object: nil
            )
            print("✅ Clear notification sent")
        }
    }
    
    private func showNotification(for content: String) {
        // ใช้ NSUserNotification (deprecated แต่ยังใช้ได้)
        let notification = NSUserNotification()
        notification.title = "Clipboard Updated"
        notification.informativeText = String(content.prefix(100))
        notification.hasActionButton = false
        
        NSUserNotificationCenter.default.deliver(notification)
        
        // หรือแค่ print สำหรับ debug
        print("📋 Clipboard: \(String(content.prefix(50)))")
    }
    
    // Methods สำหรับอัพเดต settings
    func updateSettings() {
        settingsDidChange()
    }
}
