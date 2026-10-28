// swift-tools-version: 6.0
import PackageDescription

// PixSEO builds with Command Line Tools only (no Xcode).
// The Finder extension is compiled by scripts/build-app.sh with swiftc, because it needs the
// `_NSExtensionMain` entry point and app-extension-safe flags that SwiftPM executables don't support.
// Run tests with scripts/test.sh (it adds the swift-testing paths CLT needs).
let package = Package(
    name: "PixSEO",
    platforms: [.macOS(.v14)],
    dependencies: [
        // ImageIO can read WebP but not write it; libwebp (BSD) does the encoding.
        .package(url: "https://github.com/SDWebImage/libwebp-Xcode", exact: "1.6.0"),
    ],
    targets: [
        // Shared by the app and the Finder extension: request encoding, file types, size presets.
        // Keep it dependency-free and app-extension-safe.
        .target(name: "PixSEOShared"),
        // Image engine, encoders and SEO naming. No UI, so everything here is unit-tested.
        .target(
            name: "PixSEOCore",
            dependencies: ["PixSEOShared", .product(name: "libwebp", package: "libwebp-Xcode")]
        ),
        .executableTarget(name: "PixSEOApp", dependencies: ["PixSEOShared", "PixSEOCore"]),
        .testTarget(name: "PixSEOSharedTests", dependencies: ["PixSEOShared"]),
        .testTarget(name: "PixSEOCoreTests", dependencies: ["PixSEOCore"]),
    ]
)
