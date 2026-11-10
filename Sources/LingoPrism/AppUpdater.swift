import AppKit
import Sparkle

/// Owns Sparkle's standard updater for the lifetime of the menu-bar app.
@MainActor
final class AppUpdater {
    static let shared = AppUpdater()

    private let controller: SPUStandardUpdaterController

    private init() {
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func checkForUpdates() {
        guard controller.updater.canCheckForUpdates else { return }
        controller.checkForUpdates(nil)
    }
}
