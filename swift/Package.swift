// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ShortcutsMCP",
    platforms: [
        .macOS(.v15),
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk", from: "0.10.0"),
    ],
    targets: [
        .executableTarget(
            name: "ShortcutsMCP",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
            ]
        ),
    ]
)
