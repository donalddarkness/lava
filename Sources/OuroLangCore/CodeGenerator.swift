import Foundation

/// Protocol for code generators targeting different backends
public protocol CodeGenerator {
    /// Emit code for the given AST of top-level declarations
    func emit(_ decls: [Decl]) throws -> String
}

/// Stub LLVM IR code generator
public class LLVMCodeGenerator: CodeGenerator {
    public init() {}
    public func emit(_ decls: [Decl]) throws -> String {
        // LLVM IR generation is not yet implemented; return informative placeholder
        var header = "; ModuleID = 'module'\n"
        header += "; LLVM IR code generation is not yet implemented\n"
        return header
    }
}

/// Stub JavaScript code generator
public class JSCodeGenerator: CodeGenerator {
    public init() {}
    public func emit(_ decls: [Decl]) throws -> String {
        // Generate intermediate code using ASTPrinter then transform to JS-like syntax
        let printer = ASTPrinter()
        var code = ""
        for decl in decls {
            code += try decl.accept(visitor: printer)
            code += "\n"
        }
        // Simple transform: replace Swift 'func' with JS 'function'
        let jsCode = code.replacingOccurrences(of: "func ", with: "function ")
        return jsCode
    }
}

/// Stub Swift code generator (transpiler)
public class SwiftCodeGenerator: CodeGenerator {
    public init() {}
    public func emit(_ decls: [Decl]) throws -> String {
        // Use ASTPrinter to reconstruct Swift source
        let printer = ASTPrinter()
        var code = ""
        for decl in decls {
            code += try decl.accept(visitor: printer)
            code += "\n"
        }
        return code
    }
}

/// MLIR code generator using AST-based printer
public class MLIRCodeGenerator: CodeGenerator {
    public init() {}

    public func emit(_ decls: [Decl]) throws -> String {
        let printer = MLIRPrinter()
        var code = "module {\n"
        for decl in decls {
            code += try decl.accept(visitor: printer)
            code += "\n"
        }
        code += "}\n"
        return code
    }
} 