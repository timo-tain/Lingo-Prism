import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginService: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var message: String?

    init() {
        refresh()
    }

    func refresh() {
        switch SMAppService.mainApp.status {
        case .enabled:
            isEnabled = true
            message = nil
        case .requiresApproval:
            isEnabled = false
            message = AppLocalizer.text(.launchNeedsApproval)
        case .notRegistered, .notFound:
            isEnabled = false
            message = nil
        @unknown default:
            isEnabled = false
            message = AppLocalizer.text(.launchStatusUnavailable)
        }
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            refresh()
        } catch {
            isEnabled = false
            message = AppLocalizer.format(.launchUpdateFailedFormat, error.localizedDescription)
        }
    }
}
