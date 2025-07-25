// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JuiceBox",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "JuiceBox",
            targets: ["JuiceBox"]
        ),
    ],
    dependencies: [
        // Add any external dependencies here
    ],
    targets: [
        .target(
            name: "JuiceBox",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "JuiceBoxTests",
            dependencies: ["JuiceBox"],
            path: "Tests"
        ),
    ]
)