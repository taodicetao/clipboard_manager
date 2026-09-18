import AppKit
import os

final class HistoryStore {
    private struct StoredHistory: Codable {
        var version: Int
        var items: [StoredItem]
    }

    private struct StoredItem: Codable {
        var id: UUID
        var kind: ClipboardItem.Kind
        var content: String
        var fileURLs: [String]
        var imageDigest: String?
        var sourceBundleIdentifier: String?
        var createdAt: Date

        init(_ item: ClipboardItem) {
            id = item.id
            kind = item.kind
            content = item.content
            fileURLs = item.fileURLs.map(\.path)
            imageDigest = item.imageDigest
            sourceBundleIdentifier = item.sourceBundleIdentifier
            createdAt = item.createdAt
        }
    }

    static let defaultDirectory: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent(Bundle.main.bundleIdentifier ?? "ClipboardManager", isDirectory: true)
    }()

    private static let currentVersion = 1
    private static let saveDelay: TimeInterval = 0.5

    private let directory: URL
    private let queue = DispatchQueue(label: "ClipboardManager.HistoryStore")
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ClipboardManager", category: "HistoryStore")
    private var pendingItems: [ClipboardItem] = []
    private var pendingSave: DispatchWorkItem?

    init(directory: URL = HistoryStore.defaultDirectory) {
        self.directory = directory
    }

    func load() -> [ClipboardItem] {
        guard let data = try? Data(contentsOf: historyURL) else { return [] }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(StoredHistory.self, from: data).items.compactMap(restore)
        } catch {
            logger.error("Failed to load history: \(error.localizedDescription)")
            return []
        }
    }

    func save(_ items: [ClipboardItem]) {
        pendingItems = items
        pendingSave?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.writePending() }
        pendingSave = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.saveDelay, execute: work)
    }

    func flush() {
        if pendingSave != nil {
            pendingSave?.cancel()
            writePending()
        }
        queue.sync {}
    }

    func deleteAll() {
        pendingSave?.cancel()
        pendingSave = nil
        let directory = self.directory
        queue.async {
            try? FileManager.default.removeItem(at: directory)
        }
    }

    private var historyURL: URL {
        directory.appendingPathComponent("history.json")
    }

    private var imagesDirectory: URL {
        directory.appendingPathComponent("images", isDirectory: true)
    }

    private func imageURL(for id: UUID) -> URL {
        imagesDirectory.appendingPathComponent("\(id.uuidString).png")
    }

    private func restore(_ record: StoredItem) -> ClipboardItem? {
        var image: NSImage?
        if record.kind == .image {
            guard let loaded = NSImage(contentsOf: imageURL(for: record.id)) else { return nil }
            image = loaded
        }
        return ClipboardItem(
            id: record.id,
            kind: record.kind,
            content: record.content,
            image: image,
            fileURLs: record.fileURLs.map { URL(fileURLWithPath: $0) },
            imageDigest: record.imageDigest,
            sourceBundleIdentifier: record.sourceBundleIdentifier,
            createdAt: record.createdAt
        )
    }

    private func writePending() {
        pendingSave = nil
        let items = pendingItems
        let records = items.map(StoredItem.init)
        let images = items.compactMap { item in item.image.map { (item.id, $0) } }
        queue.async { [self] in
            write(records, images: images)
        }
    }

    private func write(_ records: [StoredItem], images: [(UUID, NSImage)]) {
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            for (id, image) in images where !fileManager.fileExists(atPath: imageURL(for: id).path) {
                guard let png = image.pngData else { continue }
                try png.write(to: imageURL(for: id), options: .atomic)
            }
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(StoredHistory(version: Self.currentVersion, items: records)).write(to: historyURL, options: .atomic)
            let keep = Set(images.map { "\($0.0.uuidString).png" })
            for file in try fileManager.contentsOfDirectory(atPath: imagesDirectory.path) where !keep.contains(file) {
                try? fileManager.removeItem(at: imagesDirectory.appendingPathComponent(file))
            }
        } catch {
            logger.error("Failed to save history: \(error.localizedDescription)")
        }
    }
}

private extension NSImage {
    var pngData: Data? {
        guard let tiff = tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
