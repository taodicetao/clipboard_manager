// ClipboardItem.swift
import Foundation
import AppKit

struct ClipboardItem: Identifiable, Hashable {
    let id: UUID
    let content: String
    let type: ClipboardItemType
    let image: NSImage?
    let urls: [URL]?
    let timestamp: Date
    
    init(id: UUID = UUID(), content: String, type: ClipboardItemType, image: NSImage? = nil, urls: [URL]? = nil, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.type = type
        self.image = image
        self.urls = urls
        self.timestamp = timestamp
    }
    
    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum ClipboardItemType {
    case text
    case image
    case file
}
