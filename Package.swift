// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LingoPrism",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "LingoPrism", targets: ["LingoPrism"])
    ],
    targets: [
        .executableTarget(
            name: "LingoPrism",
            path: "Sources/LingoPrism"
        ),
        .testTarget(
            name: "LingoPrismTests",
            dependencies: ["LingoPrism"]
        )
    ]
)
