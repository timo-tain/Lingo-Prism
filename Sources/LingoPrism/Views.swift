import AppKit
import SwiftUI

#if canImport(Translation)
@preconcurrency import Translation
#endif

struct MenuBarView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                LingoPrismMenuBarIcon(size: 20)
                Text("Lingo Prism")
                    .font(.headline)
            }

            Button {
                model.beginSelection()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: "viewfinder")
                    Text(model.isProcessing ? AppLocalizer.text(.translating) : AppLocalizer.text(.startTranslation))
                }
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.isProcessing)

            HStack(spacing: 8) {
                quickLanguagePicker(
                    t(.sourceLanguage),
                    selection: Binding(
                        get: { model.preferences.sourceLanguage },
                        set: { model.preferences.sourceLanguage = $0 }
                    ),
                    languages: AppLanguage.allCases
                )
                quickLanguagePicker(
                    t(.targetLanguage),
                    selection: Binding(
                        get: { model.preferences.targetLanguage },
                        set: { model.preferences.targetLanguage = $0 }
                    ),
                    languages: AppLanguage.allCases.filter { $0 != .auto }
                )
            }

            Divider()
            HStack {
                Button { model.openSettings() } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "gearshape")
                        Text(AppLocalizer.text(.settings))
                    }
                }
                .buttonStyle(.plain)
                Spacer()
                Button(AppLocalizer.text(.quit)) { NSApplication.shared.terminate(nil) }
            }
            .controlSize(.small)
        }
        .environment(\.locale, Locale(identifier: model.preferences.interfaceLanguage.localeIdentifier))
    }

    private func quickLanguagePicker(
        _ title: String,
        selection: Binding<AppLanguage>,
        languages: [AppLanguage]
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Picker(title, selection: selection) {
                ForEach(languages) { language in
                    Text(language.title).tag(language)
                }
            }
            .labelsHidden()
            .controlSize(.small)
            .frame(maxWidth: .infinity)
        }
    }

    private func t(_ key: AppLocalizer.Key) -> String {
        AppLocalizer.text(key, language: model.preferences.interfaceLanguage)
    }
}

struct SettingsView: View {
    @ObservedObject var preferences: PreferencesStore
    @ObservedObject var launchAtLogin: LaunchAtLoginService
    @ObservedObject var permissions: PrivacyPermissionStore
    @State private var ollamaStatus: String?
    @State private var isCheckingOllama = false
    @State private var selfHostedStatus: String?
    @State private var isCheckingSelfHosted = false
    @State private var serviceStatus: String?
    @State private var translationTestTask: Task<Void, Never>?
    @StateObject private var shortcutRecorder = ShortcutRecorder()
    @State private var ocrLanguages: [VisionOCRLanguageStatus] = []
    @State private var systemTranslationLanguages: [SystemTranslationLanguageStatus] = []
    @State private var systemTranslationMessage: String?
    @State private var systemTranslationDownloadRequest: SystemTranslationDownloadRequest?
    @State private var debugIconTapCount = 0
    @State private var lastDebugIconTap: Date?
    @State private var isDebugPanelVisible = false
    @State private var isUpdateSimulationPresented = false
    @State private var debugPermissionMessage: String?
    @State private var debugCopyMessage: String?

    var body: some View {
        ZStack {
            GlassMaterialView()
                .ignoresSafeArea()
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 22) {
                    appHeader
                    generalSection
                    privacySection
                    translationSection
                    shortcutSection
                    ocrSection
                    if isDebugPanelVisible { debugSection }
                    Text(appVersion)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.52))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 30)
                .padding(.top, 52)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.dark)
        .environment(\.locale, Locale(identifier: preferences.interfaceLanguage.localeIdentifier))
        .background(SettingsWindowConfigurator())
        .sheet(isPresented: $isUpdateSimulationPresented) {
            UpdateFlowSimulationView(language: preferences.interfaceLanguage)
        }
        .background {
            if #available(macOS 15.0, *) {
                SystemTranslationDownloadAnchor(
                    request: systemTranslationDownloadRequest,
                    completion: handleSystemTranslationDownload
                )
                .frame(width: 1, height: 1)
                .accessibilityHidden(true)
            }
        }
        .onAppear {
            launchAtLogin.refresh()
            permissions.refresh()
            refreshOCRLanguages()
            refreshSystemTranslationLanguages()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permissions.refresh()
        }
        .onChange(of: preferences.engine) { _, _ in
            translationTestTask?.cancel()
            translationTestTask = nil
            serviceStatus = nil
            if preferences.engine == .macOS { refreshSystemTranslationLanguages() }
        }
        .onChange(of: preferences.targetLanguage) { _, _ in refreshSystemTranslationLanguages() }
        .onDisappear {
            translationTestTask?.cancel()
            translationTestTask = nil
            shortcutRecorder.cancel()
        }
    }

    private var appHeader: some View {
        VStack(spacing: 9) {
            Button(action: registerDebugIconTap) {
                LingoPrismBrandIcon(size: 82, cornerRadius: 22)
                    .frame(width: 82, height: 82)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Lingo Prism")
            Text("Lingo Prism")
                .font(.title3.weight(.bold))
            Text(appVersion)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.58))
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 3)
    }

    private var generalSection: some View {
        settingsSection(t(.general)) {
            GlassCard {
                SettingsToggleRow(
                    icon: "power", tint: .orange,
                    title: t(.launchAtLogin), subtitle: t(.launchAtLoginSubtitle),
                    isOn: Binding(get: { launchAtLogin.isEnabled }, set: { launchAtLogin.setEnabled($0) })
                )
                if let message = launchAtLogin.message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.56))
                        .padding(.leading, 44)
                        .padding(.bottom, 8)
                }
                Divider().overlay(.white.opacity(0.09))
                SettingsToggleRow(
                    icon: "gearshape", tint: .blue,
                    title: t(.showSettingsOnLaunch), subtitle: t(.showSettingsSubtitle),
                    isOn: $preferences.showSettingsOnLaunch
                )
                Divider().overlay(.white.opacity(0.09))
                SettingsRow(icon: "character.bubble", tint: .cyan, title: t(.interfaceLanguage), subtitle: t(.interfaceLanguageSubtitle)) {
                    RightAlignedControl {
                        Picker(t(.interfaceLanguage), selection: $preferences.interfaceLanguage) {
                            ForEach(AppInterfaceLanguage.allCases) { language in
                                Text(language.pickerTitle).tag(language)
                            }
                        }
                        .labelsHidden()
                    }
                }
                Divider().overlay(.white.opacity(0.09))
                SettingsRow(icon: "arrow.down.circle", tint: .green, title: t(.checkForUpdates), subtitle: appVersion) {
                    Button {
                        AppUpdater.shared.checkForUpdates()
                    } label: {
                        Image(systemName: "arrow.up.right")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityLabel(t(.checkForUpdates))
                }
            }
        }
    }

    private var translationSection: some View {
        settingsSection(t(.translation)) {
            GlassCard {
                SettingsRow(icon: "character.bubble", tint: .cyan, title: t(.translationLanguage), subtitle: t(.translationLanguageSubtitle)) {
                    EmptyView()
                }
                Divider().overlay(.white.opacity(0.09))
                HStack(spacing: 14) {
                    languagePicker(t(.sourceLanguage), selection: $preferences.sourceLanguage, languages: AppLanguage.allCases)
                    languagePicker(t(.targetLanguage), selection: $preferences.targetLanguage, languages: AppLanguage.allCases.filter { $0 != .auto })
                }
                .padding(.top, 10)
                if preferences.engine == .macOS, preferences.sourceLanguage == .auto {
                    Text(AppLocalizer.selfHosted(.chooseSourceLanguage, language: preferences.interfaceLanguage))
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.top, 6)
                }
                Divider().overlay(.white.opacity(0.09)).padding(.top, 10)
                // Keep engine and presentation in one continuous card, like
                // the reference, rather than giving every option its own box.
                SettingsRow(icon: "globe", tint: .purple, title: t(.translationEngine), subtitle: t(.translationEngineSubtitle)) {
                    RightAlignedControl {
                        Picker(t(.translationEngine), selection: $preferences.engine) {
                            ForEach(TranslationEngine.allCases) { engine in Text(engine.title).tag(engine) }
                        }
                        .labelsHidden()
                    }
                }
                SettingsRow(icon: "rectangle.inset.filled", tint: .blue, title: t(.resultDisplay), subtitle: preferences.presentation.description) {
                    RightAlignedControl {
                        Picker(t(.resultDisplay), selection: $preferences.presentation) {
                            ForEach(TranslationPresentation.allCases) { mode in Text(mode.title).tag(mode) }
                        }
                        .labelsHidden()
                    }
                }
                if preferences.engine == .ollama {
                    Divider().overlay(.white.opacity(0.09))
                    VStack(alignment: .leading, spacing: 9) {
                        TextField(t(.ollamaURL), text: $preferences.ollamaURL)
                        TextField(t(.ollamaModel), text: $preferences.ollamaModel)
                        HStack {
                            if let ollamaStatus { Text(ollamaStatus).foregroundStyle(.white.opacity(0.58)) }
                            Spacer()
                            Button(isCheckingOllama ? t(.checking) : t(.testOllama)) { checkOllama() }
                                .disabled(isCheckingOllama)
                        }
                        .font(.caption)
                    }
                    .textFieldStyle(.roundedBorder)
                    .padding(.top, 10)
                }
                if preferences.engine == .openAICompatible {
                    Divider().overlay(.white.opacity(0.09))
                    VStack(alignment: .leading, spacing: 9) {
                        HStack {
                            Text(AppLocalizer.selfHosted(.endpoint, language: preferences.interfaceLanguage))
                                .foregroundStyle(.white.opacity(0.64))
                            Spacer()
                            RightAlignedControl {
                                Picker(AppLocalizer.selfHosted(.endpoint, language: preferences.interfaceLanguage), selection: selfHostedPresetBinding) {
                                    ForEach(SelfHostedEndpointPreset.allCases) { preset in Text(preset.title).tag(preset) }
                                }
                                .labelsHidden()
                            }
                        }
                        TextField(AppLocalizer.selfHosted(.endpoint, language: preferences.interfaceLanguage), text: $preferences.selfHostedURL)
                        TextField(AppLocalizer.selfHosted(.model, language: preferences.interfaceLanguage), text: $preferences.selfHostedModel)
                        HStack {
                            if let selfHostedStatus { Text(selfHostedStatus).foregroundStyle(.white.opacity(0.58)) }
                            Spacer()
                            Button(isCheckingSelfHosted ? t(.checking) : AppLocalizer.selfHosted(.testConnection, language: preferences.interfaceLanguage)) {
                                checkSelfHostedEndpoint()
                            }
                            .disabled(isCheckingSelfHosted)
                        }
                        .font(.caption)
                    }
                    .textFieldStyle(.roundedBorder)
                    .padding(.top, 10)
                }
                if preferences.engine == .macOS {
                    Divider().overlay(.white.opacity(0.09))
                    systemTranslationSection
                }
                Divider().overlay(.white.opacity(0.09))
                HStack {
                    if let serviceStatus {
                        Text(serviceStatus)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.58))
                            .lineLimit(2)
                            .textSelection(.enabled)
                    }
                    Spacer()
                    if translationTestTask != nil { ProgressView().controlSize(.small) }
                    Button(translationTestTask == nil ? t(.testTranslation) : t(.cancelTest)) {
                        if let task = translationTestTask {
                            task.cancel()
                            translationTestTask = nil
                            serviceStatus = nil
                        } else {
                            testTranslation()
                        }
                    }
                }
                .padding(.top, 10)
            }
        }
    }

    private var privacySection: some View {
        settingsSection(p(.title)) {
            GlassCard {
                Text(p(.subtitle))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
                    .padding(.bottom, 8)
                ForEach(PrivacyPermission.allCases) { permission in
                    privacyRow(permission)
                    if permission != PrivacyPermission.allCases.last {
                        Divider().overlay(.white.opacity(0.09))
                    }
                }
                HStack {
                    Spacer()
                    Button(p(.refresh)) { permissions.refresh() }
                        .buttonStyle(.bordered)
                }
                .padding(.top, 9)
            }
        }
    }

    private func privacyRow(_ permission: PrivacyPermission) -> some View {
        HStack(spacing: 10) {
            Image(systemName: permissions.isAuthorized(permission) ? "checkmark.shield" : "exclamationmark.shield")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(permissions.isAuthorized(permission) ? .green : .orange)
                .frame(width: 24, height: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(privacyName(permission))
                    .font(.subheadline.weight(.semibold))
                Text(permissions.isAuthorized(permission) ? p(.authorized) : p(.notAuthorized))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.54))
            }
            Spacer()
            Button(permissions.isAuthorized(permission) ? p(.openSystemSettings) : p(.requestPermission)) {
                permissions.request(permission)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 7)
    }

    private var systemTranslationSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            SettingsRow(
                icon: "apple.logo",
                tint: .gray,
                title: AppLocalizer.selfHosted(.systemLanguages, language: preferences.interfaceLanguage),
                subtitle: AppLocalizer.selfHosted(.systemLanguagesSubtitle, language: preferences.interfaceLanguage)
            ) { EmptyView() }

            if #unavailable(macOS 26.0) {
                Text(AppLocalizer.selfHosted(.requiresMacOS26, language: preferences.interfaceLanguage))
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.top, 2)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(systemTranslationLanguages) { status in
                    HStack(spacing: 7) {
                        Image(systemName: systemTranslationSymbol(status.availability))
                            .foregroundStyle(systemTranslationColor(status.availability))
                        Text(status.language.title)
                            .lineLimit(1)
                        Spacer(minLength: 2)
                        Text(systemTranslationLabel(status.availability))
                            .foregroundStyle(.white.opacity(0.54))
                            .lineLimit(1)
                    }
                    .font(.caption2)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 7))
                }
            }
            .padding(.top, 2)

            HStack {
                if systemTranslationDownloadRequest != nil { ProgressView().controlSize(.small) }
                Spacer()
                Button(AppLocalizer.selfHosted(.recheckLanguages, language: preferences.interfaceLanguage)) {
                    refreshSystemTranslationLanguages()
                }
                Button(AppLocalizer.selfHosted(.downloadSelectedPair, language: preferences.interfaceLanguage)) {
                    requestSystemTranslationDownload()
                }
                .disabled(preferences.sourceLanguage == .auto || systemTranslationDownloadRequest != nil)
            }
            if let systemTranslationMessage {
                Text(systemTranslationMessage)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
                    .padding(.top, 2)
            }
        }
        .padding(.top, 10)
    }

    private var shortcutSection: some View {
        settingsSection(t(.shortcut)) {
            GlassCard {
                SettingsRow(icon: "keyboard", tint: .mint, title: t(.shortcutTitle), subtitle: f(.currentFormat, preferences.effectiveHotkey.displayString)) {
                    RightAlignedControl {
                        Picker(t(.shortcutTitle), selection: $preferences.hotkeyPreset) {
                            ForEach(HotkeyPreset.allCases) { preset in Text(preset.title).tag(preset) }
                        }
                        .labelsHidden()
                    }
                }
                if preferences.hotkeyPreset == .custom {
                    Divider().overlay(.white.opacity(0.09))
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(t(.customShortcut))
                            Text(shortcutRecorder.isRecording ? t(.pressShortcut) : t(.modifierRequired))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.54))
                        }
                        Spacer()
                        Button(shortcutRecorder.isRecording ? t(.pressShortcut) : preferences.customHotkey.displayString) {
                            shortcutRecorder.begin { preferences.customHotkey = $0 }
                        }
                        .buttonStyle(.bordered)
                        if shortcutRecorder.isRecording {
                            Button(t(.cancel)) { shortcutRecorder.cancel() }.buttonStyle(.link)
                        }
                    }
                    .padding(.top, 10)
                }
                Text(t(.accessibilityHelp))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.54))
                    .padding(.top, 10)
            }
        }
    }

    private var ocrSection: some View {
        settingsSection(t(.textRecognition)) {
            GlassCard {
                SettingsRow(icon: "text.viewfinder", tint: .teal, title: t(.visionOCR), subtitle: t(.visionOCRSubtitle)) { EmptyView() }
                Divider().overlay(.white.opacity(0.09))
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(ocrLanguages) { status in
                        HStack(spacing: 7) {
                            Image(systemName: status.isAvailable ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(status.isAvailable ? .green : .orange)
                            Text(status.language.title)
                            Spacer()
                        }
                        .font(.caption)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 7))
                    }
                }
                .padding(.top, 10)
                HStack {
                    Spacer()
                    Button(t(.recheck)) { refreshOCRLanguages() }
                    Button(t(.manageSystemLanguages)) { VisionLanguageCatalog.openLanguageAndRegionSettings() }
                }
                .padding(.top, 10)
                Text(t(.visionInfo))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.54))
                    .padding(.top, 7)
            }
        }
    }

    private var debugSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text(d(.title))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.88))
                Text(d(.description))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
            }

            settingsSection(d(.updateTestingSection)) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Button {
                            isUpdateSimulationPresented = true
                        } label: {
                            Label(d(.simulateUpdateFlow), systemImage: "arrow.triangle.2.circlepath")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                        Text(d(.simulationNotice))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.58))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            settingsSection(d(.frameSection)) {
                GlassCard {
                    debugColorRow(d(.primaryColor), binding: borderColorBinding(\.borderPrimaryColor))
                    Divider().overlay(.white.opacity(0.09))
                    debugColorRow(d(.secondaryColor), binding: borderColorBinding(\.borderSecondaryColor))
                    Divider().overlay(.white.opacity(0.09))
                    debugColorRow(d(.tertiaryColor), binding: borderColorBinding(\.borderTertiaryColor))
                    Divider().overlay(.white.opacity(0.09))
                    debugSliderRow(
                        title: d(.strokeWidth),
                        value: $preferences.borderStrokeWidth,
                        range: 1...8,
                        suffix: "pt"
                    )
                    Divider().overlay(.white.opacity(0.09))
                    debugSliderRow(
                        title: d(.glowWidth),
                        value: $preferences.borderGlowWidth,
                        range: 0...28,
                        suffix: "pt"
                    )
                    Divider().overlay(.white.opacity(0.09))
                    debugSliderRow(
                        title: d(.animationSpeed),
                        value: $preferences.borderAnimationSpeed,
                        range: 0.05...2,
                        suffix: "cycles/s",
                        step: 0.05,
                        precision: 2
                    )
                    Divider().overlay(.white.opacity(0.09))
                    HStack(spacing: 10) {
                        Spacer()
                        Button {
                            copyDebugParameters()
                        } label: {
                            Label(
                                debugCopyMessage ?? d(.copyParameters),
                                systemImage: debugCopyMessage == nil ? "doc.on.doc" : "checkmark"
                            )
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        if debugCopyMessage != nil {
                            Text(d(.copyParametersHint))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.58))
                        }
                    }
                    .padding(.top, 5)
                }
            }

            settingsSection(d(.permissionsSection)) {
                GlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(p(.resetAllPermissions))
                            .font(.subheadline.weight(.semibold))
                        ForEach(PrivacyPermission.allCases) { permission in
                            HStack {
                                Text(privacyName(permission))
                                    .font(.caption)
                                Spacer()
                                Button(p(.resetPermission)) {
                                    debugPermissionMessage = permissions.reset(permission)
                                        ? p(.resetSucceeded)
                                        : p(.resetFailed)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        HStack {
                            Spacer()
                            Button(p(.resetAllPermissions)) {
                                debugPermissionMessage = permissions.resetAll()
                                    ? p(.resetSucceeded)
                                    : p(.resetFailed)
                            }
                            if let debugPermissionMessage {
                                Text(debugPermissionMessage)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.58))
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
        }
    }

    private func copyDebugParameters() {
        let appearance = BorderAppearance.current()
        let parameters = """
        {
          "borderPrimaryColor": "\(appearance.primaryColor)",
          "borderSecondaryColor": "\(appearance.secondaryColor)",
          "borderTertiaryColor": "\(appearance.tertiaryColor)",
          "borderStrokeWidth": \(String(format: "%.2f", appearance.strokeWidth)),
          "borderGlowWidth": \(String(format: "%.2f", appearance.glowWidth)),
          "borderAnimationSpeed": \(String(format: "%.2f", appearance.animationSpeed))
        }
        """
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(parameters, forType: .string)
        debugCopyMessage = d(.parametersCopied)
    }

    private func settingsSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.88))
                .padding(.leading, 2)
            content()
        }
    }

    private func languagePicker(_ title: String, selection: Binding<AppLanguage>, languages: [AppLanguage]) -> some View {
        HStack {
            Text(title).foregroundStyle(.white.opacity(0.64))
            Spacer(minLength: 8)
            RightAlignedControl {
                Picker(title, selection: selection) {
                    ForEach(languages) { language in Text(language.title).tag(language) }
                }
                .labelsHidden()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var selfHostedPresetBinding: Binding<SelfHostedEndpointPreset> {
        Binding(
            get: { preferences.selfHostedPreset },
            set: { preferences.applySelfHostedPreset($0) }
        )
    }

    private func t(_ key: AppLocalizer.Key) -> String {
        AppLocalizer.text(key, language: preferences.interfaceLanguage)
    }

    private func f(_ key: AppLocalizer.Key, _ value: CVarArg) -> String {
        AppLocalizer.format(key, value, language: preferences.interfaceLanguage)
    }

    private func d(_ key: AppLocalizer.DebugKey) -> String {
        AppLocalizer.debug(key, language: preferences.interfaceLanguage)
    }

    private func p(_ key: AppLocalizer.PrivacyKey) -> String {
        AppLocalizer.privacy(key, language: preferences.interfaceLanguage)
    }

    private func privacyName(_ permission: PrivacyPermission) -> String {
        switch permission {
        case .screenRecording: p(.screenRecording)
        case .accessibility: p(.accessibility)
        }
    }

    private func registerDebugIconTap() {
        let now = Date()
        if let lastDebugIconTap, now.timeIntervalSince(lastDebugIconTap) > 1.5 {
            debugIconTapCount = 0
        }
        lastDebugIconTap = now
        debugIconTapCount += 1
        guard debugIconTapCount >= 10 else { return }
        isDebugPanelVisible = true
        debugIconTapCount = 0
    }

    private func borderColorBinding(_ keyPath: ReferenceWritableKeyPath<PreferencesStore, String>) -> Binding<Color> {
        Binding(
            get: { Color(nsColor: BorderAppearanceColor.color(from: preferences[keyPath: keyPath], fallback: .white)) },
            set: { preferences[keyPath: keyPath] = BorderAppearanceColor.hex(from: NSColor($0)) }
        )
    }

    private func debugColorRow(_ title: String, binding: Binding<Color>) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Spacer()
            ColorPicker(title, selection: binding, supportsOpacity: false)
                .labelsHidden()
        }
        .padding(.vertical, 5)
    }

    private func debugSliderRow(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        suffix: String,
        step: Double = 0.25,
        precision: Int = 1
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                let format = precision == 2 ? "%.2f" : "%.1f"
                Text("\(String(format: format, value.wrappedValue)) \(suffix)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.62))
            }
            Slider(value: value, in: range, step: step)
        }
        .padding(.vertical, 5)
    }

    private func testTranslation() {
        let engine = preferences.engine
        let target = preferences.targetLanguage
        let ollamaURL = preferences.ollamaURL
        let ollamaModel = preferences.ollamaModel
        let selfHostedURL = preferences.selfHostedURL
        let selfHostedModel = preferences.selfHostedModel
        serviceStatus = nil
        translationTestTask = Task { @MainActor in
            let startedAt = DispatchTime.now().uptimeNanoseconds
            do {
                let result = try await TranslationService.translate(
                    lines: [RecognizedLine(text: "Hello, welcome to Lingo Prism.", boundingBox: .init(x: 0, y: 0, width: 1, height: 1))],
                    engine: engine, sourceLanguage: .english, targetLanguage: target,
                    ollamaURL: ollamaURL, ollamaModel: ollamaModel,
                    selfHostedURL: selfHostedURL, selfHostedModel: selfHostedModel
                )
                guard !Task.isCancelled else { return }
                let elapsedMilliseconds = Int((DispatchTime.now().uptimeNanoseconds - startedAt) / 1_000_000)
                let duration = AppLocalizer.format(.testDurationFormat, elapsedMilliseconds)
                serviceStatus = AppLocalizer.format(.testSuccessFormat, engine.shortTitle, "\(result.translatedText)\(duration)")
            } catch {
                guard !Task.isCancelled else { return }
                serviceStatus = error.localizedDescription
            }
            translationTestTask = nil
        }
    }

    private func checkOllama() {
        isCheckingOllama = true
        ollamaStatus = nil
        let url = preferences.ollamaURL
        Task {
            do {
                let models = try await OllamaCatalog.models(at: url)
                await MainActor.run {
                    self.isCheckingOllama = false
                    self.ollamaStatus = models.isEmpty
                        ? AppLocalizer.text(.connectedNoModels)
                        : AppLocalizer.format(.connectedFormat, models.prefix(3).joined(separator: ", "))
                }
            } catch {
                await MainActor.run {
                    self.isCheckingOllama = false
                    self.ollamaStatus = AppLocalizer.text(.cannotConnect)
                }
            }
        }
    }

    private func checkSelfHostedEndpoint() {
        isCheckingSelfHosted = true
        selfHostedStatus = nil
        let url = preferences.selfHostedURL
        Task {
            do {
                let models = try await OpenAICompatibleCatalog.models(at: url)
                await MainActor.run {
                    self.isCheckingSelfHosted = false
                    self.selfHostedStatus = models.isEmpty
                        ? AppLocalizer.text(.connectedNoModels)
                        : AppLocalizer.format(.connectedFormat, models.prefix(3).joined(separator: ", "))
                }
            } catch {
                await MainActor.run {
                    self.isCheckingSelfHosted = false
                    self.selfHostedStatus = AppLocalizer.text(.cannotConnect)
                }
            }
        }
    }

    private func refreshOCRLanguages() {
        ocrLanguages = VisionLanguageCatalog.statuses()
    }

    private func refreshSystemTranslationLanguages() {
        let target = preferences.targetLanguage
        Task {
            let statuses = await SystemTranslationCatalog.statuses(forTarget: target)
            await MainActor.run { self.systemTranslationLanguages = statuses }
        }
    }

    private func requestSystemTranslationDownload() {
        guard preferences.sourceLanguage != .auto else {
            systemTranslationMessage = AppLocalizer.selfHosted(.chooseSourceLanguage, language: preferences.interfaceLanguage)
            return
        }
        guard #available(macOS 15.0, *) else {
            systemTranslationMessage = AppLocalizer.selfHosted(.requiresMacOS26, language: preferences.interfaceLanguage)
            return
        }
        systemTranslationMessage = AppLocalizer.selfHosted(.downloading, language: preferences.interfaceLanguage)
        systemTranslationDownloadRequest = .init(source: preferences.sourceLanguage, target: preferences.targetLanguage)
    }

    @MainActor
    private func handleSystemTranslationDownload(_ result: Result<Void, Error>) {
        systemTranslationDownloadRequest = nil
        switch result {
        case .success:
            systemTranslationMessage = nil
            refreshSystemTranslationLanguages()
        case .failure:
            systemTranslationMessage = AppLocalizer.selfHosted(.downloadFailed, language: preferences.interfaceLanguage)
        }
    }

    private func systemTranslationLabel(_ status: SystemTranslationAvailability) -> String {
        switch status {
        case .installed: AppLocalizer.selfHosted(.installed, language: preferences.interfaceLanguage)
        case .downloadable: AppLocalizer.selfHosted(.availableToDownload, language: preferences.interfaceLanguage)
        case .unsupported, .unavailable: AppLocalizer.selfHosted(.unsupported, language: preferences.interfaceLanguage)
        }
    }

    private func systemTranslationSymbol(_ status: SystemTranslationAvailability) -> String {
        switch status {
        case .installed: "checkmark.circle.fill"
        case .downloadable: "arrow.down.circle.fill"
        case .unsupported, .unavailable: "exclamationmark.triangle.fill"
        }
    }

    private func systemTranslationColor(_ status: SystemTranslationAvailability) -> Color {
        switch status {
        case .installed: .green
        case .downloadable: .blue
        case .unsupported, .unavailable: .orange
        }
    }

    private var appVersion: String {
        let bundle = Bundle.main
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return AppLocalizer.format(.versionFormat, "\(version) (\(build))", language: preferences.interfaceLanguage)
    }
}

#if canImport(Translation)
@available(macOS 15.0, *)
private struct SystemTranslationDownloadAnchor: View {
    let request: SystemTranslationDownloadRequest?
    let completion: @MainActor (Result<Void, Error>) -> Void
    @State private var configuration: TranslationSession.Configuration?

    var body: some View {
        Color.clear
            .onAppear { installConfiguration(for: request) }
            .onChange(of: request) { _, value in installConfiguration(for: value) }
            .translationTask(configuration) { session in
                do {
                    try await session.prepareTranslation()
                    completion(.success(()))
                } catch {
                    completion(.failure(error))
                }
                configuration = nil
            }
    }

    private func installConfiguration(for request: SystemTranslationDownloadRequest?) {
        guard let request,
              let sourceCode = request.source.translationCode,
              let targetCode = request.target.translationCode else {
            configuration = nil
            return
        }
        configuration = TranslationSession.Configuration(
            source: Locale.Language(identifier: sourceCode),
            target: Locale.Language(identifier: targetCode)
        )
    }
}
#endif

private struct GlassMaterialView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}

/// Settings is a SwiftUI scene, so configure its host window after this tiny
/// view joins the hierarchy. The content runs through the transparent title
/// area; only macOS's close control remains in the top-left corner.
private struct SettingsWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> SettingsWindowHostView { SettingsWindowHostView() }

    func updateNSView(_ view: SettingsWindowHostView, context: Context) {
        view.configureWindow()
    }
}

private final class SettingsWindowHostView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configureWindow()
    }

    func configureWindow() {
        DispatchQueue.main.async { [weak self] in
            guard let window = self?.window else { return }
            SettingsWindowRegistry.shared.window = window
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.titlebarSeparatorStyle = .none
            window.toolbar?.isVisible = false
            window.styleMask.insert(.fullSizeContentView)
            window.isOpaque = false
            window.backgroundColor = .clear
            window.standardWindowButton(.closeButton)?.isHidden = false
            window.standardWindowButton(.miniaturizeButton)?.isHidden = true
            window.standardWindowButton(.zoomButton)?.isHidden = true
        }
    }
}

@MainActor
final class SettingsWindowRegistry {
    static let shared = SettingsWindowRegistry()
    weak var window: NSWindow?

    @discardableResult
    func bringToFront() -> Bool {
        guard let window, window.isVisible else { return false }
        NSApp.activate(ignoringOtherApps: true)
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        return true
    }
}

/// MenuBarExtra does not always install SwiftUI's `showSettingsWindow:` action
/// in the responder chain. Own the settings window directly so opening it is
/// deterministic and a second click reliably brings the same window forward.
@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: ManagedSettingsWindow?

    func show(
        preferences: PreferencesStore,
        launchAtLogin: LaunchAtLoginService,
        permissions: PrivacyPermissionStore? = nil
    ) {
        if let window, window.isVisible {
            NSApp.activate(ignoringOtherApps: true)
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
            return
        }

        let window = ManagedSettingsWindow(
            contentRect: CGRect(x: 0, y: 0, width: 600, height: 700),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.title = "Lingo Prism"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.titlebarSeparatorStyle = .none
        window.toolbar?.isVisible = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.minSize = CGSize(width: 520, height: 560)
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.contentView = NSHostingView(
            rootView: SettingsView(
                preferences: preferences,
                launchAtLogin: launchAtLogin,
                permissions: permissions ?? PrivacyPermissionStore()
            )
                .frame(width: 600, height: 700)
        )
        window.didClose = { [weak self, weak window] in
            guard let self, self.window === window else { return }
            self.window = nil
            SettingsWindowRegistry.shared.window = nil
        }
        self.window = window
        SettingsWindowRegistry.shared.window = window
        window.center()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}

private final class ManagedSettingsWindow: NSWindow {
    var didClose: (() -> Void)?

    override func close() {
        super.close()
        didClose?()
    }
}

private struct GlassCard<Content: View>: View {
    @ViewBuilder let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(13)
        .background(.black.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private enum SettingsLayout {
    static let controlColumnWidth: CGFloat = 180
}

/// Keeps menu-style controls on a shared right edge even when their labels
/// have different intrinsic widths or are localized.
private struct RightAlignedControl<Content: View>: View {
    @ViewBuilder let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            content
        }
        .frame(width: SettingsLayout.controlColumnWidth, alignment: .trailing)
    }
}

private struct SettingsRow<Trailing: View>: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    @ViewBuilder let trailing: Trailing

    init(icon: String, tint: Color, title: String, subtitle: String, @ViewBuilder trailing: () -> Trailing) {
        self.icon = icon
        self.tint = tint
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.52))
                    .lineLimit(2)
            }
            Spacer(minLength: 10)
            trailing
        }
        .padding(.vertical, 4)
    }
}

private struct SettingsToggleRow: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        SettingsRow(icon: icon, tint: tint, title: title, subtitle: subtitle) {
            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
    }
}

@MainActor
private final class ShortcutRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    private var monitor: Any?

    func begin(onCapture: @escaping (KeyboardShortcut) -> Void) {
        cancel()
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isRecording else { return event }
            if event.keyCode == 53 {
                self.cancel()
                return nil
            }
            let allowed: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
            let modifiers = event.modifierFlags.intersection(allowed)
            guard !modifiers.isEmpty,
                  let rawLabel = event.charactersIgnoringModifiers,
                  !rawLabel.isEmpty else {
                return nil
            }
            let shortcut = KeyboardShortcut(
                keyCode: event.keyCode,
                modifiers: modifiers,
                keyLabel: rawLabel.uppercased()
            )
            onCapture(shortcut)
            self.cancel()
            return nil
        }
    }

    func cancel() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        isRecording = false
    }
}

