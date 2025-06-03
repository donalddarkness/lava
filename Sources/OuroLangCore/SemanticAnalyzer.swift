import Foundation

/// SemanticAnalyzer performs symbol resolution and basic type checking on the AST
public class SemanticAnalyzer {
    private let symbols = SymbolTable()

    public init() {}

    /// Analyze a list of top-level declarations
    public func analyze(_ decls: [Decl]) throws {
        // First pass: define all types and global functions/variables
        for decl in decls {
            switch decl {
            case let classDecl as ClassDecl:
                let typeDef = TypeDefinition(
                    name: classDecl.name.text,
                    isInterface: false,
                    isAbstract: false,
                    isSealed: false,
                    isPrimitive: false,
                    line: classDecl.line,
                    column: classDecl.column
                )
                try symbols.define(typeDef)
            case let structDecl as StructDecl:
                let typeDef = TypeDefinition(
                    name: structDecl.name.text,
                    isInterface: false,
                    isAbstract: false,
                    isSealed: false,
                    isPrimitive: false,
                    line: structDecl.line,
                    column: structDecl.column
                )
                try symbols.define(typeDef)
            case let enumDecl as EnumDecl:
                let typeDef = TypeDefinition(
                    name: enumDecl.name.text,
                    isInterface: false,
                    isAbstract: false,
                    isSealed: false,
                    isPrimitive: false,
                    line: enumDecl.line,
                    column: enumDecl.column
                )
                try symbols.define(typeDef)
            case let interfaceDecl as InterfaceDecl:
                let typeDef = TypeDefinition(
                    name: interfaceDecl.name.text,
                    isInterface: true,
                    isAbstract: true,
                    isSealed: false,
                    isPrimitive: false,
                    line: interfaceDecl.line,
                    column: interfaceDecl.column
                )
                try symbols.define(typeDef)
            case let funcDecl as FunctionDecl:
                // define global function as method symbol in global scope
                let returnType = funcDecl.returnType.flatMap { symbols.resolveType($0.name.text) }
                let params: [ParameterSymbol] = funcDecl.params.map {
                    let t = symbols.resolveType($0.type.name.text)!
                    return ParameterSymbol(name: $0.name.text, type: t, hasDefaultValue: $0.defaultValue != nil, line: funcDecl.line, column: funcDecl.column)
                }
                let methodSym = MethodSymbol(
                    name: funcDecl.name.text,
                    returnType: returnType,
                    parameters: params,
                    isStatic: false,
                    isAbstract: false,
                    isOverride: false,
                    isConstructor: false,
                    isAsync: false,
                    line: funcDecl.line,
                    column: funcDecl.column
                )
                try symbols.define(methodSym)
            case let varDecl as VarDecl:
                let varType = varDecl.typeAnnotation.flatMap { symbols.resolveType($0.name.text) } ?? symbols.getPrimitiveType("Void")!
                let varSym = VariableSymbol(
                    name: varDecl.name.text,
                    type: varType,
                    isMutable: true,
                    line: varDecl.line,
                    column: varDecl.column
                )
                try symbols.define(varSym)
            default:
                break
            }
        }
        // TODO: deeper analysis (scope, usage, type consistency)
    }
} 