import AppKit
import SwiftUI

/// Every in-app brand mark reads the exact PNG supplied for Lingo Prism. The
/// PNG is intentionally separate from the app's `.icns`: AppKit and Launch
/// Services can cache application icons, whereas these UI placements must
/// always reproduce the supplied artwork exactly.
enum LingoPrismBrandAsset {
    static func image(size: CGFloat? = nil) -> NSImage {
        let image: NSImage
        if let url = Bundle.main.url(forResource: "LingoPrismBrand", withExtension: "png"),
           let bundled = NSImage(contentsOf: url) {
            image = bundled
        } else {
            image = NSImage(size: NSSize(width: 1, height: 1))
        }
        guard let size else { return image }
        let copy = image.copy() as? NSImage ?? image
        copy.size = NSSize(width: size, height: size)
        return copy
    }
}

enum LingoPrismMenuBarAsset {
    static func image(size: CGFloat? = nil) -> NSImage {
        let image: NSImage
        if let url = Bundle.main.url(forResource: "LingoPrismMenuBar", withExtension: "png"),
           let bundled = NSImage(contentsOf: url) {
            image = bundled
        } else {
            image = NSImage(size: NSSize(width: 1, height: 1))
        }
        guard let size else { return image }
        let copy = image.copy() as? NSImage ?? image
        copy.size = NSSize(width: size, height: size)
        return copy
    }
}

struct LingoPrismBrandIcon: View {
    let size: CGFloat
    var cornerRadius: CGFloat? = nil

    var body: some View {
        // MenuBarExtra reads the NSImage's intrinsic size rather than only the
        // SwiftUI frame, so size the backing image itself for every placement.
        Image(nsImage: LingoPrismBrandAsset.image(size: size))
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius ?? size * 0.19, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// The menu-bar status area uses a background-free white mark so it remains
/// legible over both light and dark menu bars. The full-color app mark remains
/// reserved for the popup, settings header, and application icon.
struct LingoPrismMenuBarIcon: View {
    let size: CGFloat

    var body: some View {
        Image(nsImage: LingoPrismMenuBarAsset.image(size: size))
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
