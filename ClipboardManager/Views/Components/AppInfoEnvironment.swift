import SwiftUI

private struct AppInfoCacheKey: EnvironmentKey {
    static let defaultValue = AppInfoCache()
}

extension EnvironmentValues {
    var appInfo: AppInfoCache {
        get { self[AppInfoCacheKey.self] }
        set { self[AppInfoCacheKey.self] = newValue }
    }
}
