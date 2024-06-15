// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package (
    name: "MetalManager",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_13),
        .macCatalyst(.v13),
        .tvOS(.v12),
        .visionOS(.v1)
    ], products: [
        .library(name: "MetalManager", targets: ["MetalManager"]),
    ], targets: [
        .target(name: "MetalManager"),
        .testTarget(name: "MetalManagerTests", dependencies: ["MetalManager"]),
    ], swiftLanguageVersions: [.v6]
)
