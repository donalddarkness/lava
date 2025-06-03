import Foundation

/// Adapter that connects the actor-based ModernCodeGenerator to the synchronous CodeGenerator protocol
public class ModernCodeGeneratorAdapter: CodeGenerator {
    private let modernGenerator = ModernCodeGenerator()
    
    public init() {}
    
    /// Emit code for the given AST of top-level declarations
    /// This method bridges the synchronous CodeGenerator protocol to the async ModernCodeGenerator
    public func emit(_ decls: [Decl]) throws -> String {
        // Convert decls to AST
        let ast = convertToAST(decls)
        
        // Use TaskGroup to bridge async to sync
        return try Task.detached {
            do {
                let output = try await self.modernGenerator.generateCode(from: ast)
                return output.code
            } catch {
                throw error
            }
        }.result.get()
    }
    
    /// Converts standard declarations to the AST format expected by ModernCodeGenerator
    private func convertToAST(_ decls: [Decl]) -> AST {
        // Convert declarations to ASTNodes
        let nodes = decls.map { decl -> ASTNode in
            return DeclNode(decl: decl)
        }
        
        return AST(nodes: nodes)
    }
}

/// Declaration node that wraps a Decl for the AST
private struct DeclNode: ASTNode {
    let decl: Decl
    
    init(decl: Decl) {
        self.decl = decl
    }
}
