import Foundation
import Carbon
import AppKit

class GlobalHotkeyManager {
    static let shared = GlobalHotkeyManager()
    
    private var hotkeyID: EventHotKeyID?
    private var eventHandler: EventHandlerRef?
    private var hotkeyRef: EventHotKeyRef?
    
    var onHotkeyPressed: (() -> Void)?
    
    private init() {}
    
    func registerHotkey() {
        // Unregister existing hotkey first
        unregisterHotkey()
        
        // Setup hotkey: Cmd+;
        let hotkeyIDValue = 1
        hotkeyID = EventHotKeyID(signature: OSType(hotkeyIDValue), id: UInt32(hotkeyIDValue))
        
        // Key code for semicolon (;) = 0x29
        let keyCode: UInt32 = 0x29
        let modifiers: UInt32 = UInt32(cmdKey)
        
        // Install event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                     eventKind: OSType(kEventHotKeyPressed))
        
        InstallEventHandler(GetApplicationEventTarget(),
                          hotkeyHandler,
                          1,
                          &eventType,
                          Unmanaged.passUnretained(self).toOpaque(),
                          &eventHandler)
        
        // Register the hotkey
        RegisterEventHotKey(keyCode,
                          modifiers,
                          hotkeyID!,
                          GetApplicationEventTarget(),
                          0,
                          &hotkeyRef)
        
        print("🔥 Global hotkey registered: Cmd+;")
    }
    
    func unregisterHotkey() {
        if let hotkeyRef = hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
        }
        
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
    
    deinit {
        unregisterHotkey()
    }
}

// C callback function
private func hotkeyHandler(nextHandler: EventHandlerCallRef?,
                          event: EventRef?,
                          userData: UnsafeMutableRawPointer?) -> OSStatus {
    
    if let userData = userData {
        let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
        
        DispatchQueue.main.async {
            manager.onHotkeyPressed?()
        }
    }
    
    return noErr
}//
//  GlobalHotkeyManager.swift
//  ClipboardManager
//
//  Created by Apirat Parnthong on 4/9/2568 BE.
//

