import SwiftUI

@main
struct LingoPrismApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(model: model)
                .frame(width: 320)
                .padding(12)
        }
        label: {
            LingoPrismBrandIcon(size: 18, cornerRadius: 4)
                .accessibilityLabel("Lingo Prism")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(preferences: model.preferences, launchAtLogin: model.launchAtLogin)
                .frame(width: 600, height: 700)
        }
    }
}
