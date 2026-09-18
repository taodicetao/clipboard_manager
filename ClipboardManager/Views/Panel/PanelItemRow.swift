import SwiftUI

struct PanelItemRow: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    let appInfo: AppInfoCache
    let actions: PanelActions

    private static let iconSize: CGFloat = 32

    var body: some View {
        HStack(spacing: 10) {
            leading
                .frame(width: Self.iconSize, height: Self.iconSize)
            VStack(alignment: .leading, spacing: 3) {
                Text(item.content.trimmingCharacters(in: .whitespacesAndNewlines))
                    .font(.system(size: 13))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 4) {
                    if let bundleIdentifier = item.sourceBundleIdentifier {
                        SourceAppIconView(bundleIdentifier: bundleIdentifier, appInfo: appInfo, size: 14)
                        if let name = appInfo.name(for: bundleIdentifier) {
                            Text(name)
                            Text("·")
                        }
                    }
                    Text(item.createdAt, format: .relative(presentation: .named, unitsStyle: .abbreviated))
                }
                .font(.system(size: 11))
                .foregroundStyle(secondaryStyle)
                .lineLimit(1)
            }
            if index < 9 {
                Text("⌘\(index + 1)")
                    .font(.system(size: 11).monospacedDigit())
                    .foregroundStyle(isSelected ? secondaryStyle : AnyShapeStyle(.tertiary))
            }
        }
        .padding(.horizontal, 12)
        .frame(height: PanelMetrics.rowHeight)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            actions.select(item)
        }
        .contextMenu {
            Button("Paste") { actions.paste(item) }
            Button("Copy") { actions.copy(item) }
            Divider()
            Button("Delete", role: .destructive) { actions.delete(item) }
        }
    }

    private var secondaryStyle: AnyShapeStyle {
        isSelected ? AnyShapeStyle(.white.opacity(0.7)) : AnyShapeStyle(.secondary)
    }

    @ViewBuilder
    private var leading: some View {
        switch item.kind {
        case .image:
            if let image = item.image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: Self.iconSize, height: Self.iconSize)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(.separator, lineWidth: 0.5))
            }
        case .file:
            if let url = item.fileURLs.first {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .frame(width: Self.iconSize, height: Self.iconSize)
            }
        case .text:
            Image(systemName: "text.alignleft")
                .font(.system(size: 18))
                .foregroundStyle(secondaryStyle)
        }
    }
}
