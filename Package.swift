// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "JLI18n",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "JLI18n", targets: ["JLI18n"]),
        .library(name: "JLI18nSwiftUI", targets: ["JLI18nSwiftUI"]),
        .library(name: "JLI18nUIKit", targets: ["JLI18nUIKit"]),
        .library(name: "JLI18nAppKit", targets: ["JLI18nAppKit"]),
        .library(name: "JLI18nTesting", targets: ["JLI18nTesting"])
    ],
    targets: [
        .target(
            name: "JLI18n",
            resources: [.process("Resources")]
        ),
        .target(
            name: "JLI18nSwiftUI",
            dependencies: ["JLI18n"]
        ),
        .target(
            name: "JLI18nUIKit",
            dependencies: ["JLI18n"]
        ),
        .target(
            name: "JLI18nAppKit",
            dependencies: ["JLI18n"]
        ),
        .target(
            name: "JLI18nTesting",
            dependencies: ["JLI18n"]
        ),
        .testTarget(
            name: "JLI18nTests",
            dependencies: ["JLI18n", "JLI18nTesting"],
            resources: [.process("Fixtures")]
        ),
        .testTarget(
            name: "JLI18nSwiftUITests",
            dependencies: ["JLI18nSwiftUI", "JLI18nTesting"]
        ),
        .testTarget(
            name: "JLI18nUIKitTests",
            dependencies: ["JLI18nUIKit", "JLI18nTesting"]
        ),
        .testTarget(
            name: "JLI18nAppKitTests",
            dependencies: ["JLI18nAppKit", "JLI18nTesting"]
        ),
        .testTarget(
            name: "JLI18nTestingTests",
            dependencies: ["JLI18nTesting"]
        )
    ]
)
