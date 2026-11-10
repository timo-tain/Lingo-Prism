import AppKit
import Foundation
import Testing
@testable import LingoPrism

@MainActor
@Suite(.serialized)
struct ShortcutAndOCRTests {
    @Test func presetShortcutsIncludeTheRequestedModifierCombinations() throws {
        let optionCommand = try #require(HotkeyPreset.optionCommand.shortcut)
        let controlOptionCommand = try #require(HotkeyPreset.controlOptionCommand.shortcut)
        let controlShiftCommand = try #require(HotkeyPreset.controlShiftCommand.shortcut)

        #expect(optionCommand.displayString == "⌥⌘T")
        #expect(controlOptionCommand.displayString == "Ctrl + ⌥⌘T")
        #expect(controlShiftCommand.displayString == "Ctrl + ⇧⌘T")
        #expect(HotkeyPreset.custom.shortcut == nil)
    }

    @Test func customShortcutPersistsAndOverridesThePreset() throws {
        let suiteName = "LingoPrismTests.shortcuts.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let first = PreferencesStore(defaults: defaults)
        #expect(first.effectiveHotkey.displayString == "⇧⌘T")
        first.hotkeyPreset = .custom
        first.customHotkey = KeyboardShortcut(keyCode: 1, modifiers: [.control, .option], keyLabel: "S")
        first.showSettingsOnLaunch = true
        first.interfaceLanguage = .german

        let reloaded = PreferencesStore(defaults: defaults)
        #expect(reloaded.hotkeyPreset == .custom)
        #expect(reloaded.effectiveHotkey.displayString == "Ctrl + ⌥S")
        #expect(reloaded.effectiveHotkey.keyCode == 1)
        #expect(reloaded.showSettingsOnLaunch)
        #expect(reloaded.interfaceLanguage == .german)
    }

    @Test func selfHostedEndpointPresetsFillKnownLocalDefaultsAndPersist() throws {
        let suiteName = "LingoPrismTests.self-hosted.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let preferences = PreferencesStore(defaults: defaults)
        preferences.applySelfHostedPreset(.jan)
        #expect(preferences.selfHostedURL == "http://127.0.0.1:1337/v1")
        #expect(preferences.selfHostedModel.isEmpty)
        preferences.selfHostedModel = "jan-model"

        let reloaded = PreferencesStore(defaults: defaults)
        #expect(reloaded.selfHostedPreset == .jan)
        #expect(reloaded.selfHostedURL == "http://127.0.0.1:1337/v1")
        #expect(reloaded.selfHostedModel == "jan-model")
        #expect(SelfHostedEndpointPreset.lmStudio.defaultURL == "http://127.0.0.1:1234/v1")
        #expect(SelfHostedEndpointPreset.localAI.defaultURL == "http://127.0.0.1:8080/v1")
        #expect(SelfHostedEndpointPreset.vLLM.defaultURL == "http://127.0.0.1:8000/v1")
        #expect(SelfHostedEndpointPreset.llamaCPP.defaultURL == "http://127.0.0.1:8080/v1")
    }

    @Test func interfaceLanguageUsesSupportedSystemLanguageOrEnglishFallback() throws {
        #expect(
            Set(AppInterfaceLanguage.allCases.map(\.rawValue))
                == Set(AppLanguage.allCases.filter { $0 != .auto }.map(\.rawValue))
        )
        #expect(AppInterfaceLanguage.systemDefault(preferredIdentifiers: ["ja-JP"]) == .japanese)
        #expect(AppInterfaceLanguage.systemDefault(preferredIdentifiers: ["zh-CN"]) == .simplifiedChinese)
        #expect(AppInterfaceLanguage.systemDefault(preferredIdentifiers: ["zh-Hant-TW"]) == .traditionalChinese)
        #expect(AppInterfaceLanguage.systemDefault(preferredIdentifiers: ["it-IT", "nl-NL"]) == .english)

        let suiteName = "LingoPrismTests.initial-language.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preferences = PreferencesStore(defaults: defaults)
        #expect(preferences.showSettingsOnLaunch)
        #expect(defaults.string(forKey: "interfaceLanguage") == preferences.interfaceLanguage.rawValue)

        for language in AppInterfaceLanguage.allCases {
            #expect(!AppLocalizer.text(.general, language: language).isEmpty)
            #expect(!AppLocalizer.text(.translation, language: language).isEmpty)
            #expect(!AppLocalizer.noTextHint(language: language).isEmpty)
        }

        for engine in TranslationEngine.allCases {
            #expect(!engine.title.localizedCaseInsensitiveContains("no api"))
            #expect(!engine.title.contains("免金鑰"))
        }
        for language in AppInterfaceLanguage.allCases {
            for key in [AppLocalizer.Key.googleEngine, .bingEngine, .yandexEngine, .deepLEngine] {
                #expect(!AppLocalizer.text(key, language: language).localizedCaseInsensitiveContains("no api"))
                #expect(!AppLocalizer.text(key, language: language).contains("免金鑰"))
            }
        }
    }

    @Test func translationTestDurationUsesMillisecondsSuffix() {
        #expect(
            AppLocalizer.format(.testDurationFormat, 123, language: .traditionalChinese)
                == "（耗時 123 毫秒）"
        )
    }

    @Test func privacyPermissionCatalogProvidesSystemSettingsFlows() {
        #expect(PrivacyPermission.allCases == [.screenRecording, .accessibility])
        #expect(PrivacyPermission.screenRecording.tccService == "ScreenCapture")
        #expect(PrivacyPermission.accessibility.tccService == "Accessibility")
        for permission in PrivacyPermission.allCases {
            #expect(permission.settingsURL.scheme == "x-apple.systempreferences")
        }
        #expect(AppLocalizer.privacy(.title, language: .traditionalChinese) == "隱私權授權")
        #expect(AppLocalizer.privacy(.requestPermission, language: .traditionalChinese) == "授權")
        #expect(!AppLocalizer.privacy(.resetPermission, language: .english).isEmpty)
    }

    @Test func visionStatusCoversEveryLanguageTheAppCanRequest() {
        let statuses = VisionLanguageCatalog.statuses()
        #expect(statuses.map(\.language) == AppLanguage.allCases.filter { $0 != .auto })
    }

    @Test func systemTranslationStatusCoversEveryConfiguredSourceLanguage() async {
        let statuses = await SystemTranslationCatalog.statuses(forTarget: .traditionalChinese)
        #expect(statuses.map(\.language) == AppLanguage.allCases.filter { $0 != .auto })
    }

    @Test func borderAppearanceDebugValuesPersistAndStayInRange() throws {
        let suiteName = "LingoPrismTests.border-appearance.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let defaultsAppearance = BorderAppearance.current(defaults: defaults)
        #expect(defaultsAppearance.primaryColor == "#A8EAFA")
        #expect(defaultsAppearance.secondaryColor == "#7651FF")
        #expect(defaultsAppearance.tertiaryColor == "#F052D1")
        #expect(defaultsAppearance.strokeWidth == 1)
        #expect(defaultsAppearance.glowWidth == 14)
        #expect(defaultsAppearance.animationSpeed == 1)

        let preferences = PreferencesStore(defaults: defaults)
        preferences.borderPrimaryColor = "#123456"
        preferences.borderSecondaryColor = "#654321"
        preferences.borderTertiaryColor = "#ABCDEF"
        preferences.borderStrokeWidth = 4.5
        preferences.borderGlowWidth = 18
        preferences.borderAnimationSpeed = 1.25

        let appearance = BorderAppearance.current(defaults: defaults)
        #expect(appearance.primaryColor == "#123456")
        #expect(appearance.secondaryColor == "#654321")
        #expect(appearance.tertiaryColor == "#ABCDEF")
        #expect(appearance.strokeWidth == 4.5)
        #expect(appearance.glowWidth == 18)
        #expect(appearance.animationSpeed == 1.25)
        #expect(AppLocalizer.debug(.animationSpeed, language: .traditionalChinese) == "流光速度")
        #expect(!AppLocalizer.debug(.title, language: .traditionalChinese).isEmpty)
    }

    @Test func settingsControllerCreatesAndReusesAGlassSettingsWindow() throws {
        let suiteName = "LingoPrismTests.settings-window.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preferences = PreferencesStore(defaults: defaults)
        let launchAtLogin = LaunchAtLoginService()

        SettingsWindowController.shared.show(preferences: preferences, launchAtLogin: launchAtLogin)
        let window = try #require(NSApp.windows.first { $0.title == "Lingo Prism" && $0.isVisible })
        #expect(window.isOpaque == false)
        #expect(window.titleVisibility == .hidden)
        SettingsWindowController.shared.show(preferences: preferences, launchAtLogin: launchAtLogin)
        #expect(NSApp.windows.filter { $0.title == "Lingo Prism" && $0.isVisible }.count == 1)
        window.close()
    }
}
