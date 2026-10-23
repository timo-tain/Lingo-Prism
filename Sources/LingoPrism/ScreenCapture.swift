import AppKit
import CoreGraphics

struct ScreenSelection {
    let screen: NSScreen
    /// A rectangle in points, relative to the selected NSScreen.
    let localRect: CGRect

    var screenRect: CGRect {
        localRect.offsetBy(dx: screen.frame.minX, dy: screen.frame.minY)
    }
}

enum ScreenCaptureService {
    /// This is deliberately a permission and display-list check only. Taking a
    /// full-screen image here made entering selection needlessly slow.
    static func prepareSelection() throws -> [NSScreen] {
        guard CGPreflightScreenCaptureAccess() else {
            // The prompt opens the privacy pane on current macOS versions. The user must enable it.
            CGRequestScreenCaptureAccess()
            throw CaptureError.permissionRequired
        }

        guard !NSScreen.screens.isEmpty else { throw CaptureError.noScreen }
        return NSScreen.screens
    }

    /// Capture only after the mouse is released, when the chosen screen and
    /// rectangle are known. The selection overlay briefly orders itself out so
    /// its dimming treatment is never included in the OCR image.
    static func capture(_ selection: ScreenSelection) throws -> CGImage {
        let screen = selection.screen
        guard let displayNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
              let image = CGDisplayCreateImage(CGDirectDisplayID(displayNumber.uint32Value)) else {
            throw CaptureError.captureFailed
        }

        let screenFrame = screen.frame
        guard screenFrame.width > 0, screenFrame.height > 0 else { throw CaptureError.captureFailed }

        let scaleX = CGFloat(image.width) / screenFrame.width
        let scaleY = CGFloat(image.height) / screenFrame.height
        let rect = selection.localRect.integral
        let pixelRect = CGRect(
            x: rect.minX * scaleX,
            y: CGFloat(image.height) - rect.maxY * scaleY,
            width: rect.width * scaleX,
            height: rect.height * scaleY
        ).integral.intersection(CGRect(x: 0, y: 0, width: image.width, height: image.height))

        guard !pixelRect.isNull, pixelRect.width >= 2, pixelRect.height >= 2,
              let cropped = image.cropping(to: pixelRect) else {
            throw CaptureError.selectionInvalid
        }
        return cropped
    }

    enum CaptureError: LocalizedError {
        case permissionRequired
        case noScreen
        case captureFailed
        case selectionInvalid

        var errorDescription: String? {
            switch self {
            case .permissionRequired:
                AppLocalizer.text(.screenRecordingPermission)
            case .noScreen: AppLocalizer.text(.noScreen)
            case .captureFailed: AppLocalizer.text(.captureFailed)
            case .selectionInvalid: AppLocalizer.text(.selectionInvalid)
            }
        }
    }
}
