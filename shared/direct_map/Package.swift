// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "DirectMapCore", platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "DirectMapCore", targets: ["DirectMapCore"])],
    targets: [
        .target(name: "MapCompression", linkerSettings: [.linkedLibrary("z")]),
        .target(name: "DirectMapCore", dependencies: ["MapCompression"]),
        .testTarget(name: "DirectMapCoreTests", dependencies: ["DirectMapCore"], resources: [.copy("Fixtures")])
    ])
