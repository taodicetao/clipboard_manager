import Foundation
import Observation

@Observable
final class PanelState {
    var searchText = "" {
        didSet { if searchText != oldValue { selectedIndex = 0 } }
    }
    var selectedIndex = 0
    var isSearchFocused = false
    private(set) var presentationID = UUID()

    @ObservationIgnored private let service: PasteboardService

    init(service: PasteboardService) {
        self.service = service
    }

    var filteredItems: [ClipboardItem] {
        let items = service.clipboardItems
        guard !searchText.isEmpty else { return items }
        return items.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
    }

    var totalCount: Int {
        service.clipboardItems.count
    }

    var selectedItem: ClipboardItem? {
        let items = filteredItems
        return items.indices.contains(selectedIndex) ? items[selectedIndex] : nil
    }

    func prepareForPresentation() {
        searchText = ""
        selectedIndex = 0
        presentationID = UUID()
    }

    func moveUp() {
        selectedIndex = max(0, selectedIndex - 1)
    }

    func moveDown() {
        selectedIndex = min(max(0, filteredItems.count - 1), selectedIndex + 1)
    }

    func clampSelection() {
        selectedIndex = min(selectedIndex, max(0, filteredItems.count - 1))
    }
}
