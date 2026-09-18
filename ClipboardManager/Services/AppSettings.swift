import Foundation
import Observation

@Observable
final class AppSettings {
    static let maxItemsOptions = [20, 50, 100, 200]

    var maxItems: Int { didSet { defaults.set(maxItems, forKey: Key.maxItems) } }
    var pollingInterval: TimeInterval { didSet { defaults.set(pollingInterval, forKey: Key.pollingInterval) } }
    var captureImages: Bool { didSet { defaults.set(captureImages, forKey: Key.captureImages) } }
    var showNotifications: Bool { didSet { defaults.set(showNotifications, forKey: Key.showNotifications) } }
    var persistHistory: Bool { didSet { defaults.set(persistHistory, forKey: Key.persistHistory) } }
    var pasteOnSelect: Bool { didSet { defaults.set(pasteOnSelect, forKey: Key.pasteOnSelect) } }
    var focusSearchOnOpen: Bool { didSet { defaults.set(focusSearchOnOpen, forKey: Key.focusSearchOnOpen) } }
    var panelPosition: PanelPosition { didSet { defaults.set(panelPosition.rawValue, forKey: Key.panelPosition) } }
    var hotkey: Hotkey { didSet { defaults.set(try? JSONEncoder().encode(hotkey), forKey: Key.hotkey) } }
    var excludedBundleIdentifiers: [String] { didSet { defaults.set(excludedBundleIdentifiers, forKey: Key.excludedBundleIdentifiers) } }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        Self.migrate(defaults)
        maxItems = defaults.object(forKey: Key.maxItems) as? Int ?? 50
        pollingInterval = defaults.object(forKey: Key.pollingInterval) as? TimeInterval ?? 0.5
        captureImages = defaults.object(forKey: Key.captureImages) as? Bool ?? true
        showNotifications = defaults.object(forKey: Key.showNotifications) as? Bool ?? false
        persistHistory = defaults.object(forKey: Key.persistHistory) as? Bool ?? true
        pasteOnSelect = defaults.object(forKey: Key.pasteOnSelect) as? Bool ?? true
        focusSearchOnOpen = defaults.object(forKey: Key.focusSearchOnOpen) as? Bool ?? true
        panelPosition = defaults.string(forKey: Key.panelPosition).flatMap(PanelPosition.init(rawValue:)) ?? .atCursor
        hotkey = defaults.data(forKey: Key.hotkey).flatMap { try? JSONDecoder().decode(Hotkey.self, from: $0) } ?? .default
        excludedBundleIdentifiers = defaults.stringArray(forKey: Key.excludedBundleIdentifiers) ?? []
    }

    private enum Key {
        static let maxItems = "maxItems"
        static let pollingInterval = "pollingInterval"
        static let captureImages = "captureImages"
        static let showNotifications = "showNotifications"
        static let persistHistory = "persistHistory"
        static let pasteOnSelect = "pasteOnSelect"
        static let focusSearchOnOpen = "focusSearchOnOpen"
        static let panelPosition = "panelPosition"
        static let hotkey = "hotkey"
        static let excludedBundleIdentifiers = "excludedBundleIdentifiers"
    }

    private static func migrate(_ defaults: UserDefaults) {
        if let showImages = defaults.object(forKey: "showImages") as? Bool {
            defaults.set(showImages, forKey: Key.captureImages)
            defaults.removeObject(forKey: "showImages")
        }
        defaults.removeObject(forKey: "autoStart")
        if let stored = defaults.object(forKey: Key.maxItems) as? Int, !maxItemsOptions.contains(stored) {
            defaults.removeObject(forKey: Key.maxItems)
        }
    }
}
