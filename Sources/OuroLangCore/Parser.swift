//
//  Parser.swift
//  OuroLangCore
//
//  Created by YourName on TodayDate.
//

import Foundation

/// Error types that can occur during parsing.
public enum ParserError: Error, CustomStringConvertible {
    case unexpectedToken(Token, String)
    case invalidExpression(String, line: Int, column: Int)
    case invalidStatement(String, line: Int, column: Int)
    case invalidType(String, line: Int, column: Int)
    case missingToken(String, line: Int, column: Int)
    
    public var description: String {
        switch self {
        case .unexpectedToken(let token, let expected):
            return "Unexpected token \(token.type) (\(token.lexeme)) at line \(token.line), column \(token.column). Expected \(expected)."
        case .invalidExpression(let details, let line, let column):
            return "Invalid expression at line \(line), column \(column): \(details)"
        case .invalidStatement(let details, let line, let column):
            return "Invalid statement at line \(line), column \(column): \(details)"
        case .invalidType(let details, let line, let column):
            return "Invalid type at line \(line), column \(column): \(details)"
        case .missingToken(let expected, let line, let column):
            return "Expected \(expected) at line \(line), column \(column)"
        }
    }
}

/// The Parser converts a sequence of tokens into an Abstract Syntax Tree (AST).
public class Parser {
    private let tokens: [Token]
    private var current: Int = 0
    
    public init(tokens: [Token]) {
        self.tokens = tokens
    }
    
    // MARK: - Parsing Entry Points
    
    /// Parses the entire source into a list of declarations.
    public func parse() throws -> [Decl] {
        var declarations: [Decl] = []
        
        while !isAtEnd() {
            if let declaration = try parseDeclaration() {
                declarations.append(declaration)
            }
        }
        
        return declarations
    }
    
    // MARK: - Declaration Parsing
    
    /// Parses a declaration (class, function, variable, etc.).
    private func parseDeclaration() throws -> Decl? {
        do {
            if match(.class) {
                return try parseClassDeclaration()
            }
            if match(.struct) {
                return try parseStructDeclaration()
            }
            if match(.enum) {
                return try parseEnumDeclaration()
            }
            if match(.interface) {
                return try parseInterfaceDeclaration()
            }
            if match(.func) {
                return try parseFunctionDeclaration()
            }
            if match(.var) {
                return try parseVarDeclaration()
            }
            
            // If it's not a declaration, it might be a statement
            return try parseStatement() as? Decl
        } catch {
            synchronize()
            return nil
        }
    }
    
    /// Parses a class declaration.
    private func parseClassDeclaration() throws -> ClassDecl {
        let name = try consume(.identifier, "Expected class name.")
        // inheritance and interfaces
        var superclass: TypeNode? = nil
        var interfaces: [TypeNode] = []
        if match(.colon) {
            superclass = try parseType()
            while match(.comma) {
                interfaces.append(try parseType())
            }
        }
        try consume(.leftBrace, "Expected '{' before class body.")
        var methods: [FunctionDecl] = []
        var properties: [VarDecl] = []
        while !check(.rightBrace) && !isAtEnd() {
            if match(.var) {
                properties.append(try parseVarDeclaration())
            } else if match(.func) {
                methods.append(try parseFunctionDeclaration())
            } else {
                _ = try parseStatement()
            }
        }
        try consume(.rightBrace, "Expected '}' after class body.")
        return ClassDecl(name: name, superclass: superclass, interfaces: interfaces, methods: methods, properties: properties, line: name.line, column: name.column)
    }
    
    /// Parses a struct declaration.
    private func parseStructDeclaration() throws -> StructDecl {
        let name = try consume(.identifier, "Expected struct name.")
        var interfaces: [TypeNode] = []
        if match(.colon) {
            repeat { interfaces.append(try parseType()) } while match(.comma)
        }
        try consume(.leftBrace, "Expected '{' before struct body.")
        var methods: [FunctionDecl] = []
        var properties: [VarDecl] = []
        while !check(.rightBrace) && !isAtEnd() {
            if match(.var) { properties.append(try parseVarDeclaration()) }
            else if match(.func) { methods.append(try parseFunctionDeclaration()) }
            else { _ = try parseStatement() }
        }
        try consume(.rightBrace, "Expected '}' after struct body.")
        return StructDecl(name: name, interfaces: interfaces, methods: methods, properties: properties, line: name.line, column: name.column)
    }
    
    /// Parses an enum declaration.
    private func parseEnumDeclaration() throws -> EnumDecl {
        let name = try consume(.identifier, "Expected enum name.")
        var rawType: TypeNode? = nil
        if match(.colon) { rawType = try parseType() }
        try consume(.leftBrace, "Expected '{' before enum body.")
        var cases: [EnumCase] = []
        var methods: [FunctionDecl] = []
        while !check(.rightBrace) && !isAtEnd() {
            if check(.identifier) {
                let caseName = try consume(.identifier, "Expected enum case name.")
                var rawValue: Expr? = nil
                if match(.equal) { rawValue = try parseExpression() }
                cases.append(EnumCase(name: caseName, rawValue: rawValue))
                try consume(.semicolon, "Expected ';' after enum case.")
            } else if match(.func) {
                methods.append(try parseFunctionDeclaration())
            } else {
                _ = try parseStatement()
            }
        }
        try consume(.rightBrace, "Expected '}' after enum body.")
        return EnumDecl(name: name, rawType: rawType, cases: cases, methods: methods, line: name.line, column: name.column)
    }
    
    /// Parses an interface declaration.
    private func parseInterfaceDeclaration() throws -> InterfaceDecl {
        let name = try consume(.identifier, "Expected interface name.")
        try consume(.leftBrace, "Expected '{' before interface body.")
        var methods: [FunctionDecl] = []
        while !check(.rightBrace) && !isAtEnd() {
            if match(.func) { methods.append(try parseFunctionDeclaration()) }
            else { _ = try parseStatement() }
        }
        try consume(.rightBrace, "Expected '}' after interface body.")
        return InterfaceDecl(name: name, methods: methods, line: name.line, column: name.column)
    }
    
    /// Parses a function declaration.
    private func parseFunctionDeclaration() throws -> FunctionDecl {
        let name = try consume(.identifier, "Expected function name.")
        try consume(.leftParen, "Expected '(' after function name.")
        var params: [Parameter] = []
        if !check(.rightParen) {
            repeat {
                let paramName = try consume(.identifier, "Expected parameter name.")
                try consume(.colon, "Expected ':' after parameter name.")
                let typeNode = try parseType()
                params.append(Parameter(name: paramName, type: typeNode))
            } while match(.comma)
        }
        try consume(.rightParen, "Expected ')' after parameters.")
        var returnType: TypeNode? = nil
        if match(.arrow) {
            returnType = try parseType()
        }
        // function body
        let body: BlockStmt
        if match(.leftBrace) {
            body = try parseBlockStatement()
        } else {
            throw ParserError.invalidStatement("Expected function body.", line: peek().line, column: peek().column)
        }
        return FunctionDecl(name: name, params: params, returnType: returnType, body: body, line: name.line, column: name.column)
    }
    
    /// Parses a variable declaration.
    private func parseVarDeclaration() throws -> VarDecl {
        let name = try consume(.identifier, "Expected variable name.")
        
        // Optional type annotation
        var typeNode: TypeNode? = nil
        if match(.colon) {
            typeNode = try parseType()
        }
        
        // Optional initializer
        var initializer: Expr? = nil
        if match(.equal) {
            initializer = try parseExpression()
        }
        
        try consume(.semicolon, "Expected ';' after variable declaration.")
        
        return VarDecl(name: name, typeAnnotation: typeNode, initializer: initializer, line: name.line, column: name.column)
    }
    
    // MARK: - Statement Parsing
    
    /// Parses a statement.
    private func parseStatement() throws -> Stmt {
        if match(.if) {
            return try parseIfStatement()
        }
        if match(.while) {
            return try parseWhileStatement()
        }
        if match(.for) {
            return try parseForStatement()
        }
        if match(.return) {
            return try parseReturnStatement()
        }
        if match(.break) {
            return try parseBreakStatement()
        }
        if match(.continue) {
            return try parseContinueStatement()
        }
        if match(.leftBrace) {
            return try parseBlockStatement()
        }
        
        if match(.yield) {
            return try parseYieldStatement()
        }

        if match(.defer) {
            return try parseDeferStatement()
        }
        
        // If it's not a specific statement type, it's an expression statement
        return try parseExpressionStatement()
    }
    
    /// Parses an if statement.
    private func parseIfStatement() throws -> IfStmt {
        try consume(.leftParen, "Expected '(' after 'if'.")
        let condition = try parseExpression()
        try consume(.rightParen, "Expected ')' after if condition.")
        
        let thenBranch = try parseStatement()
        var elseBranch: Stmt? = nil
        
        if match(.else) {
            elseBranch = try parseStatement()
        }
        
        return IfStmt(
            condition: condition,
            thenBranch: thenBranch,
            elseBranch: elseBranch,
            line: previous().line,
            column: previous().column
        )
    }
    
    /// Parses a while statement.
    private func parseWhileStatement() throws -> WhileStmt {
        // 'while' already matched
        try consume(.leftParen, "Expected '(' after 'while'.")
        let condition = try parseExpression()
        try consume(.rightParen, "Expected ')' after while condition.")
        let body = try parseStatement()
        return WhileStmt(condition: condition, body: body, line: previous().line, column: previous().column)
    }
    
    /// Parses a for statement.
    private func parseForStatement() throws -> ForStmt {
        // 'for' already matched
        try consume(.leftParen, "Expected '(' after 'for'.")
        // initializer: var decl or expression or empty
        var initializer: Stmt? = nil
        if !match(.semicolon) {
            if match(.var) {
                initializer = try parseVarDeclaration()
            } else {
                initializer = try parseExpressionStatement()
            }
        }
        // condition
        var condition: Expr? = nil
        if !match(.semicolon) {
            condition = try parseExpression()
            try consume(.semicolon, "Expected ';' after for condition.")
        }
        // increment
        var increment: Expr? = nil
        if !check(.rightParen) {
            increment = try parseExpression()
        }
        try consume(.rightParen, "Expected ')' after for clauses.")
        // body
        let body = try parseStatement()
        return ForStmt(initializer: initializer, condition: condition, increment: increment, body: body, line: previous().line, column: previous().column)
    }
    
    /// Parses a block statement (a sequence of statements in braces).
    private func parseBlockStatement() throws -> BlockStmt {
        var statements: [Stmt] = []
        let openingBrace = previous()
        
        while !check(.rightBrace) && !isAtEnd() {
            if let declaration = try parseDeclaration() as? Stmt {
                statements.append(declaration)
            }
        }
        
        try consume(.rightBrace, "Expected '}' after block.")
        
        return BlockStmt(statements: statements, line: openingBrace.line, column: openingBrace.column)
    }
    
    /// Parses a return statement.
    private func parseReturnStatement() throws -> ReturnStmt {
        let keyword = previous()
        var value: Expr? = nil
        
        if !check(.semicolon) {
            value = try parseExpression()
        }
        
        try consume(.semicolon, "Expected ';' after return value.")
        
        return ReturnStmt(keyword: keyword, value: value, line: keyword.line, column: keyword.column)
    }
    
    /// Parses a break statement.
    private func parseBreakStatement() throws -> BreakStmt {
        let keyword = previous()
        try consume(.semicolon, "Expected ';' after break.")
        return BreakStmt(keyword: keyword, line: keyword.line, column: keyword.column)
    }
    
    /// Parses a continue statement.
    private func parseContinueStatement() throws -> ContinueStmt {
        let keyword = previous()
        try consume(.semicolon, "Expected ';' after continue.")
        return ContinueStmt(keyword: keyword, line: keyword.line, column: keyword.column)
    }
    
    /// Parses a yield statement.
    private func parseYieldStatement() throws -> YieldStmt {
        let keyword = previous()
        var value: Expr? = nil

        if !check(.semicolon) {
            value = try parseExpression()
        }

        try consume(.semicolon, "Expected ';' after yield value.")

        return YieldStmt(keyword: keyword, value: value, line: keyword.line, column: keyword.column)
    }

    /// Parses a defer statement.
    private func parseDeferStatement() throws -> DeferStmt {
        let keyword = previous()
        let body = try parseBlockStatement()
        return DeferStmt(keyword: keyword, body: body, line: keyword.line, column: keyword.column)
    }
    
    /// Parses an expression statement.
    private func parseExpressionStatement() throws -> ExpressionStmt {
        let expr = try parseExpression()
        try consume(.semicolon, "Expected ';' after expression.")
        return ExpressionStmt(expression: expr, line: expr.line, column: expr.column)
    }
    
    // MARK: - Expression Parsing
    
    /// Parses an expression.
    private func parseExpression() throws -> Expr {
        return try parseAssignment()
    }
    
    /// Parses an assignment expression.
    private func parseAssignment() throws -> Expr {
        let expr = try parseOr()
        
        if match(.equal, .plusEqual, .minusEqual, .starEqual, .slashEqual, .percentEqual) {
            let op = previous()
            let value = try parseAssignment()
            
            // Check if the LHS is a valid assignment target
            if let variableExpr = expr as? VariableExpr {
                // Variable assignment: a = expr
                // Convert compound operators (+=, -=, etc.) to their expanded form
                if op.type != .equal {
                    // For example, a += b becomes a = a + b
                    let binaryOperatorType: TokenType
                    switch op.type {
                    case .plusEqual: binaryOperatorType = .plus
                    case .minusEqual: binaryOperatorType = .minus
                    case .starEqual: binaryOperatorType = .star
                    case .slashEqual: binaryOperatorType = .slash
                    case .percentEqual: binaryOperatorType = .percent
                    default: fatalError("Unexpected compound assignment operator")
                    }
                    
                    let binaryOperator = Token(
                        type: binaryOperatorType,
                        lexeme: String(binaryOperatorType.rawValue),
                        literal: nil,
                        line: op.line,
                        column: op.column
                    )
                    
                    let right = BinaryExpr(
                        left: expr,
                        op: binaryOperator,
                        right: value,
                        line: op.line,
                        column: op.column
                    )
                    
                    return AssignExpr(
                        name: variableExpr.name,
                        value: right,
                        line: op.line,
                        column: op.column
                    )
                }
                
                return AssignExpr(
                    name: variableExpr.name,
                    value: value,
                    line: op.line,
                    column: op.column
                )
            } else if let getExpr = expr as? GetExpr {
                // Property assignment: obj.prop = expr
                return SetExpr(
                    object: getExpr.object,
                    name: getExpr.name,
                    value: value,
                    line: op.line,
                    column: op.column
                )
            } else if let indexExpr = expr as? IndexExpr {
                // Array index assignment: arr[i] = expr
                // Not implemented yet, but would be handled here
                throw ParserError.invalidExpression("Array index assignment not yet supported", line: op.line, column: op.column)
            }
            
            throw ParserError.invalidExpression("Invalid assignment target", line: op.line, column: op.column)
        }
        
        return expr
    }
    
    /// Parses a logical OR expression.
    private func parseOr() throws -> Expr {
        var expr = try parseAnd()
        
        while match(.or) {
            let op = previous()
            let right = try parseAnd()
            expr = BinaryExpr(left: expr, op: op, right: right, line: op.line, column: op.column)
        }
        
        return expr
    }
    
    /// Parses a logical AND expression.
    private func parseAnd() throws -> Expr {
        var expr = try parseEquality()
        
        while match(.and) {
            let op = previous()
            let right = try parseEquality()
            expr = BinaryExpr(left: expr, op: op, right: right, line: op.line, column: op.column)
        }
        
        return expr
    }
    
    /// Parses an equality expression.
    private func parseEquality() throws -> Expr {
        var expr = try parseComparison()
        
        while match(.bangEqual, .equalEqual) {
            let op = previous()
            let right = try parseComparison()
            expr = BinaryExpr(left: expr, op: op, right: right, line: op.line, column: op.column)
        }
        
        return expr
    }
    
    /// Parses a comparison expression.
    private func parseComparison() throws -> Expr {
        var expr = try parseTerm()
        
        while match(.greater, .greaterEqual, .less, .lessEqual) {
            let op = previous()
            let right = try parseTerm()
            expr = BinaryExpr(left: expr, op: op, right: right, line: op.line, column: op.column)
        }
        
        return expr
    }
    
    /// Parses a term expression (addition, subtraction).
    private func parseTerm() throws -> Expr {
        var expr = try parseFactor()
        
        while match(.minus, .plus) {
            let op = previous()
            let right = try parseFactor()
            expr = BinaryExpr(left: expr, op: op, right: right, line: op.line, column: op.column)
        }
        
        return expr
    }
    
    /// Parses a factor expression (multiplication, division, modulo).
    private func parseFactor() throws -> Expr {
        var expr = try parseUnary()
        
        while match(.slash, .star, .percent) {
            let op = previous()
            let right = try parseUnary()
            expr = BinaryExpr(left: expr, op: op, right: right, line: op.line, column: op.column)
        }
        
        return expr
    }
    
    /// Parses a unary expression (!, -).
    private func parseUnary() throws -> Expr {
        if match(.bang, .minus) {
            let op = previous()
            let right = try parseUnary()
            return UnaryExpr(op: op, right: right, line: op.line, column: op.column)
        }
        
        return try parseCall()
    }
    
    /// Parses a function or method call.
    private func parseCall() throws -> Expr {
        var expr = try parsePrimary()
        
        while true {
            if match(.leftParen) {
                expr = try finishCall(callee: expr)
            } else if match(.leftBracket) {
                expr = try finishIndex(array: expr)
            } else if match(.dot) {
                let name = try consume(.identifier, "Expected property name after '.'.")
                expr = GetExpr(object: expr, name: name, line: name.line, column: name.column)
            } else {
                break
            }
        }
        
        return expr
    }
    
    /// Helper method to parse the arguments of a function call.
    private func finishCall(callee: Expr) throws -> Expr {
        var arguments: [Expr] = []
        
        // Parse arguments if there are any
        if !check(.rightParen) {
            repeat {
                if arguments.count >= 255 {
                    throw ParserError.invalidExpression("Function call with more than 255 arguments is not supported", line: peek().line, column: peek().column)
                }
                arguments.append(try parseExpression())
            } while match(.comma)
        }
        
        let paren = try consume(.rightParen, "Expected ')' after arguments.")
        
        return CallExpr(callee: callee, paren: paren, arguments: arguments, line: callee.line, column: callee.column)
    }
    
    /// Helper method to parse an array index access.
    private func finishIndex(array: Expr) throws -> Expr {
        let index = try parseExpression()
        let closeBracket = try consume(.rightBracket, "Expected ']' after index.")
        
        return IndexExpr(array: array, index: index, line: array.line, column: array.column)
    }
    
    /// Parses a primary expression (literal, grouping, variable).
    private func parsePrimary() throws -> Expr {
        if match(.false) {
            return LiteralExpr(value: false, tokenType: .false, line: previous().line, column: previous().column)
        }
        
        if match(.true) {
            return LiteralExpr(value: true, tokenType: .true, line: previous().line, column: previous().column)
        }
        
        if match(.null) {
            return LiteralExpr(value: nil, tokenType: .null, line: previous().line, column: previous().column)
        }
        
        if match(.integer, .float, .string, .char) {
            return LiteralExpr(
                value: previous().literal,
                tokenType: previous().type,
                line: previous().line,
                column: previous().column
            )
        }
        
        if match(.leftParen) {
            let expr = try parseExpression()
            try consume(.rightParen, "Expected ')' after expression.")
            return GroupingExpr(expression: expr, line: expr.line, column: expr.column)
        }
        
        if match(.this) {
            return ThisExpr(keyword: previous(), line: previous().line, column: previous().column)
        }
        
        if match(.super) {
            try consume(.dot, "Expected '.' after 'super'.")
            let method = try consume(.identifier, "Expected superclass method name.")
            return SuperExpr(keyword: previous(), method: method, line: previous().line, column: previous().column)
        }
        
        if match(.leftBracket) {
            return try parseArrayLiteral()
        }
        
        if match(.identifier) {
            return VariableExpr(name: previous(), line: previous().line, column: previous().column)
        }
        
        throw ParserError.unexpectedToken(peek(), "expression")
    }
    
    /// Parses an array literal expression.
    private func parseArrayLiteral() throws -> Expr {
        var elements: [Expr] = []
        let startToken = previous()
        
        if !check(.rightBracket) {
            repeat {
                elements.append(try parseExpression())
            } while match(.comma)
        }
        
        try consume(.rightBracket, "Expected ']' after array elements.")
        
        return ArrayExpr(elements: elements, line: startToken.line, column: startToken.column)
    }
    
    /// Parses a type annotation.
    private func parseType() throws -> TypeNode {
        if match(.identifier) {
            let name = previous()
            
            if match(.leftBracket) {
                // Array type
                try consume(.rightBracket, "Expected ']' after array type.")
                return ArrayType(
                    elementType: NamedType(name: name, line: name.line, column: name.column),
                    line: name.line,
                    column: name.column
                )
            } else if match(.less) {
                // Generic type
                var typeArguments: [TypeNode] = []
                
                repeat {
                    typeArguments.append(try parseType())
                } while match(.comma)
                
                try consume(.greater, "Expected '>' after generic type arguments.")
                
                return GenericType(
                    baseType: NamedType(name: name, line: name.line, column: name.column),
                    typeArguments: typeArguments,
                    line: name.line,
                    column: name.column
                )
            }
            
            return NamedType(name: name, line: name.line, column: name.column)
        }
        
        throw ParserError.invalidType("Expected type name", line: peek().line, column: peek().column)
    }
    
    // MARK: - Helper Methods
    
    /// Checks if the current token is of any of the given types without advancing.
    private func check(_ types: TokenType...) -> Bool {
        if isAtEnd() { return false }
        
        for type in types {
            if peek().type == type {
                return true
            }
        }
        
        return false
    }
    
    /// Matches the current token against any of the given types and advances if there's a match.
    @discardableResult
    private func match(_ types: TokenType...) -> Bool {
        for type in types {
            if check(type) {
                advance()
                return true
            }
        }
        
        return false
    }
    
    /// Consumes the current token if it matches the expected type, otherwise throws an error.
    @discardableResult
    private func consume(_ type: TokenType, _ message: String) throws -> Token {
        if check(type) {
            return advance()
        }
        
        throw ParserError.unexpectedToken(peek(), message)
    }
    
    /// Returns the current token without advancing.
    private func peek() -> Token {
        return tokens[current]
    }
    
    /// Returns true if we've reached the end of the token stream.
    private func isAtEnd() -> Bool {
        return peek().type == .eof
    }
    
    /// Advances to the next token and returns the previous one.
    @discardableResult
    private func advance() -> Token {
        if !isAtEnd() {
            current += 1
        }
        return previous()
    }
    
    /// Returns the most recently consumed token.
    private func previous() -> Token {
        return tokens[current - 1]
    }
    
    /// Synchronizes the parser after an error, advancing to a statement boundary.
    private func synchronize() {
        advance()
        
        while !isAtEnd() {
            // If we just saw a semicolon, we're likely at a statement boundary
            if previous().type == .semicolon { return }
            
            // Or if we see a token that could start a new statement
            switch peek().type {
            case .class, .func, .var, .for, .if, .while, .return:
                return
            default:
                advance()
            }
        }
    }
}

// MARK: - Additional Types Not Directly Defined in AST.swift

/// Assignment expression class (e.g., x = 10)
public class AssignExpr: Expr {
    public let name: Token
    public let value: Expr
    
    public init(name: Token, value: Expr, line: Int, column: Int) {
        self.name = name
        self.value = value
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        // This would need to be added to the ASTVisitor protocol
        fatalError("AssignExpr.accept not implemented")
    }
}