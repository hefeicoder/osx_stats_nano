// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "OSXStatsNano",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "OSXStatsNano",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("CoreFoundation")
            ]
        ),
        .testTarget(
            name: "MonitorTests",
            dependencies: ["OSXStatsNano"],
            path: "Tests/MonitorTests"
        )
    ]
)
