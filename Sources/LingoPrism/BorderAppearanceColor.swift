import AppKit

enum BorderAppearanceColor {
    static func color(from value: String, fallback: NSColor) -> NSColor {
        let hex = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard hex.count == 6, let number = UInt32(hex, radix: 16) else { return fallback }
        return NSColor(
            red: CGFloat((number >> 16) & 0xFF) / 255,
            green: CGFloat((number >> 8) & 0xFF) / 255,
            blue: CGFloat(number & 0xFF) / 255,
            alpha: 1
        )
    }

    static func hex(from color: NSColor) -> String {
        let rgb = color.usingColorSpace(.deviceRGB) ?? color
        return String(
            format: "#%02X%02X%02X",
            Int((rgb.redComponent * 255).rounded()),
            Int((rgb.greenComponent * 255).rounded()),
            Int((rgb.blueComponent * 255).rounded())
        )
    }
}
