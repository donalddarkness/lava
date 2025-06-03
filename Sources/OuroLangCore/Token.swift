//
//  Token.swift
//  OuroLangCore
//
//  Created by YourName on TodayDate.
//

import Foundation

/// Represents a lexical token in the OuroLang source code.
public struct Token: Equatable, Hashable {
    /// The type of the token.
    public let type: TokenType

    /// The textual representation of the token (lexeme).
    public let lexeme: String

    /// The literal value of the token, if any (e.g., number, string content).
    public let literal: Any?

    /// The 1-based line number where the token appears.
    public let line: Int

    /// The 1-based column number where the token begins.
    public let column: Int

    public init(type: TokenType, lexeme: String, literal: Any? = nil, line: Int, column: Int) {
        self.type = type
        self.lexeme = lexeme
        self.literal = literal
        self.line = line
        self.column = column
    }

    // MARK: - Equatable
    public static func == (lhs: Token, rhs: Token) -> Bool {
        return lhs.type == rhs.type &&
               lhs.lexeme == rhs.lexeme &&
               areEqual(lhs.literal, rhs.literal) &&
               lhs.line == rhs.line &&
               lhs.column == rhs.column
    }

    // MARK: - Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(lexeme)
        // Note: Hashing `Any?` directly can be problematic.
        // For simplicity here, we might rely on type and lexeme for primary hashing
        // or implement more robust Any? hashing if literals are diverse and critical for uniqueness.
        if let literalValue = literal as? AnyHashable {
            hasher.combine(literalValue)
        }
        hasher.combine(line)
        hasher.combine(column)
    }
}

/// Helper to compare `Any?` for Equatable conformance.
private func areEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil):
        return true
    case (let l as String, let r as String):
        return l == r
    case (let l as Int, let r as Int):
        return l == r
    case (let l as Double, let r as Double):
        return l == r
    case (let l as Bool, let r as Bool):
        return l == r
    // Add more types as needed for literals
    default:
        return false
    }
}

/// Defines the various types of tokens that can appear in OuroLang.
public enum TokenType: Equatable, Hashable, CaseIterable {
    // MARK: - Single-character tokens
    case leftParen, rightParen   // ( )
    case leftBrace, rightBrace   // { }
    case leftBracket, rightBracket // [ ]
    case comma                   // ,
    case dot                     // .
    case colon                   // :
    case semicolon               // ;
    case questionMark            // ?

    // MARK: - One or two character tokens
    case minus, minusEqual       // - -=
    case plus, plusEqual         // + +=
    case slash, slashEqual       // / /=
    case star, starEqual         // * *=
    case percent, percentEqual   // % %=

    case bang, bangEqual         // ! !=
    case equal, equalEqual       // = ==
    case greater, greaterEqual   // > >=
    case less, lessEqual         // < <=

    case arrow                   // -> (e.g., for lambda or return type)
    case doubleDot               // .. (e.g., for ranges, exclusive)
    case tripleDot               // ... (e.g., for ranges, inclusive, or varargs)

    // MARK: - Literals
    case identifier
    case string
    case integer
    case float
    case char

    // MARK: - Keywords
    // Types & Declarations
    case `class`
    case `struct`
    case `enum`
    case `interface`
    case `var`
    case `const` // or `let` if Ouro prefers
    case `func` // or `def`, `method`
    case `init`
    case `extension`
    case `typealias`
    case `protocol` // if Ouro uses this term for interfaces

    // Control Flow
    case `if`, `else`
    case `switch`, `case`, `default`
    case `for`, `in`
    case `while`, `do` // `do-while` might need separate handling or be `repeat-while`
    case `break`, `continue`
    case `return`
    case `throw`, `throws`, `rethrows`
    case `try`, `catch`, `finally`

    // Boolean & Null
    case `true`, `false`
    case `null` // or `nil`

    // Access Modifiers & Other Modifiers
    case `public`, `private`, `protected`, `internal`, `fileprivate`
    case `static`
    case `final`
    case `abstract` // if applicable
    case `sealed`   // if applicable
    case `override`
    case `lazy`
    case `async`, `await`
    case `get`, `set`, `willSet`, `didSet` // For properties

    // Operators as keywords (if any, e.g., 'is', 'as')
    case `is`, `as` // `as?`, `as!` might be handled by `as` + `?` or `!` tokens

    // Inheritance & Implementation
    case `extends`
    case `implements`
    case `super`, `this` // `this` might be `self`

    // Modules & Imports
    case `import`, `package`, `module`

    // MARK: - Special
    case eof // End Of File
    case unknown // For unrecognized characters/sequences

    // Add more as OuroLang's syntax is defined
}

// Convenience for debugging and LSP
extension Token: CustomStringConvertible {
    public var description: String {
        var desc = "\(type)(\"\(lexeme)\""
        if let literal = literal {
            desc += ", lit: \(literal)"
        }
        desc += " @ L\(line):C\(column))"
        return desc
    }
}
