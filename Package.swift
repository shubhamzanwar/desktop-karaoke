// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DesktopKaraoke",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "DesktopKaraoke",
            path: "Sources/DesktopKaraoke",
            resources: [
                .copy("Resources/Fonts/Fredoka.ttf"),
                .copy("Resources/Fonts/OFL.txt")
            ]
        ),
        .testTarget(
            name: "DesktopKaraokeTests",
            dependencies: ["DesktopKaraoke"],
            path: "Tests/DesktopKaraokeTests"
        )
    ]
)
