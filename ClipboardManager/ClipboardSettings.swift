// ClipboardSettings.swift
import Foundation
import SwiftUI

class ClipboardSettings: ObservableObject {
    @AppStorage("maxItems") var maxItems: Int = 50
    @AppStorage("pollingInterval") var pollingInterval: Double = 0.5
    @AppStorage("showImages") var showImages: Bool = true
    @AppStorage("showNotifications") var showNotifications: Bool = false
    @AppStorage("autoStart") var autoStart: Bool = false
    
    func resetToDefaults() {
        maxItems = 50
        pollingInterval = 0.5
        showImages = true
        showNotifications = false
        autoStart = false
        
        // แจ้งว่า settings เปลี่ยน
        NotificationCenter.default.post(name: .settingsChanged, object: nil)
    }
}
