import AppKit

final class AppInfoCache {
    private var icons: [String: NSImage] = [:]
    private var names: [String: String] = [:]

    func icon(for bundleIdentifier: String) -> NSImage? {
        if let cached = icons[bundleIdentifier] { return cached }
        guard let url = applicationURL(for: bundleIdentifier) else { return nil }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icons[bundleIdentifier] = icon
        return icon
    }

    func name(for bundleIdentifier: String) -> String? {
        if let cached = names[bundleIdentifier] { return cached }
        guard let url = applicationURL(for: bundleIdentifier) else { return nil }
        let name = FileManager.default.displayName(atPath: url.path)
        names[bundleIdentifier] = name
        return name
    }

    private func applicationURL(for bundleIdentifier: String) -> URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
    }
}
