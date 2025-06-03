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
        // Placeholder implementation - replace with actual parsing logic
        throw ParserError.invalidStatement("Class declaration parsing not yet implemented", line: peek().line, column: peek().column)
    }
    
    /// Parses a struct declaration.
    private func parseStructDeclaration() throws -> StructDecl {
        // Placeholder implementation - replace with actual parsing logic
        throw ParserError.invalidStatement("Struct declaration parsing not yet implemented", line: peek().line, column: peek().column)
    }
    
    /// Parses an enum declaration.
    private func parseEnumDeclaration() throws -> EnumDecl {
        // Placeholder implementation - replace with actual parsing logic
        throw ParserError.invalidStatement("Enum declaration parsing not yet implemented", line: peek().line, column: peek().column)
    }
    
    /// Parses an interface declaration.
    private func parseInterfaceDeclaration() throws -> InterfaceDecl {
        // Placeholder implementation - replace with actual parsing logic
        throw ParserError.invalidStatement("Interface declaration parsing not yet implemented", line: peek().line, column: peek().column)
    }
    
    /// Parses a function declaration.
    private func parseFunctionDeclaration() throws -> FunctionDecl {
        // Placeholder implementation - replace with actual parsing logic
        throw ParserError.invalidStatement("Function declaration parsing not yet implemented", line: peek().line, column: peek().column)
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
        // Placeholder implementation - replace with actual parsing logic
        throw ParserError.invalidStatement("While statement parsing not yet implemented", line: peek().line, column: peek().column)
    }
    
    /// Parses a for statement.
    private func parseForStatement() throws -> ForStmt {
        // Placeholder implementation - replace with actual parsing logic
        throw ParserError.invalidStatement("For statement parsing not yet implemented", line: peek().line, column: peek().column)
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
            let operator = previous()
            let value = try parseAssignment()
            
            // Check if the LHS is a valid assignment target
            if let variableExpr = expr as? VariableExpr {
                // Variable assignment: a = expr
                // Convert compound operators (+=, -=, etc.) to their expanded form
                if operator.type != .equal {
                    // For example, a += b becomes a = a + b
                    let binaryOperatorType: TokenType
                    switch operator.type {
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
                        line: operator.line,
                        column: operator.column
                    )
                    
                    let right = BinaryExpr(
                        left: expr,
                        operator: binaryOperator,
                        right: value,
                        line: expr.line,
                        column: expr.column
                    )
                    
                    return AssignExpr(
                        name: variableExpr.name,
                        value: right,
                        line: operator.line,
                        column: operator.column
                    )
                }
                
                return AssignExpr(
                    name: variableExpr.name,
                    value: value,
                    line: operator.line,
                    column: operator.column
                )
            } else if let getExpr = expr as? GetExpr {
                // Property assignment: obj.prop = expr
                return SetExpr(
                    object: getExpr.object,
                    name: getExpr.name,
                    value: value,
                    line: operator.line,
                    column: operator.column
                )
            } else if let indexExpr = expr as? IndexExpr {
                // Array index assignment: arr[i] = expr
                // Not implemented yet, but would be handled here
                throw ParserError.invalidExpression("Array index assignment not yet supported", line: operator.line, column: operator.column)
            }
            
            throw ParserError.invalidExpression("Invalid assignment target", line: operator.line, column: operator.column)
        }
        
        return expr
    }
    
    /// Parses a logical OR expression.
    private func parseOr() throws -> Expr {
        var expr = try parseAnd()
        
        while match(.or) {
            let operator = previous()
            let right = try parseAnd()
            expr = BinaryExpr(left: expr, operator: operator, right: right, line: operator.line, column: operator.column)
        }
        
        return expr
    }
    
    /// Parses a logical AND expression.
    private func parseAnd() throws -> Expr {
        var expr = try parseEquality()
        
        while match(.and) {
            let operator = previous()
            let right = try parseEquality()
            expr = BinaryExpr(left: expr, operator: operator, right: right, line: operator.line, column: operator.column)
        }
        
        return expr
    }
    
    /// Parses an equality expression.
    private func parseEquality() throws -> Expr {
        var expr = try parseComparison()
        
        while match(.bangEqual, .equalEqual) {
            let operator = previous()
            let right = try parseComparison()
            expr = BinaryExpr(left: expr, operator: operator, right: right, line: operator.line, column: operator.column)
        }
        
        return expr
    }
    
    /// Parses a comparison expression.
    private func parseComparison() throws -> Expr {
        var expr = try parseTerm()
        
        while match(.greater, .greaterEqual, .less, .lessEqual) {
            let operator = previous()
            let right = try parseTerm()
            expr = BinaryExpr(left: expr, operator: operator, right: right, line: operator.line, column: operator.column)
        }
        
        return expr
    }
    
    /// Parses a term expression (addition, subtraction).
    private func parseTerm() throws -> Expr {
        var expr = try parseFactor()
        
        while match(.minus, .plus) {
            let operator = previous()
            let right = try parseFactor()
            expr = BinaryExpr(left: expr, operator: operator, right: right, line: operator.line, column: operator.column)
        }
        
        return expr
    }
    
    /// Parses a factor expression (multiplication, division, modulo).
    private func parseFactor() throws -> Expr {
        var expr = try parseUnary()
        
        while match(.slash, .star, .percent) {
            let operator = previous()
            let right = try parseUnary()
            expr = BinaryExpr(left: expr, operator: operator, right: right, line: operator.line, column: operator.column)
        }
        
        return expr
    }
    
    /// Parses a unary expression (!, -).
    private func parseUnary() throws -> Expr {
        if match(.bang, .minus) {
            let operator = previous()
            let right = try parseUnary()
            return UnaryExpr(operator: operator, right: right, line: operator.line, column: operator.column)
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