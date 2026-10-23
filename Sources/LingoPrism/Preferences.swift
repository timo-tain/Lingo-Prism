import Foundation

enum BorderAppearanceDefaults {
    static let primaryColor = "borderPrimaryColor"
    static let secondaryColor = "borderSecondaryColor"
    static let tertiaryColor = "borderTertiaryColor"
    static let strokeWidth = "borderStrokeWidth"
    static let glowWidth = "borderGlowWidth"
}

struct BorderAppearance {
    let primaryColor: String
    let secondaryColor: String
    let tertiaryColor: String
    let strokeWidth: CGFloat
    let glowWidth: CGFloat

    static let defaultPrimaryColor = "#269FFF"
    static let defaultSecondaryColor = "#7651FF"
    static let defaultTertiaryColor = "#F052D1"
    static let defaultStrokeWidth: CGFloat = 3
    static let defaultGlowWidth: CGFloat = 14

    static func current(defaults: UserDefaults = .standard) -> Self {
        Self(
            primaryColor: defaults.string(forKey: BorderAppearanceDefaults.primaryColor) ?? defaultPrimaryColor,
            secondaryColor: defaults.string(forKey: BorderAppearanceDefaults.secondaryColor) ?? defaultSecondaryColor,
            tertiaryColor: defaults.string(forKey: BorderAppearanceDefaults.tertiaryColor) ?? defaultTertiaryColor,
            strokeWidth: clamped(CGFloat((defaults.object(forKey: BorderAppearanceDefaults.strokeWidth) as? NSNumber)?.doubleValue ?? Double(defaultStrokeWidth)), range: 1...8),
            glowWidth: clamped(CGFloat((defaults.object(forKey: BorderAppearanceDefaults.glowWidth) as? NSNumber)?.doubleValue ?? Double(defaultGlowWidth)), range: 0...28)
        )
    }

    private static func clamped(_ value: CGFloat, range: ClosedRange<CGFloat>) -> CGFloat {
        min(max(value, range.lowerBound), range.upperBound)
    }
}

@MainActor
final class PreferencesStore: ObservableObject {
    private enum Key {
        static let engine = "translationEngine"
        static let sourceLanguage = "sourceLanguage"
        static let targetLanguage = "targetLanguage"
        static let ollamaURL = "ollamaURL"
        static let ollamaModel = "ollamaModel"
        static let selfHostedPreset = "selfHostedEndpointPreset"
        static let selfHostedURL = "selfHostedEndpointURL"
        static let selfHostedModel = "selfHostedEndpointModel"
        static let presentation = "translationPresentation"
        static let hotkeyPreset = "hotkeyPreset"
        static let customHotkeyCode = "customHotkeyCode"
        static let customHotkeyModifiers = "customHotkeyModifiers"
        static let customHotkeyLabel = "customHotkeyLabel"
        static let showSettingsOnLaunch = "showSettingsOnLaunch"
        static let interfaceLanguage = "interfaceLanguage"
        static let didInitializeLaunchAtLogin = "didInitializeLaunchAtLogin"
    }

    @Published var engine: TranslationEngine { didSet { save() } }
    @Published var sourceLanguage: AppLanguage { didSet { save() } }
    @Published var targetLanguage: AppLanguage { didSet { save() } }
    @Published var ollamaURL: String { didSet { save() } }
    @Published var ollamaModel: String { didSet { save() } }
    @Published var selfHostedPreset: SelfHostedEndpointPreset { didSet { save() } }
    @Published var selfHostedURL: String { didSet { save() } }
    @Published var selfHostedModel: String { didSet { save() } }
    @Published var presentation: TranslationPresentation { didSet { save() } }
    @Published var hotkeyPreset: HotkeyPreset { didSet { save() } }
    @Published var customHotkey: KeyboardShortcut { didSet { save() } }
    @Published var showSettingsOnLaunch: Bool { didSet { save() } }
    @Published var interfaceLanguage: AppInterfaceLanguage { didSet { save() } }
    @Published var borderPrimaryColor: String { didSet { save() } }
    @Published var borderSecondaryColor: String { didSet { save() } }
    @Published var borderTertiaryColor: String { didSet { save() } }
    @Published var borderStrokeWidth: Double { didSet { save() } }
    @Published var borderGlowWidth: Double { didSet { save() } }
    private let defaults: UserDefaults

    var effectiveHotkey: KeyboardShortcut { hotkeyPreset.shortcut ?? customHotkey }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        engine = TranslationEngine(rawValue: defaults.string(forKey: Key.engine) ?? "") ?? .google
        sourceLanguage = AppLanguage(rawValue: defaults.string(forKey: Key.sourceLanguage) ?? "") ?? .auto
        targetLanguage = AppLanguage(rawValue: defaults.string(forKey: Key.targetLanguage) ?? "") ?? .traditionalChinese
        ollamaURL = defaults.string(forKey: Key.ollamaURL) ?? "http://127.0.0.1:11434"
        ollamaModel = defaults.string(forKey: Key.ollamaModel) ?? "llama3.2"
        selfHostedPreset = SelfHostedEndpointPreset(rawValue: defaults.string(forKey: Key.selfHostedPreset) ?? "") ?? .lmStudio
        selfHostedURL = defaults.string(forKey: Key.selfHostedURL) ?? SelfHostedEndpointPreset.lmStudio.defaultURL
        selfHostedModel = defaults.string(forKey: Key.selfHostedModel) ?? SelfHostedEndpointPreset.lmStudio.defaultModel
        presentation = TranslationPresentation(rawValue: defaults.string(forKey: Key.presentation) ?? "") ?? .overlay
        hotkeyPreset = HotkeyPreset(rawValue: defaults.string(forKey: Key.hotkeyPreset) ?? "") ?? .commandShift
        let storedCode = defaults.object(forKey: Key.customHotkeyCode) as? NSNumber
        let storedModifiers = defaults.object(forKey: Key.customHotkeyModifiers) as? NSNumber
        let defaultShortcut = HotkeyPreset.commandShift.shortcut!
        customHotkey = KeyboardShortcut(
            keyCode: UInt16(truncatingIfNeeded: storedCode?.intValue ?? 17),
            modifiersRawValue: UInt(truncatingIfNeeded: storedModifiers?.intValue ?? Int(defaultShortcut.modifiersRawValue)),
            keyLabel: defaults.string(forKey: Key.customHotkeyLabel) ?? "T"
        )
        // Both general options are opt-out on a clean install. `object(forKey:)`
        // distinguishes an absent preference from an explicit false choice.
        showSettingsOnLaunch = (defaults.object(forKey: Key.showSettingsOnLaunch) as? Bool) ?? true
        interfaceLanguage = AppInterfaceLanguage(rawValue: defaults.string(forKey: Key.interfaceLanguage) ?? "")
            ?? AppInterfaceLanguage.systemDefault()
        borderPrimaryColor = defaults.string(forKey: BorderAppearanceDefaults.primaryColor) ?? BorderAppearance.defaultPrimaryColor
        borderSecondaryColor = defaults.string(forKey: BorderAppearanceDefaults.secondaryColor) ?? BorderAppearance.defaultSecondaryColor
        borderTertiaryColor = defaults.string(forKey: BorderAppearanceDefaults.tertiaryColor) ?? BorderAppearance.defaultTertiaryColor
        borderStrokeWidth = defaults.object(forKey: BorderAppearanceDefaults.strokeWidth) as? Double ?? Double(BorderAppearance.defaultStrokeWidth)
        borderGlowWidth = defaults.object(forKey: BorderAppearanceDefaults.glowWidth) as? Double ?? Double(BorderAppearance.defaultGlowWidth)
        defaults.set(engine.rawValue, forKey: Key.engine)
        defaults.set(showSettingsOnLaunch, forKey: Key.showSettingsOnLaunch)
        defaults.set(interfaceLanguage.rawValue, forKey: Key.interfaceLanguage)
    }

    var needsInitialLaunchAtLoginSetup: Bool {
        !defaults.bool(forKey: Key.didInitializeLaunchAtLogin)
    }

    func markInitialLaunchAtLoginSetupComplete() {
        defaults.set(true, forKey: Key.didInitializeLaunchAtLogin)
    }

    private func save() {
        defaults.set(engine.rawValue, forKey: Key.engine)
        defaults.set(sourceLanguage.rawValue, forKey: Key.sourceLanguage)
        defaults.set(targetLanguage.rawValue, forKey: Key.targetLanguage)
        defaults.set(ollamaURL, forKey: Key.ollamaURL)
        defaults.set(ollamaModel, forKey: Key.ollamaModel)
        defaults.set(selfHostedPreset.rawValue, forKey: Key.selfHostedPreset)
        defaults.set(selfHostedURL, forKey: Key.selfHostedURL)
        defaults.set(selfHostedModel, forKey: Key.selfHostedModel)
        defaults.set(presentation.rawValue, forKey: Key.presentation)
        defaults.set(hotkeyPreset.rawValue, forKey: Key.hotkeyPreset)
        defaults.set(Int(customHotkey.keyCode), forKey: Key.customHotkeyCode)
        defaults.set(Int(customHotkey.modifiersRawValue), forKey: Key.customHotkeyModifiers)
        defaults.set(customHotkey.keyLabel, forKey: Key.customHotkeyLabel)
        defaults.set(showSettingsOnLaunch, forKey: Key.showSettingsOnLaunch)
        defaults.set(interfaceLanguage.rawValue, forKey: Key.interfaceLanguage)
        defaults.set(borderPrimaryColor, forKey: BorderAppearanceDefaults.primaryColor)
        defaults.set(borderSecondaryColor, forKey: BorderAppearanceDefaults.secondaryColor)
        defaults.set(borderTertiaryColor, forKey: BorderAppearanceDefaults.tertiaryColor)
        defaults.set(borderStrokeWidth, forKey: BorderAppearanceDefaults.strokeWidth)
        defaults.set(borderGlowWidth, forKey: BorderAppearanceDefaults.glowWidth)
    }

    func applySelfHostedPreset(_ preset: SelfHostedEndpointPreset) {
        selfHostedPreset = preset
        guard preset != .custom else { return }
        selfHostedURL = preset.defaultURL
        selfHostedModel = preset.defaultModel
    }
}
