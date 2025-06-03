import XCTest
@testable import OuroLangCore

final class LexerTests: XCTestCase {
    func testEmptySource() throws {
        // Empty source should produce only EOF token
        let lexer = Lexer(source: "")
        let tokens = try lexer.scanTokens()
        
        XCTAssertEqual(tokens.count, 1)
        XCTAssertEqual(tokens[0].type, .eof)
    }
    
    func testSingleCharacterTokens() throws {
        let source = "(){},;."
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        
        // Expected tokens + EOF
        XCTAssertEqual(tokens.count, 8)
        XCTAssertEqual(tokens[0].type, .leftParen)
        XCTAssertEqual(tokens[1].type, .rightParen)
        XCTAssertEqual(tokens[2].type, .leftBrace)
        XCTAssertEqual(tokens[3].type, .rightBrace)
        XCTAssertEqual(tokens[4].type, .comma)
        XCTAssertEqual(tokens[5].type, .semicolon)
        XCTAssertEqual(tokens[6].type, .dot)
        XCTAssertEqual(tokens[7].type, .eof)
    }
    
    func testMultiCharacterOperators() throws {
        let source = "== != <= >= += -= *= /="
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        
        // Expected tokens + EOF
        XCTAssertEqual(tokens.count, 9)
        XCTAssertEqual(tokens[0].type, .equalEqual)
        XCTAssertEqual(tokens[1].type, .bangEqual)
        XCTAssertEqual(tokens[2].type, .lessEqual)
        XCTAssertEqual(tokens[3].type, .greaterEqual)
        XCTAssertEqual(tokens[4].type, .plusEqual)
        XCTAssertEqual(tokens[5].type, .minusEqual)
        XCTAssertEqual(tokens[6].type, .starEqual)
        XCTAssertEqual(tokens[7].type, .slashEqual)
        XCTAssertEqual(tokens[8].type, .eof)
    }
    
    func testRangeDots() throws {
        let source = ".. ..."
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        
        XCTAssertEqual(tokens.count, 3)
        XCTAssertEqual(tokens[0].type, .doubleDot)
        XCTAssertEqual(tokens[1].type, .tripleDot)
        XCTAssertEqual(tokens[2].type, .eof)
    }
    
    func testKeywords() throws {
        let source = "class struct enum interface var const func if else while for return true false null"
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        
        // Expected tokens + EOF
        XCTAssertEqual(tokens.count, 16)
        XCTAssertEqual(tokens[0].type, .class)
        XCTAssertEqual(tokens[1].type, .struct)
        XCTAssertEqual(tokens[2].type, .enum)
        XCTAssertEqual(tokens[3].type, .interface)
        XCTAssertEqual(tokens[4].type, .var)
        XCTAssertEqual(tokens[5].type, .const)
        XCTAssertEqual(tokens[6].type, .func)
        XCTAssertEqual(tokens[7].type, .if)
        XCTAssertEqual(tokens[8].type, .else)
        XCTAssertEqual(tokens[9].type, .while)
        XCTAssertEqual(tokens[10].type, .for)
        XCTAssertEqual(tokens[11].type, .return)
        XCTAssertEqual(tokens[12].type, .true)
        XCTAssertEqual(tokens[13].type, .false)
        XCTAssertEqual(tokens[14].type, .null)
        XCTAssertEqual(tokens[15].type, .eof)
    }
    
    func testIdentifiers() throws {
        let source = "firstName _count x123"
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        
        // Expected tokens + EOF
        XCTAssertEqual(tokens.count, 4)
        
        XCTAssertEqual(tokens[0].type, .identifier)
        XCTAssertEqual(tokens[0].lexeme, "firstName")
        XCTAssertEqual(tokens[0].literal as? String, "firstName")
        
        XCTAssertEqual(tokens[1].type, .identifier)
        XCTAssertEqual(tokens[1].lexeme, "_count")
        XCTAssertEqual(tokens[1].literal as? String, "_count")
        
        XCTAssertEqual(tokens[2].type, .identifier)
        XCTAssertEqual(tokens[2].lexeme, "x123")
        XCTAssertEqual(tokens[2].literal as? String, "x123")
        
        XCTAssertEqual(tokens[3].type, .eof)
    }
    
    func testStringLiterals() throws {
        let source = "\"Hello, world!\" \"Line 1\\nLine 2\" \"Quote: \\\"\""
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        
        // Expected tokens + EOF
        XCTAssertEqual(tokens.count, 4)
        
        XCTAssertEqual(tokens[0].type, .string)
        XCTAssertEqual(tokens[0].literal as? String, "Hello, world!")
        
        XCTAssertEqual(tokens[1].type, .string)
        XCTAssertEqual(tokens[1].literal as? String, "Line 1\nLine 2")
        
        XCTAssertEqual(tokens[2].type, .string)
        XCTAssertEqual(tokens[2].literal as? String, "Quote: \"")
        
        XCTAssertEqual(tokens[3].type, .eof)
    }
    
    func testCharLiterals() throws {
        let source = "'a' '\\n' '\\'' '\"'"
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        
        // Expected tokens + EOF
        XCTAssertEqual(tokens.count, 5)
        
        XCTAssertEqual(tokens[0].type, .char)
        XCTAssertEqual(tokens[0].literal as? Character, "a")
        
        XCTAssertEqual(tokens[1].type, .char)
        XCTAssertEqual(tokens[1].literal as? Character, "\n")
        
        XCTAssertEqual(tokens[2].type, .char)
        XCTAssertEqual(tokens[2].literal as? Character, "'")
        
        XCTAssertEqual(tokens[3].type, .char)
        XCTAssertEqual(tokens[3].literal as? Character, "\"")
        
        XCTAssertEqual(tokens[4].type, .eof)
    }
    
    func testNumberLiterals() throws {
        let source = "123 3.14 0xFF 0b101 1.5e2"
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        
        // Expected tokens + EOF
        XCTAssertEqual(tokens.count, 6)
        
        XCTAssertEqual(tokens[0].type, .integer)
        XCTAssertEqual(tokens[0].literal as? Int, 123)
        
        XCTAssertEqual(tokens[1].type, .float)
        XCTAssertEqual(tokens[1].literal as? Double, 3.14)
        
        XCTAssertEqual(tokens[2].type, .integer)
        XCTAssertEqual(tokens[2].literal as? Int, 255) // 0xFF = 255
        
        XCTAssertEqual(tokens[3].type, .integer)
        XCTAssertEqual(tokens[3].literal as? Int, 5) // 0b101 = 5
        
        XCTAssertEqual(tokens[4].type, .float)
        XCTAssertEqual(tokens[4].literal as? Double, 150.0) // 1.5e2 = 150
        
        XCTAssertEqual(tokens[5].type, .eof)
    }
    
    func testComments() throws {
        let source = """
        // This is a single-line comment
        123 // Another comment
        /* This is a
           multi-line comment */
        456
        """
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        
        // Expected tokens + EOF
        XCTAssertEqual(tokens.count, 3)
        
        XCTAssertEqual(tokens[0].type, .integer)
        XCTAssertEqual(tokens[0].literal as? Int, 123)
        
        XCTAssertEqual(tokens[1].type, .integer)
        XCTAssertEqual(tokens[1].literal as? Int, 456)
        
        XCTAssertEqual(tokens[2].type, .eof)
    }
    
    func testMixedSource() throws {
        let source = """
        class Example {
            var count = 10;
            
            func increment() {
                count += 1;
                return count;
            }
        }
        """
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        
        // We're just checking that the lexer doesn't throw an error
        // and produces the expected number of tokens
        XCTAssertEqual(tokens.count, 21) // 20 tokens + EOF
    }
    
    func testLineAndColumnTracking() throws {
        let source = """
        var x = 10;
        x += 5;
        """
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        
        XCTAssertEqual(tokens[0].line, 1) // var
        XCTAssertEqual(tokens[0].column, 1)
        
        XCTAssertEqual(tokens[1].line, 1) // x
        XCTAssertEqual(tokens[1].column, 5)
        
        XCTAssertEqual(tokens[6].line, 2) // x
        XCTAssertEqual(tokens[6].column, 1)
        
        XCTAssertEqual(tokens[7].line, 2) // +=
        XCTAssertEqual(tokens[7].column, 3)
    }
    
    func testErrorHandling() {
        // Test unterminated string
        do {
            let lexer = Lexer(source: "\"unterminated")
            _ = try lexer.scanTokens()
            XCTFail("Expected lexer to throw an error for unterminated string")
        } catch is LexerError {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Test unterminated char
        do {
            let lexer = Lexer(source: "'")
            _ = try lexer.scanTokens()
            XCTFail("Expected lexer to throw an error for unterminated character literal")
        } catch is LexerError {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Test invalid escape sequence
        do {
            let lexer = Lexer(source: "\"\\z\"")
            _ = try lexer.scanTokens()
            XCTFail("Expected lexer to throw an error for invalid escape sequence")
        } catch is LexerError {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Test unterminated multi-line comment
        do {
            let lexer = Lexer(source: "/* unterminated")
            _ = try lexer.scanTokens()
            XCTFail("Expected lexer to throw an error for unterminated multi-line comment")
        } catch is LexerError {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testEdgeCaseTokens() {
        // Add tests for edge-case tokens
    }

    func testUnicodeSupport() {
        // Add tests for unicode handling
    }

    func testMultiLineStrings() {
        // Add tests for multi-line strings
    }
}