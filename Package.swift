// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClipboardManager",
    platforms: [.macOS("15.5")],
    targets: [
        .target(
            name: "ClipboardManager",
            path: "ClipboardManager",
            exclude: ["App", "Info.plist", "Assets.xcassets", "ClipboardManager.entitlements"]
        ),
        .testTarget(
            name: "ClipboardManagerTests",
            dependencies: ["ClipboardManager"],
            path: "ClipboardManagerTests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
