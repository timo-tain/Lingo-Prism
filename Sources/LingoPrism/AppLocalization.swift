import Foundation

/// The language used by Lingo Prism itself. This is deliberately separate from
/// the source/target languages used for a translation.
enum AppInterfaceLanguage: String, CaseIterable, Identifiable, Sendable {
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

    /// Endonyms make the language picker understandable even before its UI
    /// has switched into the newly selected language.
    var pickerTitle: String {
        switch self {
        case .english: "English"
        case .traditionalChinese: "繁體中文"
        case .simplifiedChinese: "简体中文"
        case .japanese: "日本語"
        case .korean: "한국어"
        case .spanish: "Español"
        case .french: "Français"
        case .german: "Deutsch"
        case .russian: "Русский"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .english: "en"
        case .traditionalChinese: "zh-Hant"
        case .simplifiedChinese: "zh-Hans"
        case .japanese: "ja"
        case .korean: "ko"
        case .spanish: "es"
        case .french: "fr"
        case .german: "de"
        case .russian: "ru"
        }
    }

    static func systemDefault(preferredIdentifiers: [String] = Locale.preferredLanguages) -> Self {
        for identifier in preferredIdentifiers {
            let locale = Locale(identifier: identifier)
            switch locale.language.languageCode?.identifier.lowercased() {
            case "en": return .english
            case "ja": return .japanese
            case "ko": return .korean
            case "es": return .spanish
            case "fr": return .french
            case "de": return .german
            case "ru": return .russian
            case "zh":
                let script = locale.language.script?.identifier.lowercased()
                let region = locale.region?.identifier.uppercased()
                return script == "hans" || region == "CN" || region == "SG" ? .simplifiedChinese : .traditionalChinese
            default: continue
            }
        }
        return .english
    }
}

/// Runtime-selectable strings are kept in code instead of `Localizable.strings`
/// so changing the in-app language takes effect immediately without restarting
/// Lingo Prism. Missing translations always fall back to English, never a key.
enum AppLocalizer {
    enum EngineTitle {
        case macOS
        case openAICompatible
    }

    enum SelfHostedKey {
        case custom
        case endpoint
        case model
        case testConnection
        case systemLanguages
        case systemLanguagesSubtitle
        case installed
        case availableToDownload
        case unsupported
        case recheckLanguages
        case downloadSelectedPair
        case chooseSourceLanguage
        case requiresMacOS26
        case downloading
        case downloadFailed
    }

    enum PrivacyKey {
        case title
        case subtitle
        case screenRecording
        case accessibility
        case authorized
        case notAuthorized
        case requestPermission
        case openSystemSettings
        case refresh
        case resetPermission
        case resetAllPermissions
        case resetSucceeded
        case resetFailed
    }

    enum DebugKey {
        case title
        case description
        case primaryColor
        case secondaryColor
        case tertiaryColor
        case strokeWidth
        case glowWidth
        case animationSpeed
        case frameSection
        case permissionsSection
        case updateTestingSection, simulateUpdateFlow, simulationNotice
        case updateAvailableTitle, updateAvailableMessage, releaseNotesTitle, simulatedReleaseNote, later, installUpdate
        case copyParameters
        case parametersCopied
        case copyParametersHint
    }

    enum Key: String {
        case ok
        case general, launchAtLogin, launchAtLoginSubtitle, showSettingsOnLaunch, showSettingsSubtitle
        case interfaceLanguage, interfaceLanguageSubtitle
        case translation, translationLanguage, translationLanguageSubtitle, sourceLanguage, targetLanguage
        case translationEngine, translationEngineSubtitle, resultDisplay
        case googleEngine, bingEngine, yandexEngine, deepLEngine, ollamaEngine
        case overlayPresentation, floatingPresentation, overlayDescription, floatingDescription
        case ollamaURL, ollamaModel, testOllama, checking, testTranslation, cancelTest, testSuccessFormat, testDurationFormat
        case connectedNoModels, connectedFormat, cannotConnect
        case shortcut, shortcutTitle, currentFormat, customShortcut, pressShortcut, modifierRequired, cancel, accessibilityHelp
        case textRecognition, visionOCR, visionOCRSubtitle, recheck, manageSystemLanguages, visionInfo
        case versionFormat, checkForUpdates, check, updateVersion, update, updateAvailableFormat
        case startTranslation, translating, settings, quit
        case languageAuto, languageEnglish, languageTraditionalChinese, languageSimplifiedChinese
        case languageJapanese, languageKorean, languageSpanish, languageFrench, languageGerman, languageRussian
        case statusReady, statusAccessibilityEnabled, statusAccessibilityDisabled, targetRequiredTitle, targetRequiredMessage
        case statusSelectArea, statusSelectionCancelled, recognizing, translatingText, translatedLinesFormat
        case copiedTranslation, copiedOriginal, couldNotTranslate, translationUnfinished
        case selectionTitle, selectionInstruction, selectionTooSmall, selectionAccessibility, selectionProcessingFormat, selectionSizeFormat
        case screenRecordingPermission, noScreen, captureFailed, selectionInvalid
        case errorNoText, errorTargetLanguageRequired, errorOllamaInvalid, errorOllamaServiceFormat, errorOllamaDetail
        case errorOllamaUnavailableFormat, errorInvalidResponse
        case errorRateLimitedFormat, errorWebHTTPFormat, errorWebNetworkFormat, errorWebResponseFormat, errorWebConfigurationFormat, errorWebCertificateFormat
        case overlayTitle, original, translated, showOriginal, showTranslation, copyTranslation, copyOriginal
        case reselect, close, closeOverlay, overlayAccessibility, translationSegmentFormat
        case launchNeedsApproval, launchStatusUnavailable, launchUpdateFailedFormat
    }

    static var currentLanguage: AppInterfaceLanguage {
        guard let raw = UserDefaults.standard.string(forKey: "interfaceLanguage"),
              let language = AppInterfaceLanguage(rawValue: raw) else {
            return AppInterfaceLanguage.systemDefault()
        }
        return language
    }

    static func text(_ key: Key, language: AppInterfaceLanguage = currentLanguage) -> String {
        let value: String
        switch key {
        case .translationEngineSubtitle:
            value = translationEngineSubtitle(language: language)
        case .checkForUpdates:
            value = checkForUpdatesLabel(language: language)
        case .check:
            switch language {
            case .english: value = "Check"
            case .traditionalChinese, .simplifiedChinese: value = "檢查"
            case .japanese: value = "確認"
            case .korean: value = "확인"
            case .spanish: value = "Comprobar"
            case .french: value = "Vérifier"
            case .german: value = "Prüfen"
            case .russian: value = "Проверить"
            }
        case .updateVersion:
            switch language {
            case .english: value = "Update Available"
            case .traditionalChinese: value = "更新版本"
            case .simplifiedChinese: value = "更新版本"
            case .japanese: value = "アップデート"
            case .korean: value = "업데이트"
            case .spanish: value = "Actualizar versión"
            case .french: value = "Mettre à jour"
            case .german: value = "Version aktualisieren"
            case .russian: value = "Обновить версию"
            }
        case .update:
            switch language {
            case .english: value = "Update"
            case .traditionalChinese: value = "更新"
            case .simplifiedChinese: value = "更新"
            case .japanese: value = "更新"
            case .korean: value = "업데이트"
            case .spanish: value = "Actualizar"
            case .french: value = "Mettre à jour"
            case .german: value = "Aktualisieren"
            case .russian: value = "Обновить"
            }
        case .updateAvailableFormat:
            switch language {
            case .english: value = "Lingo Prism %@ is available to update."
            case .traditionalChinese: value = "Lingo Prism %@ 有新版本可供更新。"
            case .simplifiedChinese: value = "Lingo Prism %@ 有新版本可供更新。"
            case .japanese: value = "Lingo Prism %@ をアップデートできます。"
            case .korean: value = "Lingo Prism %@ 업데이트를 사용할 수 있습니다."
            case .spanish: value = "Hay una actualización de Lingo Prism %@ disponible."
            case .french: value = "Une mise à jour de Lingo Prism %@ est disponible."
            case .german: value = "Ein Update für Lingo Prism %@ ist verfügbar."
            case .russian: value = "Доступно обновление Lingo Prism %@."
            }
        case .testDurationFormat:
            switch language {
            case .english: value = " (elapsed %d ms)"
            case .traditionalChinese: value = "（耗時 %d 毫秒）"
            case .simplifiedChinese: value = "（耗时 %d 毫秒）"
            case .japanese: value = "（所要時間 %d ミリ秒）"
            case .korean: value = "（소요 시간 %dms）"
            case .spanish: value = "（tiempo: %d ms）"
            case .french: value = "（durée : %d ms）"
            case .german: value = "（Dauer: %d ms）"
            case .russian: value = "（время: %d мс）"
            }
        case .googleEngine:
            value = "Google"
        case .bingEngine:
            value = "Bing"
        case .yandexEngine:
            value = "Yandex"
        case .deepLEngine:
            value = "DeepL"
        default:
            value = tables[language]?[key] ?? tables[.english]![key] ?? key.rawValue
        }
        return value
    }

    static func format(_ key: Key, _ values: CVarArg..., language: AppInterfaceLanguage = currentLanguage) -> String {
        String(format: text(key, language: language), locale: Locale(identifier: language.localeIdentifier), arguments: values)
    }

    private static func checkForUpdatesLabel(language: AppInterfaceLanguage) -> String {
        switch language {
        case .english: "Check for Updates"
        case .traditionalChinese: "檢查更新"
        case .simplifiedChinese: "检查更新"
        case .japanese: "アップデートを確認"
        case .korean: "업데이트 확인"
        case .spanish: "Buscar actualizaciones"
        case .french: "Rechercher des mises à jour"
        case .german: "Nach Updates suchen"
        case .russian: "Проверить обновления"
        }
    }

    static func privacy(_ key: PrivacyKey, language: AppInterfaceLanguage = currentLanguage) -> String {
        let english: [PrivacyKey: String] = [
            .title: "Privacy Permissions", .subtitle: "Check and manage access needed for screen translation.",
            .screenRecording: "Screen Recording", .accessibility: "Accessibility", .authorized: "Authorized", .notAuthorized: "Not authorized",
            .requestPermission: "Authorize", .openSystemSettings: "Open System Settings", .refresh: "Refresh",
            .resetPermission: "Reset permission (Debug)", .resetAllPermissions: "Reset all permissions",
            .resetSucceeded: "Permission reset. Recheck after returning from System Settings.", .resetFailed: "Could not reset this permission."
        ]
        let strings: [PrivacyKey: String]
        switch language {
        case .traditionalChinese:
            strings = [
                .title: "隱私權授權", .subtitle: "檢查與管理螢幕翻譯所需的系統權限。",
                .screenRecording: "螢幕錄製", .accessibility: "輔助使用", .authorized: "已授權", .notAuthorized: "尚未授權",
                .requestPermission: "授權", .openSystemSettings: "開啟系統設定", .refresh: "重新檢查",
                .resetPermission: "移除授權（Debug）", .resetAllPermissions: "移除所有授權",
                .resetSucceeded: "已移除授權；從系統設定返回後重新檢查。", .resetFailed: "無法移除此授權。"
            ]
        case .simplifiedChinese:
            strings = [
                .title: "隐私权限", .subtitle: "检查和管理屏幕翻译所需的系统权限。",
                .screenRecording: "屏幕录制", .accessibility: "辅助功能", .authorized: "已授权", .notAuthorized: "尚未授权",
                .requestPermission: "授权", .openSystemSettings: "打开系统设置", .refresh: "重新检查",
                .resetPermission: "移除授权（Debug）", .resetAllPermissions: "移除所有授权",
                .resetSucceeded: "已移除授权；从系统设置返回后重新检查。", .resetFailed: "无法移除此授权。"
            ]
        case .japanese:
            strings = [
                .title: "プライバシー権限", .subtitle: "画面翻訳に必要なアクセスを確認・管理します。",
                .screenRecording: "画面収録", .accessibility: "アクセシビリティ", .authorized: "許可済み", .notAuthorized: "未許可",
                .requestPermission: "許可する", .openSystemSettings: "システム設定を開く", .refresh: "再確認",
                .resetPermission: "権限をリセット（Debug）", .resetAllPermissions: "すべての権限をリセット",
                .resetSucceeded: "権限をリセットしました。システム設定から戻って再確認してください。", .resetFailed: "権限をリセットできませんでした。"
            ]
        case .korean:
            strings = [
                .title: "개인정보 보호 권한", .subtitle: "화면 번역에 필요한 접근 권한을 확인하고 관리합니다.",
                .screenRecording: "화면 기록", .accessibility: "손쉬운 사용", .authorized: "허용됨", .notAuthorized: "허용되지 않음",
                .requestPermission: "허용", .openSystemSettings: "시스템 설정 열기", .refresh: "다시 확인",
                .resetPermission: "권한 재설정 (Debug)", .resetAllPermissions: "모든 권한 재설정",
                .resetSucceeded: "권한을 재설정했습니다. 시스템 설정에서 돌아온 후 다시 확인하세요.", .resetFailed: "권한을 재설정하지 못했습니다."
            ]
        case .spanish:
            strings = [
                .title: "Permisos de privacidad", .subtitle: "Comprueba y gestiona los accesos necesarios para traducir la pantalla.",
                .screenRecording: "Grabación de pantalla", .accessibility: "Accesibilidad", .authorized: "Autorizado", .notAuthorized: "No autorizado",
                .requestPermission: "Autorizar", .openSystemSettings: "Abrir Ajustes del Sistema", .refresh: "Comprobar de nuevo",
                .resetPermission: "Restablecer permiso (Debug)", .resetAllPermissions: "Restablecer todos los permisos",
                .resetSucceeded: "Permiso restablecido. Compruébalo de nuevo al volver de Ajustes del Sistema.", .resetFailed: "No se pudo restablecer este permiso."
            ]
        case .french:
            strings = [
                .title: "Autorisations de confidentialité", .subtitle: "Vérifiez et gérez les accès nécessaires à la traduction d’écran.",
                .screenRecording: "Enregistrement de l’écran", .accessibility: "Accessibilité", .authorized: "Autorisé", .notAuthorized: "Non autorisé",
                .requestPermission: "Autoriser", .openSystemSettings: "Ouvrir les réglages système", .refresh: "Vérifier à nouveau",
                .resetPermission: "Réinitialiser l’autorisation (Debug)", .resetAllPermissions: "Réinitialiser toutes les autorisations",
                .resetSucceeded: "Autorisation réinitialisée. Vérifiez à nouveau après votre retour des réglages système.", .resetFailed: "Impossible de réinitialiser cette autorisation."
            ]
        case .german:
            strings = [
                .title: "Datenschutzberechtigungen", .subtitle: "Zugriffe für die Bildschirmübersetzung prüfen und verwalten.",
                .screenRecording: "Bildschirmaufnahme", .accessibility: "Bedienungshilfen", .authorized: "Erlaubt", .notAuthorized: "Nicht erlaubt",
                .requestPermission: "Erlauben", .openSystemSettings: "Systemeinstellungen öffnen", .refresh: "Erneut prüfen",
                .resetPermission: "Berechtigung zurücksetzen (Debug)", .resetAllPermissions: "Alle Berechtigungen zurücksetzen",
                .resetSucceeded: "Berechtigung zurückgesetzt. Nach der Rückkehr aus den Systemeinstellungen erneut prüfen.", .resetFailed: "Berechtigung konnte nicht zurückgesetzt werden."
            ]
        case .russian:
            strings = [
                .title: "Разрешения конфиденциальности", .subtitle: "Проверяйте и управляйте доступом, необходимым для перевода экрана.",
                .screenRecording: "Запись экрана", .accessibility: "Универсальный доступ", .authorized: "Разрешено", .notAuthorized: "Не разрешено",
                .requestPermission: "Разрешить", .openSystemSettings: "Открыть системные настройки", .refresh: "Проверить снова",
                .resetPermission: "Сбросить разрешение (Debug)", .resetAllPermissions: "Сбросить все разрешения",
                .resetSucceeded: "Разрешение сброшено. Проверьте снова после возврата из системных настроек.", .resetFailed: "Не удалось сбросить это разрешение."
            ]
        case .english:
            strings = english
        }
        return strings[key] ?? english[key] ?? ""
    }

    /// Short enough for the pointer-adjacent, auto-dismissing OCR feedback.
    static func noTextHint(language: AppInterfaceLanguage = currentLanguage) -> String {
        switch language {
        case .english: "No text recognized"
        case .traditionalChinese: "未辨識出文字"
        case .simplifiedChinese: "未识别出文字"
        case .japanese: "文字を認識できませんでした"
        case .korean: "텍스트를 인식하지 못했습니다"
        case .spanish: "No se reconoció texto"
        case .french: "Aucun texte reconnu"
        case .german: "Kein Text erkannt"
        case .russian: "Текст не распознан"
        }
    }

    static func debug(_ key: DebugKey, language: AppInterfaceLanguage = currentLanguage) -> String {
        switch key {
        case .updateTestingSection, .simulateUpdateFlow, .simulationNotice,
             .updateAvailableTitle, .updateAvailableMessage, .releaseNotesTitle, .simulatedReleaseNote, .later, .installUpdate:
            return updateSimulationText(key, language: language)
        default:
            break
        }

        let strings: [DebugKey: String]
        switch language {
        case .english:
            strings = [.title: "Debug", .description: "Tune the translation frame. Changes apply immediately.", .primaryColor: "Primary colour", .secondaryColor: "Secondary colour", .tertiaryColor: "Highlight colour", .strokeWidth: "Frame thickness", .glowWidth: "Glow spread", .animationSpeed: "Flow speed", .frameSection: "Frame appearance", .permissionsSection: "Permission testing", .copyParameters: "Copy parameters", .parametersCopied: "Parameters copied", .copyParametersHint: "Paste this JSON to update the defaults."]
        case .traditionalChinese:
            strings = [.title: "除錯", .description: "調整翻譯外框效果；變更會立即套用。", .primaryColor: "主色", .secondaryColor: "次色", .tertiaryColor: "亮點色", .strokeWidth: "框線粗細", .glowWidth: "光暈範圍", .animationSpeed: "流光速度", .frameSection: "外框線效果", .permissionsSection: "權限測試", .copyParameters: "複製參數", .parametersCopied: "參數已複製", .copyParametersHint: "可將這段 JSON 貼回來更新預設值。"]
        case .simplifiedChinese:
            strings = [.title: "调试", .description: "调整翻译外框效果；更改会立即应用。", .primaryColor: "主色", .secondaryColor: "辅助色", .tertiaryColor: "高光色", .strokeWidth: "边框粗细", .glowWidth: "光晕范围", .animationSpeed: "流光速度", .frameSection: "边框效果", .permissionsSection: "权限测试", .copyParameters: "复制参数", .parametersCopied: "参数已复制", .copyParametersHint: "可以将这段 JSON 贴回来更新默认值。"]
        case .japanese:
            strings = [.title: "デバッグ", .description: "翻訳フレームを調整します。変更はすぐに反映されます。", .primaryColor: "メインカラー", .secondaryColor: "サブカラー", .tertiaryColor: "ハイライトカラー", .strokeWidth: "フレームの太さ", .glowWidth: "グローの広がり", .animationSpeed: "流光速度", .frameSection: "フレーム表示", .permissionsSection: "権限テスト", .copyParameters: "パラメータをコピー", .parametersCopied: "パラメータをコピーしました", .copyParametersHint: "この JSON を貼り付けてデフォルト値を更新できます。"]
        case .korean:
            strings = [.title: "디버그", .description: "번역 테두리를 조정합니다. 변경 사항은 즉시 적용됩니다.", .primaryColor: "기본 색상", .secondaryColor: "보조 색상", .tertiaryColor: "강조 색상", .strokeWidth: "테두리 두께", .glowWidth: "광채 범위", .animationSpeed: "흐르는 빛 속도", .frameSection: "테두리 효과", .permissionsSection: "권한 테스트", .copyParameters: "매개변수 복사", .parametersCopied: "매개변수를 복사했습니다", .copyParametersHint: "이 JSON을 붙여 넣어 기본값을 업데이트할 수 있습니다."]
        case .spanish:
            strings = [.title: "Depuración", .description: "Ajusta el marco de traducción. Los cambios se aplican al instante.", .primaryColor: "Color principal", .secondaryColor: "Color secundario", .tertiaryColor: "Color de acento", .strokeWidth: "Grosor del marco", .glowWidth: "Extensión del brillo", .animationSpeed: "Velocidad del flujo", .frameSection: "Aspecto del marco", .permissionsSection: "Prueba de permisos", .copyParameters: "Copiar parámetros", .parametersCopied: "Parámetros copiados", .copyParametersHint: "Pega este JSON para actualizar los valores predeterminados."]
        case .french:
            strings = [.title: "Débogage", .description: "Ajustez le cadre de traduction. Les modifications s’appliquent immédiatement.", .primaryColor: "Couleur principale", .secondaryColor: "Couleur secondaire", .tertiaryColor: "Couleur d’accent", .strokeWidth: "Épaisseur du cadre", .glowWidth: "Étendue de la lueur", .animationSpeed: "Vitesse du flux", .frameSection: "Apparence du cadre", .permissionsSection: "Test des autorisations", .copyParameters: "Copier les paramètres", .parametersCopied: "Paramètres copiés", .copyParametersHint: "Collez ce JSON pour mettre à jour les valeurs par défaut."]
        case .german:
            strings = [.title: "Debug", .description: "Übersetzungsrahmen anpassen. Änderungen werden sofort übernommen.", .primaryColor: "Primärfarbe", .secondaryColor: "Sekundärfarbe", .tertiaryColor: "Akzentfarbe", .strokeWidth: "Rahmenstärke", .glowWidth: "Leuchtweite", .animationSpeed: "Fließgeschwindigkeit", .frameSection: "Rahmenoptik", .permissionsSection: "Berechtigungstest", .copyParameters: "Parameter kopieren", .parametersCopied: "Parameter kopiert", .copyParametersHint: "Füge dieses JSON ein, um die Standardwerte zu aktualisieren."]
        case .russian:
            strings = [.title: "Отладка", .description: "Настройте рамку перевода. Изменения применяются сразу.", .primaryColor: "Основной цвет", .secondaryColor: "Дополнительный цвет", .tertiaryColor: "Акцентный цвет", .strokeWidth: "Толщина рамки", .glowWidth: "Размер свечения", .animationSpeed: "Скорость потока", .frameSection: "Вид рамки", .permissionsSection: "Проверка разрешений", .copyParameters: "Скопировать параметры", .parametersCopied: "Параметры скопированы", .copyParametersHint: "Вставьте этот JSON, чтобы обновить значения по умолчанию."]
        }
        return strings[key] ?? ""
    }

    private static func updateSimulationText(_ key: DebugKey, language: AppInterfaceLanguage) -> String {
        let english: [DebugKey: String] = [
            .updateTestingSection: "Update flow testing", .simulateUpdateFlow: "Simulate an available update",
            .simulationNotice: "Shows the passive update notice in the menu bar popover. No files are downloaded or installed.",
            .updateAvailableTitle: "A new version is available", .updateAvailableMessage: "Lingo Prism %@ is ready to install.",
            .releaseNotesTitle: "What’s New", .simulatedReleaseNote: "Improved screen translation and stability.",
            .later: "Later", .installUpdate: "Update Now"
        ]
        let traditionalChinese: [DebugKey: String] = [
            .updateTestingSection: "更新流程測試", .simulateUpdateFlow: "模擬有可用更新",
            .simulationNotice: "在選單列浮動視窗顯示被動更新提示；不會下載或安裝檔案。",
            .updateAvailableTitle: "有新版本可供更新", .updateAvailableMessage: "Lingo Prism %@ 已準備好安裝。",
            .releaseNotesTitle: "更新內容", .simulatedReleaseNote: "改善螢幕翻譯與穩定性。",
            .later: "稍後", .installUpdate: "立即更新"
        ]
        let simplifiedChinese: [DebugKey: String] = [
            .updateTestingSection: "更新流程测试", .simulateUpdateFlow: "模拟有可用更新",
            .simulationNotice: "在菜单栏浮动窗口显示被动更新提示；不会下载或安装文件。",
            .updateAvailableTitle: "有新版本可供更新", .updateAvailableMessage: "Lingo Prism %@ 已准备好安装。",
            .releaseNotesTitle: "更新内容", .simulatedReleaseNote: "改进屏幕翻译与稳定性。",
            .later: "稍后", .installUpdate: "立即更新"
        ]
        if language == .traditionalChinese { return traditionalChinese[key] ?? "" }
        if language == .simplifiedChinese { return simplifiedChinese[key] ?? "" }
        return english[key] ?? ""
    }

    static func engineTitle(_ key: EngineTitle, language: AppInterfaceLanguage = currentLanguage) -> String {
        switch key {
        case .openAICompatible:
            switch language {
            case .traditionalChinese: "OpenAI 相容端點"
            case .simplifiedChinese: "OpenAI 兼容端点"
            case .japanese: "OpenAI 互換エンドポイント"
            case .korean: "OpenAI 호환 엔드포인트"
            case .spanish: "Extremo compatible con OpenAI"
            case .french: "Point de terminaison compatible OpenAI"
            case .german: "OpenAI-kompatibler Endpunkt"
            case .russian: "OpenAI-совместимый endpoint"
            case .english: "OpenAI-Compatible Endpoint"
            }
        case .macOS:
            switch language {
            case .traditionalChinese: "Mac 內建翻譯"
            case .simplifiedChinese: "Mac 内建翻译"
            case .japanese: "Mac内蔵翻訳"
            case .korean: "Mac 내장 번역"
            case .spanish: "Traducción de macOS"
            case .french: "Traduction macOS"
            case .german: "macOS-Übersetzung"
            case .russian: "Перевод macOS"
            case .english: "macOS Translation"
            }
        }
    }

    static func selfHosted(_ key: SelfHostedKey, language: AppInterfaceLanguage = currentLanguage) -> String {
        let english: [SelfHostedKey: String] = [
            .custom: "Custom", .endpoint: "Server address", .model: "Model name", .testConnection: "Test Connection",
            .systemLanguages: "System Translation Languages", .systemLanguagesSubtitle: "Availability for the selected target language",
            .installed: "Installed", .availableToDownload: "Available to download", .unsupported: "Not supported",
            .recheckLanguages: "Recheck", .downloadSelectedPair: "Download selected pair", .chooseSourceLanguage: "Choose a source language before using System Translation",
            .requiresMacOS26: "Translation in Lingo Prism requires macOS 26 or later.", .downloading: "Preparing system language download…",
            .downloadFailed: "The system language download could not be started."
        ]
        let traditionalChinese: [SelfHostedKey: String] = [
            .custom: "自訂", .endpoint: "伺服器位址", .model: "模型名稱", .testConnection: "測試連線",
            .systemLanguages: "系統翻譯語言", .systemLanguagesSubtitle: "依目前選擇的目標語言顯示可用性",
            .installed: "已安裝", .availableToDownload: "可下載", .unsupported: "不支援",
            .recheckLanguages: "重新檢查", .downloadSelectedPair: "下載所選語言配對", .chooseSourceLanguage: "使用系統翻譯前請先選擇原文語言",
            .requiresMacOS26: "Lingo Prism 內使用系統翻譯需要 macOS 26 或以上版本。", .downloading: "正在準備系統語言下載…",
            .downloadFailed: "無法開始系統語言下載。"
        ]
        let simplifiedChinese: [SelfHostedKey: String] = [
            .custom: "自定义", .endpoint: "服务器地址", .model: "模型名称", .testConnection: "测试连接",
            .systemLanguages: "系统翻译语言", .systemLanguagesSubtitle: "显示所选目标语言的可用性",
            .installed: "已安装", .availableToDownload: "可下载", .unsupported: "不支持",
            .recheckLanguages: "重新检查", .downloadSelectedPair: "下载所选语言对", .chooseSourceLanguage: "使用系统翻译前请选择源语言",
            .requiresMacOS26: "在 Lingo Prism 中使用系统翻译需要 macOS 26 或更高版本。", .downloading: "正在准备系统语言下载…",
            .downloadFailed: "无法开始系统语言下载。"
        ]
        let strings: [SelfHostedKey: String]
        switch language {
        case .traditionalChinese: strings = traditionalChinese
        case .simplifiedChinese: strings = simplifiedChinese
        case .japanese:
            strings = [.custom: "カスタム", .endpoint: "サーバーアドレス", .model: "モデル名", .testConnection: "接続をテスト", .systemLanguages: "システム翻訳言語", .systemLanguagesSubtitle: "選択中の翻訳先に対する利用状況", .installed: "インストール済み", .availableToDownload: "ダウンロード可能", .unsupported: "非対応", .recheckLanguages: "再確認", .downloadSelectedPair: "選択した言語ペアをダウンロード", .chooseSourceLanguage: "システム翻訳を使う前に原文の言語を選択してください", .requiresMacOS26: "Lingo Prism 内のシステム翻訳には macOS 26 以降が必要です。", .downloading: "システム言語のダウンロードを準備中…", .downloadFailed: "システム言語のダウンロードを開始できませんでした。"]
        case .korean:
            strings = [.custom: "사용자화", .endpoint: "서버 주소", .model: "모델 이름", .testConnection: "연결 테스트", .systemLanguages: "시스템 번역 언어", .systemLanguagesSubtitle: "선택한 대상 언어의 사용 가능 여부", .installed: "설치됨", .availableToDownload: "다운로드 가능", .unsupported: "지원되지 않음", .recheckLanguages: "다시 확인", .downloadSelectedPair: "선택한 언어 쌍 다운로드", .chooseSourceLanguage: "시스템 번역을 사용하기 전에 원본 언어를 선택하세요", .requiresMacOS26: "Lingo Prism에서 시스템 번역을 사용하려면 macOS 26 이상이 필요합니다.", .downloading: "시스템 언어 다운로드 준비 중…", .downloadFailed: "시스템 언어 다운로드를 시작할 수 없습니다."]
        case .spanish:
            strings = [.custom: "Personalizado", .endpoint: "Dirección del servidor", .model: "Nombre del modelo", .testConnection: "Probar conexión", .systemLanguages: "Idiomas de traducción del sistema", .systemLanguagesSubtitle: "Disponibilidad para el idioma de destino seleccionado", .installed: "Instalado", .availableToDownload: "Disponible para descargar", .unsupported: "No compatible", .recheckLanguages: "Comprobar de nuevo", .downloadSelectedPair: "Descargar par seleccionado", .chooseSourceLanguage: "Elige un idioma de origen antes de usar la traducción del sistema", .requiresMacOS26: "La traducción del sistema en Lingo Prism requiere macOS 26 o posterior.", .downloading: "Preparando la descarga del idioma del sistema…", .downloadFailed: "No se pudo iniciar la descarga del idioma del sistema."]
        case .french:
            strings = [.custom: "Personnalisé", .endpoint: "Adresse du serveur", .model: "Nom du modèle", .testConnection: "Tester la connexion", .systemLanguages: "Langues de traduction système", .systemLanguagesSubtitle: "Disponibilité pour la langue cible sélectionnée", .installed: "Installé", .availableToDownload: "Disponible au téléchargement", .unsupported: "Non pris en charge", .recheckLanguages: "Vérifier à nouveau", .downloadSelectedPair: "Télécharger la paire sélectionnée", .chooseSourceLanguage: "Choisissez une langue source avant d’utiliser la traduction système", .requiresMacOS26: "La traduction système dans Lingo Prism nécessite macOS 26 ou ultérieur.", .downloading: "Préparation du téléchargement de la langue système…", .downloadFailed: "Impossible de démarrer le téléchargement de la langue système."]
        case .german:
            strings = [.custom: "Benutzerdefiniert", .endpoint: "Serveradresse", .model: "Modellname", .testConnection: "Verbindung testen", .systemLanguages: "Systemübersetzungssprachen", .systemLanguagesSubtitle: "Verfügbarkeit für die gewählte Zielsprache", .installed: "Installiert", .availableToDownload: "Zum Download verfügbar", .unsupported: "Nicht unterstützt", .recheckLanguages: "Erneut prüfen", .downloadSelectedPair: "Ausgewähltes Sprachpaar laden", .chooseSourceLanguage: "Wählen Sie vor der Systemübersetzung eine Ausgangssprache", .requiresMacOS26: "Die Systemübersetzung in Lingo Prism erfordert macOS 26 oder neuer.", .downloading: "Download der Systemsprache wird vorbereitet…", .downloadFailed: "Der Download der Systemsprache konnte nicht gestartet werden."]
        case .russian:
            strings = [.custom: "Пользовательский", .endpoint: "Адрес сервера", .model: "Название модели", .testConnection: "Проверить подключение", .systemLanguages: "Языки системного перевода", .systemLanguagesSubtitle: "Доступность для выбранного целевого языка", .installed: "Установлено", .availableToDownload: "Доступно для загрузки", .unsupported: "Не поддерживается", .recheckLanguages: "Проверить снова", .downloadSelectedPair: "Загрузить выбранную пару", .chooseSourceLanguage: "Перед системным переводом выберите исходный язык", .requiresMacOS26: "Для системного перевода в Lingo Prism требуется macOS 26 или новее.", .downloading: "Подготовка загрузки системного языка…", .downloadFailed: "Не удалось начать загрузку системного языка."]
        case .english: strings = english
        }
        return strings[key] ?? english[key] ?? ""
    }

    private static func translationEngineSubtitle(language: AppInterfaceLanguage) -> String {
        switch language {
        case .traditionalChinese: "預設使用 Google，也可改用本機或系統翻譯"
        case .simplifiedChinese: "默认使用 Google，也可改用本地或系统翻译"
        case .japanese: "既定は Google。ローカルまたはシステム翻訳にも変更できます"
        case .korean: "기본값은 Google이며, 로컬 또는 시스템 번역으로 변경할 수 있습니다"
        case .spanish: "Google es el valor predeterminado; también puedes usar traducción local o del sistema"
        case .french: "Google est utilisé par défaut ; la traduction locale ou système est aussi disponible"
        case .german: "Google ist voreingestellt; lokale oder Systemübersetzung ist ebenfalls verfügbar"
        case .russian: "По умолчанию используется Google; также доступны локальный и системный перевод"
        case .english: "Google is the default; local and system translation are also available"
        }
    }

    private static let tables: [AppInterfaceLanguage: [Key: String]] = [
        .english: [
            .ok: "OK", .general: "General", .launchAtLogin: "Launch at Login", .launchAtLoginSubtitle: "Open automatically when you sign in",
            .showSettingsOnLaunch: "Show Settings at Launch", .showSettingsSubtitle: "Open this window when Lingo Prism starts",
            .interfaceLanguage: "App Language", .interfaceLanguageSubtitle: "Language used by Lingo Prism",
            .translation: "Translation", .translationLanguage: "Translation Languages", .translationLanguageSubtitle: "Choose the recognized text and target language", .sourceLanguage: "Source", .targetLanguage: "Target",
            .translationEngine: "Translation Engine", .translationEngineSubtitle: "Google is the default and needs no API key", .resultDisplay: "Result Display",
            .googleEngine: "Google (No API Key)", .bingEngine: "Bing (No API Key)", .yandexEngine: "Yandex (No API Key)", .deepLEngine: "DeepL (No API Key)", .ollamaEngine: "Local Ollama",
            .overlayPresentation: "Screen Overlay (Default)", .floatingPresentation: "Floating Window", .overlayDescription: "Redraw translation in place while keeping the screen background.", .floatingDescription: "Show a source and translation card next to the selection.",
            .ollamaURL: "Ollama server address", .ollamaModel: "Model name", .testOllama: "Test Ollama Connection", .checking: "Checking…", .testTranslation: "Test Translation", .cancelTest: "Cancel Test", .testSuccessFormat: "%@ test succeeded: %@", .testDurationFormat: " (elapsed %d ms)",
            .connectedNoModels: "Connected, but no models were found", .connectedFormat: "Connected: %@", .cannotConnect: "Unable to connect",
            .shortcut: "Shortcut", .shortcutTitle: "Start Screen Translation", .currentFormat: "Current: %@", .customShortcut: "Custom Shortcut", .pressShortcut: "Press a shortcut; Esc cancels", .modifierRequired: "At least one modifier key is required", .cancel: "Cancel", .accessibilityHelp: "To use the shortcut while another app is active, allow Lingo Prism in Privacy & Security > Accessibility.",
            .textRecognition: "Text Recognition", .visionOCR: "Vision OCR", .visionOCRSubtitle: "Text recognition happens on this Mac", .recheck: "Check Again", .manageSystemLanguages: "Manage System Languages", .visionInfo: "Vision language models are managed by macOS. Return here and check again after changing system languages.",
            .versionFormat: "Version %@", .startTranslation: "Translate Screen", .translating: "Translating…", .settings: "Settings", .quit: "Quit",
            .languageAuto: "Auto Detect", .languageEnglish: "English", .languageTraditionalChinese: "Traditional Chinese", .languageSimplifiedChinese: "Simplified Chinese", .languageJapanese: "Japanese", .languageKorean: "Korean", .languageSpanish: "Spanish", .languageFrench: "French", .languageGerman: "German", .languageRussian: "Russian",
            .statusReady: "Ready", .statusAccessibilityEnabled: "Global shortcut enabled", .statusAccessibilityDisabled: "Allow Lingo Prism in Accessibility, then return to the app", .targetRequiredTitle: "Choose a Target Language", .targetRequiredMessage: "The target language cannot be Auto Detect.",
            .statusSelectArea: "Drag to select the area to translate", .statusSelectionCancelled: "Selection cancelled", .recognizing: "Recognizing text…", .translatingText: "Translating text…", .translatedLinesFormat: "Translated %d lines", .copiedTranslation: "Translation copied to clipboard", .copiedOriginal: "Source text copied to clipboard", .couldNotTranslate: "Unable to translate", .translationUnfinished: "Translation Not Finished",
            .selectionTitle: "Select translation area", .selectionInstruction: "Drag to select · Right-click to cancel", .selectionTooSmall: "Area is too small. Drag again · Right-click to cancel", .selectionAccessibility: "Screen selection", .selectionProcessingFormat: "Processing selected area: %@", .selectionSizeFormat: "Selected area %@ × %@",
            .screenRecordingPermission: "Screen Recording permission is required. Allow Lingo Prism in System Settings > Privacy & Security, then try again.", .noScreen: "No screen is available to capture.", .captureFailed: "Unable to capture the screen image.", .selectionInvalid: "The selection is too small or outside the screen.",
            .errorNoText: "No text was recognized in the selected area. Adjust the area or zoom in and try again.", .errorTargetLanguageRequired: "Choose a target language in Settings.", .errorOllamaInvalid: "The Ollama address or model name is invalid.", .errorOllamaServiceFormat: "Ollama returned an error (%d). %@", .errorOllamaDetail: "Check the model name and server log.", .errorOllamaUnavailableFormat: "Unable to connect to Ollama (%@). Start Ollama, check the address, and make sure the model is downloaded.", .errorInvalidResponse: "The translation service returned unreadable content.", .errorRateLimitedFormat: "%@ is temporarily rate limited (429). Try again later or choose another engine.", .errorWebHTTPFormat: "%@ returned HTTP %d. The public endpoint may be temporarily unavailable or restricted.", .errorWebNetworkFormat: "Unable to connect to %@. Check the network or choose another engine.", .errorWebResponseFormat: "%@ returned unreadable content or a different number of lines. Its service interface may have changed.", .errorWebConfigurationFormat: "Enter a valid %@ HTTP(S) service address.", .errorWebCertificateFormat: "%@ returned a certificate that could not be verified. The connection was stopped.",
            .overlayTitle: "Screen Translation", .original: "Original", .translated: "Translation", .showOriginal: "Show original", .showTranslation: "Show translation", .copyTranslation: "Copy Translation", .copyOriginal: "Copy Original", .reselect: "Select Again", .close: "Close", .closeOverlay: "Close screen translation", .overlayAccessibility: "Screen translation overlay", .translationSegmentFormat: "Translation segment %d",
            .launchNeedsApproval: "macOS needs approval for Lingo Prism in Login Items.", .launchStatusUnavailable: "Unable to read the launch-at-login status.", .launchUpdateFailedFormat: "Unable to update launch at login: %@"
        ],
        .traditionalChinese: [
            .ok: "好", .general: "一般", .launchAtLogin: "登入時啟動", .launchAtLoginSubtitle: "登入 Mac 後自動開啟",
            .showSettingsOnLaunch: "啟動時顯示設定", .showSettingsSubtitle: "開啟 Lingo Prism 後立即顯示此視窗", .interfaceLanguage: "介面語言", .interfaceLanguageSubtitle: "Lingo Prism 使用的顯示語言",
            .translation: "翻譯", .translationLanguage: "翻譯語言", .translationLanguageSubtitle: "選擇辨識原文與目標語言", .sourceLanguage: "原文", .targetLanguage: "目標",
            .translationEngine: "翻譯引擎", .translationEngineSubtitle: "Google 預設免金鑰", .resultDisplay: "結果顯示", .googleEngine: "Google（免金鑰）", .bingEngine: "Bing（免金鑰）", .yandexEngine: "Yandex（免金鑰）", .deepLEngine: "DeepL（免金鑰）", .ollamaEngine: "本機 Ollama",
            .overlayPresentation: "螢幕覆蓋（預設）", .floatingPresentation: "浮動視窗", .overlayDescription: "在原文字位置重繪譯文，保留畫面背景。", .floatingDescription: "在選取區域旁顯示原文與譯文卡片。",
            .ollamaURL: "Ollama 伺服器位址", .ollamaModel: "模型名稱", .testOllama: "測試 Ollama 連線", .checking: "檢查中…", .testTranslation: "測試翻譯", .cancelTest: "取消測試", .testSuccessFormat: "%@ 測試成功：%@", .testDurationFormat: "（耗時 %d 毫秒）", .connectedNoModels: "已連線，但尚未找到模型", .connectedFormat: "已連線：%@", .cannotConnect: "無法連線",
            .shortcut: "快捷鍵", .shortcutTitle: "啟動框選翻譯", .currentFormat: "目前：%@", .customShortcut: "自訂組合", .pressShortcut: "按下組合鍵；Esc 取消", .modifierRequired: "至少需一個修飾鍵", .cancel: "取消", .accessibilityHelp: "在其他 App 前景時使用快捷鍵，需要在「隱私權與安全性 > 輔助使用」允許 Lingo Prism。",
            .textRecognition: "文字辨識", .visionOCR: "Vision OCR", .visionOCRSubtitle: "辨識會在此 Mac 本機完成", .recheck: "重新檢查", .manageSystemLanguages: "管理系統語言", .visionInfo: "Vision 語言模型由 macOS 管理；完成系統語言設定後，回到這裡重新檢查。",
            .versionFormat: "版本 %@", .startTranslation: "開始螢幕翻譯", .translating: "正在處理…", .settings: "設定", .quit: "結束",
            .languageAuto: "自動偵測", .languageEnglish: "英文", .languageTraditionalChinese: "繁體中文", .languageSimplifiedChinese: "簡體中文", .languageJapanese: "日文", .languageKorean: "韓文", .languageSpanish: "西班牙文", .languageFrench: "法文", .languageGerman: "德文", .languageRussian: "俄文",
            .statusReady: "準備就緒", .statusAccessibilityEnabled: "全域快捷鍵已啟用", .statusAccessibilityDisabled: "請在系統設定啟用「輔助使用」後回到 Lingo Prism", .targetRequiredTitle: "請選擇目標語言", .targetRequiredMessage: "目標語言不能設為「自動偵測」。", .statusSelectArea: "拖曳選取要翻譯的畫面區域", .statusSelectionCancelled: "已取消選取", .recognizing: "辨識畫面文字…", .translatingText: "正在翻譯文字…", .translatedLinesFormat: "已翻譯 %d 行文字", .copiedTranslation: "譯文已複製到剪貼簿", .copiedOriginal: "原文已複製到剪貼簿", .couldNotTranslate: "無法完成翻譯", .translationUnfinished: "翻譯未完成",
            .selectionTitle: "選取翻譯範圍", .selectionInstruction: "拖曳框選、右鍵取消", .selectionTooSmall: "範圍太小，請重新拖曳、右鍵取消", .selectionAccessibility: "螢幕框選", .selectionProcessingFormat: "正在處理選取範圍：%@", .selectionSizeFormat: "框選範圍 %@ × %@", .screenRecordingPermission: "需要「螢幕錄製」權限。請在系統設定的「隱私權與安全性」中允許 Lingo Prism，然後再試一次。", .noScreen: "找不到可擷取的螢幕。", .captureFailed: "無法擷取螢幕影像。", .selectionInvalid: "選取範圍太小或超出螢幕。",
            .errorNoText: "在選取區域中沒有辨識到文字。請調整範圍或放大內容後再試一次。", .errorTargetLanguageRequired: "請在設定中選擇目標語言。", .errorOllamaInvalid: "Ollama 位址或模型名稱無效。", .errorOllamaServiceFormat: "Ollama 回傳錯誤（%d）。%@", .errorOllamaDetail: "請檢查模型名稱與伺服器日誌。", .errorInvalidResponse: "翻譯服務回傳了無法讀取的內容。",
            .overlayTitle: "覆蓋翻譯結果", .original: "原文", .translated: "譯文", .showOriginal: "顯示原文", .showTranslation: "顯示譯文", .copyTranslation: "複製譯文", .copyOriginal: "複製原文", .reselect: "重新選取", .close: "關閉", .closeOverlay: "關閉覆蓋翻譯", .overlayAccessibility: "螢幕覆蓋翻譯", .translationSegmentFormat: "譯文第 %d 段", .launchNeedsApproval: "macOS 需要你在「登入項目」中允許 Lingo Prism。", .launchStatusUnavailable: "無法讀取開機啟動狀態。", .launchUpdateFailedFormat: "無法更新登入時啟動：%@"
        ],
        .simplifiedChinese: [
            .ok: "好", .general: "通用", .launchAtLogin: "登录时启动", .launchAtLoginSubtitle: "登录 Mac 后自动打开", .showSettingsOnLaunch: "启动时显示设置", .showSettingsSubtitle: "启动 Lingo Prism 时打开此窗口", .interfaceLanguage: "应用语言", .interfaceLanguageSubtitle: "Lingo Prism 的显示语言",
            .translation: "翻译", .translationLanguage: "翻译语言", .translationLanguageSubtitle: "选择识别原文和目标语言", .sourceLanguage: "原文", .targetLanguage: "目标", .translationEngine: "翻译引擎", .translationEngineSubtitle: "Google 默认免密钥", .resultDisplay: "结果显示", .googleEngine: "Google（免密钥）", .bingEngine: "Bing（免密钥）", .yandexEngine: "Yandex（免密钥）", .deepLEngine: "DeepL（免密钥）", .ollamaEngine: "本地 Ollama",
            .overlayPresentation: "屏幕覆盖（默认）", .floatingPresentation: "浮动窗口", .overlayDescription: "在原文位置重绘译文，保留屏幕背景。", .floatingDescription: "在选区旁显示原文和译文卡片。", .ollamaURL: "Ollama 服务器地址", .ollamaModel: "模型名称", .testOllama: "测试 Ollama 连接", .checking: "检查中…", .testTranslation: "测试翻译", .cancelTest: "取消测试", .testSuccessFormat: "%@ 测试成功：%@", .connectedNoModels: "已连接，但尚未找到模型", .connectedFormat: "已连接：%@", .cannotConnect: "无法连接",
            .shortcut: "快捷键", .shortcutTitle: "启动框选翻译", .currentFormat: "当前：%@", .customShortcut: "自定义组合键", .pressShortcut: "按下组合键；Esc 取消", .modifierRequired: "至少需要一个修饰键", .cancel: "取消", .accessibilityHelp: "在其他应用位于前台时使用快捷键，需要在“隐私与安全性 > 辅助功能”中允许 Lingo Prism。", .textRecognition: "文字识别", .visionOCR: "Vision OCR", .visionOCRSubtitle: "识别在此 Mac 本机完成", .recheck: "重新检查", .manageSystemLanguages: "管理系统语言", .visionInfo: "Vision 语言模型由 macOS 管理；更改系统语言后，请回到这里重新检查。", .versionFormat: "版本 %@", .startTranslation: "开始屏幕翻译", .translating: "正在处理…", .settings: "设置", .quit: "退出",
            .languageAuto: "自动检测", .languageEnglish: "英语", .languageTraditionalChinese: "繁体中文", .languageSimplifiedChinese: "简体中文", .languageJapanese: "日语", .languageKorean: "韩语", .languageSpanish: "西班牙语", .languageFrench: "法语", .languageGerman: "德语", .languageRussian: "俄语",
            .statusReady: "准备就绪", .statusAccessibilityEnabled: "全局快捷键已启用", .statusAccessibilityDisabled: "请在系统设置中启用“辅助功能”后返回 Lingo Prism", .targetRequiredTitle: "请选择目标语言", .targetRequiredMessage: "目标语言不能为“自动检测”。", .statusSelectArea: "拖拽选择要翻译的区域", .statusSelectionCancelled: "已取消选择", .recognizing: "正在识别文字…", .translatingText: "正在翻译文字…", .translatedLinesFormat: "已翻译 %d 行文字", .copiedTranslation: "译文已复制到剪贴板", .copiedOriginal: "原文已复制到剪贴板", .couldNotTranslate: "无法完成翻译", .translationUnfinished: "翻译未完成",
            .selectionTitle: "选择翻译区域", .selectionInstruction: "拖拽框选、右键取消", .selectionTooSmall: "区域太小，请重新拖拽、右键取消", .selectionAccessibility: "屏幕框选", .screenRecordingPermission: "需要“屏幕录制”权限。请在系统设置的“隐私与安全性”中允许 Lingo Prism，然后重试。", .noScreen: "找不到可捕捉的屏幕。", .captureFailed: "无法捕捉屏幕图像。", .selectionInvalid: "选区太小或超出屏幕。",
            .errorNoText: "在选区中没有识别到文字。请调整范围或放大内容后重试。", .errorTargetLanguageRequired: "请在设置中选择目标语言。", .errorOllamaInvalid: "Ollama 地址或模型名称无效。", .errorOllamaServiceFormat: "Ollama 返回错误（%d）。%@", .errorOllamaDetail: "请检查模型名称和服务器日志。", .errorInvalidResponse: "翻译服务返回了无法读取的内容。", .overlayTitle: "屏幕翻译结果", .original: "原文", .translated: "译文", .showOriginal: "显示原文", .showTranslation: "显示译文", .copyTranslation: "复制译文", .copyOriginal: "复制原文", .reselect: "重新选择", .close: "关闭", .closeOverlay: "关闭屏幕翻译", .overlayAccessibility: "屏幕覆盖翻译", .translationSegmentFormat: "译文第 %d 段", .launchNeedsApproval: "macOS 需要你在“登录项”中允许 Lingo Prism。", .launchStatusUnavailable: "无法读取登录启动状态。", .launchUpdateFailedFormat: "无法更新登录启动：%@"
        ],
        .japanese: [
            .ok: "OK", .general: "一般", .launchAtLogin: "ログイン時に起動", .launchAtLoginSubtitle: "Mac へのサインイン時に自動で開く", .showSettingsOnLaunch: "起動時に設定を表示", .showSettingsSubtitle: "Lingo Prism の起動時にこのウインドウを開く", .interfaceLanguage: "アプリの言語", .interfaceLanguageSubtitle: "Lingo Prism で使用する表示言語",
            .translation: "翻訳", .translationLanguage: "翻訳言語", .translationLanguageSubtitle: "認識する原文と翻訳先を選択", .sourceLanguage: "原文", .targetLanguage: "翻訳先", .translationEngine: "翻訳エンジン", .translationEngineSubtitle: "Google はデフォルトで API キー不要", .resultDisplay: "結果の表示", .googleEngine: "Google（API キー不要）", .bingEngine: "Bing（API キー不要）", .yandexEngine: "Yandex（API キー不要）", .deepLEngine: "DeepL（API キー不要）", .ollamaEngine: "ローカル Ollama",
            .overlayPresentation: "画面オーバーレイ（デフォルト）", .floatingPresentation: "フローティングウインドウ", .overlayDescription: "画面の背景を残したまま原文位置に翻訳を描画します。", .floatingDescription: "選択範囲の横に原文と翻訳のカードを表示します。", .ollamaURL: "Ollama サーバーアドレス", .ollamaModel: "モデル名", .testOllama: "Ollama 接続をテスト", .checking: "確認中…", .testTranslation: "翻訳をテスト", .cancelTest: "テストをキャンセル", .testSuccessFormat: "%@ のテストに成功しました：%@", .connectedNoModels: "接続済みですが、モデルがありません", .connectedFormat: "接続済み：%@", .cannotConnect: "接続できません",
            .shortcut: "ショートカット", .shortcutTitle: "画面翻訳を開始", .currentFormat: "現在：%@", .customShortcut: "カスタムショートカット", .pressShortcut: "ショートカットを押してください。Esc でキャンセル", .modifierRequired: "修飾キーを 1 つ以上指定してください", .cancel: "キャンセル", .accessibilityHelp: "ほかのアプリが前面にあるときにショートカットを使うには、「プライバシーとセキュリティ > アクセシビリティ」で Lingo Prism を許可してください。", .textRecognition: "テキスト認識", .visionOCR: "Vision OCR", .visionOCRSubtitle: "認識はこの Mac 上で実行されます", .recheck: "再確認", .manageSystemLanguages: "システム言語を管理", .visionInfo: "Vision の言語モデルは macOS が管理しています。システム言語を変更した後、ここに戻って再確認してください。", .versionFormat: "バージョン %@", .startTranslation: "画面を翻訳", .translating: "翻訳中…", .settings: "設定", .quit: "終了",
            .languageAuto: "自動検出", .languageEnglish: "英語", .languageTraditionalChinese: "繁体字中国語", .languageSimplifiedChinese: "簡体字中国語", .languageJapanese: "日本語", .languageKorean: "韓国語", .languageSpanish: "スペイン語", .languageFrench: "フランス語", .languageGerman: "ドイツ語", .languageRussian: "ロシア語",
            .statusReady: "準備完了", .statusAccessibilityEnabled: "グローバルショートカットを有効にしました", .statusAccessibilityDisabled: "「アクセシビリティ」で Lingo Prism を許可してからアプリに戻ってください", .targetRequiredTitle: "翻訳先の言語を選択", .targetRequiredMessage: "翻訳先を「自動検出」にすることはできません。", .statusSelectArea: "翻訳する範囲をドラッグして選択", .statusSelectionCancelled: "選択をキャンセルしました", .recognizing: "文字を認識中…", .translatingText: "文字を翻訳中…", .translatedLinesFormat: "%d 行を翻訳しました", .copiedTranslation: "翻訳をクリップボードにコピーしました", .copiedOriginal: "原文をクリップボードにコピーしました", .couldNotTranslate: "翻訳できません", .translationUnfinished: "翻訳を完了できませんでした",
            .selectionTitle: "翻訳範囲を選択", .selectionInstruction: "ドラッグして選択・右クリックでキャンセル", .selectionTooSmall: "範囲が小さすぎます。再度ドラッグ・右クリックでキャンセル", .selectionAccessibility: "画面選択", .screenRecordingPermission: "「画面収録」アクセスが必要です。システム設定 > プライバシーとセキュリティで Lingo Prism を許可してから、もう一度試してください。", .noScreen: "キャプチャ可能な画面がありません。", .captureFailed: "画面イメージをキャプチャできません。", .selectionInvalid: "選択範囲が小さすぎるか、画面外です。",
            .errorNoText: "選択範囲内に文字が見つかりませんでした。範囲を調整するか拡大して再試行してください。", .errorTargetLanguageRequired: "設定で翻訳先の言語を選択してください。", .errorOllamaInvalid: "Ollama のアドレスまたはモデル名が無効です。", .errorOllamaServiceFormat: "Ollama がエラーを返しました（%d）。%@", .errorOllamaDetail: "モデル名とサーバーログを確認してください。", .errorInvalidResponse: "翻訳サービスから読み取れない内容が返されました。", .overlayTitle: "画面翻訳結果", .original: "原文", .translated: "翻訳", .showOriginal: "原文を表示", .showTranslation: "翻訳を表示", .copyTranslation: "翻訳をコピー", .copyOriginal: "原文をコピー", .reselect: "再選択", .close: "閉じる", .closeOverlay: "画面翻訳を閉じる", .overlayAccessibility: "画面オーバーレイ翻訳", .translationSegmentFormat: "翻訳セグメント %d", .launchNeedsApproval: "「ログイン項目」で Lingo Prism の許可が必要です。", .launchStatusUnavailable: "ログイン時起動の状態を読み取れません。", .launchUpdateFailedFormat: "ログイン時起動を更新できません：%@"
        ],
        .korean: [
            .ok: "확인", .general: "일반", .launchAtLogin: "로그인 시 실행", .launchAtLoginSubtitle: "Mac에 로그인하면 자동으로 열기", .showSettingsOnLaunch: "시작 시 설정 표시", .showSettingsSubtitle: "Lingo Prism를 시작할 때 이 윈도우 열기", .interfaceLanguage: "앱 언어", .interfaceLanguageSubtitle: "Lingo Prism에 사용할 표시 언어", .translation: "번역", .translationLanguage: "번역 언어", .translationLanguageSubtitle: "인식할 원문과 대상 언어 선택", .sourceLanguage: "원문", .targetLanguage: "대상", .translationEngine: "번역 엔진", .translationEngineSubtitle: "Google은 기본값이며 API 키가 필요하지 않음", .resultDisplay: "결과 표시", .googleEngine: "Google(API 키 없음)", .bingEngine: "Bing(API 키 없음)", .yandexEngine: "Yandex(API 키 없음)", .deepLEngine: "DeepL(API 키 없음)", .ollamaEngine: "로컬 Ollama", .overlayPresentation: "화면 오버레이(기본)", .floatingPresentation: "플로팅 윈도우", .overlayDescription: "화면 배경을 유지하며 원문 위치에 번역을 다시 그립니다.", .floatingDescription: "선택 영역 옆에 원문과 번역 카드를 표시합니다.", .ollamaURL: "Ollama 서버 주소", .ollamaModel: "모델 이름", .testOllama: "Ollama 연결 테스트", .checking: "확인 중…", .testTranslation: "번역 테스트", .cancelTest: "테스트 취소", .testSuccessFormat: "%@ 테스트 성공: %@", .connectedNoModels: "연결되었지만 모델을 찾지 못했습니다", .connectedFormat: "연결됨: %@", .cannotConnect: "연결할 수 없음", .shortcut: "단축키", .shortcutTitle: "화면 번역 시작", .currentFormat: "현재: %@", .customShortcut: "사용자화 단축키", .pressShortcut: "단축키를 누르세요. Esc는 취소", .modifierRequired: "보조 키가 하나 이상 필요합니다", .cancel: "취소", .accessibilityHelp: "다른 앱이 활성화된 상태에서 단축키를 사용하려면 개인정보 보호 및 보안 > 손쉬운 사용에서 Lingo Prism를 허용하세요.", .textRecognition: "텍스트 인식", .visionOCR: "Vision OCR", .visionOCRSubtitle: "인식은 이 Mac에서 수행됩니다", .recheck: "다시 확인", .manageSystemLanguages: "시스템 언어 관리", .visionInfo: "Vision 언어 모델은 macOS가 관리합니다. 시스템 언어를 변경한 후 여기로 돌아와 다시 확인하세요.", .versionFormat: "버전 %@", .startTranslation: "화면 번역", .translating: "번역 중…", .settings: "설정", .quit: "종료", .languageAuto: "자동 감지", .languageEnglish: "영어", .languageTraditionalChinese: "번체 중국어", .languageSimplifiedChinese: "간체 중국어", .languageJapanese: "일본어", .languageKorean: "한국어", .languageSpanish: "스페인어", .languageFrench: "프랑스어", .languageGerman: "독일어", .languageRussian: "러시아어",
            .statusReady: "준비 완료", .statusAccessibilityEnabled: "전역 단축키가 활성화됨", .statusAccessibilityDisabled: "손쉬운 사용에서 Lingo Prism를 허용한 후 앱으로 돌아오세요", .targetRequiredTitle: "대상 언어 선택", .targetRequiredMessage: "대상 언어는 자동 감지가 될 수 없습니다.", .statusSelectArea: "번역할 영역을 드래그하여 선택", .statusSelectionCancelled: "선택 취소됨", .recognizing: "텍스트 인식 중…", .translatingText: "텍스트 번역 중…", .translatedLinesFormat: "%d줄 번역됨", .copiedTranslation: "번역이 클립보드에 복사됨", .copiedOriginal: "원문이 클립보드에 복사됨", .couldNotTranslate: "번역할 수 없음", .translationUnfinished: "번역을 완료하지 못함", .selectionTitle: "번역 영역 선택", .selectionInstruction: "드래그하여 선택 · 오른쪽 클릭으로 취소", .selectionTooSmall: "영역이 너무 작습니다. 다시 드래그 · 오른쪽 클릭으로 취소", .selectionAccessibility: "화면 선택", .screenRecordingPermission: "화면 기록 권한이 필요합니다. 시스템 설정 > 개인정보 보호 및 보안에서 Lingo Prism를 허용한 후 다시 시도하세요.", .noScreen: "캡처할 수 있는 화면이 없습니다.", .captureFailed: "화면 이미지를 캡처할 수 없습니다.", .selectionInvalid: "선택 영역이 너무 작거나 화면 밖에 있습니다.", .errorNoText: "선택 영역에서 텍스트를 인식하지 못했습니다. 범위를 조정하거나 확대 후 다시 시도하세요.", .errorTargetLanguageRequired: "설정에서 대상 언어를 선택하세요.", .errorOllamaInvalid: "Ollama 주소 또는 모델 이름이 잘못되었습니다.", .errorOllamaServiceFormat: "Ollama 오류(%d): %@", .errorOllamaDetail: "모델 이름과 서버 로그를 확인하세요.", .errorInvalidResponse: "번역 서비스에서 읽을 수 없는 내용을 반환했습니다.", .overlayTitle: "화면 번역 결과", .original: "원문", .translated: "번역", .showOriginal: "원문 표시", .showTranslation: "번역 표시", .copyTranslation: "번역 복사", .copyOriginal: "원문 복사", .reselect: "다시 선택", .close: "닫기", .closeOverlay: "화면 번역 닫기", .overlayAccessibility: "화면 오버레이 번역", .translationSegmentFormat: "번역 구간 %d", .launchNeedsApproval: "로그인 항목에서 Lingo Prism 승인이 필요합니다.", .launchStatusUnavailable: "로그인 시 실행 상태를 읽을 수 없습니다.", .launchUpdateFailedFormat: "로그인 시 실행을 업데이트할 수 없음: %@"
        ],
        .spanish: [
            .ok: "Aceptar", .general: "General", .launchAtLogin: "Abrir al iniciar sesión", .launchAtLoginSubtitle: "Abrir automáticamente al iniciar sesión", .showSettingsOnLaunch: "Mostrar ajustes al abrir", .showSettingsSubtitle: "Abrir esta ventana al iniciar Lingo Prism", .interfaceLanguage: "Idioma de la app", .interfaceLanguageSubtitle: "Idioma que usa Lingo Prism", .translation: "Traducción", .translationLanguage: "Idiomas de traducción", .translationLanguageSubtitle: "Elige el texto reconocido y el idioma de destino", .sourceLanguage: "Origen", .targetLanguage: "Destino", .translationEngine: "Motor de traducción", .translationEngineSubtitle: "Google es predeterminado y no requiere clave API", .resultDisplay: "Mostrar resultado", .googleEngine: "Google (sin clave API)", .bingEngine: "Bing (sin clave API)", .yandexEngine: "Yandex (sin clave API)", .deepLEngine: "DeepL (sin clave API)", .ollamaEngine: "Ollama local", .overlayPresentation: "Superposición de pantalla (predeterminado)", .floatingPresentation: "Ventana flotante", .overlayDescription: "Redibuja la traducción en su lugar y conserva el fondo.", .floatingDescription: "Muestra una tarjeta de original y traducción junto a la selección.", .ollamaURL: "Dirección del servidor Ollama", .ollamaModel: "Nombre del modelo", .testOllama: "Probar conexión de Ollama", .checking: "Comprobando…", .testTranslation: "Probar traducción", .cancelTest: "Cancelar prueba", .testSuccessFormat: "Prueba de %@ correcta: %@", .connectedNoModels: "Conectado, pero no se encontraron modelos", .connectedFormat: "Conectado: %@", .cannotConnect: "No se puede conectar", .shortcut: "Atajo", .shortcutTitle: "Iniciar traducción de pantalla", .currentFormat: "Actual: %@", .customShortcut: "Atajo personalizado", .pressShortcut: "Pulsa un atajo; Esc cancela", .modifierRequired: "Se requiere al menos una tecla modificadora", .cancel: "Cancelar", .accessibilityHelp: "Para usar el atajo con otra app activa, permite Lingo Prism en Privacidad y seguridad > Accesibilidad.", .textRecognition: "Reconocimiento de texto", .visionOCR: "Vision OCR", .visionOCRSubtitle: "El reconocimiento se realiza en este Mac", .recheck: "Comprobar de nuevo", .manageSystemLanguages: "Gestionar idiomas del sistema", .visionInfo: "macOS gestiona los modelos de idioma de Vision. Vuelve y comprueba de nuevo tras cambiar los idiomas del sistema.", .versionFormat: "Versión %@", .startTranslation: "Traducir pantalla", .translating: "Traduciendo…", .settings: "Ajustes", .quit: "Salir", .languageAuto: "Detectar automáticamente", .languageEnglish: "Inglés", .languageTraditionalChinese: "Chino tradicional", .languageSimplifiedChinese: "Chino simplificado", .languageJapanese: "Japonés", .languageKorean: "Coreano", .languageSpanish: "Español", .languageFrench: "Francés", .languageGerman: "Alemán", .languageRussian: "Ruso",
            .statusReady: "Listo", .statusAccessibilityEnabled: "Atajo global activado", .statusAccessibilityDisabled: "Permite Lingo Prism en Accesibilidad y vuelve a la app", .targetRequiredTitle: "Elige un idioma de destino", .targetRequiredMessage: "El idioma de destino no puede ser la detección automática.", .statusSelectArea: "Arrastra para seleccionar el área que quieres traducir", .statusSelectionCancelled: "Selección cancelada", .recognizing: "Reconociendo texto…", .translatingText: "Traduciendo texto…", .translatedLinesFormat: "%d líneas traducidas", .copiedTranslation: "Traducción copiada al portapapeles", .copiedOriginal: "Texto original copiado al portapapeles", .couldNotTranslate: "No se puede traducir", .translationUnfinished: "Traducción sin terminar", .selectionTitle: "Seleccionar área de traducción", .selectionInstruction: "Arrastra para seleccionar · Clic derecho para cancelar", .selectionTooSmall: "El área es demasiado pequeña. Arrastra de nuevo · Clic derecho para cancelar", .selectionAccessibility: "Selección de pantalla", .screenRecordingPermission: "Se requiere permiso de grabación de pantalla. Permite Lingo Prism en Configuración del Sistema > Privacidad y seguridad y vuelve a intentarlo.", .noScreen: "No hay una pantalla disponible para capturar.", .captureFailed: "No se pudo capturar la imagen de pantalla.", .selectionInvalid: "La selección es demasiado pequeña o está fuera de la pantalla.", .errorNoText: "No se reconoció texto en el área seleccionada. Ajusta el área o amplía el contenido e inténtalo de nuevo.", .errorTargetLanguageRequired: "Elige un idioma de destino en Ajustes.", .errorOllamaInvalid: "La dirección o el nombre de modelo de Ollama no es válido.", .errorOllamaServiceFormat: "Ollama devolvió un error (%d). %@", .errorOllamaDetail: "Comprueba el nombre del modelo y el registro del servidor.", .errorInvalidResponse: "El servicio de traducción devolvió contenido ilegible.", .overlayTitle: "Traducción de pantalla", .original: "Original", .translated: "Traducción", .showOriginal: "Mostrar original", .showTranslation: "Mostrar traducción", .copyTranslation: "Copiar traducción", .copyOriginal: "Copiar original", .reselect: "Seleccionar de nuevo", .close: "Cerrar", .closeOverlay: "Cerrar traducción de pantalla", .overlayAccessibility: "Superposición de traducción de pantalla", .translationSegmentFormat: "Segmento de traducción %d", .launchNeedsApproval: "macOS necesita aprobación para Lingo Prism en Ítems de inicio.", .launchStatusUnavailable: "No se puede leer el estado de inicio de sesión.", .launchUpdateFailedFormat: "No se pudo actualizar el inicio de sesión: %@"
        ],
        .french: [
            .ok: "OK", .general: "Général", .launchAtLogin: "Ouvrir à la connexion", .launchAtLoginSubtitle: "Ouvrir automatiquement à votre connexion", .showSettingsOnLaunch: "Afficher les réglages au lancement", .showSettingsSubtitle: "Ouvrir cette fenêtre au démarrage de Lingo Prism", .interfaceLanguage: "Langue de l’app", .interfaceLanguageSubtitle: "Langue utilisée par Lingo Prism", .translation: "Traduction", .translationLanguage: "Langues de traduction", .translationLanguageSubtitle: "Choisissez le texte reconnu et la langue cible", .sourceLanguage: "Source", .targetLanguage: "Cible", .translationEngine: "Moteur de traduction", .translationEngineSubtitle: "Google est le choix par défaut, sans clé API", .resultDisplay: "Affichage du résultat", .googleEngine: "Google (sans clé API)", .bingEngine: "Bing (sans clé API)", .yandexEngine: "Yandex (sans clé API)", .deepLEngine: "DeepL (sans clé API)", .ollamaEngine: "Ollama local", .overlayPresentation: "Superposition d’écran (par défaut)", .floatingPresentation: "Fenêtre flottante", .overlayDescription: "Redessine la traduction à sa place en conservant le fond.", .floatingDescription: "Affiche une carte du texte source et de la traduction près de la sélection.", .ollamaURL: "Adresse du serveur Ollama", .ollamaModel: "Nom du modèle", .testOllama: "Tester la connexion Ollama", .checking: "Vérification…", .testTranslation: "Tester la traduction", .cancelTest: "Annuler le test", .testSuccessFormat: "Test %@ réussi : %@", .connectedNoModels: "Connecté, mais aucun modèle n’a été trouvé", .connectedFormat: "Connecté : %@", .cannotConnect: "Impossible de se connecter", .shortcut: "Raccourci", .shortcutTitle: "Démarrer la traduction d’écran", .currentFormat: "Actuel : %@", .customShortcut: "Raccourci personnalisé", .pressShortcut: "Appuyez sur un raccourci ; Échap annule", .modifierRequired: "Au moins une touche de modification est requise", .cancel: "Annuler", .accessibilityHelp: "Pour utiliser le raccourci lorsqu’une autre app est active, autorisez Lingo Prism dans Confidentialité et sécurité > Accessibilité.", .textRecognition: "Reconnaissance de texte", .visionOCR: "Vision OCR", .visionOCRSubtitle: "La reconnaissance s’effectue sur ce Mac", .recheck: "Vérifier à nouveau", .manageSystemLanguages: "Gérer les langues système", .visionInfo: "Les modèles linguistiques Vision sont gérés par macOS. Revenez ici après avoir changé les langues système.", .versionFormat: "Version %@", .startTranslation: "Traduire l’écran", .translating: "Traduction…", .settings: "Réglages", .quit: "Quitter", .languageAuto: "Détection automatique", .languageEnglish: "Anglais", .languageTraditionalChinese: "Chinois traditionnel", .languageSimplifiedChinese: "Chinois simplifié", .languageJapanese: "Japonais", .languageKorean: "Coréen", .languageSpanish: "Espagnol", .languageFrench: "Français", .languageGerman: "Allemand", .languageRussian: "Russe",
            .statusReady: "Prêt", .statusAccessibilityEnabled: "Raccourci global activé", .statusAccessibilityDisabled: "Autorisez Lingo Prism dans Accessibilité, puis revenez dans l’app", .targetRequiredTitle: "Choisir une langue cible", .targetRequiredMessage: "La langue cible ne peut pas être Détection automatique.", .statusSelectArea: "Faites glisser pour sélectionner la zone à traduire", .statusSelectionCancelled: "Sélection annulée", .recognizing: "Reconnaissance du texte…", .translatingText: "Traduction du texte…", .translatedLinesFormat: "%d lignes traduites", .copiedTranslation: "Traduction copiée dans le presse-papiers", .copiedOriginal: "Texte source copié dans le presse-papiers", .couldNotTranslate: "Impossible de traduire", .translationUnfinished: "Traduction non terminée", .selectionTitle: "Sélectionner une zone de traduction", .selectionInstruction: "Faites glisser pour sélectionner · clic droit pour annuler", .selectionTooSmall: "La zone est trop petite. Faites glisser à nouveau · clic droit pour annuler", .selectionAccessibility: "Sélection d’écran", .screenRecordingPermission: "L’autorisation d’enregistrement de l’écran est requise. Autorisez Lingo Prism dans Réglages Système > Confidentialité et sécurité, puis réessayez.", .noScreen: "Aucun écran n’est disponible pour la capture.", .captureFailed: "Impossible de capturer l’image de l’écran.", .selectionInvalid: "La sélection est trop petite ou hors de l’écran.", .errorNoText: "Aucun texte n’a été reconnu dans la zone sélectionnée. Ajustez la zone ou zoomez puis réessayez.", .errorTargetLanguageRequired: "Choisissez une langue cible dans Réglages.", .errorOllamaInvalid: "L’adresse ou le nom de modèle Ollama n’est pas valide.", .errorOllamaServiceFormat: "Ollama a renvoyé une erreur (%d). %@", .errorOllamaDetail: "Vérifiez le nom du modèle et le journal du serveur.", .errorInvalidResponse: "Le service de traduction a renvoyé un contenu illisible.", .overlayTitle: "Traduction d’écran", .original: "Original", .translated: "Traduction", .showOriginal: "Afficher l’original", .showTranslation: "Afficher la traduction", .copyTranslation: "Copier la traduction", .copyOriginal: "Copier l’original", .reselect: "Sélectionner à nouveau", .close: "Fermer", .closeOverlay: "Fermer la traduction d’écran", .overlayAccessibility: "Superposition de traduction d’écran", .translationSegmentFormat: "Segment de traduction %d", .launchNeedsApproval: "macOS nécessite l’approbation de Lingo Prism dans Ouverture à la connexion.", .launchStatusUnavailable: "Impossible de lire l’état de l’ouverture à la connexion.", .launchUpdateFailedFormat: "Impossible de mettre à jour l’ouverture à la connexion : %@"
        ],
        .german: [
            .ok: "OK", .general: "Allgemein", .launchAtLogin: "Bei Anmeldung starten", .launchAtLoginSubtitle: "Beim Anmelden am Mac automatisch öffnen", .showSettingsOnLaunch: "Einstellungen beim Start zeigen", .showSettingsSubtitle: "Dieses Fenster beim Start von Lingo Prism öffnen", .interfaceLanguage: "App-Sprache", .interfaceLanguageSubtitle: "Anzeigesprache von Lingo Prism", .translation: "Übersetzung", .translationLanguage: "Übersetzungssprachen", .translationLanguageSubtitle: "Erkannten Text und Zielsprache auswählen", .sourceLanguage: "Quelle", .targetLanguage: "Ziel", .translationEngine: "Übersetzungsmodul", .translationEngineSubtitle: "Google ist Standard und benötigt keinen API-Schlüssel", .resultDisplay: "Ergebnisanzeige", .googleEngine: "Google (ohne API-Schlüssel)", .bingEngine: "Bing (ohne API-Schlüssel)", .yandexEngine: "Yandex (ohne API-Schlüssel)", .deepLEngine: "DeepL (ohne API-Schlüssel)", .ollamaEngine: "Lokales Ollama", .overlayPresentation: "Bildschirmüberlagerung (Standard)", .floatingPresentation: "Schwebefenster", .overlayDescription: "Zeichnet die Übersetzung an gleicher Stelle und behält den Hintergrund.", .floatingDescription: "Zeigt eine Karte mit Original und Übersetzung neben der Auswahl.", .ollamaURL: "Ollama-Serveradresse", .ollamaModel: "Modellname", .testOllama: "Ollama-Verbindung testen", .checking: "Prüfen…", .testTranslation: "Übersetzung testen", .cancelTest: "Test abbrechen", .testSuccessFormat: "%@-Test erfolgreich: %@", .connectedNoModels: "Verbunden, aber keine Modelle gefunden", .connectedFormat: "Verbunden: %@", .cannotConnect: "Verbindung nicht möglich", .shortcut: "Kurzbefehl", .shortcutTitle: "Bildschirmübersetzung starten", .currentFormat: "Aktuell: %@", .customShortcut: "Eigener Kurzbefehl", .pressShortcut: "Kurzbefehl drücken; Esc bricht ab", .modifierRequired: "Mindestens eine Sondertaste ist erforderlich", .cancel: "Abbrechen", .accessibilityHelp: "Um den Kurzbefehl bei aktiver anderer App zu verwenden, erlaube Lingo Prism unter Datenschutz & Sicherheit > Bedienungshilfen.", .textRecognition: "Texterkennung", .visionOCR: "Vision OCR", .visionOCRSubtitle: "Die Erkennung erfolgt auf diesem Mac", .recheck: "Erneut prüfen", .manageSystemLanguages: "Systemsprachen verwalten", .visionInfo: "Vision-Sprachmodelle werden von macOS verwaltet. Kehre hierher zurück und prüfe erneut, nachdem du die Systemsprachen geändert hast.", .versionFormat: "Version %@", .startTranslation: "Bildschirm übersetzen", .translating: "Übersetzen…", .settings: "Einstellungen", .quit: "Beenden", .languageAuto: "Automatisch erkennen", .languageEnglish: "Englisch", .languageTraditionalChinese: "Traditionelles Chinesisch", .languageSimplifiedChinese: "Vereinfachtes Chinesisch", .languageJapanese: "Japanisch", .languageKorean: "Koreanisch", .languageSpanish: "Spanisch", .languageFrench: "Französisch", .languageGerman: "Deutsch", .languageRussian: "Russisch",
            .statusReady: "Bereit", .statusAccessibilityEnabled: "Globaler Kurzbefehl aktiviert", .statusAccessibilityDisabled: "Erlaube Lingo Prism unter Bedienungshilfen und kehre dann zur App zurück", .targetRequiredTitle: "Zielsprache auswählen", .targetRequiredMessage: "Die Zielsprache kann nicht automatisch erkannt werden.", .statusSelectArea: "Zum Auswählen des zu übersetzenden Bereichs ziehen", .statusSelectionCancelled: "Auswahl abgebrochen", .recognizing: "Text wird erkannt…", .translatingText: "Text wird übersetzt…", .translatedLinesFormat: "%d Zeilen übersetzt", .copiedTranslation: "Übersetzung in die Zwischenablage kopiert", .copiedOriginal: "Originaltext in die Zwischenablage kopiert", .couldNotTranslate: "Übersetzung nicht möglich", .translationUnfinished: "Übersetzung nicht abgeschlossen", .selectionTitle: "Übersetzungsbereich auswählen", .selectionInstruction: "Zum Auswählen ziehen · Rechtsklick zum Abbrechen", .selectionTooSmall: "Bereich ist zu klein. Erneut ziehen · Rechtsklick zum Abbrechen", .selectionAccessibility: "Bildschirmauswahl", .screenRecordingPermission: "Die Berechtigung zur Bildschirmaufnahme ist erforderlich. Erlaube Lingo Prism unter Systemeinstellungen > Datenschutz & Sicherheit und versuche es erneut.", .noScreen: "Kein Bildschirm zur Aufnahme verfügbar.", .captureFailed: "Bildschirmbild konnte nicht aufgenommen werden.", .selectionInvalid: "Die Auswahl ist zu klein oder liegt außerhalb des Bildschirms.", .errorNoText: "Im ausgewählten Bereich wurde kein Text erkannt. Passe den Bereich an oder vergrößere den Inhalt und versuche es erneut.", .errorTargetLanguageRequired: "Wähle in den Einstellungen eine Zielsprache aus.", .errorOllamaInvalid: "Ollama-Adresse oder Modellname ist ungültig.", .errorOllamaServiceFormat: "Ollama hat einen Fehler zurückgegeben (%d). %@", .errorOllamaDetail: "Überprüfe Modellname und Serverprotokoll.", .errorInvalidResponse: "Der Übersetzungsdienst hat unlesbare Inhalte zurückgegeben.", .overlayTitle: "Bildschirmübersetzung", .original: "Original", .translated: "Übersetzung", .showOriginal: "Original anzeigen", .showTranslation: "Übersetzung anzeigen", .copyTranslation: "Übersetzung kopieren", .copyOriginal: "Original kopieren", .reselect: "Erneut auswählen", .close: "Schließen", .closeOverlay: "Bildschirmübersetzung schließen", .overlayAccessibility: "Bildschirmübersetzungs-Overlay", .translationSegmentFormat: "Übersetzungssegment %d", .launchNeedsApproval: "macOS benötigt die Genehmigung für Lingo Prism in Anmeldeobjekten.", .launchStatusUnavailable: "Status für Start bei Anmeldung kann nicht gelesen werden.", .launchUpdateFailedFormat: "Start bei Anmeldung konnte nicht aktualisiert werden: %@"
        ],
        .russian: [
            .ok: "ОК", .general: "Основные", .launchAtLogin: "Открывать при входе", .launchAtLoginSubtitle: "Автоматически открывать при входе в Mac", .showSettingsOnLaunch: "Показывать настройки при запуске", .showSettingsSubtitle: "Открывать это окно при запуске Lingo Prism", .interfaceLanguage: "Язык приложения", .interfaceLanguageSubtitle: "Язык интерфейса Lingo Prism", .translation: "Перевод", .translationLanguage: "Языки перевода", .translationLanguageSubtitle: "Выберите распознаваемый текст и язык перевода", .sourceLanguage: "Исходный", .targetLanguage: "Целевой", .translationEngine: "Сервис перевода", .translationEngineSubtitle: "Google используется по умолчанию и не требует ключа API", .resultDisplay: "Отображение результата", .googleEngine: "Google (без ключа API)", .bingEngine: "Bing (без ключа API)", .yandexEngine: "Yandex (без ключа API)", .deepLEngine: "DeepL (без ключа API)", .ollamaEngine: "Локальный Ollama", .overlayPresentation: "Наложение на экран (по умолчанию)", .floatingPresentation: "Плавающее окно", .overlayDescription: "Перерисовывает перевод на месте, сохраняя фон экрана.", .floatingDescription: "Показывает карточку оригинала и перевода рядом с выделением.", .ollamaURL: "Адрес сервера Ollama", .ollamaModel: "Имя модели", .testOllama: "Проверить подключение Ollama", .checking: "Проверка…", .testTranslation: "Проверить перевод", .cancelTest: "Отменить проверку", .testSuccessFormat: "%@ успешно проверен: %@", .connectedNoModels: "Подключено, но модели не найдены", .connectedFormat: "Подключено: %@", .cannotConnect: "Не удаётся подключиться", .shortcut: "Сочетание клавиш", .shortcutTitle: "Начать перевод экрана", .currentFormat: "Текущее: %@", .customShortcut: "Своё сочетание", .pressShortcut: "Нажмите сочетание; Esc отменяет", .modifierRequired: "Нужна хотя бы одна клавиша-модификатор", .cancel: "Отмена", .accessibilityHelp: "Чтобы использовать сочетание, когда активно другое приложение, разрешите Lingo Prism в «Конфиденциальность и безопасность» > «Универсальный доступ».", .textRecognition: "Распознавание текста", .visionOCR: "Vision OCR", .visionOCRSubtitle: "Распознавание выполняется на этом Mac", .recheck: "Проверить снова", .manageSystemLanguages: "Управлять системными языками", .visionInfo: "Языковые модели Vision управляются macOS. После изменения системных языков вернитесь сюда и проверьте снова.", .versionFormat: "Версия %@", .startTranslation: "Перевести экран", .translating: "Перевод…", .settings: "Настройки", .quit: "Выйти", .languageAuto: "Определять автоматически", .languageEnglish: "Английский", .languageTraditionalChinese: "Традиционный китайский", .languageSimplifiedChinese: "Упрощённый китайский", .languageJapanese: "Японский", .languageKorean: "Корейский", .languageSpanish: "Испанский", .languageFrench: "Французский", .languageGerman: "Немецкий", .languageRussian: "Русский",
            .statusReady: "Готово", .statusAccessibilityEnabled: "Глобальное сочетание включено", .statusAccessibilityDisabled: "Разрешите Lingo Prism в «Универсальном доступе», затем вернитесь в приложение", .targetRequiredTitle: "Выберите целевой язык", .targetRequiredMessage: "Целевым языком нельзя выбрать автоопределение.", .statusSelectArea: "Перетащите, чтобы выделить область для перевода", .statusSelectionCancelled: "Выделение отменено", .recognizing: "Распознавание текста…", .translatingText: "Перевод текста…", .translatedLinesFormat: "Переведено строк: %d", .copiedTranslation: "Перевод скопирован в буфер обмена", .copiedOriginal: "Исходный текст скопирован в буфер обмена", .couldNotTranslate: "Не удаётся перевести", .translationUnfinished: "Перевод не завершён", .selectionTitle: "Выберите область перевода", .selectionInstruction: "Перетащите для выбора · правый клик для отмены", .selectionTooSmall: "Область слишком мала. Перетащите снова · правый клик для отмены", .selectionAccessibility: "Выбор области экрана", .screenRecordingPermission: "Требуется разрешение на запись экрана. Разрешите Lingo Prism в «Системные настройки» > «Конфиденциальность и безопасность», затем повторите попытку.", .noScreen: "Нет экрана для захвата.", .captureFailed: "Не удалось захватить изображение экрана.", .selectionInvalid: "Выбранная область слишком мала или за пределами экрана.", .errorNoText: "В выбранной области не распознан текст. Измените область или увеличьте содержимое и повторите попытку.", .errorTargetLanguageRequired: "Выберите целевой язык в настройках.", .errorOllamaInvalid: "Адрес Ollama или имя модели недействительны.", .errorOllamaServiceFormat: "Ollama вернул ошибку (%d). %@", .errorOllamaDetail: "Проверьте имя модели и журнал сервера.", .errorInvalidResponse: "Сервис перевода вернул нечитаемое содержимое.", .overlayTitle: "Перевод экрана", .original: "Оригинал", .translated: "Перевод", .showOriginal: "Показать оригинал", .showTranslation: "Показать перевод", .copyTranslation: "Копировать перевод", .copyOriginal: "Копировать оригинал", .reselect: "Выбрать снова", .close: "Закрыть", .closeOverlay: "Закрыть перевод экрана", .overlayAccessibility: "Наложение перевода экрана", .translationSegmentFormat: "Сегмент перевода %d", .launchNeedsApproval: "macOS требуется разрешение для Lingo Prism в объектах входа.", .launchStatusUnavailable: "Не удаётся прочитать состояние запуска при входе.", .launchUpdateFailedFormat: "Не удалось обновить запуск при входе: %@"
        ]
    ]
}
