// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyESBuild",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftyESBuild",
            targets: ["SwiftyESBuild"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-tools-support-core.git", .upToNextMinor(from: "0.5.2")),
        .package(url: "https://github.com/apple/swift-docc-plugin", .upToNextMinor(from: "1.3.0")),
        .package(url: "https://github.com/apple/swift-log.git", .upToNextMinor(from: "1.5.3")),
        .package(url: "https://github.com/swift-server/async-http-client.git", .upToNextMinor(from: "1.18.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftyESBuild",
            dependencies: [
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ]
        ),
        .testTarget(
            name: "SwiftyESBuildTests",
            dependencies: ["SwiftyESBuild", .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core")]
        ),
    ]
)
