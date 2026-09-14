// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "OrbitLab",
    platforms: [.iOS("15.0")],
    products: [
        .library(name: "OrbitLab", targets: ["OrbitLab"])
    ],
    targets: [
        .target(
            name: "OrbitLab",
            path: ".",
            exclude: ["Tests", "UITests", "Package.swift"],
            resources: [],
            swiftSettings: [.unsafeFlags(["-parse-as-library"])]
        ),
        .testTarget(
            name: "OrbitLabTests",
            dependencies: ["OrbitLab"],
            path: "Tests"
        ),
        .testTarget(
            name: "OrbitLabUITests",
            dependencies: ["OrbitLab"],
            path: "UITests"
        )
    ]
)
