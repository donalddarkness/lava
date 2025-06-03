import CompilerPluginSupport
// swift-tools-version:6.1
import PackageDescription

let package = Package(
    name: "Lava",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6),

    ],
    products: [
        // Core library containing Lava DSL implementation
        .library(
            name: "Lava",
            targets: ["Lava"]
        ),
        // Macros library for DSL features
        .library(
            name: "LavaMacros",
            targets: ["LavaMacros"]
        ),
        // Demo application showcasing Lava DSL features
        .executable(
            name: "LavaDemo",
            targets: ["LavaDemo"]
        ),
        // OuroLang Core libraries
        .library(
            name: "OuroLangCore",
            targets: ["OuroLangCore"]
        ),
        // OuroLang Compiler
        .executable(
            name: "OuroCompiler",
            targets: ["OuroCompiler"]
        ),
        // OuroLang Transpiler
        .executable(
            name: "OuroTranspiler",
            targets: ["OuroTranspiler"]
        ),
        // Language Server Protocol implementation for IDE integration
        .executable(
            name: "OuroLSP",
            targets: ["OuroLangLSP"]
        ),
    ],
    dependencies: [
        // SwiftSyntax for macros
        .package(url: "https://github.com/apple/swift-syntax.git", branch: "main"),
        // SwiftLog for unified logging API
        .package(url: "https://github.com/apple/swift-log.git", branch: "main"),
        // DocC plugin for documentation generation
        .package(url: "https://github.com/apple/swift-docc-plugin.git", branch: "main"),
        // Collections for advanced data structures
        .package(url: "https://github.com/apple/swift-collections.git", branch: "main"),
    ],
    targets: [
        .macro(
            name: "LavaMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "Lava",
            dependencies: [
                "LavaMacros",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Collections", package: "swift-collections"),
            ],
            plugins: [
                .plugin(name: "SwiftDocCPlugin", package: "swift-docc-plugin")
            ]
        ),

        // Demo application for Lava DSL showcase
        .executableTarget(
            name: "LavaDemo",
            dependencies: ["Lava"]
        ),

        // OuroLang Core libraries (lexer, parser, AST, etc.)
        .target(
            name: "OuroLangCore",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Collections", package: "swift-collections"),
            ]
        ),

        // OuroLang Compiler executable
        .executableTarget(
            name: "OuroCompiler",
            dependencies: ["OuroLangCore"]
        ),

        // OuroLang Transpiler executable
        .executableTarget(
            name: "OuroTranspiler",
            dependencies: ["OuroLangCore"]
        ),

        // Language Server Protocol implementation
        .executableTarget(
            name: "OuroLangLSP",
            dependencies: ["OuroLangCore"]
        ),

        // Test targets with improved organization
        .testTarget(
            name: "LavaExtensionsTests",
            dependencies: ["Lava"]
        ),
        .testTarget(
            name: "LavaCommandMVCTests",
            dependencies: ["Lava"]
        ),
        .testTarget(
            name: "OuroLangCoreTests",
            dependencies: ["OuroLangCore"]
        ),
    ])
