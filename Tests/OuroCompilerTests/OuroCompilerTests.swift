import XCTest
@testable import OuroCompiler

final class OuroCompilerTests: XCTestCase {
    func testParseArguments_NoInputFile_ThrowsNoInputFile() {
        var args = ["swift", ]
        XCTAssertThrowsError(try parseArguments()) { error in
            if let compilerError = error as? CompilerError {
                XCTAssertEqual(compilerError, .noInputFile)
            } else {
                XCTFail("Expected CompilerError.noInputFile, got \(error)")
            }
        }
    }

    func testParseArguments_UnknownOption_ThrowsCompileError() {
        XCTAssertThrowsError(try parseArguments(['-x'])) { error in
            if case CompilerError.compileError(let message) = error {
                XCTAssertTrue(message.contains("Unknown option"))
            } else {
                XCTFail("Expected compileError, got \(error)")
            }
        }
    }

    // Additional tests for help and version flags, target and output parsing can be added here
} 