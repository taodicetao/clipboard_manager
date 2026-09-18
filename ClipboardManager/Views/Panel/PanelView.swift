import SwiftUI

struct PanelActions {
    let select: (ClipboardItem) -> Void
    let paste: (ClipboardItem) -> Void
    let copy: (ClipboardItem) -> Void
    let delete: (ClipboardItem) -> Void
}

struct PanelView: View {
    @Bindable var state: PanelState
    let settings: AppSettings
    let appInfo: AppInfoCache
    let actions: PanelActions

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            content
            footer
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onChange(of: state.presentationID, initial: true) { _, _ in
            DispatchQueue.main.async {
                isSearchFocused = settings.focusSearchOnOpen
            }
        }
        .onChange(of: state.isSearchFocused) { _, focused in
            if focused {
                isSearchFocused = true
            }
        }
        .onChange(of: isSearchFocused) { _, focused in
            state.isSearchFocused = focused
        }
    }

    private var header: some View {
        searchField
            .padding(.leading, PanelMetrics.searchFieldLeading)
            .padding(.trailing, 12)
            .padding(.top, 8)
            .frame(height: PanelMetrics.headerHeight, alignment: .top)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search Clipboard", text: $state.searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
            if !state.searchText.isEmpty {
                Button {
                    state.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .font(.system(size: 13))
        .padding(.horizontal, 12)
        .frame(height: PanelMetrics.searchFieldHeight)
        .background(.quaternary, in: Capsule())
    }

    @ViewBuilder
    private var content: some View {
        let items = state.filteredItems
        if items.isEmpty {
            emptyState
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: PanelMetrics.rowSpacing) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            PanelItemRow(
                                item: item,
                                index: index,
                                isSelected: index == state.selectedIndex,
                                appInfo: appInfo,
                                actions: actions
                            )
                            .id(item.id)
                        }
                    }
                    .padding(PanelMetrics.listPadding)
                }
                .scrollIndicators(.never)
                .onChange(of: state.selectedIndex) { _, index in
                    guard items.indices.contains(index) else { return }
                    withAnimation(.easeInOut(duration: 0.15)) {
                        proxy.scrollTo(items[index].id, anchor: .center)
                    }
                }
                .onChange(of: state.presentationID) { _, _ in
                    if let first = items.first {
                        proxy.scrollTo(first.id, anchor: .top)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        if state.searchText.isEmpty {
            ContentUnavailableView(
                "No Clipboard History",
                systemImage: "doc.on.clipboard",
                description: Text("Copy something and it will show up here.")
            )
        } else {
            ContentUnavailableView.search(text: state.searchText)
        }
    }

    private var footer: some View {
        HStack(spacing: 14) {
            KeyHint(keys: "↑↓", label: "Navigate")
            KeyHint(keys: "↩", label: settings.pasteOnSelect ? "Paste" : "Copy")
            KeyHint(keys: "⌘⌫", label: "Delete")
            KeyHint(keys: "esc", label: "Close")
            Spacer()
            Text(countLabel)
                .foregroundStyle(.tertiary)
        }
        .font(.system(size: 11))
        .padding(.horizontal, 12)
        .frame(height: PanelMetrics.footerHeight)
    }

    private var countLabel: String {
        let total = state.totalCount
        if state.searchText.isEmpty {
            return total == 1 ? "1 item" : "\(total) items"
        }
        return "\(state.filteredItems.count) of \(total)"
    }
}

private struct KeyHint: View {
    let keys: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Text(keys)
                .foregroundStyle(.secondary)
            Text(label)
                .foregroundStyle(.tertiary)
        }
    }
}
