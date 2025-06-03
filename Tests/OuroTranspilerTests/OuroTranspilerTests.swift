import XCTest
@testable import OuroTranspiler

final class OuroTranspilerTests: XCTestCase {
    func testParseArguments_NoInputFile_ThrowsNoInputFile() {
        XCTAssertThrowsError(try parseArguments()) { error in
            if let transpilerError = error as? TranspilerError {
                XCTAssertEqual(transpilerError, .noInputFile)
            } else {
                XCTFail("Expected TranspilerError.noInputFile, got \(error)")
            }
        }
    }

    func testParseArguments_UnknownOption_ThrowsTranspileError() {
        XCTAssertThrowsError(try parseArguments(['-z'])) { error in
            if case TranspilerError.transpileError(let message) = error {
                XCTAssertTrue(message.contains("Unknown option"))
            } else {
                XCTFail("Expected TranspilerError.transpileError, got \(error)")
            }
        }
    }

    // Additional tests for help, version, target parsing, and source map flag can be added here
} 