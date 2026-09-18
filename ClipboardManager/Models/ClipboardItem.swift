import AppKit

struct ClipboardItem: Identifiable, Hashable {
    enum Kind: String, Codable {
        case text
        case image
        case file
    }

    let id: UUID
    let kind: Kind
    let content: String
    let image: NSImage?
    let fileURLs: [URL]
    let imageDigest: String?
    let sourceBundleIdentifier: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        kind: Kind,
        content: String,
        image: NSImage? = nil,
        fileURLs: [URL] = [],
        imageDigest: String? = nil,
        sourceBundleIdentifier: String?,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.content = content
        self.image = image
        self.fileURLs = fileURLs
        self.imageDigest = imageDigest
        self.sourceBundleIdentifier = sourceBundleIdentifier
        self.createdAt = createdAt
    }

    func withID(_ id: UUID) -> ClipboardItem {
        ClipboardItem(
            id: id,
            kind: kind,
            content: content,
            image: image,
            fileURLs: fileURLs,
            imageDigest: imageDigest,
            sourceBundleIdentifier: sourceBundleIdentifier,
            createdAt: createdAt
        )
    }

    func hasSameContent(as other: ClipboardItem) -> Bool {
        guard kind == other.kind else { return false }
        switch kind {
        case .text: return content == other.content
        case .file: return fileURLs == other.fileURLs
        case .image: return imageDigest != nil && imageDigest == other.imageDigest
        }
    }

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
