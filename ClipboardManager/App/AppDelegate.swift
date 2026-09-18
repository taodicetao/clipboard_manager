import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let settings: AppSettings
    let historyStore: HistoryStore
    let appInfo: AppInfoCache
    let loginItems: LoginItemService
    let pasteSimulator: PasteSimulator
    let pasteboardService: PasteboardService
    let hotkeyManager: GlobalHotkeyManager

    private let panelController: ClipboardPanelController

    override init() {
        settings = AppSettings()
        historyStore = HistoryStore()
        appInfo = AppInfoCache()
        loginItems = LoginItemService()
        pasteSimulator = PasteSimulator()
        pasteboardService = PasteboardService(settings: settings, store: historyStore)
        hotkeyManager = GlobalHotkeyManager(settings: settings)
        panelController = ClipboardPanelController(
            service: pasteboardService,
            settings: settings,
            appInfo: appInfo,
            pasteSimulator: pasteSimulator
        )
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        hotkeyManager.onHotkeyPressed = { [panelController] in
            panelController.show()
        }
        hotkeyManager.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        historyStore.flush()
    }

    func showPanel() {
        panelController.show()
    }
}
