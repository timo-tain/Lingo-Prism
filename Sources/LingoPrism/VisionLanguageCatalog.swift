import AppKit
import Foundation
import Vision

struct VisionOCRLanguageStatus: Identifiable {
    let language: AppLanguage
    let isAvailable: Bool

    var id: AppLanguage { language }
}

enum VisionLanguageCatalog {
    static func statuses() -> [VisionOCRLanguageStatus] {
        let supportedCodes: [String]
        do {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            supportedCodes = try request.supportedRecognitionLanguages()
        } catch {
            supportedCodes = []
        }

        return AppLanguage.allCases
            .filter { $0 != .auto }
            .map { language in
                VisionOCRLanguageStatus(
                    language: language,
                    isAvailable: isSupported(language, by: supportedCodes)
                )
            }
    }

    static func openLanguageAndRegionSettings() {
        // Vision does not expose an API that lets third-party apps download
        // OCR models. macOS owns its language downloads, so send the user to
        // the panel that manages system Translation Languages instead.
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Localization-Settings.extension") else { return }
        NSWorkspace.shared.open(url)
    }

    private static func isSupported(_ language: AppLanguage, by supportedCodes: [String]) -> Bool {
        guard let requested = language.visionCode else { return true }
        let normalizedRequested = requested.replacingOccurrences(of: "_", with: "-").lowercased()
        return supportedCodes.contains { code in
            let normalizedCode = code.replacingOccurrences(of: "_", with: "-").lowercased()
            if normalizedCode == normalizedRequested { return true }
            // Keep Traditional and Simplified Chinese distinct. Other languages
            // may be returned by Vision with a region suffix such as en-US.
            if normalizedRequested.hasPrefix("zh-") {
                return normalizedCode.hasPrefix(normalizedRequested)
            }
            return normalizedCode == normalizedRequested || normalizedCode.hasPrefix(normalizedRequested + "-")
        }
    }
}
