// swift-tools-version:6.1
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Lava",
    products: [
        // Core library containing Lava DSL implementation
        .library(
            name: "Lava",
            targets: ["Lava"]
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
        // Combined LSP server for both .ouro (and future .lava) files
        .executable(
            name: "CombinedLSP",
            targets: ["CombinedLSP"]
        ),
        // MLIRSwift library wrapping the MLIR C API
        .library(
            name: "MLIRSwift",
            targets: ["MLIRSwift"]
        ),
    ],
    dependencies: [
        // SwiftSyntax for macros and modern Swift features
        .package(url: "https://github.com/apple/swift-syntax.git", branch: "main"),
        // SwiftLog for unified logging API
        .package(url: "https://github.com/apple/swift-log.git", branch: "main"),
        // DocC plugin for documentation generation
        .package(url: "https://github.com/apple/swift-docc-plugin.git", branch: "main"),
        // Collections for advanced data structures
        .package(url: "https://github.com/apple/swift-collections.git", branch: "main"),
        // Swift Concurrency for modern async/await support
        .package(url: "https://github.com/apple/swift-async-algorithms.git", branch: "main"),
        // Swift System for modern system interfaces
        .package(url: "https://github.com/apple/swift-system.git", branch: "main"),
    ],
    targets: [
        .macro(
            name: "LavaMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("ForwardTrailingClosures"),
                .enableUpcomingFeature("ImplicitOpenExistentials"),
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
        .target(
            name: "Lava",
            dependencies: [
                "LavaMacros",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "SystemPackage", package: "swift-system"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("ForwardTrailingClosures"),
                .enableUpcomingFeature("ImplicitOpenExistentials"),
                .enableUpcomingFeature("StrictConcurrency"),
            ],
            plugins: [
                .plugin(name: "SwiftDocCStub")
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
            ],
            plugins: [
                .plugin(name: "SwiftDocCStub")
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

        // Language Server Protocol implementation for Lava DSL
        .executableTarget(
            name: "LavaLSP",
            dependencies: ["Lava"]
        ),

        // Combined LSP target routing .ouro and .lava documents
        .executableTarget(
            name: "CombinedLSP",
            dependencies: ["OuroLangLSP", "LavaLSP"]
        ),

        // MLIR C API system library target and Swift wrapper
        .systemLibrary(
            name: "CMLIR",
            path: "cmlir"
        ),
        .target(
            name: "MLIRSwift",
            dependencies: ["CMLIR"],
            path: "Sources/MLIRSwift"
        ),
        .executableTarget(
            name: "MyMLIRApp",
            dependencies: ["MLIRSwift"],
            path: "Sources/MyMLIRApp"
        ),

        // Test targets with improved organization
        .testTarget(
            name: "LavaExtensionsTests",
            dependencies: ["Lava"],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
                .enableUpcomingFeature("ConciseMagicFile"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("ForwardTrailingClosures"),
                .enableUpcomingFeature("ImplicitOpenExistentials"),
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
        .testTarget(
            name: "LavaCommandMVCTests",
            dependencies: ["Lava"]
        ),
        .testTarget(
            name: "OuroLangCoreTests",
            dependencies: ["OuroLangCore"]
        ),
        // Unit tests for LavaLanguageServer
        .testTarget(
            name: "LavaLSPTests",
            dependencies: ["LavaLSP"]
        ),
        // Local stub plugin for documentation generation
        .plugin(
            name: "SwiftDocCStub",
            capability: .command(
                intent: .documentationGeneration()
            )
        ),
        // MLIR-based compiler for OuroLang
        .executableTarget(
            name: "OuroLangMLIR",
            dependencies: ["OuroLangCore", "MLIRSwift"],
            path: "Sources/OuroLangMLIR"
        ),
    ])
