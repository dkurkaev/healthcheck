// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HealthcheckCore",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "HealthcheckCore", targets: ["HealthcheckCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/TheAcharya/XLKit.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "HealthcheckCore",
            dependencies: [
                .product(name: "XLKit", package: "XLKit")
            ],
            path: "Sources/HealthcheckCore"
        ),
    ]
)
