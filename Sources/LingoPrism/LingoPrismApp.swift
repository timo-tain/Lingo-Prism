import AppKit
import SwiftUI

@main
struct LingoPrismApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        Settings {
            SettingsView(
                preferences: model.preferences,
                launchAtLogin: model.launchAtLogin,
                permissions: model.privacyPermissions
            )
                .frame(width: 600, height: 700)
        }
    }
}

/// Owns the menu-bar item and its compact floating panel. Both mouse buttons
/// open the panel; a left click toggles it closed when it is already visible.
@MainActor
final class MenuBarStatusController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let popover = NSPopover()

    init(model: AppModel) {
        super.init()

        if let button = statusItem.button {
            let image = LingoPrismMenuBarAsset.image(size: 18)
            image.isTemplate = true
            button.image = image
            button.imagePosition = .imageOnly
            button.toolTip = "Lingo Prism"
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        let rootView = MenuBarView(model: model)
            .frame(width: 320)
            .padding(12)
        popover.contentViewController = NSHostingController(rootView: rootView)
        popover.behavior = .transient
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let button = statusItem.button else { return }
        if NSApp.currentEvent?.type == .rightMouseUp {
            showPopover(from: button)
        } else if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover(from: button)
        }
    }

    private func showPopover(from button: NSStatusBarButton) {
        guard !popover.isShown else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        DispatchQueue.main.async { [weak self] in
            guard let self, self.popover.isShown else { return }
            self.popover.contentViewController?.view.window?.makeKey()
        }
    }
}
