// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "foldtint",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "foldtint", targets: ["foldtint"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "FoldtintKit",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .executableTarget(
            name: "foldtint",
            dependencies: ["FoldtintKit"]
        ),
        .testTarget(
            name: "FoldtintTests",
            dependencies: ["FoldtintKit"]
        ),
    ]
)
