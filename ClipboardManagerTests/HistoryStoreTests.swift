import AppKit
import Testing
@testable import ClipboardManager

@Suite struct HistoryStoreTests {
    private func makeStore() -> (HistoryStore, URL) {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("HistoryStoreTests.\(UUID().uuidString)", isDirectory: true)
        return (HistoryStore(directory: directory), directory)
    }

    @Test func roundTripsTextImageAndFileItems() throws {
        let (store, directory) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let text = ClipboardItem(kind: .text, content: "hello", sourceBundleIdentifier: "com.example.editor")
        let image = ClipboardItem(kind: .image, content: "Image 24×16", image: makeImage(color: .red), imageDigest: "digest", sourceBundleIdentifier: nil)
        let file = ClipboardItem(kind: .file, content: "hosts", fileURLs: [URL(fileURLWithPath: "/etc/hosts")], sourceBundleIdentifier: "com.apple.finder")

        store.save([text, image, file])
        store.flush()

        let loaded = store.load()
        #expect(loaded.map(\.id) == [text.id, image.id, file.id])
        #expect(loaded[0].content == "hello")
        #expect(loaded[0].sourceBundleIdentifier == "com.example.editor")
        #expect(loaded[1].image != nil)
        #expect(loaded[1].imageDigest == "digest")
        #expect(loaded[2].fileURLs == [URL(fileURLWithPath: "/etc/hosts")])
        #expect(FileManager.default.fileExists(atPath: directory.appendingPathComponent("images/\(image.id.uuidString).png").path))
    }

    @Test func removesOrphanedImagesOnSave() throws {
        let (store, directory) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let image = ClipboardItem(kind: .image, content: "Image", image: makeImage(color: .blue), imageDigest: "d", sourceBundleIdentifier: nil)
        store.save([image])
        store.flush()
        store.save([])
        store.flush()
        let remaining = try FileManager.default.contentsOfDirectory(atPath: directory.appendingPathComponent("images").path)
        #expect(remaining.isEmpty)
        #expect(store.load().isEmpty)
    }

    @Test func deleteAllRemovesTheDirectory() {
        let (store, directory) = makeStore()
        store.save([ClipboardItem(kind: .text, content: "x", sourceBundleIdentifier: nil)])
        store.flush()
        store.deleteAll()
        store.flush()
        #expect(!FileManager.default.fileExists(atPath: directory.path))
    }

    @Test func corruptHistoryLoadsEmpty() throws {
        let (store, directory) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: directory.appendingPathComponent("history.json"))
        #expect(store.load().isEmpty)
    }

    @Test func imageItemsWithMissingFilesAreSkipped() throws {
        let (store, directory) = makeStore()
        defer { try? FileManager.default.removeItem(at: directory) }
        let image = ClipboardItem(kind: .image, content: "Image", image: makeImage(color: .green), imageDigest: "d", sourceBundleIdentifier: nil)
        let text = ClipboardItem(kind: .text, content: "kept", sourceBundleIdentifier: nil)
        store.save([image, text])
        store.flush()
        try FileManager.default.removeItem(at: directory.appendingPathComponent("images/\(image.id.uuidString).png"))
        #expect(store.load().map(\.content) == ["kept"])
    }
}
