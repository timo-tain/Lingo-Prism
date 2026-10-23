import AppKit
import Foundation

enum TranslationEngine: String, CaseIterable, Identifiable, Sendable {
    case google
    case bing
    case yandex
    case deepl
    case macOS
    case ollama
    case openAICompatible

    var id: String { rawValue }

    var title: String {
        switch self {
        // Brand names do not need localization. Keeping these labels direct also
        // prevents an implementation detail such as "no API key" from becoming
        // part of the engine name.
        case .google: "Google"
        case .bing: "Bing"
        case .yandex: "Yandex"
        case .deepl: "DeepL"
        case .macOS: AppLocalizer.engineTitle(.macOS)
        case .ollama: AppLocalizer.text(.ollamaEngine)
        case .openAICompatible: AppLocalizer.engineTitle(.openAICompatible)
        }
    }

    var shortTitle: String {
        switch self {
        case .google: "Google"
        case .bing: "Bing"
        case .yandex: "Yandex"
        case .deepl: "DeepL"
        case .macOS: "macOS"
        case .ollama: "Ollama"
        case .openAICompatible: "OpenAI-compatible"
        }
    }
}

/// Common local servers that implement OpenAI's chat-completions wire format.
/// The preset only fills editable defaults; it never starts a service or sends
/// traffic until the person selects this translation engine.
enum SelfHostedEndpointPreset: String, CaseIterable, Identifiable, Sendable {
    case lmStudio
    case localAI
    case vLLM
    case llamaCPP
    case jan
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lmStudio: "LM Studio"
        case .localAI: "LocalAI"
        case .vLLM: "vLLM"
        case .llamaCPP: "llama.cpp"
        case .jan: "Jan"
        case .custom: AppLocalizer.selfHosted(.custom)
        }
    }

    var defaultURL: String {
        switch self {
        case .lmStudio: "http://127.0.0.1:1234/v1"
        case .localAI, .llamaCPP: "http://127.0.0.1:8080/v1"
        case .vLLM: "http://127.0.0.1:8000/v1"
        case .jan: "http://127.0.0.1:1337/v1"
        case .custom: ""
        }
    }

    var defaultModel: String {
        switch self {
        case .lmStudio: "local-model"
        case .localAI: ""
        case .vLLM: ""
        case .llamaCPP: ""
        case .jan: ""
        case .custom: ""
        }
    }
}

enum TranslationPresentation: String, CaseIterable, Identifiable {
    case overlay
    case floatingWindow

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overlay: AppLocalizer.text(.overlayPresentation)
        case .floatingWindow: AppLocalizer.text(.floatingPresentation)
        }
    }

    var description: String {
        switch self {
        case .overlay: AppLocalizer.text(.overlayDescription)
        case .floatingWindow: AppLocalizer.text(.floatingDescription)
        }
    }
}

enum HotkeyPreset: String, CaseIterable, Identifiable {
    // The first three presets mirror the combinations shown in the supplied
    // macOS shortcut menu. All presets use T because it is easy to reach with
    // the left hand while the pointer is already over the text to translate.
    case optionCommand
    case controlOptionCommand
    case controlShiftCommand
    case commandShift
    case controlOption
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .optionCommand: "⌥⌘ T"
        case .controlOptionCommand: "Ctrl + ⌥⌘ T"
        case .controlShiftCommand: "Ctrl + ⇧⌘ T"
        case .commandShift: "⇧⌘ T"
        case .controlOption: "Ctrl + ⌥ T"
        case .custom: AppLocalizer.text(.customShortcut)
        }
    }

    var shortcut: KeyboardShortcut? {
        switch self {
        case .optionCommand:
            KeyboardShortcut(keyCode: 17, modifiers: [.option, .command], keyLabel: "T")
        case .controlOptionCommand:
            KeyboardShortcut(keyCode: 17, modifiers: [.control, .option, .command], keyLabel: "T")
        case .controlShiftCommand:
            KeyboardShortcut(keyCode: 17, modifiers: [.control, .shift, .command], keyLabel: "T")
        case .commandShift:
            KeyboardShortcut(keyCode: 17, modifiers: [.shift, .command], keyLabel: "T")
        case .controlOption:
            KeyboardShortcut(keyCode: 17, modifiers: [.control, .option], keyLabel: "T")
        case .custom:
            nil
        }
    }
}

struct KeyboardShortcut: Equatable, Sendable {
    let keyCode: UInt16
    let modifiersRawValue: UInt
    let keyLabel: String

    init(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, keyLabel: String) {
        self.keyCode = keyCode
        self.modifiersRawValue = modifiers.intersection(.deviceIndependentFlagsMask).rawValue
        self.keyLabel = keyLabel
    }

    init(keyCode: UInt16, modifiersRawValue: UInt, keyLabel: String) {
        self.keyCode = keyCode
        self.modifiersRawValue = modifiersRawValue
        self.keyLabel = keyLabel
    }

    var modifiers: NSEvent.ModifierFlags { NSEvent.ModifierFlags(rawValue: modifiersRawValue) }

    var displayString: String {
        var glyphs = ""
        if modifiers.contains(.option) { glyphs += "⌥" }
        if modifiers.contains(.shift) { glyphs += "⇧" }
        if modifiers.contains(.command) { glyphs += "⌘" }
        let tail = glyphs + keyLabel
        return modifiers.contains(.control) ? "Ctrl + \(tail)" : tail
    }
}

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case auto
    case english
    case traditionalChinese
    case simplifiedChinese
    case japanese
    case korean
    case spanish
    case french
    case german
    case russian

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: AppLocalizer.text(.languageAuto)
        case .english: AppLocalizer.text(.languageEnglish)
        case .traditionalChinese: AppLocalizer.text(.languageTraditionalChinese)
        case .simplifiedChinese: AppLocalizer.text(.languageSimplifiedChinese)
        case .japanese: AppLocalizer.text(.languageJapanese)
        case .korean: AppLocalizer.text(.languageKorean)
        case .spanish: AppLocalizer.text(.languageSpanish)
        case .french: AppLocalizer.text(.languageFrench)
        case .german: AppLocalizer.text(.languageGerman)
        case .russian: AppLocalizer.text(.languageRussian)
        }
    }

    var googleCode: String? {
        switch self {
        case .auto: nil
        case .english: "en"
        case .traditionalChinese: "zh-TW"
        case .simplifiedChinese: "zh-CN"
        case .japanese: "ja"
        case .korean: "ko"
        case .spanish: "es"
        case .french: "fr"
        case .german: "de"
        case .russian: "ru"
        }
    }

    var visionCode: String? {
        switch self {
        case .auto: nil
        case .traditionalChinese: "zh-Hant"
        case .simplifiedChinese: "zh-Hans"
        default: googleCode
        }
    }

    /// BCP-47 identifier used by Apple's Translation framework.
    var translationCode: String? {
        switch self {
        case .auto: nil
        case .traditionalChinese: "zh-Hant"
        case .simplifiedChinese: "zh-Hans"
        default: googleCode
        }
    }

    var promptName: String {
        switch self {
        case .auto: "the source language automatically"
        case .english: "English"
        case .traditionalChinese: "Traditional Chinese (Taiwan)"
        case .simplifiedChinese: "Simplified Chinese"
        case .japanese: "Japanese"
        case .korean: "Korean"
        case .spanish: "Spanish"
        case .french: "French"
        case .german: "German"
        case .russian: "Russian"
        }
    }
}

struct TranslationResult: Sendable {
    let lines: [TranslatedLine]
    let sourceLanguage: AppLanguage
    let targetLanguage: AppLanguage
    let engine: TranslationEngine

    var sourceText: String { lines.map(\.sourceText).joined(separator: "\n") }
    var translatedText: String { lines.map(\.translatedText).joined(separator: "\n") }
}

struct TranslatedLine: Sendable, Identifiable {
    let id: UUID
    let sourceText: String
    let translatedText: String
    /// Vision uses unit coordinates with its origin at the lower-left of the image.
    let boundingBox: NormalizedRect
}

struct NormalizedRect: Sendable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}

