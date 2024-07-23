// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package (
    name: "MetalManager",
    platforms: [
        .iOS(.v14),
        .macOS(.v10_15),
        .macCatalyst(.v14),
        .tvOS(.v14),
        .visionOS(.v1)
    ], products: [
        .library(name: "MetalManager", targets: ["MetalManager"]),
    ], targets: [
        .target(name: "MetalManager"),
        .testTarget(name: "MetalManagerTests", dependencies: ["MetalManager"]),
    ], swiftLanguageVersions: [.v6]
)
