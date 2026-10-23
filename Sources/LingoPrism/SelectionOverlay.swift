import AppKit

@MainActor
final class SelectionOverlayController {
    static let shared = SelectionOverlayController()

    private var windows: [SelectionWindow] = []
    private var completion: ((ScreenSelection?) -> Void)?
    private weak var activeWindow: SelectionWindow?
    private weak var activeCanvas: SelectionCanvasView?

    func present(screens: [NSScreen], completion: @escaping (ScreenSelection?) -> Void) {
        dismiss()
        guard !screens.isEmpty else {
            completion(nil)
            return
        }
        self.completion = completion
        let pointer = NSEvent.mouseLocation
        var keyWindow: SelectionWindow?

        for screen in screens {
            // Explicitly set the global frame after construction; don't mix a
            // screen-relative initializer origin with the global display frame.
            let window = SelectionWindow(
                contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false
            )
            window.title = AppLocalizer.text(.selectionTitle)
            window.isReleasedWhenClosed = false
            window.level = .screenSaver
            window.isOpaque = false
            window.backgroundColor = .clear
            window.hasShadow = false
            window.ignoresMouseEvents = false
            window.acceptsMouseMovedEvents = true
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

            let view = SelectionCanvasView(
                frame: CGRect(origin: .zero, size: screen.frame.size),
                initialCursorPoint: screen.frame.contains(pointer)
                    ? CGPoint(x: pointer.x - screen.frame.minX, y: pointer.y - screen.frame.minY)
                    : nil
            )
            view.onSelect = { [weak self, weak window, weak view] rect in
                guard let window, let view else { return }
                self?.keepSelectionWhileProcessing(
                    ScreenSelection(screen: screen, localRect: rect), window: window, canvas: view
                )
            }
            view.onCancel = { [weak self] in self?.finish(nil) }
            window.contentView = view
            window.setFrame(screen.frame, display: false)
            windows.append(window)
            if screen.frame.contains(pointer) { keyWindow = window }
        }

        NSApp.activate(ignoringOtherApps: true)
        for window in windows {
            window.orderFrontRegardless()
            window.contentView?.display()
        }
        if let window = keyWindow ?? windows.first {
            window.makeKeyAndOrderFront(nil)
            window.makeFirstResponder(window.contentView)
        }
    }

    func dismiss() {
        completion = nil
        let oldWindows = windows
        windows = []
        activeCanvas?.stopLoading()
        activeCanvas = nil
        activeWindow = nil
        for window in oldWindows {
            (window.contentView as? SelectionCanvasView)?.stopLoading()
            window.orderOut(nil)
            window.close()
        }
        NSCursor.arrow.set()
    }

    /// Updates the selection that stays visible between mouse-up and the final
    /// presentation. Keeping this as a real AppKit window prevents a blank,
    /// click-through moment while Vision or the translator is working.
    func updateLoading(message: String) {
        activeCanvas?.setLoading(message: message)
    }

    private func keepSelectionWhileProcessing(
        _ selection: ScreenSelection, window: SelectionWindow, canvas: SelectionCanvasView
    ) {
        guard let callback = completion else { return }
        completion = nil

        activeWindow = window
        activeCanvas = canvas
        canvas.beginLoading(message: AppLocalizer.text(.recognizing))
        window.ignoresMouseEvents = true

        // Only the screen that owns the selected rectangle remains visible.
        // Its lightweight, click-through chrome stays in place until the
        // translated overlay has been constructed.
        let otherWindows = windows.filter { $0 !== window }
        windows = [window]
        for otherWindow in otherWindows {
            otherWindow.orderOut(nil)
            otherWindow.close()
        }
        window.orderFrontRegardless()

        // Let AppKit finish mouseUp before OCR begins, but deliberately keep
        // this window alive. The result path dismisses it in the same main-run
        // loop turn in which it shows the translated overlay.
        DispatchQueue.main.async { callback(selection) }
    }

    private func finish(_ selection: ScreenSelection?) {
        guard let callback = completion else { return }
        completion = nil
        // Finish delivering mouseUp before releasing the event's view/window.
        DispatchQueue.main.async { [self] in
            dismiss()
            callback(selection)
        }
    }
}

private final class SelectionWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Synchronous event handling keeps both gesture coordinates and visual feedback
/// in the same AppKit event, including event-tracking run-loop modes.
final class SelectionCanvasView: NSView {
    var onSelect: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var anchor: CGPoint?
    private(set) var selection = CGRect.zero
    private var cursorPoint: CGPoint?
    private var instruction = AppLocalizer.text(.selectionInstruction)
    private(set) var isLoading = false
    private var loadingMessage = AppLocalizer.text(.recognizing)
    private var loadingPhase = 0
    private var loadingTimer: Timer?
    private var borderPhase: CGFloat = 0
    private var borderTimer: Timer?

    init(frame: CGRect, initialCursorPoint: CGPoint? = nil) {
        super.init(frame: frame)
        autoresizingMask = [.width, .height]
        // The whole canvas is transparent so the user can keep reading the
        // live desktop while choosing a region.
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        if let initialCursorPoint {
            cursorPoint = CGPoint(
                x: min(max(initialCursorPoint.x, bounds.minX), bounds.maxX),
                y: min(max(initialCursorPoint.y, bounds.minY), bounds.maxY)
            )
        }
        setAccessibilityElement(true)
        setAccessibilityLabel(AppLocalizer.text(.selectionAccessibility))
        updateAccessibility()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var isOpaque: Bool { false }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func resetCursorRects() { addCursorRect(bounds, cursor: isLoading ? .arrow : .crosshair) }

    override func draw(_ dirtyRect: NSRect) {
        if !selection.isEmpty {
            if isLoading {
                drawAnimatedSelectionBorder()
                drawLoadingState()
            } else {
                drawStaticSelectionBorder()
            }
        }
        if !isLoading, let cursorPoint { drawFollowBadge(instruction, near: cursorPoint) }
    }

    override func mouseDown(with event: NSEvent) {
        guard !isLoading else { return }
        anchor = point(for: event)
        cursorPoint = anchor
        selection = .zero
        instruction = AppLocalizer.text(.selectionInstruction)
        refresh()
    }

    override func mouseDragged(with event: NSEvent) {
        guard !isLoading else { return }
        updateSelection(to: point(for: event))
    }

    override func mouseUp(with event: NSEvent) {
        guard !isLoading else { return }
        guard anchor != nil else { return }
        // The final event location is authoritative even when drag events coalesce.
        updateSelection(to: point(for: event))
        anchor = nil
        if selection.width >= 14, selection.height >= 14 {
            onSelect?(selection)
        } else {
            selection = .zero
            stopBorderAnimation()
            instruction = AppLocalizer.text(.selectionTooSmall)
            refresh()
        }
    }

    override func mouseMoved(with event: NSEvent) {
        guard !isLoading else { return }
        cursorPoint = point(for: event)
        NSCursor.crosshair.set()
        if anchor == nil { needsDisplay = true }
    }

    override func rightMouseDown(with event: NSEvent) {
        guard !isLoading else { return }
        onCancel?()
    }
    override func cancelOperation(_ sender: Any?) {
        guard !isLoading else { return }
        onCancel?()
    }
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53, !isLoading { onCancel?() }
        else { super.keyDown(with: event) }
    }

    func beginLoading(message: String) {
        guard !selection.isEmpty else { return }
        isLoading = true
        anchor = nil
        cursorPoint = nil
        setLoading(message: message)
        startBorderAnimationIfNeeded()
        NSCursor.arrow.set()
        window?.invalidateCursorRects(for: self)

        loadingTimer?.invalidate()
        let timer = Timer(
            timeInterval: 1.0 / 12.0, target: self,
            selector: #selector(advanceLoadingAnimation(_:)), userInfo: nil, repeats: true
        )
        loadingTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func setLoading(message: String) {
        loadingMessage = message
        if isLoading { instruction = message }
        updateAccessibility()
        needsDisplay = true
    }

    func stopLoading() {
        loadingTimer?.invalidate()
        loadingTimer = nil
        stopBorderAnimation()
        isLoading = false
    }

    @objc private func advanceLoadingAnimation(_ timer: Timer) {
        loadingPhase = (loadingPhase + 1) % 12
        needsDisplay = true
    }

    private func point(for event: NSEvent) -> CGPoint {
        let value = convert(event.locationInWindow, from: nil)
        return CGPoint(x: min(max(value.x, bounds.minX), bounds.maxX), y: min(max(value.y, bounds.minY), bounds.maxY))
    }

    private func updateSelection(to point: CGPoint) {
        guard let anchor else { return }
        cursorPoint = point
        selection = CGRect(
            x: min(anchor.x, point.x), y: min(anchor.y, point.y),
            width: abs(point.x - anchor.x), height: abs(point.y - anchor.y)
        )
        refresh()
    }

    private func startBorderAnimationIfNeeded() {
        // A detached test canvas does not need an active run-loop animation;
        // real selection canvases are always installed in a screen window.
        guard borderTimer == nil, window != nil else { return }
        let timer = Timer(
            timeInterval: 1.0 / 30.0, target: self,
            selector: #selector(advanceBorderAnimation(_:)), userInfo: nil, repeats: true
        )
        borderTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopBorderAnimation() {
        borderTimer?.invalidate()
        borderTimer = nil
    }

    @objc private func advanceBorderAnimation(_ timer: Timer) {
        borderPhase = (borderPhase + 0.014).truncatingRemainder(dividingBy: 1)
        needsDisplay = true
    }

    private func refresh() {
        updateAccessibility()
        needsDisplay = true
        displayIfNeeded()
    }

    private func updateAccessibility() {
        if isLoading {
            setAccessibilityValue(AppLocalizer.format(.selectionProcessingFormat, loadingMessage))
        } else {
            setAccessibilityValue(selection.isEmpty
                ? instruction
                : AppLocalizer.format(
                    .selectionSizeFormat,
                    String(Int(selection.width)),
                    String(Int(selection.height))
                ))
        }
    }

    private func drawLoadingState() {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .semibold), .foregroundColor: NSColor.white
        ]
        let textSize = loadingMessage.size(withAttributes: attributes)
        let cardWidth = min(bounds.width - 24, max(170, textSize.width + 56))
        let cardHeight: CGFloat = 34
        let preferredY = selection.maxY + 12
        let y = preferredY + cardHeight <= bounds.maxY - 12
            ? preferredY
            : max(bounds.minY + 12, selection.minY - cardHeight - 12)
        let card = CGRect(x: min(max(selection.midX - cardWidth / 2, bounds.minX + 12), bounds.maxX - cardWidth - 12),
                          y: y, width: cardWidth, height: cardHeight)
        NSColor.black.withAlphaComponent(0.68).setFill()
        NSBezierPath(roundedRect: card, xRadius: 9, yRadius: 9).fill()

        let center = CGPoint(x: card.minX + 18, y: card.midY)
        for index in 0..<12 {
            let angle = CGFloat(index) / 12 * (.pi * 2) - .pi / 2
            let progress = (index - loadingPhase + 12) % 12
            let alpha = 0.18 + (1 - CGFloat(progress) / 12) * 0.82
            let path = NSBezierPath()
            path.move(to: CGPoint(x: center.x + cos(angle) * 5, y: center.y + sin(angle) * 5))
            path.line(to: CGPoint(x: center.x + cos(angle) * 8, y: center.y + sin(angle) * 8))
            path.lineWidth = 2
            path.lineCapStyle = .round
            NSColor.white.withAlphaComponent(alpha).setStroke()
            path.stroke()
        }
        loadingMessage.draw(in: CGRect(x: card.minX + 34, y: card.minY + 9, width: card.width - 46, height: textSize.height), withAttributes: attributes)
    }

    /// This is deliberately static: it matches the finished translation frame
    /// without suggesting that OCR has already started.
    private func drawStaticSelectionBorder() {
        SelectionBorderStyle.draw(in: selection, emphasis: .idle)
    }

    /// Draw several thin, colour-shifting passes around the perimeter. The
    /// broad low-alpha pass is the outer bloom, while the crisp pass keeps the
    /// actual selection edge easy to read on light and dark screens.
    private func drawAnimatedSelectionBorder() {
        SelectionBorderStyle.draw(in: selection, phase: borderPhase, emphasis: .processing)
    }

    private func drawBadge(_ text: String, centeredAt center: CGPoint, fontSize: CGFloat) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize, weight: .medium), .foregroundColor: NSColor.white
        ]
        let size = text.size(withAttributes: attributes)
        let width = min(size.width + 32, bounds.width - 24)
        let x = min(max(center.x - width / 2, bounds.minX + 12), bounds.maxX - width - 12)
        let rect = CGRect(x: x, y: center.y - (size.height + 22) / 2, width: width, height: size.height + 22)
        NSColor.black.withAlphaComponent(0.88).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 10, yRadius: 10).fill()
        text.draw(in: rect.insetBy(dx: 16, dy: 11), withAttributes: attributes)
    }

    private func drawFollowBadge(_ text: String, near point: CGPoint) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .semibold), .foregroundColor: NSColor.white
        ]
        let size = text.size(withAttributes: attributes)
        let width = min(size.width + 28, bounds.width - 24)
        let height = size.height + 18
        let x = min(max(point.x + 18, bounds.minX + 12), bounds.maxX - width - 12)
        let y = min(max(point.y - height - 18, bounds.minY + 12), bounds.maxY - height - 12)
        let rect = CGRect(x: x, y: y, width: width, height: height)
        NSColor.black.withAlphaComponent(0.78).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 9, yRadius: 9).fill()
        text.draw(in: rect.insetBy(dx: 14, dy: 9), withAttributes: attributes)
    }
}

/// The finished frame and selection frame share one visual language. Processing
/// adds motion but deliberately keeps a fixed visual weight for its full run.
enum SelectionBorderStyle {
    enum Emphasis {
        case idle
        case processing
    }

    static func draw(in sourceRect: CGRect, phase: CGFloat = 0, emphasis: Emphasis = .idle) {
        let rect = sourceRect.integral
        guard rect.width > 1, rect.height > 1 else { return }
        let appearance = BorderAppearance.current()
        let scale: CGFloat = emphasis == .processing ? 1 : 0.52
        let coreWidth = max(1, appearance.strokeWidth * scale)
        let glowWidth = max(coreWidth, appearance.glowWidth * scale)
        let middleWidth = max(coreWidth, (glowWidth + coreWidth) * 0.5)
        let widths: [(CGFloat, CGFloat)] = [(glowWidth, 0.13), (middleWidth, 0.23), (coreWidth, 0.96)]
        let corners = perimeterCorners(in: rect)
        let progress = cornerProgress(for: rect)

        for (lineWidth, alpha) in widths {
            for index in 0..<4 {
                drawGradientEdge(
                    from: corners[index], to: corners[index + 1],
                    startColor: color(at: progress[index], phase: phase, appearance: appearance),
                    endColor: color(at: progress[index + 1], phase: phase, appearance: appearance),
                    width: lineWidth,
                    alpha: alpha
                )
            }
        }

        NSColor.white.withAlphaComponent(0.54).setStroke()
        let highlight = NSBezierPath(rect: rect.insetBy(dx: coreWidth / 2, dy: coreWidth / 2))
        highlight.lineWidth = emphasis == .processing ? 0.8 : 0.55
        highlight.stroke()
    }

    private static func perimeterCorners(in rect: CGRect) -> [CGPoint] {
        [
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY)
        ]
    }

    private static func cornerProgress(for rect: CGRect) -> [CGFloat] {
        let perimeter = max(1, 2 * (rect.width + rect.height))
        return [
            0,
            rect.width / perimeter,
            (rect.width + rect.height) / perimeter,
            (rect.width * 2 + rect.height) / perimeter,
            1
        ]
    }

    private static func drawGradientEdge(
        from: CGPoint,
        to: CGPoint,
        startColor: NSColor,
        endColor: NSColor,
        width: CGFloat,
        alpha: CGFloat
    ) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let edge = CGMutablePath()
        edge.move(to: from)
        edge.addLine(to: to)
        let stroke = edge.copy(
            strokingWithWidth: width,
            lineCap: .square,
            lineJoin: .miter,
            miterLimit: 2
        )
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: [
                startColor.withAlphaComponent(alpha).cgColor,
                endColor.withAlphaComponent(alpha).cgColor
            ] as CFArray,
            locations: [0, 1]
        ) else { return }
        context.saveGState()
        context.addPath(stroke)
        context.clip()
        context.drawLinearGradient(gradient, start: from, end: to, options: [])
        context.restoreGState()
    }

    private static func color(at progress: CGFloat, phase: CGFloat, appearance: BorderAppearance) -> NSColor {
        let colors = [
            BorderAppearanceColor.color(from: appearance.primaryColor, fallback: .systemBlue),
            BorderAppearanceColor.color(from: appearance.secondaryColor, fallback: .systemPurple),
            BorderAppearanceColor.color(from: appearance.tertiaryColor, fallback: .systemPink),
            BorderAppearanceColor.color(from: appearance.secondaryColor, fallback: .systemPurple),
            BorderAppearanceColor.color(from: appearance.primaryColor, fallback: .systemBlue)
        ]
        let wrapped = (progress - phase).truncatingRemainder(dividingBy: 1)
        let position = wrapped < 0 ? wrapped + 1 : wrapped
        let value = position * CGFloat(colors.count - 1)
        let index = min(Int(value), colors.count - 2)
        let next = index + 1
        return colors[index].blended(withFraction: value - floor(value), of: colors[next]) ?? colors[index]
    }
}
