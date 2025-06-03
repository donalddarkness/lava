import XCTest
@testable import OuroLangCore

final class ParserTests: XCTestCase {
    func testWhileLoopInFunction() throws {
        let source = "func foo() { while (x < 10) x = x + 1; }"
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        let parser = Parser(tokens: tokens)
        let decls = try parser.parse()
        XCTAssertEqual(decls.count, 1)
        guard let funcDecl = decls[0] as? FunctionDecl else {
            XCTFail("Expected FunctionDecl")
            return
        }
        let stmt = funcDecl.body.statements.first
        XCTAssertTrue(stmt is WhileStmt)
    }

    func testForLoopInFunction() throws {
        let source = "func foo() { for (var i = 0; i < 5; i = i + 1) { } }"
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        let parser = Parser(tokens: tokens)
        let decls = try parser.parse()
        XCTAssertEqual(decls.count, 1)
        let funcDecl = decls[0] as! FunctionDecl
        let stmt = funcDecl.body.statements.first
        XCTAssertTrue(stmt is ForStmt)
    }

    func testClassDeclaration() throws {
        let source = "class A: B, C { var x: Int; func f() {} }"
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        let parser = Parser(tokens: tokens)
        let decls = try parser.parse()
        XCTAssertEqual(decls.count, 1)
        let classDecl = decls[0] as! ClassDecl
        XCTAssertEqual(classDecl.name.text, "A")
        XCTAssertEqual(classDecl.superclass?.name.text, "B")
        XCTAssertEqual(classDecl.interfaces.map { $0.name.text }, ["C"])
        XCTAssertEqual(classDecl.properties.count, 1)
        XCTAssertEqual(classDecl.methods.count, 1)
    }

    func testStructDeclaration() throws {
        let source = "struct S: I1, I2 { var y = 2; func g() {} }"
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        let parser = Parser(tokens: tokens)
        let decls = try parser.parse()
        XCTAssertEqual(decls.count, 1)
        let structDecl = decls[0] as! StructDecl
        XCTAssertEqual(structDecl.name.text, "S")
        XCTAssertEqual(structDecl.interfaces.map { $0.name.text }, ["I1", "I2"])
        XCTAssertEqual(structDecl.properties.count, 1)
        XCTAssertEqual(structDecl.methods.count, 1)
    }

    func testEnumDeclaration() throws {
        let source = "enum E { Case1; Case2 = 5; func h() {} }"
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        let parser = Parser(tokens: tokens)
        let decls = try parser.parse()
        XCTAssertEqual(decls.count, 1)
        let enumDecl = decls[0] as! EnumDecl
        XCTAssertEqual(enumDecl.name.text, "E")
        XCTAssertEqual(enumDecl.cases.map { $0.name.text }, ["Case1", "Case2"])
        XCTAssertEqual(enumDecl.methods.count, 1)
    }

    func testInterfaceDeclaration() throws {
        let source = "interface I { func k(); }"
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        let parser = Parser(tokens: tokens)
        let decls = try parser.parse()
        XCTAssertEqual(decls.count, 1)
        let interfaceDecl = decls[0] as! InterfaceDecl
        XCTAssertEqual(interfaceDecl.name.text, "I")
        XCTAssertEqual(interfaceDecl.methods.count, 1)
    }

    func testFunctionDeclaration() throws {
        let source = "func add(a: Int, b: Int) -> Int { return a + b; }"
        let lexer = Lexer(source: source)
        let tokens = try lexer.scanTokens()
        let parser = Parser(tokens: tokens)
        let decls = try parser.parse()
        XCTAssertEqual(decls.count, 1)
        let funcDecl = decls[0] as! FunctionDecl
        XCTAssertEqual(funcDecl.name.text, "add")
        XCTAssertEqual(funcDecl.params.count, 2)
        XCTAssertEqual(funcDecl.returnType.map { ($0 as! NamedType).name.text }, "Int")
    }
} 