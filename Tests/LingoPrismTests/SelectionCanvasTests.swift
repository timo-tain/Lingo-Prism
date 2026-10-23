import AppKit
import Testing
@testable import LingoPrism

@MainActor
@Suite(.serialized)
struct SelectionCanvasTests {
    private func canvas() throws -> SelectionCanvasView {
        let context = try #require(CGContext(
            data: nil, width: 800, height: 500, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 800, height: 500))
        let image = try #require(context.makeImage())
        _ = image
        return SelectionCanvasView(frame: CGRect(x: 0, y: 0, width: 800, height: 500))
    }

    private func mouse(_ type: NSEvent.EventType, _ x: CGFloat, _ y: CGFloat) throws -> NSEvent {
        try #require(NSEvent.mouseEvent(
            with: type, location: CGPoint(x: x, y: y), modifierFlags: [],
            timestamp: 0, windowNumber: 0, context: nil, eventNumber: 0, clickCount: 1, pressure: 1
        ))
    }

    @Test func dragUpdatesSelectionBeforeMouseUpWithoutMaskAndDrawsFinalStyleOutline() throws {
        let view = try canvas()
        #expect(!view.isOpaque)
        view.mouseDown(with: try mouse(.leftMouseDown, 100, 100))
        view.mouseDragged(with: try mouse(.leftMouseDragged, 500, 350))
        #expect(view.selection == CGRect(x: 100, y: 100, width: 400, height: 250))
        #expect(view.accessibilityValue() as? String == "框選範圍 400 × 250")

        // Render the actual selection view during the gesture, with no mouseUp.
        let bitmap = try #require(NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 800, pixelsHigh: 500, bitsPerSample: 8,
            samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ))
        let graphics = try #require(NSGraphicsContext(bitmapImageRep: bitmap))
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphics
        NSColor.white.setFill()
        NSBezierPath(rect: view.bounds).fill()
        view.draw(view.bounds)
        NSGraphicsContext.restoreGraphicsState()
        let outside = try #require(bitmap.colorAt(x: 50, y: 250)?.usingColorSpace(.deviceRGB))
        let inside = try #require(bitmap.colorAt(x: 300, y: 250)?.usingColorSpace(.deviceRGB))
        let border = try #require(bitmap.colorAt(x: 100, y: 250)?.usingColorSpace(.deviceRGB))
        if ProcessInfo.processInfo.environment["LINGOPRISM_SELECTION_PREVIEW"] == "1" {
            let data = try #require(bitmap.representation(using: .png, properties: [:]))
            try data.write(to: URL(fileURLWithPath: "/tmp/lingoprism_selection_preview.png"))
        }
        #expect(outside.redComponent > 0.95) // fully transparent outside the selection
        #expect(inside.redComponent > 0.95) // fully transparent selected region
        #expect(max(border.redComponent, border.greenComponent, border.blueComponent)
            - min(border.redComponent, border.greenComponent, border.blueComponent) > 0.2) // static blue-purple final-style edge
    }

    @Test func usesFinalEventLocationEvenWithoutIntermediateDragEvents() throws {
        let view = try canvas()
        var result: CGRect?
        view.onSelect = { result = $0 }
        view.mouseDown(with: try mouse(.leftMouseDown, 500, 350))
        view.mouseUp(with: try mouse(.leftMouseUp, 100, 100))
        #expect(result == CGRect(x: 100, y: 100, width: 400, height: 250))
    }

    @Test func clickDoesNotDismissAndAllowsAnotherDrag() throws {
        let view = try canvas()
        var selected = false
        var cancelled = false
        view.onSelect = { _ in selected = true }
        view.onCancel = { cancelled = true }
        view.mouseDown(with: try mouse(.leftMouseDown, 100, 100))
        view.mouseUp(with: try mouse(.leftMouseUp, 102, 103))
        #expect(!selected)
        #expect(!cancelled)
        #expect(view.selection.isEmpty)
        view.mouseDown(with: try mouse(.leftMouseDown, 100, 100))
        view.mouseDragged(with: try mouse(.leftMouseDragged, 450, 300))
        view.mouseUp(with: try mouse(.leftMouseUp, 500, 350))
        #expect(selected)
    }

    @Test func clampsToScreenAndRightClickCancels() throws {
        let view = try canvas()
        var result: CGRect?
        var cancelled = false
        view.onSelect = { result = $0 }
        view.onCancel = { cancelled = true }
        view.mouseDown(with: try mouse(.leftMouseDown, 100, 100))
        view.mouseUp(with: try mouse(.leftMouseUp, 1_000, -50))
        #expect(result == CGRect(x: 100, y: 0, width: 700, height: 100))
        view.rightMouseDown(with: try mouse(.rightMouseDown, 100, 100))
        #expect(cancelled)
    }

    @Test func selectionStaysVisibleAndLocksWhileLoading() throws {
        let view = try canvas()
        view.mouseDown(with: try mouse(.leftMouseDown, 100, 100))
        view.mouseUp(with: try mouse(.leftMouseUp, 500, 350))
        let selectedRect = view.selection

        view.beginLoading(message: "正在翻譯文字…")
        defer { view.stopLoading() }
        #expect(view.isLoading)
        #expect(view.accessibilityValue() as? String == "正在處理選取範圍：正在翻譯文字…")

        // The selected pixels stay transparent, while the loading treatment
        // remains visibly outside the preserved rectangle.
        let bitmap = try #require(NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 800, pixelsHigh: 500, bitsPerSample: 8,
            samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ))
        let graphics = try #require(NSGraphicsContext(bitmapImageRep: bitmap))
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = graphics
        NSColor.white.setFill()
        NSBezierPath(rect: view.bounds).fill()
        view.draw(view.bounds)
        NSGraphicsContext.restoreGraphicsState()
        let loadingInterior = try #require(bitmap.colorAt(x: 300, y: 250)?.usingColorSpace(.deviceRGB))
        let retainedBorder = try #require(bitmap.colorAt(x: 100, y: 250)?.usingColorSpace(.deviceRGB))
        let loadingCard = try #require(bitmap.colorAt(x: 300, y: 120)?.usingColorSpace(.deviceRGB))
        #expect(loadingInterior.redComponent > 0.95)
        #expect(max(retainedBorder.redComponent, retainedBorder.greenComponent, retainedBorder.blueComponent)
            - min(retainedBorder.redComponent, retainedBorder.greenComponent, retainedBorder.blueComponent) > 0.2)
        #expect(loadingCard.redComponent < 0.8)

        // A second gesture or Esc cannot discard the still-processing region.
        view.mouseDown(with: try mouse(.leftMouseDown, 10, 10))
        view.mouseUp(with: try mouse(.leftMouseUp, 30, 30))
        view.cancelOperation(nil)
        #expect(view.selection == selectedRect)
    }
}
