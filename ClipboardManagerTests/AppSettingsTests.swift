import Foundation
import Testing
@testable import ClipboardManager

@Suite struct AppSettingsTests {
    private func makeDefaults() -> (UserDefaults, String) {
        let name = "AppSettingsTests.\(UUID().uuidString)"
        return (UserDefaults(suiteName: name)!, name)
    }

    @Test func freshInstallUsesDefaults() {
        let (defaults, name) = makeDefaults()
        defer { UserDefaults.standard.removePersistentDomain(forName: name) }
        let settings = AppSettings(defaults: defaults)
        #expect(settings.maxItems == 50)
        #expect(settings.pollingInterval == 0.5)
        #expect(settings.captureImages)
        #expect(!settings.showNotifications)
        #expect(settings.persistHistory)
        #expect(settings.pasteOnSelect)
        #expect(settings.focusSearchOnOpen)
        #expect(settings.panelPosition == .atCursor)
        #expect(settings.hotkey == .default)
        #expect(settings.excludedBundleIdentifiers.isEmpty)
    }

    @Test func changesPersistToANewInstance() {
        let (defaults, name) = makeDefaults()
        defer { UserDefaults.standard.removePersistentDomain(forName: name) }
        let settings = AppSettings(defaults: defaults)
        settings.maxItems = 200
        settings.captureImages = false
        settings.panelPosition = .screenCenter
        settings.hotkey = Hotkey(keyCode: 40, carbonModifiers: 256)
        settings.excludedBundleIdentifiers = ["com.example.vault"]

        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.maxItems == 200)
        #expect(!reloaded.captureImages)
        #expect(reloaded.panelPosition == .screenCenter)
        #expect(reloaded.hotkey == Hotkey(keyCode: 40, carbonModifiers: 256))
        #expect(reloaded.excludedBundleIdentifiers == ["com.example.vault"])
    }

    @Test func migratesLegacyKeys() {
        let (defaults, name) = makeDefaults()
        defer { UserDefaults.standard.removePersistentDomain(forName: name) }
        defaults.set(false, forKey: "showImages")
        defaults.set(true, forKey: "autoStart")
        defaults.set(25, forKey: "maxItems")

        let settings = AppSettings(defaults: defaults)
        #expect(!settings.captureImages)
        #expect(settings.maxItems == 50)
        #expect(defaults.object(forKey: "showImages") == nil)
        #expect(defaults.object(forKey: "autoStart") == nil)
    }

    @Test func keepsLegacyMaxItemsWhenStillAnOption() {
        let (defaults, name) = makeDefaults()
        defer { UserDefaults.standard.removePersistentDomain(forName: name) }
        defaults.set(20, forKey: "maxItems")
        #expect(AppSettings(defaults: defaults).maxItems == 20)
    }
}
