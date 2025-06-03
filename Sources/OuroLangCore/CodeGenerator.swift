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
        // TODO: generate LLVM IR
        return ";; LLVM IR code generation not yet implemented"
    }
}

/// Stub JavaScript code generator
public class JSCodeGenerator: CodeGenerator {
    public init() {}
    public func emit(_ decls: [Decl]) throws -> String {
        // TODO: generate JavaScript code
        return "// JavaScript code generation not yet implemented"
    }
}

/// Stub Swift code generator (transpiler)
public class SwiftCodeGenerator: CodeGenerator {
    public init() {}
    public func emit(_ decls: [Decl]) throws -> String {
        // TODO: generate Swift source
        return "// Swift code generation not yet implemented"
    }
} 