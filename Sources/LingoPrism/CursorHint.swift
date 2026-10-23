import AppKit

/// A short, non-interactive status hint that lives next to the pointer. It is
/// deliberately a borderless click-through panel, so feedback never interrupts
/// the app the person was translating.
@MainActor
final class CursorHintController {
    static let shared = CursorHintController()

    private var panel: CursorHintPanel?
    private var dismissal: DispatchWorkItem?

    func show(_ message: String) {
        dismiss()

        let size = CursorHintView.size(for: message)
        let pointer = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(pointer) }) ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? CGRect(x: pointer.x - size.width / 2, y: pointer.y - size.height / 2, width: size.width, height: size.height)
        let origin = clampedOrigin(near: pointer, size: size, in: visibleFrame)

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
        panel.ignoresMouseEvents = true
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.contentView = CursorHintView(frame: CGRect(origin: .zero, size: size), message: message)
        panel.orderFrontRegardless()
        self.panel = panel

        let dismissal = DispatchWorkItem { [weak self, weak panel] in
            self?.fadeOut(panel)
        }
        self.dismissal = dismissal
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: dismissal)
    }

    func dismiss() {
        dismissal?.cancel()
        dismissal = nil
        panel?.orderOut(nil)
        panel = nil
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
}

private final class CursorHintPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private final class CursorHintView: NSView {
    private let message: String
    private static let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: 14, weight: .semibold),
        .foregroundColor: NSColor.white
    ]

    init(frame: CGRect, message: String) {
        self.message = message
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        let bubble = bounds.insetBy(dx: 1, dy: 1)
        NSColor.black.withAlphaComponent(0.84).setFill()
        NSBezierPath(roundedRect: bubble, xRadius: 9, yRadius: 9).fill()
        NSColor.white.withAlphaComponent(0.16).setStroke()
        let outline = NSBezierPath(roundedRect: bubble.insetBy(dx: 0.5, dy: 0.5), xRadius: 8.5, yRadius: 8.5)
        outline.lineWidth = 1
        outline.stroke()
        message.draw(in: bubble.insetBy(dx: 14, dy: 9), withAttributes: Self.attributes)
    }

    static func size(for message: String) -> CGSize {
        let measured = message.size(withAttributes: attributes)
        return CGSize(width: ceil(measured.width + 30), height: max(36, ceil(measured.height + 18)))
    }
}
