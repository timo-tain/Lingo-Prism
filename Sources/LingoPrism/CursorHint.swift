import AppKit

/// A transient status hint shown beside the pointer or below the selected
/// screen region. Hovering the hint keeps it visible for as long as needed.
@MainActor
final class CursorHintController {
    static let shared = CursorHintController()

    private var panel: CursorHintPanel?
    private var dismissal: DispatchWorkItem?
    private var isPointerInsidePanel = false

    func show(_ message: String, anchoredTo selectionRect: CGRect? = nil) {
        dismiss()

        let size = CursorHintView.size(for: message)
        let pointer = NSEvent.mouseLocation
        let screen = selectionRect.flatMap { rect in
            NSScreen.screens.first(where: { $0.frame.intersects(rect) })
        } ?? NSScreen.screens.first(where: { $0.frame.contains(pointer) }) ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? CGRect(x: pointer.x - size.width / 2, y: pointer.y - size.height / 2, width: size.width, height: size.height)
        let origin: CGPoint
        if let selectionRect {
            origin = clampedOrigin(below: selectionRect, size: size, in: visibleFrame)
        } else {
            origin = clampedOrigin(near: pointer, size: size, in: visibleFrame)
        }

        let panel = CursorHintPanel(
            contentRect: CGRect(origin: origin, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.alphaValue = 1
        let hintView = CursorHintView(frame: CGRect(origin: .zero, size: size), message: message) { [weak self, weak panel] isInside in
            guard let self, let panel, self.panel === panel else { return }
            self.isPointerInsidePanel = isInside
            if isInside {
                self.cancelDismissal()
            } else {
                self.scheduleDismissal(for: panel)
            }
        }
        panel.contentView = hintView
        self.panel = panel
        isPointerInsidePanel = panel.frame.contains(pointer)
        panel.orderFrontRegardless()

        if !isPointerInsidePanel { scheduleDismissal(for: panel) }
    }

    func dismiss() {
        dismissal?.cancel()
        dismissal = nil
        isPointerInsidePanel = false
        panel?.orderOut(nil)
        panel = nil
    }

    private func cancelDismissal() {
        dismissal?.cancel()
        dismissal = nil
    }

    private func scheduleDismissal(for panel: CursorHintPanel) {
        cancelDismissal()
        guard !isPointerInsidePanel else { return }
        let dismissal = DispatchWorkItem { [weak self, weak panel] in
            self?.fadeOut(panel)
        }
        self.dismissal = dismissal
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: dismissal)
    }

    private func fadeOut(_ panel: CursorHintPanel?) {
        guard let panel, self.panel === panel else { return }
        dismissal = nil
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self, weak panel] in
            DispatchQueue.main.async {
                guard let self, let panel, self.panel === panel else { return }
                panel.orderOut(nil)
                self.panel = nil
            }
        }
    }

    private func clampedOrigin(near pointer: CGPoint, size: CGSize, in visibleFrame: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(pointer.x + 18, visibleFrame.minX + 10), visibleFrame.maxX - size.width - 10),
            y: min(max(pointer.y - size.height - 18, visibleFrame.minY + 10), visibleFrame.maxY - size.height - 10)
        )
    }

    private func clampedOrigin(below selection: CGRect, size: CGSize, in visibleFrame: CGRect) -> CGPoint {
        CGPoint(
            x: min(max(selection.midX - size.width / 2, visibleFrame.minX + 10), visibleFrame.maxX - size.width - 10),
            y: min(max(selection.minY - size.height - 10, visibleFrame.minY + 10), visibleFrame.maxY - size.height - 10)
        )
    }
}

private final class CursorHintPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private final class CursorHintView: NSView {
    private let message: String
    private let onHoverChanged: (Bool) -> Void
    private var trackingArea: NSTrackingArea?
    private static let textFont = NSFont.systemFont(ofSize: 14, weight: .semibold)
    private static let attributes: [NSAttributedString.Key: Any] = {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        return [.font: textFont, .foregroundColor: NSColor.white, .paragraphStyle: paragraph]
    }()

    init(frame: CGRect, message: String, onHoverChanged: @escaping (Bool) -> Void) {
        self.message = message
        self.onHoverChanged = onHoverChanged
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var isOpaque: Bool { false }

    override func updateTrackingAreas() {
        if let trackingArea { removeTrackingArea(trackingArea) }
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        self.trackingArea = trackingArea
        super.updateTrackingAreas()
    }

    override func mouseEntered(with event: NSEvent) { onHoverChanged(true) }
    override func mouseExited(with event: NSEvent) { onHoverChanged(false) }

    override func draw(_ dirtyRect: NSRect) {
        let bubble = bounds.insetBy(dx: 1, dy: 1)
        NSColor.black.withAlphaComponent(0.84).setFill()
        NSBezierPath(roundedRect: bubble, xRadius: 9, yRadius: 9).fill()
        NSColor.white.withAlphaComponent(0.16).setStroke()
        let outline = NSBezierPath(roundedRect: bubble.insetBy(dx: 0.5, dy: 0.5), xRadius: 8.5, yRadius: 8.5)
        outline.lineWidth = 1
        outline.stroke()
        let textRect = bubble.insetBy(dx: 14, dy: 9)
        NSAttributedString(string: message, attributes: Self.attributes)
            .draw(with: textRect, options: [.usesLineFragmentOrigin, .usesFontLeading])
    }

    static func size(for message: String) -> CGSize {
        let maximumTextWidth: CGFloat = 400
        let measured = (message as NSString).boundingRect(
            with: CGSize(width: maximumTextWidth, height: 1_000),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes
        )
        let textWidth = min(maximumTextWidth, ceil(measured.width))
        return CGSize(width: textWidth + 30, height: max(36, ceil(measured.height) + 18))
    }
}
