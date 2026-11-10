// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LingoPrism",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "LingoPrism", targets: ["LingoPrism"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.10.0")
    ],
    targets: [
        .executableTarget(
            name: "LingoPrism",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/LingoPrism"
        ),
        .testTarget(
            name: "LingoPrismTests",
            dependencies: ["LingoPrism"]
        )
    ]
)
