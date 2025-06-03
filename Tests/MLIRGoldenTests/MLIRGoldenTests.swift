import XCTest
@testable import OuroLangCore
@testable import OuroCompiler
@testable import MLIRQuasiDSL

final class MLIRGoldenTests: XCTestCase {
    func testBasicFunction() throws {
        // Create a simple function AST by parsing source
        let source = "func test() { return; }"
        let tokens = try Lexer(source: source).scanTokens()
        let ast = try Parser(tokens: tokens).parse()
        let mlir = try MLIRCodeGenerator().emit(ast)

        let goldenPath = "Tests/MLIRGoldenTests/GOLDEN_BASIC.mlir"
        let expected = try String(contentsOfFile: goldenPath, encoding: .utf8)

        XCTAssertEqual(
            mlir.trimmingCharacters(in: .whitespacesAndNewlines),
            expected.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    func testDSLBasicFunction() {
        // Build MLIR using the QuasiMLIR DSL
        let mlir = MLIR.module {
            MLIR.funcOp(name: "test") {
                MLIR.ret()
            }
        }
        let goldenPath = "Tests/MLIRGoldenTests/GOLDEN_BASIC.mlir"
        let expected = try! String(contentsOfFile: goldenPath, encoding: .utf8)

        XCTAssertEqual(
            mlir.trimmingCharacters(in: .whitespacesAndNewlines),
            expected.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
} 