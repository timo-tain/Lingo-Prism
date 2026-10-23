import AppKit
import Testing
@testable import LingoPrism

@MainActor
@Suite(.serialized)
struct TranslationCanvasTests {
    private func fixture(light: Bool = false) throws -> TranslationCanvasView {
        let context = try #require(CGContext(
            data: nil, width: 400, height: 240, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(NSColor(calibratedWhite: light ? 0.96 : 0.13, alpha: 1).cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 400, height: 240))
        context.setFillColor(light ? NSColor.black.cgColor : NSColor.white.cgColor)
        context.fill(CGRect(x: 30, y: 170, width: 200, height: 14))
        context.fill(CGRect(x: 320, y: 100, width: 12, height: 12))
        let image = try #require(context.makeImage())
        let result = TranslationResult(
            lines: [TranslatedLine(
                id: UUID(), sourceText: "Welcome to Lingo Prism", translatedText: "歡迎使用 Lingo Prism",
                boundingBox: NormalizedRect(x: 30 / 400, y: 170 / 240, width: 200 / 400, height: 14 / 240)
            )],
            sourceLanguage: .english, targetLanguage: .traditionalChinese, engine: .google
        )
        return TranslationCanvasView(
            frame: CGRect(x: 0, y: 0, width: 416, height: 286), image: image, result: result,
            selectedRect: CGRect(x: 8, y: 38, width: 400, height: 240),
            toolbarRect: CGRect(x: 198, y: 5, width: 210, height: 28)
        )
    }

    private func render(_ view: TranslationCanvasView) throws -> NSBitmapImageRep {
        let bitmap = try #require(NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 416, pixelsHigh: 286, bitsPerSample: 8,
            samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
            bytesPerRow: 0, bitsPerPixel: 0
        ))
        let graphics = try #require(NSGraphicsContext(bitmapImageRep: bitmap))
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphics
        view.draw(view.bounds)
        NSGraphicsContext.restoreGraphicsState()
        return bitmap
    }

    @Test func translatedViewCoversSourceInkAndKeepsNearbyImage() throws {
        let view = try fixture()
        let output = try render(view)
        let covered = try #require(output.colorAt(x: 170, y: 70)?.usingColorSpace(.deviceRGB))
        let untouched = try #require(output.colorAt(x: 334, y: 142)?.usingColorSpace(.deviceRGB))
        #expect(covered.redComponent < 0.35)
        #expect(untouched.redComponent > 0.85)
        #expect(view.accessibilityLabel() == "螢幕覆蓋翻譯")
        let selectableText = try #require(view.selectableTranslationViews.first)
        #expect(selectableText.string == "歡迎使用 Lingo Prism")
        #expect(selectableText.isSelectable)
        #expect(!selectableText.isEditable)
        #expect(!selectableText.drawsBackground)
        selectableText.selectAll(nil)
        #expect(selectableText.selectedRange() == NSRange(location: 0, length: (selectableText.string as NSString).length))
        if ProcessInfo.processInfo.environment["LINGOPRISM_RENDER_PREVIEW"] == "1" {
            let data = try #require(output.representation(using: .png, properties: [:]))
            try data.write(to: URL(fileURLWithPath: "/tmp/lingoprism_overlay_preview.png"))
        }
    }

    @Test func originalToggleRestoresCapturedText() throws {
        let view = try fixture()
        let toolbar = try #require(view.subviews.compactMap { $0 as? NSVisualEffectView }.first)
        #expect(toolbar.material == .hudWindow)
        #expect(toolbar.blendingMode == .behindWindow)
        #expect(toolbar.state == .active)
        let buttons = view.subviews.flatMap { $0.subviews }.compactMap { $0 as? NSButton }
        #expect(buttons.count == 4)
        let toggle = try #require(buttons.first { $0.accessibilityLabel() == "顯示原文" })
        toggle.performClick(nil)
        #expect(view.showsOriginal)
        #expect(toggle.accessibilityLabel() == "顯示譯文")
        let hidesTranslatedText = view.selectableTranslationViews.allSatisfy { $0.isHidden }
        #expect(hidesTranslatedText)
        let original = try render(view)
        let textPixel = try #require(original.colorAt(x: 170, y: 70)?.usingColorSpace(.deviceRGB))
        #expect(textPixel.redComponent > 0.85)
        toggle.performClick(nil)
        #expect(!view.showsOriginal)
        let showsTranslatedText = view.selectableTranslationViews.allSatisfy { !$0.isHidden }
        #expect(showsTranslatedText)

        var copied = false
        view.onAction = { if case .copyTranslation = $0 { copied = true } }
        let copy = try #require(buttons.first { $0.accessibilityLabel() == "複製譯文" })
        copy.performClick(nil)
        #expect(copied)
    }

    @Test func lightBackgroundUsesLightPatchAndDarkText() throws {
        let view = try fixture(light: true)
        let output = try render(view)
        let covered = try #require(output.colorAt(x: 170, y: 70)?.usingColorSpace(.deviceRGB))
        let untouched = try #require(output.colorAt(x: 334, y: 142)?.usingColorSpace(.deviceRGB))
        #expect(covered.redComponent > 0.85)
        #expect(untouched.redComponent < 0.15)
    }

    @Test func longerTranslationMovesFollowingLineWithoutOverlap() throws {
        let context = try #require(CGContext(
            data: nil, width: 400, height: 240, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(NSColor.black.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 400, height: 240))
        let image = try #require(context.makeImage())
        let lines = [
            TranslatedLine(
                id: UUID(), sourceText: "First line", translatedText: "A longer translated sentence that wraps across the available area more than once",
                boundingBox: NormalizedRect(x: 0.075, y: 170 / 240, width: 0.3, height: 14 / 240)
            ),
            TranslatedLine(
                id: UUID(), sourceText: "Second line", translatedText: "The next paragraph",
                boundingBox: NormalizedRect(x: 0.075, y: 140 / 240, width: 0.3, height: 14 / 240)
            )
        ]
        let result = TranslationResult(
            lines: lines, sourceLanguage: .english, targetLanguage: .traditionalChinese, engine: .google
        )
        let view = TranslationCanvasView(
            frame: CGRect(x: 0, y: 0, width: 416, height: 286), image: image, result: result,
            selectedRect: CGRect(x: 8, y: 38, width: 400, height: 240),
            toolbarRect: CGRect(x: 198, y: 5, width: 210, height: 28)
        )
        let frames = view.translatedTextFrames
        #expect(frames.count == 2)
        guard frames.count == 2 else { return }
        #expect(frames[0].height > 14)
        #expect(frames[0].minY > frames[1].maxY)
    }
}
