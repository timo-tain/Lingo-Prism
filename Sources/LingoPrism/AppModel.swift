import AppKit
import ApplicationServices
import Combine
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var isProcessing = false
    @Published private(set) var isSelecting = false
    @Published private(set) var status = AppLocalizer.text(.statusReady)
    @Published private(set) var latestResult: TranslationResult?
    @Published private(set) var hotkeyEnabled = false

    let preferences = PreferencesStore()
    let launchAtLogin = LaunchAtLoginService()
    private let hotkeyMonitor = HotkeyMonitor()
    private var didStart = false
    private var preferencesObserver: AnyCancellable?
    private var hotkeyObserver: AnyCancellable?

    init() {
        preferencesObserver = preferences.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        hotkeyObserver = preferences.$hotkeyPreset
            .combineLatest(preferences.$customHotkey)
            .sink { [weak self] _, _ in
                guard let self else { return }
                self.hotkeyMonitor.update(shortcut: self.preferences.effectiveHotkey)
            }
        // A menu-bar-only app has no dashboard window lifecycle. Start the
        // global shortcut when the shared model is created instead.
        start()
    }

    func start() {
        guard !didStart else { return }
        didStart = true
        hotkeyEnabled = AXIsProcessTrusted()
        hotkeyMonitor.start(shortcut: preferences.effectiveHotkey) { [weak self] in
            Task { @MainActor in self?.beginSelection() }
        }
        if preferences.needsInitialLaunchAtLoginSetup {
            // A clean installation starts with both General toggles enabled.
            // Record the attempt so an unavailable ServiceManagement state
            // does not repeatedly override a person's later choice.
            launchAtLogin.setEnabled(true)
            preferences.markInitialLaunchAtLoginSetupComplete()
        }
        if preferences.showSettingsOnLaunch {
            DispatchQueue.main.async { [weak self] in self?.openSettings() }
        }
    }

    func requestAccessibilityPermission() {
        // The SDK currently imports kAXTrustedCheckOptionPrompt as mutable global state.
        // Its documented key string avoids crossing that Swift 6 concurrency boundary.
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        hotkeyEnabled = AXIsProcessTrusted()
        status = hotkeyEnabled
            ? AppLocalizer.text(.statusAccessibilityEnabled)
            : AppLocalizer.text(.statusAccessibilityDisabled)
    }

    func openSettings() {
        SettingsWindowController.shared.show(preferences: preferences, launchAtLogin: launchAtLogin)
    }

    func beginSelection() {
        guard !isProcessing, !isSelecting else { return }
        guard preferences.targetLanguage != .auto else {
            CursorHintController.shared.show(AppLocalizer.text(.targetRequiredMessage))
            return
        }
        do {
            TranslationOverlayController.shared.dismiss()
            FloatingTranslationController.shared.dismiss()
            let screens = try ScreenCaptureService.prepareSelection()
            isSelecting = true
            status = AppLocalizer.text(.statusSelectArea)
            SelectionOverlayController.shared.present(screens: screens) { [weak self] selection in
                guard let self else { return }
                self.isSelecting = false
                guard let selection else {
                    self.status = AppLocalizer.text(.statusSelectionCancelled)
                    return
                }
                self.translate(selection)
            }
        } catch {
            present(error)
        }
    }

    private func translate(_ selection: ScreenSelection) {
        isProcessing = true
        status = AppLocalizer.text(.recognizing)
        SelectionOverlayController.shared.updateLoading(message: AppLocalizer.text(.recognizing))

        let engine = preferences.engine
        let sourceLanguage = preferences.sourceLanguage
        let targetLanguage = preferences.targetLanguage
        let ollamaURL = preferences.ollamaURL
        let ollamaModel = preferences.ollamaModel
        let selfHostedURL = preferences.selfHostedURL
        let selfHostedModel = preferences.selfHostedModel
        let presentation = preferences.presentation

        Task {
            do {
                // The selected overlay stays on screen from mouse-up through
                // the final result. It has no dim mask and only paints thin
                // chrome outside the captured content, so OCR can run without
                // closing and reopening the selection UI.
                let croppedImage = try ScreenCaptureService.capture(selection)
                let recognized = try await TextRecognitionService.recognize(croppedImage, sourceLanguage: sourceLanguage)
                guard !recognized.isEmpty else { throw TranslationError.noText }

                await MainActor.run {
                    self.status = "\(engine.title) · \(AppLocalizer.text(.translatingText))"
                    SelectionOverlayController.shared.updateLoading(message: AppLocalizer.text(.translatingText))
                }
                let result = try await TranslationService.translate(
                    lines: recognized,
                    engine: engine,
                    sourceLanguage: sourceLanguage,
                    targetLanguage: targetLanguage,
                    ollamaURL: ollamaURL,
                    ollamaModel: ollamaModel,
                    selfHostedURL: selfHostedURL,
                    selfHostedModel: selfHostedModel
                )

                await MainActor.run {
                    self.latestResult = result
                    self.isProcessing = false
                    self.status = AppLocalizer.format(.translatedLinesFormat, result.lines.count)
                    self.present(result: result, for: selection, image: croppedImage, mode: presentation)
                    // Present the result first, then remove the selection in
                    // this same run-loop turn so the user never sees a gap.
                    SelectionOverlayController.shared.dismiss()
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    SelectionOverlayController.shared.dismiss()
                    if case TranslationError.noText = error {
                        self.status = AppLocalizer.noTextHint()
                        CursorHintController.shared.show(AppLocalizer.noTextHint())
                    } else {
                        self.present(error)
                    }
                }
            }
        }
    }

    private func present(result: TranslationResult, for selection: ScreenSelection, image: CGImage, mode: TranslationPresentation) {
        switch mode {
        case .overlay:
            TranslationOverlayController.shared.present(result: result, selection: selection, image: image) { [weak self] action in
                self?.handleOverlayAction(action, result: result)
            }
        case .floatingWindow:
            FloatingTranslationController.shared.present(result: result, selection: selection) { [weak self] action in
                self?.handleOverlayAction(action, result: result)
            }
        }
    }

    private func handleOverlayAction(_ action: TranslationOverlayAction, result: TranslationResult) {
        switch action {
        case .close:
            TranslationOverlayController.shared.dismiss()
            FloatingTranslationController.shared.dismiss()
        case .reselect:
            TranslationOverlayController.shared.dismiss()
            FloatingTranslationController.shared.dismiss()
            beginSelection()
        case .copyTranslation:
            copy(result.translatedText)
            status = AppLocalizer.text(.copiedTranslation)
        case .copyOriginal:
            copy(result.sourceText)
            status = AppLocalizer.text(.copiedOriginal)
        }
    }

    private func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func present(_ error: Error) {
        isProcessing = false
        SelectionOverlayController.shared.dismiss()
        status = AppLocalizer.text(.couldNotTranslate)
        CursorHintController.shared.show(error.localizedDescription)
    }
}

private final class HotkeyMonitor {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var shortcut = HotkeyPreset.commandShift.shortcut!

    func start(shortcut: KeyboardShortcut, handler: @escaping () -> Void) {
        self.shortcut = shortcut
        guard globalMonitor == nil else { return }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.matches(event) == true { handler() }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.matches(event) == true {
                handler()
                return nil
            }
            return event
        }
    }

    func update(shortcut: KeyboardShortcut) {
        self.shortcut = shortcut
    }

    private func matches(_ event: NSEvent) -> Bool {
        let relevant: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
        return !event.isARepeat
            && event.keyCode == shortcut.keyCode
            && event.modifierFlags.intersection(relevant) == shortcut.modifiers.intersection(relevant)
    }

    deinit {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
    }
}
