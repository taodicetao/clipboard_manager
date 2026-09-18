import SwiftUI

struct SourceAppIconView: View {
    let bundleIdentifier: String
    let appInfo: AppInfoCache
    let size: CGFloat

    var body: some View {
        if let icon = appInfo.icon(for: bundleIdentifier) {
            Image(nsImage: icon)
                .resizable()
                .frame(width: size, height: size)
        } else {
            Image(systemName: "app.dashed")
                .font(.system(size: size - 2))
                .foregroundStyle(.secondary)
                .frame(width: size, height: size)
        }
    }
}
