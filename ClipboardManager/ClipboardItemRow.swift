// ClipboardItemRow.swift
import SwiftUI

struct ClipboardItemRow: View {
    let item: ClipboardItem
    let pasteboardService: PasteboardService
    
    var body: some View {
        HStack {
            // Type Icon
            Image(systemName: item.type == .text ? "doc.text" : "photo")
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                // Content
                if item.type == .text {
                    Text(item.content)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                } else {
                    HStack {
                        if let image = item.image {
                            Image(nsImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 40, height: 40)
                                .cornerRadius(4)
                        }
                        Text("รูปภาพ")
                        Spacer()
                    }
                }
                
                // Timestamp
                Text(item.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Actions
            HStack {
                Button("Copy") {
                    pasteboardService.copyToClipboard(item)
                }
                .buttonStyle(.borderless)
                
                Button("Delete") {
                    pasteboardService.removeItem(item)
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button("Copy to Clipboard") {
                pasteboardService.copyToClipboard(item)
            }
            Button("Paste") {
                pasteboardService.copyToClipboard(item)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    simulatePasteInRow()
                }
            }
            Button("Remove", role: .destructive) {
                pasteboardService.removeItem(item)
            }
        }
    }
    
    private func simulatePasteInRow() {
        // จำลอง Cmd+V keystroke
        let source = CGEventSource(stateID: .hidSystemState)
        
        let keyDownEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        keyDownEvent?.flags = .maskCommand
        
        let keyUpEvent = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUpEvent?.flags = .maskCommand
        
        keyDownEvent?.post(tap: .cghidEventTap)
        keyUpEvent?.post(tap: .cghidEventTap)
    }
}

