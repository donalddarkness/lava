//
//  AST.swift
//  OuroLangCore
//
//  Created by YourName on TodayDate.
//

import Foundation

/// Protocol defining the basic structure of all AST nodes
public protocol ASTNode {
    /// Visitor pattern implementation
    func accept<V: ASTVisitor>(visitor: V) throws -> V.Result
    
    /// Line number where this node starts in the source code
    var line: Int { get }
    
    /// Column number where this node starts in the source code
    var column: Int { get }
}

/// Base class for all expression nodes in the AST
public class Expr: ASTNode {
    public let line: Int
    public let column: Int
    
    public init(line: Int, column: Int) {
        self.line = line
        self.column = column
    }
    
    public func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        fatalError("accept(visitor:) must be implemented by subclasses")
    }
}

/// Base class for all statement nodes in the AST
public class Stmt: ASTNode {
    public let line: Int
    public let column: Int
    
    public init(line: Int, column: Int) {
        self.line = line
        self.column = column
    }
    
    public func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        fatalError("accept(visitor:) must be implemented by subclasses")
    }
}

/// Base class for all type nodes in the AST
public class TypeNode: ASTNode {
    public let line: Int
    public let column: Int
    
    public init(line: Int, column: Int) {
        self.line = line
        self.column = column
    }
    
    public func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        fatalError("accept(visitor:) must be implemented by subclasses")
    }
}

/// Base class for all declaration nodes in the AST
public class Decl: ASTNode {
    public let line: Int
    public let column: Int
    
    public init(line: Int, column: Int) {
        self.line = line
        self.column = column
    }
    
    public func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        fatalError("accept(visitor:) must be implemented by subclasses")
    }
}

/// Visitor protocol for traversing the AST
public protocol ASTVisitor {
    associatedtype Result
    
    // Expressions
    func visitBinaryExpr(_ expr: BinaryExpr) throws -> Result
    func visitGroupingExpr(_ expr: GroupingExpr) throws -> Result
    func visitLiteralExpr(_ expr: LiteralExpr) throws -> Result
    func visitUnaryExpr(_ expr: UnaryExpr) throws -> Result
    func visitVariableExpr(_ expr: VariableExpr) throws -> Result
    func visitCallExpr(_ expr: CallExpr) throws -> Result
    func visitGetExpr(_ expr: GetExpr) throws -> Result
    func visitSetExpr(_ expr: SetExpr) throws -> Result
    func visitThisExpr(_ expr: ThisExpr) throws -> Result
    func visitSuperExpr(_ expr: SuperExpr) throws -> Result
    func visitArrayExpr(_ expr: ArrayExpr) throws -> Result
    func visitIndexExpr(_ expr: IndexExpr) throws -> Result
    // New expression visit methods for additional AST node types
    func visitAssignExpr(_ expr: AssignExpr) throws -> Result
    func visitSetIndexExpr(_ expr: SetIndexExpr) throws -> Result
    func visitDictionaryExpr(_ expr: DictionaryExpr) throws -> Result
    func visitSetExpr(_ expr: SetExpr) throws -> Result
    func visitLambdaExpr(_ expr: LambdaExpr) throws -> Result
    func visitMethodReferenceExpr(_ expr: MethodReferenceExpr) throws -> Result
    
    // Statements
    func visitExpressionStmt(_ stmt: ExpressionStmt) throws -> Result
    func visitBlockStmt(_ stmt: BlockStmt) throws -> Result
    func visitIfStmt(_ stmt: IfStmt) throws -> Result
    func visitWhileStmt(_ stmt: WhileStmt) throws -> Result
    func visitForStmt(_ stmt: ForStmt) throws -> Result
    func visitReturnStmt(_ stmt: ReturnStmt) throws -> Result
    func visitBreakStmt(_ stmt: BreakStmt) throws -> Result
    func visitContinueStmt(_ stmt: ContinueStmt) throws -> Result
    func visitYieldStmt(_ stmt: YieldStmt) throws -> Result
    func visitDeferStmt(_ stmt: DeferStmt) throws -> Result
    
    // Declarations
    func visitVarDecl(_ decl: VarDecl) throws -> Result
    func visitFunctionDecl(_ decl: FunctionDecl) throws -> Result
    func visitClassDecl(_ decl: ClassDecl) throws -> Result
    func visitStructDecl(_ decl: StructDecl) throws -> Result
    func visitEnumDecl(_ decl: EnumDecl) throws -> Result
    func visitInterfaceDecl(_ decl: InterfaceDecl) throws -> Result
    
    // Types
    func visitNamedType(_ type: NamedType) throws -> Result
    func visitArrayType(_ type: ArrayType) throws -> Result
    func visitGenericType(_ type: GenericType) throws -> Result
    // New type visit methods for additional TypeNode types
    func visitDictionaryType(_ type: DictionaryType) throws -> Result
    func visitSetType(_ type: SetType) throws -> Result
    func visitTupleType(_ type: TupleType) throws -> Result
    func visitFunctionType(_ type: FunctionType) throws -> Result
}

// MARK: - Expression Node Types

/// Binary expression (e.g., a + b, x > y)
public class BinaryExpr: Expr {
    public let left: Expr
    public let op: Token
    public let right: Expr
    
    public init(left: Expr, op: Token, right: Expr, line: Int, column: Int) {
        self.left = left
        self.op = op
        self.right = right
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitBinaryExpr(self)
    }
}

/// Grouping expression (e.g., (a + b))
public class GroupingExpr: Expr {
    public let expression: Expr
    
    public init(expression: Expr, line: Int, column: Int) {
        self.expression = expression
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitGroupingExpr(self)
    }
}

/// Literal expression (e.g., 123, "hello", true)
public class LiteralExpr: Expr {
    public let value: Any?
    public let tokenType: TokenType
    
    public init(value: Any?, tokenType: TokenType, line: Int, column: Int) {
        self.value = value
        self.tokenType = tokenType
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitLiteralExpr(self)
    }
}

/// Unary expression (e.g., !isValid, -count)
public class UnaryExpr: Expr {
    public let op: Token
    public let right: Expr
    
    public init(op: Token, right: Expr, line: Int, column: Int) {
        self.op = op
        self.right = right
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitUnaryExpr(self)
    }
}

/// Variable reference expression (e.g., count, name)
public class VariableExpr: Expr {
    public let name: Token
    
    public init(name: Token, line: Int, column: Int) {
        self.name = name
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitVariableExpr(self)
    }
}

/// Function/method call expression (e.g., calculate(x, y))
public class CallExpr: Expr {
    public let callee: Expr
    public let paren: Token
    public let arguments: [Expr]
    
    public init(callee: Expr, paren: Token, arguments: [Expr], line: Int, column: Int) {
        self.callee = callee
        self.paren = paren
        self.arguments = arguments
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitCallExpr(self)
    }
}

/// Property access expression (e.g., person.name)
public class GetExpr: Expr {
    public let object: Expr
    public let name: Token
    
    public init(object: Expr, name: Token, line: Int, column: Int) {
        self.object = object
        self.name = name
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitGetExpr(self)
    }
}

/// Property assignment expression (e.g., person.name = "John")
public class SetExpr: Expr {
    public let object: Expr
    public let name: Token
    public let value: Expr
    
    public init(object: Expr, name: Token, value: Expr, line: Int, column: Int) {
        self.object = object
        self.name = name
        self.value = value
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitSetExpr(self)
    }
}

/// "this" or "self" reference expression
public class ThisExpr: Expr {
    public let keyword: Token
    
    public init(keyword: Token, line: Int, column: Int) {
        self.keyword = keyword
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitThisExpr(self)
    }
}

/// "super" reference expression (e.g., super.method())
public class SuperExpr: Expr {
    public let keyword: Token
    public let method: Token
    
    public init(keyword: Token, method: Token, line: Int, column: Int) {
        self.keyword = keyword
        self.method = method
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitSuperExpr(self)
    }
}

/// Array literal expression (e.g., [1, 2, 3])
public class ArrayExpr: Expr {
    public let elements: [Expr]
    
    public init(elements: [Expr], line: Int, column: Int) {
        self.elements = elements
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitArrayExpr(self)
    }
}

/// Array indexing expression (e.g., array[0])
public class IndexExpr: Expr {
    public let array: Expr
    public let index: Expr
    
    public init(array: Expr, index: Expr, line: Int, column: Int) {
        self.array = array
        self.index = index
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitIndexExpr(self)
    }
}

// MARK: - Statement Node Types

/// Expression statement (e.g., print("hello");)
public class ExpressionStmt: Stmt {
    public let expression: Expr
    
    public init(expression: Expr, line: Int, column: Int) {
        self.expression = expression
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitExpressionStmt(self)
    }
}

/// Block statement (e.g., { statement1; statement2; })
public class BlockStmt: Stmt {
    public let statements: [Stmt]
    
    public init(statements: [Stmt], line: Int, column: Int) {
        self.statements = statements
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitBlockStmt(self)
    }
}

/// If statement
public class IfStmt: Stmt {
    public let condition: Expr
    public let thenBranch: Stmt
    public let elseBranch: Stmt?
    
    public init(condition: Expr, thenBranch: Stmt, elseBranch: Stmt?, line: Int, column: Int) {
        self.condition = condition
        self.thenBranch = thenBranch
        self.elseBranch = elseBranch
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitIfStmt(self)
    }
}

/// While statement
public class WhileStmt: Stmt {
    public let condition: Expr
    public let body: Stmt
    
    public init(condition: Expr, body: Stmt, line: Int, column: Int) {
        self.condition = condition
        self.body = body
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitWhileStmt(self)
    }
}

/// For statement
public class ForStmt: Stmt {
    public let initializer: Stmt?
    public let condition: Expr?
    public let increment: Expr?
    public let body: Stmt
    
    public init(initializer: Stmt?, condition: Expr?, increment: Expr?, body: Stmt, line: Int, column: Int) {
        self.initializer = initializer
        self.condition = condition
        self.increment = increment
        self.body = body
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitForStmt(self)
    }
}

/// Return statement
public class ReturnStmt: Stmt {
    public let keyword: Token
    public let value: Expr?
    
    public init(keyword: Token, value: Expr?, line: Int, column: Int) {
        self.keyword = keyword
        self.value = value
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitReturnStmt(self)
    }
}

/// Break statement
public class BreakStmt: Stmt {
    public let keyword: Token
    
    public init(keyword: Token, line: Int, column: Int) {
        self.keyword = keyword
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitBreakStmt(self)
    }
}

/// Continue statement
public class ContinueStmt: Stmt {
    public let keyword: Token
    
    public init(keyword: Token, line: Int, column: Int) {
        self.keyword = keyword
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitContinueStmt(self)
    }
}

/// Yield statement
public class YieldStmt: Stmt {
    public let keyword: Token
    public let value: Expr?
    
    public init(keyword: Token, value: Expr?, line: Int, column: Int) {
        self.keyword = keyword
        self.value = value
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitYieldStmt(self)
    }
}

/// Defer statement
public class DeferStmt: Stmt {
    public let keyword: Token
    public let body: BlockStmt
    
    public init(keyword: Token, body: BlockStmt, line: Int, column: Int) {
        self.keyword = keyword
        self.body = body
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitDeferStmt(self)
    }
}

// MARK: - Declaration Node Types

/// Variable declaration (e.g., var x = 10;)
public class VarDecl: Decl {
    public let name: Token
    public let typeAnnotation: TypeNode?
    public let initializer: Expr?
    
    public init(name: Token, typeAnnotation: TypeNode?, initializer: Expr?, line: Int, column: Int) {
        self.name = name
        self.typeAnnotation = typeAnnotation
        self.initializer = initializer
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitVarDecl(self)
    }
}

/// Parameter in a function declaration
public struct Parameter {
    public let name: Token
    public let type: TypeNode
    public let defaultValue: Expr?
    
    public init(name: Token, type: TypeNode, defaultValue: Expr? = nil) {
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
    }
}

/// Function declaration
public class FunctionDecl: Decl {
    public let name: Token
    public let params: [Parameter]
    public let returnType: TypeNode?
    public let body: BlockStmt
    
    public init(name: Token, params: [Parameter], returnType: TypeNode?, body: BlockStmt, line: Int, column: Int) {
        self.name = name
        self.params = params
        self.returnType = returnType
        self.body = body
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitFunctionDecl(self)
    }
}

/// Class declaration
public class ClassDecl: Decl {
    public let name: Token
    public let superclass: TypeNode?
    public let interfaces: [TypeNode]
    public let methods: [FunctionDecl]
    public let properties: [VarDecl]
    
    public init(name: Token, superclass: TypeNode?, interfaces: [TypeNode], methods: [FunctionDecl], properties: [VarDecl], line: Int, column: Int) {
        self.name = name
        self.superclass = superclass
        self.interfaces = interfaces
        self.methods = methods
        self.properties = properties
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitClassDecl(self)
    }
}

/// Struct declaration
public class StructDecl: Decl {
    public let name: Token
    public let interfaces: [TypeNode]
    public let methods: [FunctionDecl]
    public let properties: [VarDecl]
    
    public init(name: Token, interfaces: [TypeNode], methods: [FunctionDecl], properties: [VarDecl], line: Int, column: Int) {
        self.name = name
        self.interfaces = interfaces
        self.methods = methods
        self.properties = properties
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitStructDecl(self)
    }
}

/// Enum case declaration
public struct EnumCase {
    public let name: Token
    public let rawValue: Expr?
    
    public init(name: Token, rawValue: Expr? = nil) {
        self.name = name
        self.rawValue = rawValue
    }
}

/// Enum declaration
public class EnumDecl: Decl {
    public let name: Token
    public let rawType: TypeNode?
    public let cases: [EnumCase]
    public let methods: [FunctionDecl]
    
    public init(name: Token, rawType: TypeNode?, cases: [EnumCase], methods: [FunctionDecl], line: Int, column: Int) {
        self.name = name
        self.rawType = rawType
        self.cases = cases
        self.methods = methods
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitEnumDecl(self)
    }
}

/// Interface declaration
public class InterfaceDecl: Decl {
    public let name: Token
    public let extendedInterfaces: [TypeNode]
    public let methods: [FunctionDecl]
    
    public init(name: Token, extendedInterfaces: [TypeNode], methods: [FunctionDecl], line: Int, column: Int) {
        self.name = name
        self.extendedInterfaces = extendedInterfaces
        self.methods = methods
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitInterfaceDecl(self)
    }
}

// MARK: - Type Node Types

/// Named type (e.g., Int, String, Person)
public class NamedType: TypeNode {
    public let name: Token
    
    public init(name: Token, line: Int, column: Int) {
        self.name = name
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitNamedType(self)
    }
}

/// Array type (e.g., [Int], [String])
public class ArrayType: TypeNode {
    public let elementType: TypeNode
    
    public init(elementType: TypeNode, line: Int, column: Int) {
        self.elementType = elementType
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitArrayType(self)
    }
}

/// Generic type (e.g., Dictionary<String, Int>, Array<T>)
public class GenericType: TypeNode {
    public let baseType: TypeNode
    public let typeArguments: [TypeNode]
    
    public init(baseType: TypeNode, typeArguments: [TypeNode], line: Int, column: Int) {
        self.baseType = baseType
        self.typeArguments = typeArguments
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitGenericType(self)
    }
}

// Example of using Swift's type system improvements in AST
public struct ASTNodeExample: Hashable, Codable, Sendable {
    // Use existential any for flexible type handling
    public var type: any TypeProtocol

    // Implement Equatable
    public static func == (lhs: ASTNodeExample, rhs: ASTNodeExample) -> Bool {
        return lhs.type.name == rhs.type.name
    }

    // Implement Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type.name)
    }

    // Implement Codable
    enum CodingKeys: String, CodingKey {
        case type
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let typeName = try container.decode(String.self, forKey: .type)
        self.type = TypeRegistry.shared.type(for: typeName)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type.name, forKey: .type)
    }
}

// Placeholder definition for TypeProtocol
public protocol TypeProtocol: Sendable {
    var name: String { get }
}

// Convert TypeRegistry to actor for concurrency safety
public actor TypeRegistry {
    public static let shared = TypeRegistry()

    public func type(for name: String) -> any TypeProtocol {
        return DummyType(name: name)
    }
}

// Dummy type conforming to TypeProtocol
public struct DummyType: TypeProtocol, Sendable {
    public var name: String
}