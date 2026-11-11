import AppKit
import Sparkle

/// Owns Sparkle's standard updater for the lifetime of the menu-bar app.
@MainActor
final class AppUpdater: NSObject, SPUUpdaterDelegate, @preconcurrency SPUStandardUserDriverDelegate {
    static let shared = AppUpdater()

    var onUpdateAvailable: ((String) -> Void)?
    private lazy var controller = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: self,
        userDriverDelegate: self
    )

    private override init() {}

    func start() {
        _ = controller
    }

    func checkForUpdates() {
        guard controller.updater.canCheckForUpdates else { return }
        controller.checkForUpdates(nil)
    }

    func checkForUpdatesInBackground() {
        guard controller.updater.canCheckForUpdates else { return }
        controller.updater.checkForUpdatesInBackground()
    }

    func updater(_ updater: SPUUpdater, didFindValidUpdate item: SUAppcastItem) {
        onUpdateAvailable?(item.versionString)
    }

    var supportsGentleScheduledUpdateReminders: Bool { true }

    func standardUserDriverShouldHandleShowingScheduledUpdate(
        _ update: SUAppcastItem,
        andInImmediateFocus immediateFocus: Bool
    ) -> Bool {
        false
    }

    func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool,
        forUpdate update: SUAppcastItem,
        state: SPUUserUpdateState
    ) {
        if !handleShowingUpdate {
            onUpdateAvailable?(update.versionString)
        }
    }
}
