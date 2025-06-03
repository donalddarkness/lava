//
//  main.swift
//  OuroCompiler
//
//  Created by OuroLang Team on TodayDate.
//

import Foundation
import OuroLangCore

let version = "0.1.0"

// MARK: - Command Line Argument Parsing

enum CompilerError: Error, CustomStringConvertible {
    case noInputFile
    case fileNotFound(String)
    case readError(String)
    case lexError(LexerError)
    case parseError(ParserError)
    case compileError(String)
    case outputError(String)
    
    var description: String {
        switch self {
        case .noInputFile:
            return "Error: No input file specified"
        case .fileNotFound(let path):
            return "Error: File not found: \(path)"
        case .readError(let message):
            return "Error reading file: \(message)"
        case .lexError(let error):
            return "Lexical error: \(error)"
        case .parseError(let error):
            return "Parse error: \(error)"
        case .compileError(let message):
            return "Compilation error: \(message)"
        case .outputError(let message):
            return "Output error: \(message)"
        }
    }
}

struct CompilerOptions {
    var sourceFile: String = ""
    var outputFile: String?
    var target: String = "llvm"
    var optimizationLevel: Int = 0
    var verbose: Bool = false
    var showHelp: Bool = false
    var showVersion: Bool = false
}

func parseArguments() throws -> CompilerOptions {
    var options = CompilerOptions()
    var args = CommandLine.arguments.dropFirst()
    
    while !args.isEmpty {
        let arg = args.removeFirst()
        
        switch arg {
        case "-o", "--output":
            guard !args.isEmpty else {
                throw CompilerError.compileError("Missing output file after \(arg)")
            }
            options.outputFile = args.removeFirst()
            
        case "-t", "--target":
            guard !args.isEmpty else {
                throw CompilerError.compileError("Missing target after \(arg)")
            }
            options.target = args.removeFirst()
            
        case "-O0", "-O1", "-O2", "-O3":
            options.optimizationLevel = Int(arg.dropFirst(2))!
            
        case "-v", "--verbose":
            options.verbose = true
            
        case "-h", "--help":
            options.showHelp = true
            
        case "--version":
            options.showVersion = true
            
        default:
            if arg.hasPrefix("-") {
                throw CompilerError.compileError("Unknown option: \(arg)")
            } else {
                options.sourceFile = arg
            }
        }
    }
    
    if !options.showHelp && !options.showVersion && options.sourceFile.isEmpty {
        throw CompilerError.noInputFile
    }
    
    return options
}

func printHelp() {
    print("""
    OuroLang Compiler v\(version)
    
    Usage: ouro [options] input_file
    
    Options:
      -o, --output <file>    Specify output file (default: based on input file)
      -t, --target <target>  Specify compilation target (default: llvm)
                            Supported targets: llvm, js, swift
      -O0, -O1, -O2, -O3    Set optimization level (default: -O0)
      -v, --verbose         Enable verbose output
      -h, --help            Display this help message
      --version             Display version information
    
    """)
}

func printVersion() {
    print("OuroLang Compiler v\(version)")
}

// MARK: - Compiler Pipeline

func compile(options: CompilerOptions) throws {
    // Set up verbose logging if requested
    if options.verbose {
        print("Compiling \(options.sourceFile) with target \(options.target), optimization level \(options.optimizationLevel)")
    }
    
    // Read the source file
    let sourceURL = URL(fileURLWithPath: options.sourceFile)
    guard FileManager.default.fileExists(atPath: sourceURL.path) else {
        throw CompilerError.fileNotFound(options.sourceFile)
    }
    
    let sourceCode: String
    do {
        sourceCode = try String(contentsOf: sourceURL, encoding: .utf8)
    } catch {
        throw CompilerError.readError(error.localizedDescription)
    }
    
    // Lex the source into tokens
    let lexer = Lexer(source: sourceCode)
    let tokens: [Token]
    do {
        tokens = try lexer.scanTokens()
        if options.verbose {
            print("Lexical analysis complete: \(tokens.count) tokens generated")
        }
    } catch let error as LexerError {
        throw CompilerError.lexError(error)
    }
    
    // Parse the tokens into an AST
    let parser = Parser(tokens: tokens)
    let ast: [Decl]
    do {
        ast = try parser.parse()
        if options.verbose {
            print("Parsing complete: \(ast.count) top-level declarations found")
        }
    } catch let error as ParserError {
        throw CompilerError.parseError(error)
    }
    
    // Semantic analysis (type checking and symbol resolution)
    if options.verbose {
        print("Starting semantic analysis...")
    }
    do {
        let analyzer = SemanticAnalyzer()
        try analyzer.analyze(ast)
        if options.verbose {
            print("Semantic analysis complete")
        }
    } catch let error as SymbolError {
        throw CompilerError.compileError(error.description)
    }

    // Code generation based on target
    if options.verbose {
        print("Starting code generation for target '", options.target, "'")
    }
    let generator: CodeGenerator
    switch options.target.lowercased() {
    case "llvm":
        generator = LLVMCodeGenerator()
    case "js":
        generator = JSCodeGenerator()
    case "swift":
        generator = SwiftCodeGenerator()
    default:
        throw CompilerError.compileError("Unsupported target: \(options.target)")
    }
    let outputCode: String
    do {
        outputCode = try generator.emit(ast)
    } catch {
        throw CompilerError.compileError("Code generation failed: \(error)")
    }

    // Write the output to file
    let outputPath = options.outputFile ?? sourceURL.deletingPathExtension().appendingPathExtension(targetExtension(for: options.target)).path
    do {
        try outputCode.write(to: URL(fileURLWithPath: outputPath), atomically: true, encoding: .utf8)
        if options.verbose {
            print("Output written to: \(outputPath)")
        }
    } catch {
        throw CompilerError.outputError(error.localizedDescription)
    }

    print("Compilation completed successfully.")
}

func targetExtension(for target: String) -> String {
    switch target.lowercased() {
    case "llvm": return "bc"
    case "js": return "js"
    case "swift": return "swift"
    default: return "out"
    }
}

// MARK: - Main Entry Point

do {
    let options = try parseArguments()
    
    if options.showVersion {
        printVersion()
        exit(0)
    }
    
    if options.showHelp {
        printHelp()
        exit(0)
    }
    
    try compile(options: options)
} catch {
    print("\(error)")
    exit(1)
}

// Example of using strict concurrency in compiler
public actor Compiler {
    public func compile(source: String) async throws -> CompiledOutput {
        // Use actors to ensure thread-safe compilation
        let ast = try await parse(source)
        return try await generateCode(from: ast)
    }
}