import AppKit
import Testing
@testable import ClipboardManager

@Suite(.serialized) struct PasteboardServiceTests {
    @Test func capturesTextWithSourceApplication() {
        let env = TestEnvironment()
        defer { env.tearDown() }
        env.copyText("hello")
        #expect(env.service.clipboardItems.count == 1)
        #expect(env.service.clipboardItems.first?.kind == .text)
        #expect(env.service.clipboardItems.first?.content == "hello")
        #expect(env.service.clipboardItems.first?.sourceBundleIdentifier == NSWorkspace.shared.frontmostApplication?.bundleIdentifier)
    }

    @Test func ignoresBlankText() {
        let env = TestEnvironment()
        defer { env.tearDown() }
        env.copyText("   \n")
        #expect(env.service.clipboardItems.isEmpty)
    }

    @Test func copyingExistingContentMovesItToTopKeepingIdentity() {
        let env = TestEnvironment()
        defer { env.tearDown() }
        env.copyText("first")
        let originalID = env.service.clipboardItems[0].id
        env.copyText("second")
        env.copyText("first")
        #expect(env.service.clipboardItems.map(\.content) == ["first", "second"])
        #expect(env.service.clipboardItems[0].id == originalID)
    }

    @Test func skipsConcealedPasswordManagerContent() {
        let env = TestEnvironment()
        defer { env.tearDown() }
        env.pasteboard.declareTypes([.string, NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")], owner: nil)
        env.pasteboard.setString("secret", forType: .string)
        env.service.checkForChanges()
        #expect(env.service.clipboardItems.isEmpty)
    }

    @Test func skipsExcludedApplications() throws {
        let env = TestEnvironment()
        defer { env.tearDown() }
        let frontmost = try #require(NSWorkspace.shared.frontmostApplication?.bundleIdentifier)
        env.settings.excludedBundleIdentifiers = [frontmost]
        env.copyText("excluded")
        #expect(env.service.clipboardItems.isEmpty)
        env.settings.excludedBundleIdentifiers = []
        env.copyText("allowed")
        #expect(env.service.clipboardItems.map(\.content) == ["allowed"])
    }

    @Test func capturesImagesAndDeduplicatesByPixels() {
        let env = TestEnvironment()
        defer { env.tearDown() }
        env.copyImage(makeImage(color: .systemTeal))
        #expect(env.service.clipboardItems.first?.kind == .image)
        #expect(env.service.clipboardItems.first?.imageDigest != nil)
        env.copyImage(makeImage(color: .systemTeal))
        #expect(env.service.clipboardItems.count == 1)
        env.copyImage(makeImage(color: .systemPink))
        #expect(env.service.clipboardItems.count == 2)
    }

    @Test func imageCaptureCanBeDisabled() {
        let env = TestEnvironment()
        defer { env.tearDown() }
        env.settings.captureImages = false
        env.copyImage(makeImage(color: .black))
        #expect(env.service.clipboardItems.isEmpty)
    }

    @Test func capturesFileURLsBeforeTheirTextRepresentation() {
        let env = TestEnvironment()
        defer { env.tearDown() }
        env.copyFiles(["/etc/hosts", "/etc/passwd"])
        #expect(env.service.clipboardItems.first?.kind == .file)
        #expect(env.service.clipboardItems.first?.content == "hosts, passwd")
        #expect(env.service.clipboardItems.first?.fileURLs.count == 2)
    }

    @Test func trimsHistoryToMaxItems() {
        let env = TestEnvironment()
        defer { env.tearDown() }
        env.settings.maxItems = 20
        for index in 0..<25 {
            env.copyText("item \(index)")
        }
        #expect(env.service.clipboardItems.count == 20)
        #expect(env.service.clipboardItems.first?.content == "item 24")
    }

    @Test func writingBackToThePasteboardDoesNotRecapture() {
        let env = TestEnvironment()
        defer { env.tearDown() }
        env.copyText("a")
        env.copyText("b")
        env.service.copyToClipboard(env.service.clipboardItems[1])
        env.service.checkForChanges()
        #expect(env.service.clipboardItems.map(\.content) == ["b", "a"])
        #expect(env.pasteboard.string(forType: .string) == "a")
    }

    @Test func removeAndClear() {
        let env = TestEnvironment()
        defer { env.tearDown() }
        env.copyText("a")
        env.copyText("b")
        env.service.removeItem(env.service.clipboardItems[0])
        #expect(env.service.clipboardItems.map(\.content) == ["a"])
        env.service.clearAll()
        #expect(env.service.clipboardItems.isEmpty)
    }

    @Test func persistsOnlyWhenEnabled() {
        let env = TestEnvironment()
        defer { env.tearDown() }
        env.settings.persistHistory = false
        env.copyText("volatile")
        env.store.flush()
        #expect(!FileManager.default.fileExists(atPath: env.directory.appendingPathComponent("history.json").path))

        env.settings.persistHistory = true
        env.store.flush()
        #expect(FileManager.default.fileExists(atPath: env.directory.appendingPathComponent("history.json").path))
        #expect(env.store.load().map(\.content) == ["volatile"])
    }

    @Test func restoresHistoryOnLaunch() {
        let env = TestEnvironment()
        defer { env.tearDown() }
        env.copyText("remembered")
        env.store.flush()
        let relaunched = PasteboardService(settings: env.settings, store: env.store, pasteboard: env.pasteboard)
        #expect(relaunched.clipboardItems.map(\.content) == ["remembered"])
    }
}
