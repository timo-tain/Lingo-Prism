import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let projectRoot = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let sourceURL = projectRoot.appending(path: "Resources/LingoPrismBrand.png")
let iconsetURL = projectRoot.appending(path: "Resources/LingoPrism.iconset", directoryHint: .isDirectory)
let masterSize = 1024
let bytesPerPixel = 4
let bytesPerRow = masterSize * bytesPerPixel
let pixelCount = masterSize * masterSize

guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
      let sourceImage = CGImageSourceCreateImageAtIndex(source, 0, nil),
      let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
else {
    fatalError("Could not read the Lingo Prism brand image.")
}

let sourceBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: pixelCount * bytesPerPixel)
sourceBytes.initialize(repeating: 0, count: pixelCount * bytesPerPixel)
defer { sourceBytes.deallocate() }

let rgbaInfo = CGBitmapInfo.byteOrder32Big.union(
    CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
)
guard let sourceContext = CGContext(
    data: sourceBytes,
    width: masterSize,
    height: masterSize,
    bitsPerComponent: 8,
    bytesPerRow: bytesPerRow,
    space: colorSpace,
    bitmapInfo: rgbaInfo.rawValue
) else {
    fatalError("Could not create the app icon canvas.")
}
sourceContext.interpolationQuality = .high
sourceContext.draw(sourceImage, in: CGRect(x: 0, y: 0, width: masterSize, height: masterSize))

// Apple applies the rounded-rectangle mask. Extend the existing background
// pixels through the old transparent rounded corners so the source artwork
// itself remains a full-bleed square without a second, baked-in border.
var nearestOpaquePixel = [Int32](repeating: -1, count: pixelCount)
var queue = [Int32]()
queue.reserveCapacity(pixelCount)
for pixel in 0..<pixelCount where sourceBytes[pixel * bytesPerPixel + 3] == 255 {
    let index = Int32(pixel)
    nearestOpaquePixel[pixel] = index
    queue.append(index)
}

var queueHead = 0
while queueHead < queue.count {
    let pixel = Int(queue[queueHead])
    queueHead += 1
    let row = pixel / masterSize
    let column = pixel % masterSize
    let seed = nearestOpaquePixel[pixel]
    let minRow = max(0, row - 1)
    let maxRow = min(masterSize - 1, row + 1)
    let minColumn = max(0, column - 1)
    let maxColumn = min(masterSize - 1, column + 1)

    for neighborRow in minRow...maxRow {
        for neighborColumn in minColumn...maxColumn {
            let neighbor = neighborRow * masterSize + neighborColumn
            guard nearestOpaquePixel[neighbor] == -1 else { continue }
            nearestOpaquePixel[neighbor] = seed
            queue.append(Int32(neighbor))
        }
    }
}

var fullBleedBytes = [UInt8](repeating: 255, count: pixelCount * bytesPerPixel)
for pixel in 0..<pixelCount {
    let offset = pixel * bytesPerPixel
    let seedOffset = Int(nearestOpaquePixel[pixel]) * bytesPerPixel
    let alpha = Double(sourceBytes[offset + 3]) / 255
    for channel in 0..<3 {
        let originalPremultiplied = Double(sourceBytes[offset + channel])
        let extendedBackground = Double(sourceBytes[seedOffset + channel]) * (1 - alpha)
        fullBleedBytes[offset + channel] = UInt8(min(255, (originalPremultiplied + extendedBackground).rounded()))
    }
}

func makeOpaqueImage(bytes: UnsafeRawPointer, width: Int, height: Int, rowBytes: Int) -> CGImage {
    let imageData = Data(bytes: bytes, count: rowBytes * height)
    guard let provider = CGDataProvider(data: imageData as CFData),
          let image = CGImage(
              width: width,
              height: height,
              bitsPerComponent: 8,
              bitsPerPixel: 32,
              bytesPerRow: rowBytes,
              space: colorSpace,
              bitmapInfo: CGBitmapInfo.byteOrder32Big.union(
                  CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
              ),
              provider: provider,
              decode: nil,
              shouldInterpolate: true,
              intent: .defaultIntent
          )
    else {
        fatalError("Could not create a full-bleed app icon image.")
    }
    return image
}

let masterImage = fullBleedBytes.withUnsafeBytes {
    makeOpaqueImage(bytes: $0.baseAddress!, width: masterSize, height: masterSize, rowBytes: bytesPerRow)
}
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let iconSizes: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024)
]

for (name, size) in iconSizes {
    let rowBytes = size * bytesPerPixel
    let resizedBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: rowBytes * size)
    resizedBytes.initialize(repeating: 255, count: rowBytes * size)
    defer { resizedBytes.deallocate() }
    guard let context = CGContext(
        data: resizedBytes,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: rowBytes,
        space: colorSpace,
        bitmapInfo: rgbaInfo.rawValue
    ) else {
        fatalError("Could not resize the (name) app icon image.")
    }
    context.interpolationQuality = .high
    context.draw(masterImage, in: CGRect(x: 0, y: 0, width: size, height: size))
    let image = makeOpaqueImage(bytes: resizedBytes, width: size, height: size, rowBytes: rowBytes)
    let destinationURL = iconsetURL.appending(path: "\(name).png")
    guard let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        fatalError("Could not write \(destinationURL.path).")
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        fatalError("Could not finish writing \(destinationURL.path).")
    }
}
