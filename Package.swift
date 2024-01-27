// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MetalManager",
    products: [
        .library(name: "MetalManager", targets: ["MetalManager"]),
    ], targets: [
        .target(name: "MetalManager"),
        .testTarget(name: "MetalManagerTests", dependencies: ["MetalManager"]),
    ]
)
