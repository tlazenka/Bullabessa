// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Bullabessa",
    products: [
        .library(
            name: "Egg",
            targets: ["Egg"]
        ),
        .library(
            name: "SwiftParsec",
            targets: ["SwiftParsec"]
        ),
        .library(
            name: "Operations",
            targets: ["Operations"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Egg",
            dependencies: ["SwiftParsec"]
        ),
        .testTarget(
            name: "EggTests",
            dependencies: ["Egg"]
        ),
        .target(
            name: "SwiftParsec",
            dependencies: []
        ),
        .testTarget(
            name: "SwiftParsecTests",
            dependencies: ["SwiftParsec"]
        ),
        .target(
            name: "Operations",
            dependencies: []
        ),
        .testTarget(
            name: "OperationsTests",
            dependencies: ["Operations"]
        ),
    ]
)
