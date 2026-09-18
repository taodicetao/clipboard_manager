import Observation
import ServiceManagement

@Observable
final class LoginItemService {
    private(set) var status: SMAppService.Status
    var lastError: String?

    init() {
        status = SMAppService.mainApp.status
    }

    var isEnabled: Bool {
        status == .enabled
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
        refresh()
    }

    func refresh() {
        status = SMAppService.mainApp.status
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
