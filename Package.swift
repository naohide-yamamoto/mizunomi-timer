// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "mizunomi-timer",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(name: "MizunomiTimer", targets: ["MizunomiTimer"])
    ],
    targets: [
        .executableTarget(
            name: "MizunomiTimer",
            path: "Sources/MizunomiTimer",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ServiceManagement")
            ]
        )
    ]
)
