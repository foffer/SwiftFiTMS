// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftFiTMS",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftFiTMS",
            targets: ["SwiftFiTMS"]),
    ],
    dependencies: [.package(path: "../BluetoothMessageProtocol")],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftFiTMS",
            dependencies: ["BluetoothMessageProtocol"],
            resources: [.process("Resources/indoor_bike_sample_data.json")]
                
        ),
        .testTarget(
            name: "SwiftFiTMSTests",
            dependencies: ["SwiftFiTMS"]),
    ]
)
