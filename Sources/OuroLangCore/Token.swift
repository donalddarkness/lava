//
//  Token.swift
//  OuroLangCore
//
//  Created by YourName on TodayDate.
//

import Foundation

/// Represents a lexical token in the OuroLang source code.
public struct Token: Equatable, Hashable, Sendable {
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
public enum TokenType: Equatable, Hashable, CaseIterable, Sendable {
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
    case less, lessEqual         // < <=    case arrow                   // -> (e.g., for lambda or return type)
    case doubleArrow             // => (e.g., for lambda expression body)
    case doubleDot               // .. (e.g., for ranges, exclusive)
    case tripleDot               // ... (e.g., for ranges, inclusive, or varargs)
    case nullCoalescing          // ?? (null coalescing operator)
    case nullCoalescingEqual     // ??= (null coalescing assignment)
    case spaceship               // <=> (spaceship comparison operator)
    case doubleColon             // :: (method reference operator)
    
    // Bitwise operators
    case bitwiseAnd, bitwiseAndEqual     // & &=
    case bitwiseOr, bitwiseOrEqual       // | |=
    case bitwiseXor, bitwiseXorEqual     // ^ ^=
    case bitwiseNot                      // ~ (bitwise NOT)
    case leftShift, leftShiftEqual       // << <<=
    case rightShift, rightShiftEqual     // >> >>=
    case unsignedRightShift, unsignedRightShiftEqual // >>> >>>=
    
    // Power operator
    case power, powerEqual               // ** **=

    // MARK: - Literals
    case identifier
    case string
    case integer
    case float
    case char
    case binaryInteger           // 0b prefix (binary)
    case hexInteger              // 0x prefix (hexadecimal)
    case octalInteger            // 0o prefix (octal)

    // MARK: - Keywords
    // Types & Declarations
    case `class`, `struct`, `enum`, `interface`
    case `var`, `const`, `func`, `init`
    case `extension`, `typealias`, `protocol`
    case `void`                  // Void return type
    
    // Control Flow
    case `if`, `else`, `switch`, `case`, `default`
    case `for`, `in`, `while`, `do`
    case `break`, `continue`, `return`
    
    // Error Handling
    case `throw`, `throws`, `rethrows`
    case `try`, `catch`, `finally`
    case `assert`                // Assertion keyword
    
    // Literals & Values
    case `true`, `false`, `null`
    
    // Access Control
    case `public`, `private`, `protected`, `internal`, `fileprivate`
    
    // Modifiers
    case `static`, `final`, `abstract`, `sealed`
    case `override`, `lazy`, `async`, `await`
    case `get`, `set`, `willSet`, `didSet`
    
    // Type Operations
    case `is`, `as`, `typeof`    // Type checking/conversion keywords
    
    // OOP Keywords
    case `extends`, `implements` // Inheritance keywords
    case `super`, `this`, `base` // References
    
    // Module Management
    case `import`, `package`, `module`
    
    // Other Flow Control
    case `yield`, `defer`        // Control flow keywords
    
    // New keywords from migration.md
    case `new`                   // Object instantiation
    
    // MARK: - Special
    case eof                     // End Of File
    case unknown                 // For unrecognized characters/sequences

    // Logical operators
    case and, or, not            // && || !
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
