import AppKit
import ApplicationServices
import Combine
import CoreGraphics
import Foundation

enum PrivacyPermission: String, CaseIterable, Identifiable, Sendable {
    case screenRecording
    case accessibility

    var id: String { rawValue }

    var tccService: String {
        switch self {
        case .screenRecording: "ScreenCapture"
        case .accessibility: "Accessibility"
        }
    }

    var settingsURL: URL {
        let anchor: String
        switch self {
        case .screenRecording: anchor = "Privacy_ScreenCapture"
        case .accessibility: anchor = "Privacy_Accessibility"
        }
        return URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)")!
    }
}

/// Reads and launches the two privacy flows that Lingo Prism needs for its
/// core screen-translation experience. The debug reset is intentionally kept
/// here so it uses the same status refresh path as a normal permission change.
@MainActor
final class PrivacyPermissionStore: ObservableObject {
    @Published private(set) var screenRecordingAuthorized: Bool
    @Published private(set) var accessibilityAuthorized: Bool

    init() {
        screenRecordingAuthorized = CGPreflightScreenCaptureAccess()
        accessibilityAuthorized = AXIsProcessTrusted()
    }

    var allRequiredPermissionsAuthorized: Bool {
        screenRecordingAuthorized && accessibilityAuthorized
    }

    func isAuthorized(_ permission: PrivacyPermission) -> Bool {
        switch permission {
        case .screenRecording: screenRecordingAuthorized
        case .accessibility: accessibilityAuthorized
        }
    }

    func refresh() {
        screenRecordingAuthorized = CGPreflightScreenCaptureAccess()
        accessibilityAuthorized = AXIsProcessTrusted()
    }

    /// Starts the system authorization flow and opens the matching privacy
    /// pane. Opening the pane also makes the action useful after a prior deny.
    func request(_ permission: PrivacyPermission) {
        switch permission {
        case .screenRecording:
            if !screenRecordingAuthorized { CGRequestScreenCaptureAccess() }
        case .accessibility:
            // The documented key avoids passing the SDK's mutable global
            // option through Swift 6's concurrency checker.
            let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
        }
        openSystemSettings(for: permission)
        refresh()
    }

    func openSystemSettings(for permission: PrivacyPermission) {
        NSWorkspace.shared.open(permission.settingsURL)
    }

    /// Removes a TCC grant for local QA. macOS may require relaunching the app
    /// before every framework observes the reset; refresh immediately anyway.
    @discardableResult
    func reset(_ permission: PrivacyPermission) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tccutil")
        process.arguments = ["reset", permission.tccService, Bundle.main.bundleIdentifier ?? "com.timo-tain.lingoprism"]

        do {
            try process.run()
            process.waitUntilExit()
            refresh()
            return process.terminationStatus == 0
        } catch {
            refresh()
            return false
        }
    }

    @discardableResult
    func resetAll() -> Bool {
        PrivacyPermission.allCases.map { reset($0) }.allSatisfy { $0 }
    }
}
