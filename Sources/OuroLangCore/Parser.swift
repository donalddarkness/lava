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

/// Represents severity levels for diagnostic messages
public enum DiagnosticSeverity {
    case error
    case warning
    case info
    case hint
}

/// Represents a diagnostic message with source location information
public struct Diagnostic: Equatable, Hashable {
    public let severity: DiagnosticSeverity
    public let message: String
    public let line: Int
    public let column: Int
    public let source: String
    public let relatedInfo: [String]?
    
    public init(
        severity: DiagnosticSeverity, 
        message: String, 
        line: Int, 
        column: Int,
        source: String = "",
        relatedInfo: [String]? = nil
    ) {
        self.severity = severity
        self.message = message
        self.line = line
        self.column = column
        self.source = source
        self.relatedInfo = relatedInfo
    }
}

/// Manages collection and reporting of diagnostics during parsing
public class DiagnosticManager {
    private(set) var diagnostics: [Diagnostic] = []
    private var hasErrors: Bool = false
    
    /// Add a new diagnostic to the collection
    public func report(
        _ severity: DiagnosticSeverity, 
        _ message: String, 
        line: Int, 
        column: Int,
        source: String = "",
        relatedInfo: [String]? = nil
    ) {
        let diagnostic = Diagnostic(
            severity: severity,
            message: message,
            line: line,
            column: column,
            source: source,
            relatedInfo: relatedInfo
        )
        diagnostics.append(diagnostic)
        
        if severity == .error {
            hasErrors = true
        }
    }
    
    /// Report diagnostic from a token
    public func report(
        _ severity: DiagnosticSeverity,
        _ message: String,
        token: Token,
        relatedInfo: [String]? = nil
    ) {
        report(
            severity,
            message,
            line: token.line,
            column: token.column,
            source: token.lexeme,
            relatedInfo: relatedInfo
        )
    }
    
    /// Check if any errors have been reported
    public func containsErrors() -> Bool {
        return hasErrors
    }
    
    /// Clear all diagnostics
    public func clear() {
        diagnostics.removeAll()
        hasErrors = false
    }
}

/// The Parser converts a sequence of tokens into an Abstract Syntax Tree (AST).
public class Parser {
    private let tokens: [Token]
    private var current: Int = 0
    
    // Diagnostic system for better error reporting
    private let diagnostics = DiagnosticManager()
    
    // Recovery tracking for better error management
    private var panicMode = false
    private var recoveryTokens: Set<TokenType> = []
    
    // Swift 6.1 optimizations - use lazy properties for common parsing patterns
    private lazy var expressionParsers: [() throws -> Expr?] = [
        parseLambdaExpression,
        parseMethodReferenceExpression,
        parseTernaryExpression,
        parseAssignment
    ]
    
    public init(tokens: [Token]) {
        self.tokens = tokens
    }
    
    // MARK: - Parsing Entry Points
    
    /// Parses the entire source into a list of declarations.
    /// - Returns: List of parsed declarations
    /// - Throws: ParserError if unrecoverable parsing errors occur
    public func parse() throws -> [Decl] {
        var declarations: [Decl] = []
        
        while !isAtEnd() {
            if let declaration = try parseDeclaration() {
                declarations.append(declaration)
            }
        }
        
        // Report any diagnostics that were collected
        if diagnostics.containsErrors() {
            throw ParserError.invalidStatement(
                "Parsing failed with \(diagnostics.diagnostics.filter { $0.severity == .error }.count) errors",
                line: 1, 
                column: 1
            )
        }
        
        return declarations
    }
    
    /// Returns all collected diagnostics
    public func getDiagnostics() -> [Diagnostic] {
        return diagnostics.diagnostics
    }
    
    // MARK: - Declaration Parsing
    
    /// Parses a declaration (class, function, variable, etc.).
    private func parseDeclaration() throws -> Decl? {
        do {
            let declarationParsers: [(TokenType, () throws -> Decl)] = [
                (.class, parseClassDeclaration),
                (.struct, parseStructDeclaration),
                (.enum, parseEnumDeclaration),
                (.interface, parseInterfaceDeclaration),
                (.func, parseFunctionDeclaration),
                (.var, parseVarDeclaration)
            ]
            
            for (tokenType, parser) in declarationParsers {
                if match(tokenType) {
                    return try parser()
                }
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
        
        if match(.equal, .plusEqual, .minusEqual, .starEqual, .slashEqual, .percentEqual, .powerEqual, 
                .nullCoalescingEqual, .andEqual, .orEqual, .xorEqual, .leftShiftEqual, .rightShiftEqual) {
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
                    case .powerEqual: binaryOperatorType = .power
                    case .nullCoalescingEqual: binaryOperatorType = .nullCoalescing
                    case .andEqual: binaryOperatorType = .and
                    case .orEqual: binaryOperatorType = .or
                    case .xorEqual: binaryOperatorType = .xor
                    case .leftShiftEqual: binaryOperatorType = .leftShift
                    case .rightShiftEqual: binaryOperatorType = .rightShift
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
                return SetIndexExpr(
                    array: indexExpr.array,
                    index: indexExpr.index,
                    value: value,
                    line: op.line,
                    column: op.column
                )
            }
            
            throw ParserError.invalidExpression("Invalid assignment target", line: op.line, column: op.column)
        }
        
        return expr
    }
    
    /// Parses a logical OR expression.
    private func parseOr() throws -> Expr {
        var expr = try parseAnd()
        
        while match(.or, .nullCoalescing) {
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
        
        while match(.bangEqual, .equalEqual, .spaceship) {
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
        var expr = try parsePower()
        
        while match(.slash, .star, .percent) {
            let op = previous()
            let right = try parsePower()
            expr = BinaryExpr(left: expr, op: op, right: right, line: op.line, column: op.column)
        }
        
        return expr
    }
    
    /// Parses a power expression (exponentiation).
    private func parsePower() throws -> Expr {
        var expr = try parseUnary()
        
        while match(.power) {
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
        
        if match(.integer, .float, .string, .char, .binaryInteger, .hexInteger, .octalInteger) {
            return LiteralExpr(
                value: previous().literal,
                tokenType: previous().type,
                line: previous().line,
                column: previous().column
            )
        }
        
        if match(.leftParen) {
            // Check if this might be a lambda expression: (param1, param2) => expression
            if check(.identifier) {
                let peek = tokens[current]
                let peekAhead = current + 1 < tokens.count ? tokens[current + 1] : nil
                
                // Simple case: (x) => x + 1
                if peekAhead?.type == .rightParen && current + 2 < tokens.count && tokens[current + 2].type == .doubleArrow {
                    return try parseLambdaExpression()
                }
                
                // Multiple parameters: (x, y) => x + y
                if peekAhead?.type == .comma || 
                   (peekAhead?.type == .colon && current + 2 < tokens.count && tokens[current + 2].type != .doubleArrow) {
                    return try parseLambdaExpression()
                }
            }
            
            // Regular grouping expression
            let expr = try parseExpression()
            try consume(.rightParen, "Expected ')' after expression.")
            return GroupingExpr(expression: expr, line: expr.line, column: expr.column)
        }
        
        // Check for parameterless lambda: () => expression
        if check(.leftParen) && current + 1 < tokens.count && tokens[current + 1].type == .rightParen &&
           current + 2 < tokens.count && tokens[current + 2].type == .doubleArrow {
            return try parseLambdaExpression()
        }
        
        // Check for single parameter lambda without parentheses: x => x * 2
        if check(.identifier) && current + 1 < tokens.count && tokens[current + 1].type == .doubleArrow {
            return try parseSingleParamLambda()
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
        
        if match(.leftBrace) {
            return try parseDictionaryOrSetLiteral()
        }
        
        if match(.identifier) {
            // Check if this is a method reference: ClassName::methodName
            if check(.doubleColon) {
                return try parseMethodReference(className: previous())
            }
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
    
    /// Parses a dictionary or set literal expression.
    private func parseDictionaryOrSetLiteral() throws -> Expr {
        let startToken = previous() // '{'
        
        // Empty dictionary or set
        if match(.rightBrace) {
            // Default to empty dictionary since it's more common
            return DictionaryExpr(entries: [], line: startToken.line, column: startToken.column)
        }
        
        // Check if it's a set literal with a hash prefix
        let isSet = check(.hash)
        if isSet {
            advance() // consume '#'
            return try parseSetLiteral(startToken: startToken)
        }
        
        // Parse first expression to determine if it's a dictionary or set
        let firstExpr = try parseExpression()
        
        // If we see a colon after the first expression, it's a dictionary
        if match(.colon) {
            let value = try parseExpression()
            var entries: [(Expr, Expr)] = [(firstExpr, value)]
            
            // Parse remaining key-value pairs
            while match(.comma) {
                if check(.rightBrace) {
                    break // Allow trailing comma
                }
                let key = try parseExpression()
                try consume(.colon, "Expected ':' after dictionary key.")
                let value = try parseExpression()
                entries.append((key, value))
            }
            
            try consume(.rightBrace, "Expected '}' after dictionary elements.")
            return DictionaryExpr(entries: entries, line: startToken.line, column: startToken.column)
        } else {
            // It's a set with the first element already parsed
            var elements: [Expr] = [firstExpr]
            
            // Parse remaining elements
            while match(.comma) {
                if check(.rightBrace) {
                    break // Allow trailing comma
                }
                elements.append(try parseExpression())
            }
            
            try consume(.rightBrace, "Expected '}' after set elements.")
            return SetExpr(elements: elements, line: startToken.line, column: startToken.column)
        }
    }
    
    /// Parses a set literal with the '#' prefix already consumed.
    private func parseSetLiteral(startToken: Token) throws -> Expr {
        var elements: [Expr] = []
        
        if !check(.rightBrace) {
            repeat {
                elements.append(try parseExpression())
            } while match(.comma)
        }
        
        try consume(.rightBrace, "Expected '}' after set elements.")
        return SetExpr(elements: elements, line: startToken.line, column: startToken.column)
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
        
        // Dictionary/Map type: [KeyType: ValueType]
        if match(.leftBracket) {
            let keyType = try parseType()
            try consume(.colon, "Expected ':' in dictionary type.")
            let valueType = try parseType()
            try consume(.rightBracket, "Expected ']' after dictionary type.")
            
            return DictionaryType(
                keyType: keyType,
                valueType: valueType,
                line: previous().line,
                column: previous().column
            )
        }
        
        // Set type: Set<ElementType>
        if match(.set) {
            try consume(.less, "Expected '<' after 'Set'.")
            let elementType = try parseType()
            try consume(.greater, "Expected '>' after set element type.")
            
            return SetType(
                elementType: elementType,
                line: previous().line,
                column: previous().column
            )
        }
        
        // Tuple type: (Type1, Type2, ...)
        if match(.leftParen) {
            var elementTypes: [TypeNode] = []
            
            if !check(.rightParen) {
                repeat {
                    elementTypes.append(try parseType())
                } while match(.comma)
            }
            
            try consume(.rightParen, "Expected ')' after tuple type elements.")
            
            return TupleType(
                elementTypes: elementTypes,
                line: previous().line,
                column: previous().column
            )
        }
        
        // Function type: (ParamType1, ParamType2) -> ReturnType
        if check(.leftParen) && isFunctionType() {
            return try parseFunctionType()
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
    
    /// Checks if we're at the start of a function type.
    private func isFunctionType() -> Bool {
        // Save current position
        let startPos = current
        
        // Try to parse as a function type
        var success = false
        if match(.leftParen) {
            // Skip parameters
            var depth = 1
            while depth > 0 && !isAtEnd() {
                if peek().type == .leftParen {
                    depth += 1
                } else if peek().type == .rightParen {
                    depth -= 1
                }
                advance()
            }
            
            // Check if we have -> after the parameters
            if !isAtEnd() && peek().type == .arrow {
                success = true
            }
        }
        
        // Restore position
        current = startPos
        
        return success
    }
    
    /// Parses a function type: (ParamType1, ParamType2) -> ReturnType
    private func parseFunctionType() throws -> TypeNode {
        try consume(.leftParen, "Expected '(' at start of function type.")
        
        var parameterTypes: [TypeNode] = []
        
        if !check(.rightParen) {
            repeat {
                parameterTypes.append(try parseType())
            } while match(.comma)
        }
        
        try consume(.rightParen, "Expected ')' after function parameter types.")
        try consume(.arrow, "Expected '->' in function type.")
        
        let returnType = try parseType()
        
        return FunctionType(
            parameterTypes: parameterTypes,
            returnType: returnType,
            line: previous().line,
            column: previous().column
        )
    }
    
    /// Enhanced error handling for unsupported syntax
    private func unsupportedSyntaxError(_ message: String) throws -> Never {
        throw ParserError.invalidExpression(message, line: peek().line, column: peek().column)
    }

    /// Enhanced error handling for invalid constructs
    private func invalidConstructError(_ message: String) throws -> Never {
        throw ParserError.invalidStatement(message, line: peek().line, column: peek().column)
    }
    
    /// Helper method to parse a list of expressions separated by a delimiter
    private func parseExpressionList(delimiter: TokenType, terminator: TokenType) throws -> [Expr] {
        var expressions: [Expr] = []
        
        if !check(terminator) {
            repeat {
                expressions.append(try parseExpression())
            } while match(delimiter)
        }
        
        try consume(terminator, "Expected '")
        return expressions
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

/// Set index expression class (e.g., arr[i] = 10)
public class SetIndexExpr: Expr {
    public let array: Expr
    public let index: Expr
    public let value: Expr
    
    public init(array: Expr, index: Expr, value: Expr, line: Int, column: Int) {
        self.array = array
        self.index = index
        self.value = value
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitSetIndexExpr(self)
    }
}

/// Dictionary literal expression class (e.g., {"key": value})
public class DictionaryExpr: Expr {
    public let entries: [(Expr, Expr)]
    
    public init(entries: [(Expr, Expr)], line: Int, column: Int) {
        self.entries = entries
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitDictionaryExpr(self)
    }
}

/// Set literal expression class (e.g., #{1, 2, 3} or {1, 2, 3})
public class SetExpr: Expr {
    public let elements: [Expr]
    
    public init(elements: [Expr], line: Int, column: Int) {
        self.elements = elements
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitSetExpr(self)
    }
}

/// Lambda expression body type
public enum LambdaBody {
    case expression(Expr)
    case block(BlockStmt)
}

/// Lambda expression class (e.g., (x, y) => x + y or x => x * 2)
public class LambdaExpr: Expr {
    public let parameters: [Parameter]
    public let body: LambdaBody
    
    public init(parameters: [Parameter], body: LambdaBody, line: Int, column: Int) {
        self.parameters = parameters
        self.body = body
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitLambdaExpr(self)
    }
}

/// Method reference expression class (e.g., String::length)
public class MethodReferenceExpr: Expr {
    public let className: Token
    public let methodName: Token
    
    public init(className: Token, methodName: Token, line: Int, column: Int) {
        self.className = className
        self.methodName = methodName
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitMethodReferenceExpr(self)
    }
}

/// Parses a lambda expression with multiple parameters: (param1, param2) => expression
private func parseLambdaExpression() throws -> Expr {
    // We're already at the position after '('
    var parameters: [Parameter] = []
    
    if !check(.rightParen) {
        repeat {
            let name = try consume(.identifier, "Expected parameter name.")
            var type: TypeNode? = nil
            
            if match(.colon) {
                type = try parseType()
            }
            
            parameters.append(Parameter(name: name, type: type))
        } while match(.comma)
    }
    
    try consume(.rightParen, "Expected ')' after lambda parameters.")
    try consume(.doubleArrow, "Expected '=>' after lambda parameters.")
    
    // Handle both expression and block body
    if check(.leftBrace) {
        // Block body: (x, y) => { statements... }
        advance() // consume '{'
        let body = try parseBlockStatement()
        return LambdaExpr(parameters: parameters, body: .block(body), line: previous().line, column: previous().column)
    } else {
        // Expression body: (x, y) => x + y
        let expr = try parseExpression()
        return LambdaExpr(parameters: parameters, body: .expression(expr), line: previous().line, column: previous().column)
    }
}

/// Parses a lambda expression with a single parameter and no parentheses: x => x + 1
private func parseSingleParamLambda() throws -> Expr {
    let name = try consume(.identifier, "Expected parameter name.")
    let parameter = Parameter(name: name, type: nil)
    
    try consume(.doubleArrow, "Expected '=>' after parameter.")
    
    // Handle both expression and block body
    if check(.leftBrace) {
        // Block body: x => { statements... }
        advance() // consume '{'
        let body = try parseBlockStatement()
        return LambdaExpr(parameters: [parameter], body: .block(body), line: name.line, column: name.column)
    } else {
        // Expression body: x => x + 1
        let expr = try parseExpression()
        return LambdaExpr(parameters: [parameter], body: .expression(expr), line: name.line, column: name.column)
    }
}

/// Parses a method reference: ClassName::methodName
private func parseMethodReference(className: Token) throws -> Expr {
    try consume(.doubleColon, "Expected '::' in method reference.")
    let methodName = try consume(.identifier, "Expected method name after '::'.")
      return MethodReferenceExpr(
        className: className,
        methodName: methodName,
        line: className.line,
        column: className.column
    )
}

 // End of Parser class

// MARK: - Additional Type Node Classes

/// Dictionary type (e.g., [String: Int])
public class DictionaryType: TypeNode {
    public let keyType: TypeNode
    public let valueType: TypeNode
    
    public init(keyType: TypeNode, valueType: TypeNode, line: Int, column: Int) {
        self.keyType = keyType
        self.valueType = valueType
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitDictionaryType(self)
    }
}

/// Set type (e.g., Set<Int>)
public class SetType: TypeNode {
    public let elementType: TypeNode
    
    public init(elementType: TypeNode, line: Int, column: Int) {
        self.elementType = elementType
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitSetType(self)
    }
}

/// Tuple type (e.g., (Int, String, Bool))
public class TupleType: TypeNode {
    public let elementTypes: [TypeNode]
    
    public init(elementTypes: [TypeNode], line: Int, column: Int) {
        self.elementTypes = elementTypes
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitTupleType(self)
    }
}

/// Function type (e.g., (Int, String) -> Bool)
public class FunctionType: TypeNode {
    public let parameterTypes: [TypeNode]
    public let returnType: TypeNode
    
    public init(parameterTypes: [TypeNode], returnType: TypeNode, line: Int, column: Int) {
        self.parameterTypes = parameterTypes
        self.returnType = returnType
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitFunctionType(self)
    }
}

extension Parser {
    // MARK: - Advanced Error Handling
    
    /// Reports an error with the current token
    private func error(_ message: String, severity: DiagnosticSeverity = .error) -> ParserError {
        let token = peek()
        diagnostics.report(severity, message, token: token)
        return ParserError.unexpectedToken(token, message)
    }
    
    /// Enters panic mode for error recovery
    private func enterPanicMode(synchronizationTokens: Set<TokenType>) {
        if panicMode { return }
        
        panicMode = true
        recoveryTokens = synchronizationTokens
    }
    
    /// Exits panic mode after recovery
    private func exitPanicMode() {
        panicMode = false
        recoveryTokens.removeAll()
    }
    
    /// Improved synchronize method with configurable synchronization points
    private func synchronize() {
        advance()
        
        while !isAtEnd() {
            if previous().type == .semicolon { return }
            
            switch peek().type {
            case .class, .func, .var, .for, .if, .while, .return:
                return
            default:
                if recoveryTokens.contains(peek().type) {
                    exitPanicMode()
                    return
                }
            }
            
            advance()
        }
    }
    
    /// Helper method for parsing a delimited list
    /// - Parameters:
    ///   - parseElement: Function to parse a single element of the list
    ///   - delimiter: Token type expected between elements
    ///   - terminator: Token type expected at the end of the list
    ///   - errorMessage: Message to show if terminator is missing
    /// - Returns: Array of parsed elements
    private func parseDelimitedList<T>(
        parseElement: () throws -> T,
        delimiter: TokenType,
        terminator: TokenType,
        errorMessage: String
    ) throws -> [T] {
        var elements: [T] = []
        
        if !check(terminator) {
            repeat {
                do {
                    elements.append(try parseElement())
                } catch {
                    // Report the error but try to continue parsing
                    diagnostics.report(.error, "Error in list element: \(error)", token: previous())
                    synchronize()
                }
            } while match(delimiter)
        }
        
        try consume(terminator, errorMessage)
        return elements
    }
}