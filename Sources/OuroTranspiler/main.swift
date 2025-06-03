//
//  main.swift
//  OuroTranspiler
//
//  Created by OuroLang Team on TodayDate.
//

import Foundation
import OuroLangCore

let version = "0.1.0"

// MARK: - Command Line Argument Parsing

enum TranspilerError: Error, CustomStringConvertible {
    case noInputFile
    case fileNotFound(String)
    case readError(String)
    case lexError(LexerError)
    case parseError(ParserError)
    case transpileError(String)
    case outputError(String)
    case unsupportedTargetLanguage(String)
    
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
        case .transpileError(let message):
            return "Transpilation error: \(message)"
        case .outputError(let message):
            return "Output error: \(message)"
        case .unsupportedTargetLanguage(let lang):
            return "Unsupported target language: \(lang). Supported targets are: swift, javascript, typescript"
        }
    }
}

struct TranspilerOptions {
    var sourceFile: String = ""
    var outputFile: String?
    var targetLanguage: TargetLanguage = .swift
    var emitSourceMap: Bool = false
    var verbose: Bool = false
    var showHelp: Bool = false
    var showVersion: Bool = false
    var prettify: Bool = true
}

enum TargetLanguage: String {
    case swift = "swift"
    case javascript = "javascript"
    case typescript = "typescript"
    
    var fileExtension: String {
        switch self {
        case .swift: return "swift"
        case .javascript: return "js"
        case .typescript: return "ts"
        }
    }
    
    static func from(string: String) -> TargetLanguage? {
        switch string.lowercased() {
        case "swift": return .swift
        case "js", "javascript": return .javascript
        case "ts", "typescript": return .typescript
        default: return nil
        }
    }
}

func parseArguments() throws -> TranspilerOptions {
    var options = TranspilerOptions()
    var args = CommandLine.arguments.dropFirst()
    
    while !args.isEmpty {
        let arg = args.removeFirst()
        
        switch arg {
        case "-o", "--output":
            guard !args.isEmpty else {
                throw TranspilerError.transpileError("Missing output file after \(arg)")
            }
            options.outputFile = args.removeFirst()
            
        case "-t", "--target":
            guard !args.isEmpty else {
                throw TranspilerError.transpileError("Missing target language after \(arg)")
            }
            let targetString = args.removeFirst()
            if let targetLang = TargetLanguage.from(string: targetString) {
                options.targetLanguage = targetLang
            } else {
                throw TranspilerError.unsupportedTargetLanguage(targetString)
            }
            
        case "--source-map":
            options.emitSourceMap = true
            
        case "--no-pretty":
            options.prettify = false
            
        case "-v", "--verbose":
            options.verbose = true
            
        case "-h", "--help":
            options.showHelp = true
            
        case "--version":
            options.showVersion = true
            
        default:
            if arg.hasPrefix("-") {
                throw TranspilerError.transpileError("Unknown option: \(arg)")
            } else {
                options.sourceFile = arg
            }
        }
    }
    
    if !options.showHelp && !options.showVersion && options.sourceFile.isEmpty {
        throw TranspilerError.noInputFile
    }
    
    return options
}

func printHelp() {
    print("""
    OuroLang Transpiler v\(version)
    
    Usage: ouro-transpile [options] input_file
    
    Options:
      -o, --output <file>     Specify output file (default: based on input file)
      -t, --target <language> Specify target language (default: swift)
                             Supported targets: swift, javascript, typescript
      --source-map           Generate source map file
      --no-pretty            Disable output formatting
      -v, --verbose          Enable verbose output
      -h, --help             Display this help message
      --version              Display version information
    
    """)
}

func printVersion() {
    print("OuroLang Transpiler v\(version)")
}

// MARK: - Transpiler Pipeline

protocol CodeGenerator: ASTVisitor {
    var targetLanguage: TargetLanguage { get }
    func generate(ast: [Decl]) throws -> String
}

// Swift code generator placeholder
class SwiftCodeGenerator: CodeGenerator {
    typealias Result = String
    
    let targetLanguage: TargetLanguage = .swift
    
    func generate(ast: [Decl]) throws -> String {
        let result = try ast.map { try $0.accept(visitor: self) }.joined(separator: "\n\n")
        return """
        // Generated from OuroLang by OuroTranspiler v\(version)
        // Target: Swift
        
        import Foundation
        
        \(result)
        """
    }
    
    // Implement the ASTVisitor protocol methods
    func visitBinaryExpr(_ expr: BinaryExpr) throws -> String {
        let left = try expr.left.accept(visitor: self)
        let right = try expr.right.accept(visitor: self)
        return "(\(left) \(expr.operator.lexeme) \(right))"
    }
    
    func visitGroupingExpr(_ expr: GroupingExpr) throws -> String {
        let expression = try expr.expression.accept(visitor: self)
        return "(\(expression))"
    }
    
    func visitLiteralExpr(_ expr: LiteralExpr) throws -> String {
        guard let value = expr.value else {
            return "nil"
        }
        
        switch expr.tokenType {
        case .string:
            let escaped = (value as? String)?.replacingOccurrences(of: "\"", with: "\\\"") ?? ""
            return "\"\(escaped)\""
        case .integer, .float:
            return String(describing: value)
        case .true:
            return "true"
        case .false:
            return "false"
        case .char:
            if let char = value as? Character {
                return "\"\(char)\""
            }
            return "\"\""
        default:
            return String(describing: value)
        }
    }
    
    func visitUnaryExpr(_ expr: UnaryExpr) throws -> String {
        let right = try expr.right.accept(visitor: self)
        return "\(expr.operator.lexeme)\(right)"
    }
    
    func visitVariableExpr(_ expr: VariableExpr) throws -> String {
        return expr.name.lexeme
    }
    
    func visitCallExpr(_ expr: CallExpr) throws -> String {
        let callee = try expr.callee.accept(visitor: self)
        let arguments = try expr.arguments.map { try $0.accept(visitor: self) }.joined(separator: ", ")
        return "\(callee)(\(arguments))"
    }
    
    func visitGetExpr(_ expr: GetExpr) throws -> String {
        let object = try expr.object.accept(visitor: self)
        return "\(object).\(expr.name.lexeme)"
    }
    
    func visitSetExpr(_ expr: SetExpr) throws -> String {
        let object = try expr.object.accept(visitor: self)
        let value = try expr.value.accept(visitor: self)
        return "\(object).\(expr.name.lexeme) = \(value)"
    }
    
    func visitThisExpr(_ expr: ThisExpr) throws -> String {
        return "self"
    }
    
    func visitSuperExpr(_ expr: SuperExpr) throws -> String {
        return "super.\(expr.method.lexeme)"
    }
    
    func visitArrayExpr(_ expr: ArrayExpr) throws -> String {
        let elements = try expr.elements.map { try $0.accept(visitor: self) }.joined(separator: ", ")
        return "[\(elements)]"
    }
    
    func visitIndexExpr(_ expr: IndexExpr) throws -> String {
        let array = try expr.array.accept(visitor: self)
        let index = try expr.index.accept(visitor: self)
        return "\(array)[\(index)]"
    }
    
    // Statement visitors
    func visitExpressionStmt(_ stmt: ExpressionStmt) throws -> String {
        return try stmt.expression.accept(visitor: self)
    }
    
    func visitBlockStmt(_ stmt: BlockStmt) throws -> String {
        let statements = try stmt.statements.map { try $0.accept(visitor: self) }.joined(separator: "\n")
        return "{\n\(statements)\n}"
    }
    
    func visitIfStmt(_ stmt: IfStmt) throws -> String {
        let condition = try stmt.condition.accept(visitor: self)
        let thenBranch = try stmt.thenBranch.accept(visitor: self)
        var result = "if \(condition) \(thenBranch)"
        
        if let elseBranch = stmt.elseBranch {
            let elseCode = try elseBranch.accept(visitor: self)
            result += " else \(elseCode)"
        }
        
        return result
    }
    
    func visitWhileStmt(_ stmt: WhileStmt) throws -> String {
        let condition = try stmt.condition.accept(visitor: self)
        let body = try stmt.body.accept(visitor: self)
        return "while \(condition) \(body)"
    }
    
    func visitForStmt(_ stmt: ForStmt) throws -> String {
        // Implementing for loops would depend on the format in OuroLang
        // This is a simplified representation
        var result = "for "
        
        if let initializer = stmt.initializer {
            result += try initializer.accept(visitor: self)
        } else {
            result += "; "
        }
        
        if let condition = stmt.condition {
            result += try condition.accept(visitor: self)
        }
        result += "; "
        
        if let increment = stmt.increment {
            result += try increment.accept(visitor: self)
        }
        
        let body = try stmt.body.accept(visitor: self)
        return result + " \(body)"
    }
    
    func visitReturnStmt(_ stmt: ReturnStmt) throws -> String {
        if let value = stmt.value {
            return "return " + (try value.accept(visitor: self))
        }
        return "return"
    }
    
    func visitBreakStmt(_ stmt: BreakStmt) throws -> String {
        return "break"
    }
    
    func visitContinueStmt(_ stmt: ContinueStmt) throws -> String {
        return "continue"
    }
    
    // Declaration visitors
    func visitVarDecl(_ decl: VarDecl) throws -> String {
        var result = "var \(decl.name.lexeme)"
        
        if let typeAnnotation = decl.typeAnnotation {
            result += ": " + (try typeAnnotation.accept(visitor: self))
        }
        
        if let initializer = decl.initializer {
            result += " = " + (try initializer.accept(visitor: self))
        }
        
        return result + ";"
    }
    
    func visitFunctionDecl(_ decl: FunctionDecl) throws -> String {
        let params = decl.params.map { param -> String in
            var result = "\(param.name.lexeme): "
            // Add type and default value handling here
            return result
        }.joined(separator: ", ")
        
        var result = "func \(decl.name.lexeme)(\(params))"
        
        if let returnType = decl.returnType {
            result += " -> " + (try returnType.accept(visitor: self))
        }
        
        let body = try decl.body.accept(visitor: self)
        return result + " \(body)"
    }
    
    func visitClassDecl(_ decl: ClassDecl) throws -> String {
        var result = "class \(decl.name.lexeme)"
        
        if let superclass = decl.superclass {
            result += ": " + (try superclass.accept(visitor: self))
        }
        
        if !decl.interfaces.isEmpty {
            let protocols = try decl.interfaces.map { try $0.accept(visitor: self) }.joined(separator: ", ")
            if decl.superclass != nil {
                result += ", \(protocols)"
            } else {
                result += ": \(protocols)"
            }
        }
        
        result += " {\n"
        
        // Add properties
        for property in decl.properties {
            result += try property.accept(visitor: self) + "\n"
        }
        
        // Add methods
        for method in decl.methods {
            result += try method.accept(visitor: self) + "\n"
        }
        
        result += "}"
        return result
    }
    
    func visitStructDecl(_ decl: StructDecl) throws -> String {
        var result = "struct \(decl.name.lexeme)"
        
        if !decl.interfaces.isEmpty {
            let protocols = try decl.interfaces.map { try $0.accept(visitor: self) }.joined(separator: ", ")
            result += ": \(protocols)"
        }
        
        result += " {\n"
        
        // Add properties
        for property in decl.properties {
            result += try property.accept(visitor: self) + "\n"
        }
        
        // Add methods
        for method in decl.methods {
            result += try method.accept(visitor: self) + "\n"
        }
        
        result += "}"
        return result
    }
    
    func visitEnumDecl(_ decl: EnumDecl) throws -> String {
        var result = "enum \(decl.name.lexeme)"
        
        if let rawType = decl.rawType {
            result += ": " + (try rawType.accept(visitor: self))
        }
        
        result += " {\n"
        
        // Add cases
        for enumCase in decl.cases {
            result += "    case \(enumCase.name.lexeme)"
            if let rawValue = enumCase.rawValue {
                result += " = " + (try rawValue.accept(visitor: self))
            }
            result += "\n"
        }
        
        // Add methods
        for method in decl.methods {
            result += try method.accept(visitor: self) + "\n"
        }
        
        result += "}"
        return result
    }
    
    func visitInterfaceDecl(_ decl: InterfaceDecl) throws -> String {
        var result = "protocol \(decl.name.lexeme)"
        
        if !decl.extendedInterfaces.isEmpty {
            let protocols = try decl.extendedInterfaces.map { try $0.accept(visitor: self) }.joined(separator: ", ")
            result += ": \(protocols)"
        }
        
        result += " {\n"
        
        // Add method signatures
        for method in decl.methods {
            // For protocols, just include the signature without the body
            let params = method.params.map { param -> String in
                return "\(param.name.lexeme): " + "Type" // Add proper type handling
            }.joined(separator: ", ")
            
            var methodResult = "func \(method.name.lexeme)(\(params))"
            
            if let returnType = method.returnType {
                methodResult += " -> " + (try returnType.accept(visitor: self))
            }
            
            result += "    \(methodResult)\n"
        }
        
        result += "}"
        return result
    }
    
    // Type visitors
    func visitNamedType(_ type: NamedType) throws -> String {
        return type.name.lexeme
    }
    
    func visitArrayType(_ type: ArrayType) throws -> String {
        let elementType = try type.elementType.accept(visitor: self)
        return "[\(elementType)]"
    }
    
    func visitGenericType(_ type: GenericType) throws -> String {
        let baseType = try type.baseType.accept(visitor: self)
        let typeArgs = try type.typeArguments.map { try $0.accept(visitor: self) }.joined(separator: ", ")
        return "\(baseType)<\(typeArgs)>"
    }
}

// JavaScript code generator placeholder
class JavaScriptCodeGenerator: CodeGenerator {
    typealias Result = String
    
    let targetLanguage: TargetLanguage = .javascript
    
    func generate(ast: [Decl]) throws -> String {
        // Simplified implementation
        return "// JavaScript generation not fully implemented yet"
    }
    
    // Implement visitor methods (similar to SwiftCodeGenerator)
    // ...
    
    func visitBinaryExpr(_ expr: BinaryExpr) throws -> String { return "" }
    func visitGroupingExpr(_ expr: GroupingExpr) throws -> String { return "" }
    func visitLiteralExpr(_ expr: LiteralExpr) throws -> String { return "" }
    func visitUnaryExpr(_ expr: UnaryExpr) throws -> String { return "" }
    func visitVariableExpr(_ expr: VariableExpr) throws -> String { return "" }
    func visitCallExpr(_ expr: CallExpr) throws -> String { return "" }
    func visitGetExpr(_ expr: GetExpr) throws -> String { return "" }
    func visitSetExpr(_ expr: SetExpr) throws -> String { return "" }
    func visitThisExpr(_ expr: ThisExpr) throws -> String { return "" }
    func visitSuperExpr(_ expr: SuperExpr) throws -> String { return "" }
    func visitArrayExpr(_ expr: ArrayExpr) throws -> String { return "" }
    func visitIndexExpr(_ expr: IndexExpr) throws -> String { return "" }
    func visitExpressionStmt(_ stmt: ExpressionStmt) throws -> String { return "" }
    func visitBlockStmt(_ stmt: BlockStmt) throws -> String { return "" }
    func visitIfStmt(_ stmt: IfStmt) throws -> String { return "" }
    func visitWhileStmt(_ stmt: WhileStmt) throws -> String { return "" }
    func visitForStmt(_ stmt: ForStmt) throws -> String { return "" }
    func visitReturnStmt(_ stmt: ReturnStmt) throws -> String { return "" }
    func visitBreakStmt(_ stmt: BreakStmt) throws -> String { return "" }
    func visitContinueStmt(_ stmt: ContinueStmt) throws -> String { return "" }
    func visitVarDecl(_ decl: VarDecl) throws -> String { return "" }
    func visitFunctionDecl(_ decl: FunctionDecl) throws -> String { return "" }
    func visitClassDecl(_ decl: ClassDecl) throws -> String { return "" }
    func visitStructDecl(_ decl: StructDecl) throws -> String { return "" }
    func visitEnumDecl(_ decl: EnumDecl) throws -> String { return "" }
    func visitInterfaceDecl(_ decl: InterfaceDecl) throws -> String { return "" }
    func visitNamedType(_ type: NamedType) throws -> String { return "" }
    func visitArrayType(_ type: ArrayType) throws -> String { return "" }
    func visitGenericType(_ type: GenericType) throws -> String { return "" }
}

// TypeScript code generator placeholder
class TypeScriptCodeGenerator: CodeGenerator {
    typealias Result = String
    
    let targetLanguage: TargetLanguage = .typescript
    
    func generate(ast: [Decl]) throws -> String {
        // Simplified implementation
        return "// TypeScript generation not fully implemented yet"
    }
    
    // Implement visitor methods (similar to SwiftCodeGenerator)
    // ...
    
    func visitBinaryExpr(_ expr: BinaryExpr) throws -> String { return "" }
    func visitGroupingExpr(_ expr: GroupingExpr) throws -> String { return "" }
    func visitLiteralExpr(_ expr: LiteralExpr) throws -> String { return "" }
    func visitUnaryExpr(_ expr: UnaryExpr) throws -> String { return "" }
    func visitVariableExpr(_ expr: VariableExpr) throws -> String { return "" }
    func visitCallExpr(_ expr: CallExpr) throws -> String { return "" }
    func visitGetExpr(_ expr: GetExpr) throws -> String { return "" }
    func visitSetExpr(_ expr: SetExpr) throws -> String { return "" }
    func visitThisExpr(_ expr: ThisExpr) throws -> String { return "" }
    func visitSuperExpr(_ expr: SuperExpr) throws -> String { return "" }
    func visitArrayExpr(_ expr: ArrayExpr) throws -> String { return "" }
    func visitIndexExpr(_ expr: IndexExpr) throws -> String { return "" }
    func visitExpressionStmt(_ stmt: ExpressionStmt) throws -> String { return "" }
    func visitBlockStmt(_ stmt: BlockStmt) throws -> String { return "" }
    func visitIfStmt(_ stmt: IfStmt) throws -> String { return "" }
    func visitWhileStmt(_ stmt: WhileStmt) throws -> String { return "" }
    func visitForStmt(_ stmt: ForStmt) throws -> String { return "" }
    func visitReturnStmt(_ stmt: ReturnStmt) throws -> String { return "" }
    func visitBreakStmt(_ stmt: BreakStmt) throws -> String { return "" }
    func visitContinueStmt(_ stmt: ContinueStmt) throws -> String { return "" }
    func visitVarDecl(_ decl: VarDecl) throws -> String { return "" }
    func visitFunctionDecl(_ decl: FunctionDecl) throws -> String { return "" }
    func visitClassDecl(_ decl: ClassDecl) throws -> String { return "" }
    func visitStructDecl(_ decl: StructDecl) throws -> String { return "" }
    func visitEnumDecl(_ decl: EnumDecl) throws -> String { return "" }
    func visitInterfaceDecl(_ decl: InterfaceDecl) throws -> String { return "" }
    func visitNamedType(_ type: NamedType) throws -> String { return "" }
    func visitArrayType(_ type: ArrayType) throws -> String { return "" }
    func visitGenericType(_ type: GenericType) throws -> String { return "" }
}

func createCodeGenerator(for language: TargetLanguage) -> CodeGenerator {
    switch language {
    case .swift:
        return SwiftCodeGenerator()
    case .javascript:
        return JavaScriptCodeGenerator()
    case .typescript:
        return TypeScriptCodeGenerator()
    }
}

func transpile(options: TranspilerOptions) throws {
    // Set up verbose logging if requested
    if options.verbose {
        print("Transpiling \(options.sourceFile) to \(options.targetLanguage.rawValue)")
    }
    
    // Read the source file
    let sourceURL = URL(fileURLWithPath: options.sourceFile)
    guard FileManager.default.fileExists(atPath: sourceURL.path) else {
        throw TranspilerError.fileNotFound(options.sourceFile)
    }
    
    let sourceCode: String
    do {
        sourceCode = try String(contentsOf: sourceURL, encoding: .utf8)
    } catch {
        throw TranspilerError.readError(error.localizedDescription)
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
        throw TranspilerError.lexError(error)
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
        throw TranspilerError.parseError(error)
    }
    
    // Generate code for the target language
    let generator = createCodeGenerator(for: options.targetLanguage)
    let generatedCode: String
    do {
        generatedCode = try generator.generate(ast: ast)
        if options.verbose {
            print("Code generation complete")
        }
    } catch {
        throw TranspilerError.transpileError("Code generation failed: \(error)")
    }
    
    // Write the output
    let outputPath = options.outputFile ?? sourceURL.deletingPathExtension().appendingPathExtension(options.targetLanguage.fileExtension).path
    
    do {
        try generatedCode.write(toFile: outputPath, atomically: true, encoding: .utf8)
        if options.verbose {
            print("Output written to: \(outputPath)")
        }
    } catch {
        throw TranspilerError.outputError("Failed to write output: \(error)")
    }
    
    // Generate source map if requested
    if options.emitSourceMap {
        if options.verbose {
            print("Source map generation not yet implemented")
        }
    }
    
    print("Transpilation completed successfully")
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
    
    try transpile(options: options)
} catch {
    print("\(error)")
    exit(1)
}