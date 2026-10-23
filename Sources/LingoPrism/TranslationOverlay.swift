import AppKit
import SwiftUI

enum TranslationOverlayAction {
    case close
    case reselect
    case copyTranslation
    case copyOriginal
}

@MainActor
final class TranslationOverlayController {
    static let shared = TranslationOverlayController()
    private var window: TranslationWindow?

    func present(
        result: TranslationResult,
        selection: ScreenSelection,
        image: CGImage,
        onAction: @escaping (TranslationOverlayAction) -> Void
    ) {
        dismiss()
        let selected = selection.screenRect.integral
        let screen = selection.screen.frame
        let toolbarWidth: CGFloat = 210
        let toolbarHeight: CGFloat = 28
        let toolbarY = selected.minY >= screen.minY + 38
            ? selected.minY - 34
            : min(selected.maxY + 5, screen.maxY - toolbarHeight - 5)
        let toolbar = CGRect(
            x: min(max(selected.maxX - toolbarWidth, screen.minX + 5), screen.maxX - toolbarWidth - 5),
            y: toolbarY, width: toolbarWidth, height: toolbarHeight
        )
        let frame = selected.union(toolbar).insetBy(dx: -8, dy: -8).integral
        let canvas = TranslationCanvasView(
            frame: CGRect(origin: .zero, size: frame.size), image: image, result: result,
            selectedRect: selected.offsetBy(dx: -frame.minX, dy: -frame.minY),
            toolbarRect: toolbar.offsetBy(dx: -frame.minX, dy: -frame.minY)
        )
        canvas.onAction = onAction
        let window = TranslationWindow(
            contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false
        )
        window.title = AppLocalizer.text(.overlayTitle)
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.contentView = canvas
        window.setFrame(frame, display: false)
        self.window = window
        NSApp.activate(ignoringOtherApps: true)
        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(canvas)
    }

    func dismiss() {
        window?.orderOut(nil)
        window?.close()
        window = nil
    }
}

private final class TranslationWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class FloatingTranslationController {
    static let shared = FloatingTranslationController()
    private var panel: NSPanel?

    func present(
        result: TranslationResult,
        selection: ScreenSelection,
        onAction: @escaping (TranslationOverlayAction) -> Void
    ) {
        dismiss()
        let screen = selection.screen
        let selectionRect = selection.screenRect
        let width = min(max(selectionRect.width, 380), 580)
        let height: CGFloat = 300
        var origin = CGPoint(x: selectionRect.maxX + 14, y: selectionRect.maxY - height)
        if origin.x + width > screen.visibleFrame.maxX { origin.x = selectionRect.minX - width - 14 }
        if origin.x < screen.visibleFrame.minX { origin.x = max(screen.visibleFrame.minX + 14, selectionRect.minX) }
        origin.y = min(max(origin.y, screen.visibleFrame.minY + 14), screen.visibleFrame.maxY - height - 14)
        let panel = makePanel(frame: CGRect(origin: origin, size: CGSize(width: width, height: height)), screen: screen)
        panel.hasShadow = true
        panel.contentView = NSHostingView(rootView: FloatingTranslationCard(result: result, onAction: onAction))
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel
    }

    func dismiss() {
        panel?.orderOut(nil)
        panel = nil
    }
}

@MainActor
private func makePanel(frame: CGRect, screen: NSScreen) -> NSPanel {
    let panel = NSPanel(
        contentRect: frame,
        styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
        backing: .buffered,
        defer: false,
        screen: screen
    )
    panel.level = .floating
    panel.isOpaque = false
    panel.backgroundColor = .clear
    panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    panel.hidesOnDeactivate = false
    panel.isMovableByWindowBackground = false
    return panel
}

/// A frozen selection is the base layer. Only recognized text is repainted,
/// leaving icons, images, avatars and surrounding layout intact.
final class TranslationCanvasView: NSView {
    var onAction: ((TranslationOverlayAction) -> Void)?
    private let screenshot: NSImage
    private let selectedRect: CGRect
    private let result: TranslationResult
    private let blocks: [PaintedTranslationBlock]
    private let originalButton: NSButton
    private var translationTextViews: [NSTextView] = []
    private(set) var showsOriginal = false
    var translatedTextFrames: [CGRect] { blocks.map(\.textRect) }
    var selectableTranslationViews: [NSTextView] { translationTextViews }

    init(frame: CGRect, image: CGImage, result: TranslationResult, selectedRect: CGRect, toolbarRect: CGRect) {
        self.screenshot = NSImage(cgImage: image, size: selectedRect.size)
        self.selectedRect = selectedRect
        self.result = result
        self.blocks = TranslationPaintLayout.makeBlocks(result: result, image: image, size: selectedRect.size)
        self.originalButton = NSButton(title: AppLocalizer.text(.original), target: nil, action: nil)
        super.init(frame: frame)
        wantsLayer = false
        setAccessibilityElement(true)
        setAccessibilityLabel(AppLocalizer.text(.overlayAccessibility))

        // Drawing text directly into the canvas looks right but cannot be
        // selected. Keep the calculated rendering attributes and geometry,
        // then give every translated block a transparent NSTextView so users
        // can drag to select and copy only the words they need.
        for (index, block) in blocks.enumerated() {
            let textView = NSTextView(frame: block.textRect.offsetBy(dx: selectedRect.minX, dy: selectedRect.minY))
            textView.isEditable = false
            textView.isSelectable = true
            textView.isRichText = true
            textView.drawsBackground = false
            textView.backgroundColor = .clear
            textView.textContainerInset = .zero
            textView.textContainer?.lineFragmentPadding = 0
            textView.textContainer?.widthTracksTextView = true
            textView.textContainer?.containerSize = CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude)
            textView.textStorage?.setAttributedString(block.text)
            textView.setAccessibilityLabel(AppLocalizer.format(.translationSegmentFormat, index + 1))
            textView.setAccessibilityValue(block.text.string)
            addSubview(textView)
            translationTextViews.append(textView)
        }

        let toolbar = NSVisualEffectView(frame: toolbarRect)
        toolbar.material = .hudWindow
        toolbar.blendingMode = .behindWindow
        toolbar.state = .active
        toolbar.wantsLayer = true
        toolbar.layer?.cornerRadius = 10
        toolbar.layer?.masksToBounds = true
        toolbar.layer?.borderColor = NSColor.white.withAlphaComponent(0.24).cgColor
        toolbar.layer?.borderWidth = 1
        addSubview(toolbar)

        originalButton.frame = CGRect(x: 4, y: 3, width: 57, height: 22)
        originalButton.target = self
        originalButton.action = #selector(toggleOriginal)
        originalButton.toolTip = AppLocalizer.text(.showOriginal)
        originalButton.setAccessibilityLabel(AppLocalizer.text(.showOriginal))
        configure(originalButton)
        toolbar.addSubview(originalButton)

        let actions: [(String, String, Selector)] = [
            ("doc.on.doc", AppLocalizer.text(.copyTranslation), #selector(copyTranslation)),
            ("viewfinder", AppLocalizer.text(.reselect), #selector(reselect)),
            ("xmark", AppLocalizer.text(.closeOverlay), #selector(closeOverlay))
        ]
        for (index, item) in actions.enumerated() {
            let button = NSButton(frame: CGRect(x: 65 + CGFloat(index) * 45, y: 3, width: 39, height: 22))
            button.image = NSImage(systemSymbolName: item.0, accessibilityDescription: item.1)
            button.imagePosition = .imageOnly
            button.target = self
            button.action = item.2
            button.toolTip = item.1
            button.setAccessibilityLabel(item.1)
            configure(button)
            toolbar.addSubview(button)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var acceptsFirstResponder: Bool { true }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        screenshot.draw(in: selectedRect, from: .zero, operation: .copy, fraction: 1)
        if !showsOriginal {
            NSGraphicsContext.saveGraphicsState()
            NSBezierPath(rect: selectedRect).addClip()
            for block in blocks {
                block.background.setFill()
                NSBezierPath(rect: block.patchRect.offsetBy(dx: selectedRect.minX, dy: selectedRect.minY)).fill()
            }
            NSGraphicsContext.restoreGraphicsState()
        }

        SelectionBorderStyle.draw(in: selectedRect)
    }

    func setShowsOriginal(_ value: Bool) {
        showsOriginal = value
        translationTextViews.forEach { $0.isHidden = value }
        originalButton.title = value ? AppLocalizer.text(.translated) : AppLocalizer.text(.original)
        originalButton.setAccessibilityLabel(value ? AppLocalizer.text(.showTranslation) : AppLocalizer.text(.showOriginal))
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onAction?(.close) }
        else { super.keyDown(with: event) }
    }

    private func configure(_ button: NSButton) {
        button.bezelStyle = .recessed
        button.isBordered = false
        button.font = .systemFont(ofSize: 11, weight: .medium)
        button.contentTintColor = .white
    }

    @objc private func toggleOriginal() { setShowsOriginal(!showsOriginal) }
    @objc private func copyTranslation() { onAction?(.copyTranslation) }
    @objc private func reselect() { onAction?(.reselect) }
    @objc private func closeOverlay() { onAction?(.close) }
}

private struct PaintedTranslationBlock {
    let patchRect: CGRect
    let textRect: CGRect
    let text: NSAttributedString
    let background: NSColor
}

private enum TranslationPaintLayout {
    private struct Line {
        let rect: CGRect
        let translatedText: String
    }

    static func makeBlocks(result: TranslationResult, image: CGImage, size: CGSize) -> [PaintedTranslationBlock] {
        let lines: [Line] = result.lines.map { item in
            let box = item.boundingBox
            let rect = CGRect(
                x: CGFloat(box.x) * size.width,
                y: CGFloat(box.y) * size.height,
                width: CGFloat(box.width) * size.width,
                height: CGFloat(box.height) * size.height
            )
            return Line(rect: rect, translatedText: item.translatedText)
        }.sorted { lhs, rhs in
            abs(lhs.rect.midY - rhs.rect.midY) > 3 ? lhs.rect.midY > rhs.rect.midY : lhs.rect.minX < rhs.rect.minX
        }
        var groups: [[Line]] = []
        for line in lines {
            if let previous = groups.last?.last {
                let gap = previous.rect.minY - line.rect.maxY
                if gap >= -2, gap <= max(7, previous.rect.height * 0.85),
                   abs(previous.rect.minX - line.rect.minX) <= max(18, previous.rect.height * 2) {
                    groups[groups.count - 1].append(line)
                    continue
                }
            }
            groups.append([line])
        }

        let bitmap = NSBitmapImageRep(cgImage: image)
        var cursor = size.height - 3
        var output: [PaintedTranslationBlock] = []
        for group in groups {
            guard let first = group.first else { continue }
            let source = group.dropFirst().reduce(first.rect) { $0.union($1.rect) }
            let text = group.map(\.translatedText).joined(separator: "\n")
            let centered = source.width > size.width * 0.35 && abs(source.midX - size.width / 2) < size.width * 0.12
            let x = centered ? max(5, source.midX - min(size.width - 10, source.width * 1.25) / 2) : max(5, source.minX)
            let maxWidth = centered ? min(size.width - 10, source.width * 1.25) : max(24, size.width - x - 5)
            let lineHeight = group.map(\.rect.height).sorted()[group.count / 2]
            let fontSize = min(max(lineHeight * 1.02, 11), 52)
            let naturalWidth = text.split(separator: "\n").map { String($0).size(withAttributes: [.font: NSFont.systemFont(ofSize: fontSize)]).width }.max() ?? source.width
            let width = min(maxWidth, max(source.width + 5, naturalWidth + 6))
            let textX = centered ? min(max(5, source.midX - width / 2), size.width - width - 5) : x
            let top = min(size.height - 3, source.maxY + 2, cursor)
            let background = backgroundColor(near: source, bitmap: bitmap, size: size)
            let luminance = background.redComponent * 0.2126 + background.greenComponent * 0.7152 + background.blueComponent * 0.0722
            var rendered: NSAttributedString = NSAttributedString(string: text)
            var height: CGFloat = source.height
            for candidate in stride(from: fontSize, through: max(8, fontSize * 0.58), by: -1) {
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = centered ? .center : .left
                paragraph.lineBreakMode = .byWordWrapping
                rendered = NSAttributedString(string: text, attributes: [
                    .font: NSFont.systemFont(ofSize: candidate, weight: .medium),
                    .foregroundColor: luminance < 0.52 ? NSColor.white : NSColor.black,
                    .paragraphStyle: paragraph
                ])
                height = ceil(rendered.boundingRect(
                    with: CGSize(width: width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading]
                ).height)
                if height <= top - 5 || candidate <= max(8, fontSize * 0.58) + 1 { break }
            }
            let textRect = CGRect(x: textX, y: top - height, width: width, height: height)
            let patch = source.union(textRect).insetBy(dx: -4, dy: -2)
                .intersection(CGRect(origin: .zero, size: size))
            output.append(PaintedTranslationBlock(
                patchRect: patch, textRect: textRect, text: rendered,
                background: background
            ))
            cursor = textRect.minY - max(4, fontSize * 0.28)
        }
        return output
    }

    private static func backgroundColor(near rect: CGRect, bitmap: NSBitmapImageRep, size: CGSize) -> NSColor {
        var points: [CGPoint] = []
        for fraction in [0.2, 0.5, 0.8] as [CGFloat] {
            let x = rect.minX + rect.width * fraction
            for distance in [5, 10] as [CGFloat] {
                points.append(CGPoint(x: x, y: rect.minY - distance))
                points.append(CGPoint(x: x, y: rect.maxY + distance))
            }
            let y = rect.minY + rect.height * fraction
            for distance in [5, 10] as [CGFloat] {
                points.append(CGPoint(x: rect.minX - distance, y: y))
                points.append(CGPoint(x: rect.maxX + distance, y: y))
            }
        }
        let colors = points.compactMap { point -> NSColor? in
            guard point.x >= 0, point.y >= 0, point.x < size.width, point.y < size.height else { return nil }
            let pixelX = min(bitmap.pixelsWide - 1, Int(point.x / size.width * CGFloat(bitmap.pixelsWide)))
            let pixelY = min(bitmap.pixelsHigh - 1, Int((size.height - point.y) / size.height * CGFloat(bitmap.pixelsHigh)))
            return bitmap.colorAt(x: pixelX, y: pixelY)?.usingColorSpace(.deviceRGB)
        }.sorted {
            luminance($0) < luminance($1)
        }
        guard !colors.isEmpty else { return NSColor(calibratedWhite: 0.16, alpha: 1) }
        // Dark interfaces often have white text or icons near the OCR box;
        // light interfaces have the inverse. Favor the dominant background side.
        let darkBackground = luminance(colors[colors.count / 2]) < 0.5
        return colors[darkBackground ? colors.count / 4 : min(colors.count - 1, colors.count * 3 / 4)]
    }

    private static func luminance(_ color: NSColor) -> CGFloat {
        color.redComponent * 0.2126 + color.greenComponent * 0.7152 + color.blueComponent * 0.0722
    }
}

private struct FloatingTranslationCard: View {
    let result: TranslationResult
    let onAction: (TranslationOverlayAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(result.engine.title)
                    .font(.headline)
                Spacer()
                Button { onAction(.reselect) } label: { Image(systemName: "viewfinder") }
                    .buttonStyle(.borderless)
                    .help(AppLocalizer.text(.reselect))
                Button { onAction(.close) } label: { Image(systemName: "xmark") }
                    .buttonStyle(.borderless)
                    .help(AppLocalizer.text(.close))
            }
            .padding(14)

            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(result.translatedText)
                        .font(.body)
                        .textSelection(.enabled)
                    Divider()
                    Text(AppLocalizer.text(.original))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(result.sourceText)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
            }
            Divider()
            HStack {
                Button(AppLocalizer.text(.copyOriginal)) { onAction(.copyOriginal) }
                Spacer()
                Button(AppLocalizer.text(.copyTranslation)) { onAction(.copyTranslation) }
                    .keyboardShortcut("c", modifiers: [.command])
            }
            .padding(12)
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.24)))
        .padding(2)
    }
}
