// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SoftPLC",
    defaultLocalization: "en",
    platforms: [.macOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SoftPLC",
            targets: ["SoftPLC"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
		.package(url: "https://github.com/TheMisfit68/Neumorphic.git", branch: "master"),
        .package(url: "https://github.com/TheMisfit68/ModbusDriver.git", branch: "master"),
		.package(url: "https://github.com/TheMisfit68/JVSwiftCore.git", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SoftPLC",
            dependencies: [
				"Neumorphic",
                "ModbusDriver",
				"JVSwiftCore",
            ]
        )
    ]
)

