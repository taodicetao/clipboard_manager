import Testing
@testable import ClipboardManager

@Suite(.serialized) struct PanelStateTests {
    private func makeState(items: [String]) -> (PanelState, TestEnvironment) {
        let env = TestEnvironment()
        for item in items.reversed() {
            env.copyText(item)
        }
        return (PanelState(service: env.service), env)
    }

    @Test func filtersCaseInsensitivelyAndResetsSelection() {
        let (state, env) = makeState(items: ["Apple", "banana", "Apricot"])
        defer { env.tearDown() }
        state.selectedIndex = 2
        state.searchText = "ap"
        #expect(state.filteredItems.map(\.content) == ["Apple", "Apricot"])
        #expect(state.selectedIndex == 0)
        #expect(state.totalCount == 3)
    }

    @Test func navigationStaysWithinBounds() {
        let (state, env) = makeState(items: ["a", "b"])
        defer { env.tearDown() }
        state.moveUp()
        #expect(state.selectedIndex == 0)
        state.moveDown()
        state.moveDown()
        #expect(state.selectedIndex == 1)
        #expect(state.selectedItem?.content == "b")
    }

    @Test func selectionClampsAfterItemsAreRemoved() {
        let (state, env) = makeState(items: ["a", "b", "c"])
        defer { env.tearDown() }
        state.selectedIndex = 2
        env.service.removeItem(env.service.clipboardItems[2])
        state.clampSelection()
        #expect(state.selectedIndex == 1)
        env.service.clearAll()
        state.clampSelection()
        #expect(state.selectedIndex == 0)
        #expect(state.selectedItem == nil)
    }

    @Test func preparingForPresentationResetsSearchAndSelection() {
        let (state, env) = makeState(items: ["a", "b"])
        defer { env.tearDown() }
        state.searchText = "b"
        state.selectedIndex = 1
        let previous = state.presentationID
        state.prepareForPresentation()
        #expect(state.searchText.isEmpty)
        #expect(state.selectedIndex == 0)
        #expect(state.presentationID != previous)
    }
}
