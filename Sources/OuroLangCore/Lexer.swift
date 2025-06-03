//
//  Lexer.swift
//  OuroLangCore
//
//  Created by YourName on TodayDate.
//

import Foundation

/// The Lexer (also known as Scanner or Tokenizer) for OuroLang.
/// It takes a string of source code and converts it into a sequence of tokens.
/// Error types that can occur during lexical analysis.
public enum LexerError: Error, CustomStringConvertible {
    case unexpectedCharacter(Character, line: Int, column: Int)
    case unterminatedString(line: Int, column: Int)
    case unterminatedCharLiteral(line: Int, column: Int)
    case unterminatedMultilineComment(line: Int, column: Int)
    case invalidEscapeSequence(String, line: Int, column: Int)
    case invalidNumber(line: Int, column: Int)
    case invalidCharLiteral(line: Int, column: Int)
    
    public var description: String {
        switch self {
        case .unexpectedCharacter(let char, let line, let column):
            return "Unexpected character '\(char)' at line \(line), column \(column)"
        case .unterminatedString(let line, let column):
            return "Unterminated string at line \(line), column \(column)"
        case .unterminatedCharLiteral(let line, let column):
            return "Unterminated character literal at line \(line), column \(column)"
        case .unterminatedMultilineComment(let line, let column):
            return "Unterminated multi-line comment starting at line \(line), column \(column)"
        case .invalidEscapeSequence(let sequence, let line, let column):
            return "Invalid escape sequence '\\\(sequence)' at line \(line), column \(column)"
        case .invalidNumber(let line, let column):
            return "Invalid number at line \(line), column \(column)"
        case .invalidCharLiteral(let line, let column):
            return "Invalid character literal at line \(line), column \(column)"
        }
    }
    
}

public class Lexer {
    // MARK: - Helper Methods
    
    /// Advances to the next character in the source and returns the current one.
    private func advance() -> Character {
        let char = source[currentIndex]
        currentIndex = source.index(after: currentIndex)
        column += 1
        return char
    }
    
    /// Returns the current character without advancing.
    private func peek() -> Character {
        if isAtEnd() {
            return "\0" // Null character to represent EOF
        }
        return source[currentIndex]
    }
    
    /// Returns the next character (one after current) without advancing.
    private func peekNext() -> Character {
        let nextIndex = source.index(after: currentIndex)
        if nextIndex >= source.endIndex {
            return "\0" // Null character to represent EOF
        }
        return source[nextIndex]
    }
    
    /// Checks if the current character matches the expected one, and advances if it does.
    private func match(_ expected: Character) -> Bool {
        if isAtEnd() || source[currentIndex] != expected {
            return false
        }
        
        currentIndex = source.index(after: currentIndex)
        column += 1
        return true
    }
    
    /// Determines if the given character is a digit (0-9).
    private func isDigit(_ char: Character) -> Bool {
        return char >= "0" && char <= "9"
    }
    
    /// Determines if the given character is a letter (a-z, A-Z) or underscore.
    private func isAlpha(_ char: Character) -> Bool {
        return (char >= "a" && char <= "z") ||
               (char >= "A" && char <= "Z") ||
               char == "_"
    }
    
    /// Determines if the given character is alphanumeric (a-z, A-Z, 0-9) or underscore.
    private func isAlphaNumeric(_ char: Character) -> Bool {
        return isAlpha(char) || isDigit(char)
    }
    
    /// Adds a token with the specified type.
    private func addToken(type: TokenType, literal: Any? = nil) {
        let lexeme = String(source[startIndex..<currentIndex])
        tokens.append(Token(type: type, lexeme: lexeme, literal: literal, line: line, column: column - lexeme.count))
    }
    private let source: String
    private var tokens: [Token] = []

    private var startIndex: String.Index
    private var currentIndex: String.Index
    private var line: Int = 1
    private var column: Int = 1

    // Map keywords to their token types
    // This should be populated based on OuroLang's reserved keywords
    // from the `migration.md` (OuroLang Syntax Documentation).
    private static let keywords: [String: TokenType] = [
        "class": .class, "struct": .struct, "enum": .enum, "interface": .interface,
        "var": .var, "const": .const, "func": .func, "init": .init,
        "extension": .extension, "typealias": .typealias, "protocol": .protocol,
        "if": .if, "else": .else, "switch": .switch, "case": .case, "default": .default,
        "for": .for, "in": .in, "while": .while, "do": .do,
        "break": .break, "continue": .continue, "return": .return,
        "throw": .throw, "throws": .throws, "rethrows": .rethrows,
        "try": .try, "catch": .catch, "finally": .finally,
        "true": .true, "false": .false, "null": .null,
        "public": .public, "private": .private, "protected": .protected,
        "internal": .internal, "fileprivate": .fileprivate,
        "static": .static, "final": .final, "abstract": .abstract, "sealed": .sealed,
        "override": .override, "lazy": .lazy, "async": .async, "await": .await,
        "get": .get, "set": .set, "willSet": .willSet, "didSet": .didSet,
        "is": .is, "as": .as,
        "extends": .extends, "implements": .implements,
        "super": .super, "this": .this, // or "self"
        "import": .import, "package": .package, "module": .module,
        "yield": .yield, "defer": .defer // New keywords added
        // Add all keywords from OuroLang Syntax Documentation
    ]

    public init(source: String) {
        self.source = source
        self.startIndex = source.startIndex
        self.currentIndex = source.startIndex
    }

    /// Scans the source code and returns a list of tokens.
    public func scanTokens() throws -> [Token] {
        tokens = [] // Reset tokens if called multiple times
        startIndex = source.startIndex
        currentIndex = source.startIndex
        line = 1
        column = 1
        
        while !isAtEnd() {
            startIndex = currentIndex
            try scanToken()
        }

        tokens.append(Token(type: .eof, lexeme: "", literal: nil, line: line, column: column))
        return tokens
    }

    private func isAtEnd() -> Bool {
        return currentIndex >= source.endIndex
    }
    
    // MARK: - Token Handling Methods
    
    private func skipMultilineComment() throws {
        var nesting = 1
        while nesting > 0 {
            if isAtEnd() {
                throw LexerError.unterminatedMultilineComment(line: line, column: column)
            }
            
            let char = advance()
            
            if char == "\n" {
                line += 1
                column = 1
            }
            
            if char == "/" && peek() == "*" {
                advance()
                nesting += 1
            } else if char == "*" && peek() == "/" {
                advance()
                nesting -= 1
            }
        }
    }
    
    private func string() throws {
        // Note: This handles double-quoted strings
        let startLine = line
        let startColumn = column
        
        while peek() != "\"" && !isAtEnd() {
            if peek() == "\n" {
                line += 1
                column = 1
            }
            if peek() == "\\" && peekNext() == "\"" {
                // Skip escaped quote
                advance() // the backslash
                advance() // the quote
            } else {
                advance()
            }
        }
        
        if isAtEnd() {
            throw LexerError.unterminatedString(line: startLine, column: startColumn)
        }
        
        // Consume the closing "
        advance()
        
        // Get the string value without the quotes
        let value = String(source[source.index(after: startIndex)..<source.index(before: currentIndex)])
        
        // Process escape sequences
        let processedValue = try processEscapeSequences(value)
        
        addToken(type: .string, literal: processedValue)
    }
    
    private func charLiteral() throws {
        // Character literals are enclosed in single quotes: 'a'
        let startLine = line
        let startColumn = column
        
        // Handle escaped characters
        if peek() == "\\" {
            advance() // Skip backslash
            if isAtEnd() {
                throw LexerError.unterminatedCharLiteral(line: startLine, column: startColumn)
            }
            
            // Handle the escaped character
            let escapedChar = advance()
            
            if peek() != "'" {
                throw LexerError.invalidCharLiteral(line: line, column: column)
            }
            
            advance() // Consume the closing quote
            
            let value: Character
            switch escapedChar {
            case "n": value = "\n"
            case "t": value = "\t"
            case "r": value = "\r"
            case "\\": value = "\\"
            case "'": value = "'"
            case "\"": value = "\""
            case "0": value = "\0"
            // Add more escape sequences as needed
            default: throw LexerError.invalidEscapeSequence(String(escapedChar), line: line, column: column)
            }
            
            addToken(type: .char, literal: value)
        } else {
            // Regular character
            if isAtEnd() {
                throw LexerError.unterminatedCharLiteral(line: startLine, column: startColumn)
            }
            
            let value = advance()
            
            if isAtEnd() || peek() != "'" {
                throw LexerError.unterminatedCharLiteral(line: line, column: column)
            }
            
            advance() // Consume the closing quote
            
            addToken(type: .char, literal: value)
        }
    }
    
    private func processEscapeSequences(_ str: String) throws -> String {
        var result = ""
        var index = str.startIndex
        
        while index < str.endIndex {
            let char = str[index]
            
            if char == "\\" && index < str.index(before: str.endIndex) {
                // Handle escape sequence
                let nextChar = str[str.index(after: index)]
                switch nextChar {
                case "n": result.append("\n")
                case "t": result.append("\t")
                case "r": result.append("\r")
                case "\\": result.append("\\")
                case "\"": result.append("\"")
                case "'": result.append("'")
                case "0": result.append("\0")
                // Add more escape sequences as needed
                default: throw LexerError.invalidEscapeSequence(String(nextChar), line: line, column: column)
                }
                
                // Skip both the backslash and the escaped character
                index = str.index(index, offsetBy: 2)
            } else {
                result.append(char)
                index = str.index(after: index)
            }
        }
        
        return result
    }
    
    private func number() throws {
        // Handle integer and floating-point numbers
        while isDigit(peek()) { advance() }
        
        // Check for decimal point followed by digits
        if peek() == "." && isDigit(peekNext()) {
            // Consume the "."
            advance()
            
            // Consume fractional part
            while isDigit(peek()) { advance() }
            
            // Check for scientific notation (e.g., 1.23e-45)
            if peek().lowercased() == "e" {
                advance() // Consume 'e' or 'E'
                
                // Optional sign
                if peek() == "+" || peek() == "-" {
                    advance()
                }
                
                // Must have at least one digit after 'e'
                if !isDigit(peek()) {
                    throw LexerError.invalidNumber(line: line, column: column)
                }
                
                while isDigit(peek()) { advance() }
            }
            
            // Extract the value
            let valueStr = String(source[startIndex..<currentIndex])
            if let value = Double(valueStr) {
                addToken(type: .float, literal: value)
            } else {
                throw LexerError.invalidNumber(line: line, column: column)
            }
        } else {
            // Integer value
            // Check for hex, binary, or octal notation
            let valueStr = String(source[startIndex..<currentIndex])
            if valueStr.hasPrefix("0x") || valueStr.hasPrefix("0X") {
                // Hexadecimal
                if valueStr.count <= 2 {
                    throw LexerError.invalidNumber(line: line, column: column)
                }
                if let value = Int(valueStr.dropFirst(2), radix: 16) {
                    addToken(type: .integer, literal: value)
                } else {
                    throw LexerError.invalidNumber(line: line, column: column)
                }
            } else if valueStr.hasPrefix("0b") || valueStr.hasPrefix("0B") {
                // Binary
                if valueStr.count <= 2 {
                    throw LexerError.invalidNumber(line: line, column: column)
                }
                if let value = Int(valueStr.dropFirst(2), radix: 2) {
                    addToken(type: .integer, literal: value)
                } else {
                    throw LexerError.invalidNumber(line: line, column: column)
                }
            } else if valueStr.hasPrefix("0") && valueStr.count > 1 {
                // Octal
                if let value = Int(valueStr.dropFirst(1), radix: 8) {
                    addToken(type: .integer, literal: value)
                } else {
                    throw LexerError.invalidNumber(line: line, column: column)
                }
            } else {
                // Decimal
                if let value = Int(valueStr) {
                    addToken(type: .integer, literal: value)
                } else {
                    throw LexerError.invalidNumber(line: line, column: column)
                }
            }
        }
    }
    
    private func identifier() {
        while isAlphaNumeric(peek()) { advance() }
        
        // Check if it's a keyword
        let text = String(source[startIndex..<currentIndex])
        let type = Lexer.keywords[text] ?? .identifier
        
        addToken(type: type, literal: text)
    }

    private func scanToken() throws {
        let char = advance()
        
        switch char {
        // Single-character tokens
        case "(": addToken(type: .leftParen)
        case ")": addToken(type: .rightParen)
        case "{": addToken(type: .leftBrace)
        case "}": addToken(type: .rightBrace)
        case "[": addToken(type: .leftBracket)
        case "]": addToken(type: .rightBracket)
        case ",": addToken(type: .comma)
        case ".":
            if match(".") { // Check for .. or ...
                if match(".") {
                    addToken(type: .tripleDot)
                } else {
                    addToken(type: .doubleDot)
                }
            } else {
                addToken(type: .dot)
            }
        case ":": addToken(type: .colon)
        case ";": addToken(type: .semicolon)
        case "?": addToken(type: .questionMark)

        // One or two character tokens
        case "-": addToken(type: match("=") ? .minusEqual : (match(">") ? .arrow : .minus))
        case "+": addToken(type: match("=") ? .plusEqual : .plus)
        case "*": addToken(type: match("=") ? .starEqual : .star)
        case "%": addToken(type: match("=") ? .percentEqual : .percent)

        case "!": addToken(type: match("=") ? .bangEqual : .bang)
        case "=": addToken(type: match("=") ? .equalEqual : .equal)
        case "<": addToken(type: match("=") ? .lessEqual : .less)
        case ">": addToken(type: match("=") ? .greaterEqual : .greater)

        case "/":
            if match("/") { // Single-line comment
                while peek() != "\n" && !isAtEnd() { advance() }
            } else if match("*") { // Multi-line comment
                try skipMultilineComment()
            } else if match("=") {
                addToken(type: .slashEqual)
            } else {
                addToken(type: .slash)
            }
            
        case "\"": try string() // Handle string literals
        
        case "\'": try charLiteral() // Handle character literals
            
        // Handle whitespace
        case " ", "\r", "\t":
            // Just ignore these
            break
            
        case "\n":
            line += 1
            column = 1 // Reset column on new line
            break
            
        default:
            if isDigit(char) {
                try number()
            } else if isAlpha(char) {
                identifier()
            } else {
                throw LexerError.unexpectedCharacter(char, line: line, column: column)
            }
        }
    }
}