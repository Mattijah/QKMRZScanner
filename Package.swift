// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "QKMRZScanner",
    platforms: [.iOS(.v11)],
    products: [
        .library(name: "QKMRZScanner", targets: ["QKMRZScanner"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Mattijah/QKMRZParser.git", .upToNextMajor(from: "2.0.0")),
        .package(url: "https://github.com/SwiftyTesseract/SwiftyTesseract", .upToNextMajor(from: "4.0.1"))
    ],
    targets: [
        .target(
            name: "QKMRZScanner",
            dependencies: ["QKMRZParser", "SwiftyTesseract"],
            resources: [.copy("Resources/tessdata")] // `tessdata` must be located at the root
        )
    ]
)
