// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AdventOfCode2022",
    platforms: [
        .macOS(.v13), .iOS(.v16),
    ],
    products: [
        .library(
            name: "AdventOfCode2022",
            targets: ["AdventOfCode2022"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-parsing.git", from: "0.12.0"),
        .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.0.0"),
        .package(url: "https://github.com/jgriffin/EulerTools.git", from: "0.2.3"),
        .package(url: "https://github.com/apple/swift-collections.git", branch: "release/1.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AdventOfCode2022",
            dependencies: [
                .product(name: "Parsing", package: "swift-parsing"),
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "EulerTools", package: "EulerTools"),
                .product(name: "HeapModule", package: "swift-collections"),
            ]
        ),
        .testTarget(
            name: "AdventOfCode2022Tests",
            dependencies: ["AdventOfCode2022"],
            resources: [.process("resources")]
        ),
    ]
)
