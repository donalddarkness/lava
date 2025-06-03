import XCTest
@testable import LavaLSP

final class LavaLSPTests: XCTestCase {
    func testServerInitialization() {
        let server = LavaLanguageServer.shared
        XCTAssertNotNil(server, "LavaLanguageServer.shared should not be nil")
    }

    func testHandleInvalidMessage_ReturnsErrorResponse() throws {
        // Provide an invalid JSON-RPC message
        let message: [String: Any] = ["id": 1]
        let response = LavaLanguageServer.shared.handleMessage(message)
        // Expect an error response due to missing method or params
        XCTAssertNotNil(response["error"], "Expected error in response for invalid message")
    }

    func testInitializeRequest() {
        // Simulate textDocument/initialize request and verify response
    }

    func testCompletionRequest() {
        // Simulate textDocument/completion request and verify response
    }

    func testHoverRequest() {
        // Simulate textDocument/hover request and verify response
    }

    // Additional tests for initialization, initialize request, completion, hover, and diagnostics can be added here
} 