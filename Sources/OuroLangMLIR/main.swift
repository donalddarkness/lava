import Foundation
import OuroLangCore
import MLIRSwift

// A simple MLIR-based compiler CLI for OuroLang
// Usage: oro-mlir <input.ouro> [--verbose]

struct Options {
    var sourceFile: String? = nil
    var verbose: Bool = false
}

func parseArgs() -> Options {
    var opts = Options()
    var args = CommandLine.arguments.dropFirst()
    while let arg = args.first {
        args = args.dropFirst()
        if arg == "--verbose" {
            opts.verbose = true
        } else if opts.sourceFile == nil {
            opts.sourceFile = arg
        }
    }
    return opts
}

func main() throws {
    let opts = parseArgs()

    if let sourceFile = opts.sourceFile {
        // Existing file processing logic
        let src = try String(contentsOfFile: sourceFile, encoding: .utf8)
        if opts.verbose { print("Parsing source...", src) }
        let tokens = try Lexer(source: src).scanTokens()
        let ast = try Parser(tokens: tokens).parse()

        if opts.verbose { print("Generating MLIR text...") }
        let mlirText = try MLIRCodeGenerator().emit(ast)
        if opts.verbose { print(mlirText) }

        // Use MLIR C API to parse and print module
        let ctx = makeContext()
        let module = parseModule(mlirText, context: ctx)
        printModule(module)
    } else {
        // REPL mode
        print("OuroLang MLIR REPL. Type \'exit\' to quit.")
        let ctx = makeContext()

        while true {
            print("> ", terminator: "")
            guard let line = readLine() else { continue }
            if line == "exit" { break }
            if line.isEmpty { continue }

            do {
                let tokens = try Lexer(source: line).scanTokens()
                let ast = try Parser(tokens: tokens).parse()
                let mlirText = try MLIRCodeGenerator().emit(ast)
                let module = parseModule(mlirText, context: ctx)
                printModule(module)
            } catch let error as LexerError {
                print("Lexer error: \(error)")
            } catch let error as ParserError {
                print("Parser error: \(error)")
            } catch {
                print("Error: \(error)")
            }
        }
    }
}

// Run
try main() 