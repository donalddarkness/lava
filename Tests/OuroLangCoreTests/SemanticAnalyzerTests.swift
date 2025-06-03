import Foundation
import XCTest

@testable import OuroLangCore

/// Tests for the semantic analysis phase in the OuroLang compiler
final class SemanticAnalyzerTests: XCTestCase {
    
    func testTypeCheckerInitialization() {
        let typeChecker = TypeChecker()
        XCTAssertNotNil(typeChecker)
        
        // Test that primitive types are registered
        let symbolTable = SymbolTable()
        let typeResolver = TypeResolver()
        let intType = typeResolver.resolveType("Int")
        XCTAssertNotNil(intType)
        XCTAssertEqual(intType?.mlirType, "i32")
    }
    
    func testSymbolLookup() throws {
        let typeChecker = TypeChecker()
        let symbolTable = SymbolTable()
        
        // Define a simple type and verify it can be looked up
        let type = TypeDefinition(
            name: "TestType",
            isInterface: false,
            isAbstract: false, 
            isSealed: false,
            isPrimitive: false,
            line: 1,
            column: 1
        )
        
        try symbolTable.define(type)
        let resolved = symbolTable.resolveType("TestType")
        XCTAssertNotNil(resolved)
        XCTAssertEqual(resolved?.name, "TestType")
    }
    
    func testBasicTypeChecking() throws {
        let typeChecker = TypeChecker()
        
        // Create a simple variable declaration and check it
        let source = "var x: Int = 42;"
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        let parser = Parser(tokens: tokens)
        let declarations = try parser.parse()
        
        let errors = try await typeChecker.check(declarations)
        XCTAssertTrue(errors.isEmpty)
    }
    
    func testTypeErrors() throws {
        let typeChecker = TypeChecker()
        
        // Test type mismatch error detection
        let source = "var x: String = 42;"  // Type error: assigning Int to String
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        let parser = Parser(tokens: tokens)
        let declarations = try parser.parse()
        
        let errors = try await typeChecker.check(declarations)
        XCTAssertFalse(errors.isEmpty)
        XCTAssertEqual(errors.count, 1)
        
        // Check that it's a type mismatch error
        if let typeMismatchError = errors.first as? SymbolError,
           case .typeMismatch(let expected, let got, _, _) = typeMismatchError {
            XCTAssertEqual(expected, "String")
            XCTAssertEqual(got, "Int")
        } else {
            XCTFail("Expected type mismatch error")
        }
    }
    
    func testFunctionTypeChecking() throws {
        let typeChecker = TypeChecker()
        
        // Test function declaration and return type checking
        let source = """
        func add(a: Int, b: Int) -> Int {
            return a + b;
        }
        """
        
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        let parser = Parser(tokens: tokens)
        let declarations = try parser.parse()
        
        let errors = try await typeChecker.check(declarations)
        XCTAssertTrue(errors.isEmpty)
    }
    
    func testClassInheritance() throws {
        let typeChecker = TypeChecker()
        
        // Test class inheritance and method overriding
        let source = """
        class Base {
            func method() -> Int { return 0; }
        }
        
        class Derived: Base {
            func method() -> Int { return 1; }
        }
        """
        
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        let parser = Parser(tokens: tokens)
        let declarations = try parser.parse()
        
        let errors = try await typeChecker.check(declarations)
        XCTAssertTrue(errors.isEmpty)
    }
}