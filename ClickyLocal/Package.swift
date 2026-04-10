// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClickyLocal",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "ClickyLocal",
            path: ".",
            exclude: ["Resources/Info.plist", "Resources/ClickyLocal.entitlements", "Package.swift"],
            resources: [
                .process("Resources/Assets.xcassets")
            ]
        )
    ]
)
