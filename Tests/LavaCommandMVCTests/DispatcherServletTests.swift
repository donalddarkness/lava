// [@Tests](@file:lava/Tests)
import Testing
import XCTest

@testable import Lava

/// Tests for the Spring MVC-like DispatcherServlet implementation
///
/// These tests verify the core functionality of handler registration, middleware
/// execution, and response processing in the MVC framework
final class DispatcherServletTests: XCTestCase {

    private var servlet: DispatcherServlet!
    private var testPath = "/test"
    private var nonExistentPath = "/nonexistent"

    override func setUp() {
        super.setUp()
        servlet = DispatcherServlet()
    }

    override func tearDown() {
        servlet = nil
        super.tearDown()
    }

    /// Tests basic handler registration and request execution
    func testHandlerRegistrationAndExecution() {
        // Register a simple handler
        servlet.registerHandler(path: testPath) { request in
            return HttpResponse(status: .ok, body: Data("Handler executed".utf8))
        }

        // Create and execute request
        let request = HttpRequest(method: .get, path: testPath)
        let response = servlet.handleRequest(request)

        // Verify response
        XCTAssertEqual(response.status, .ok, "Response status should be OK")
        XCTAssertEqual(
            String(data: response.body ?? Data(), encoding: .utf8),
            "Handler executed",
            "Response body should match handler output"
        )
        XCTAssertNil(response.contentType, "Content type should not be set by default")
    }

    /// Tests that middleware executes in the correct order
    func testMiddlewareExecutionOrder() {
        // Track execution order
        var executionOrder: [String] = []

        // Register first middleware
        servlet.registerMiddleware { request, next in
            executionOrder.append("middleware1_before")
            var modifiedRequest = request
            modifiedRequest.headers["Middleware1"] = "Executed"
            let response = next(modifiedRequest)
            executionOrder.append("middleware1_after")
            var modifiedResponse = response
            modifiedResponse.headers["Middleware1"] = "Executed"
            return modifiedResponse
        }

        // Register second middleware
        servlet.registerMiddleware { request, next in
            executionOrder.append("middleware2_before")
            var modifiedRequest = request
            modifiedRequest.headers["Middleware2"] = "Executed"
            let response = next(modifiedRequest)
            executionOrder.append("middleware2_after")
            var modifiedResponse = response
            modifiedResponse.headers["Middleware2"] = "Executed"
            return modifiedResponse
        }

        // Register handler
        servlet.registerHandler(path: testPath) { request in
            executionOrder.append("handler")
            // Verify middleware passed the expected headers
            XCTAssertEqual(
                request.headers["Middleware1"], "Executed", "First middleware should modify request"
            )
            XCTAssertEqual(
                request.headers["Middleware2"], "Executed",
                "Second middleware should modify request")
            return HttpResponse(status: .ok, body: Data("Handler executed".utf8))
        }

        // Execute request
        let request = HttpRequest(method: .get, path: testPath)
        let response = servlet.handleRequest(request)

        // Verify response
        XCTAssertEqual(response.status, .ok, "Response status should be OK")
        XCTAssertEqual(
            String(data: response.body ?? Data(), encoding: .utf8),
            "Handler executed",
            "Response body should match handler output"
        )
        XCTAssertEqual(
            response.headers["Middleware1"], "Executed",
            "First middleware should add header to response")
        XCTAssertEqual(
            response.headers["Middleware2"], "Executed",
            "Second middleware should add header to response")

        // Verify execution order: middleware1(before) -> middleware2(before) -> handler -> middleware2(after) -> middleware1(after)
        XCTAssertEqual(
            executionOrder,
            [
                "middleware1_before", "middleware2_before", "handler", "middleware2_after",
                "middleware1_after",
            ],
            "Middleware should execute in correct order with handler in the middle")
    }

    /// Tests handler for non-existent paths
    func testNotFoundHandler() {
        let request = HttpRequest(method: .get, path: nonExistentPath)
        let response = servlet.handleRequest(request)

        XCTAssertEqual(response.status, .notFound, "Response status should be Not Found")
        XCTAssertNotNil(response.body, "Response body should not be nil")
        XCTAssertTrue(
            String(data: response.body ?? Data(), encoding: .utf8)?.contains("Not Found") ?? false,
            "Response body should indicate resource not found"
        )
    }

    /// Tests different HTTP methods
    func testHttpMethodRouting() {
        // Register handlers for different HTTP methods
        servlet.registerHandler(path: "/get") { request in
            XCTAssertEqual(request.method, .get)
            return HttpResponse(status: .ok, body: Data("GET".utf8))
        }

        servlet.registerHandler(path: "/post") { request in
            XCTAssertEqual(request.method, .post)
            return HttpResponse(status: .created, body: Data("POST".utf8))
        }

        // Test GET request
        let getRequest = HttpRequest(method: .get, path: "/get")
        let getResponse = servlet.handleRequest(getRequest)
        XCTAssertEqual(getResponse.status, .ok)
        XCTAssertEqual(String(data: getResponse.body ?? Data(), encoding: .utf8), "GET")

        // Test POST request
        let postRequest = HttpRequest(method: .post, path: "/post")
        let postResponse = servlet.handleRequest(postRequest)
        XCTAssertEqual(postResponse.status, .created)
        XCTAssertEqual(String(data: postResponse.body ?? Data(), encoding: .utf8), "POST")
    }

    /// Tests query parameter handling
    func testQueryParameterHandling() {
        servlet.registerHandler(path: "/query") { request in
            // Verify query parameters
            let name = request.queryParam("name") ?? ""
            let age = request.queryParam("age") ?? "0"
            return HttpResponse(status: .ok, body: Data("Name: \(name), Age: \(age)".utf8))
        }

        let request = HttpRequest(
            method: .get,
            path: "/query",
            queryParams: ["name": "John", "age": "30"]
        )
        let response = servlet.handleRequest(request)

        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(
            String(data: response.body ?? Data(), encoding: .utf8), "Name: John, Age: 30")
    }

    /// Tests helper methods for creating responses
    func testResponseHelpers() {
        // Test JSON response
        let jsonData = ["name": "Test User", "id": 123]
        let jsonResponse = HttpResponse.json(jsonData)

        XCTAssertEqual(jsonResponse.status, .ok)
        XCTAssertEqual(jsonResponse.contentType, "application/json; charset=utf-8")
        XCTAssertNotNil(jsonResponse.body)

        // Test text response
        let textResponse = HttpResponse.text("Hello World", status: .created)

        XCTAssertEqual(textResponse.status, .created)
        XCTAssertEqual(textResponse.contentType, "text/plain; charset=utf-8")
        XCTAssertEqual(String(data: textResponse.body ?? Data(), encoding: .utf8), "Hello World")
    }
}

@Test
func testPathParameterExtraction() {
    let servlet = DispatcherServlet()

    servlet.registerHandler(path: "/users/{id}") { request in
        guard let id = request.pathParameters["id"] else {
            return HttpResponse(status: .badRequest)
        }
        return HttpResponse(status: .ok, body: Data("User ID: \(id)".utf8))
    }

    let request = HttpRequest(method: .get, path: "/users/42")
    let response = servlet.handleRequest(request)

    #expect(response.status == .ok)
    #expect(String(data: response.body ?? Data(), encoding: .utf8) == "User ID: 42")
}

@Test
func testDifferentHttpMethods() {
    let servlet = DispatcherServlet()

    servlet.registerHandler(path: "/resource", method: .get) { _ in
        return HttpResponse(status: .ok, body: Data("GET successful".utf8))
    }

    servlet.registerHandler(path: "/resource", method: .post) { _ in
        return HttpResponse(status: .created, body: Data("POST successful".utf8))
    }

    servlet.registerHandler(path: "/resource", method: .put) { _ in
        return HttpResponse(status: .ok, body: Data("PUT successful".utf8))
    }

    servlet.registerHandler(path: "/resource", method: .delete) { _ in
        return HttpResponse(status: .noContent)
    }

    // Test GET
    var request = HttpRequest(method: .get, path: "/resource")
    var response = servlet.handleRequest(request)
    #expect(response.status == .ok)
    #expect(String(data: response.body ?? Data(), encoding: .utf8) == "GET successful")

    // Test POST
    request = HttpRequest(method: .post, path: "/resource")
    response = servlet.handleRequest(request)
    #expect(response.status == .created)
    #expect(String(data: response.body ?? Data(), encoding: .utf8) == "POST successful")

    // Test PUT
    request = HttpRequest(method: .put, path: "/resource")
    response = servlet.handleRequest(request)
    #expect(response.status == .ok)
    #expect(String(data: response.body ?? Data(), encoding: .utf8) == "PUT successful")

    // Test DELETE
    request = HttpRequest(method: .delete, path: "/resource")
    response = servlet.handleRequest(request)
    #expect(response.status == .noContent)
    #expect(response.body == nil || response.body?.isEmpty == true)
}

@Test
func testRequestBodyHandling() {
    let servlet = DispatcherServlet()

    servlet.registerHandler(path: "/echo", method: .post) { request in
        guard let body = request.body else {
            return HttpResponse(status: .badRequest)
        }
        return HttpResponse(status: .ok, body: body)
    }

    let requestBody = Data("Hello, world!".utf8)
    let request = HttpRequest(method: .post, path: "/echo", body: requestBody)
    let response = servlet.handleRequest(request)

    #expect(response.status == .ok)
    #expect(response.body == requestBody)
    #expect(String(data: response.body ?? Data(), encoding: .utf8) == "Hello, world!")
}

@Test
func testCustomErrorHandler() {
    let servlet = DispatcherServlet()

    // Register custom 404 handler
    servlet.registerErrorHandler(status: .notFound) { request in
        return HttpResponse(
            status: .notFound,
            headers: ["Content-Type": "application/json"],
            body: Data(
                """
                {"error": "Resource not found", "path": "\(request.path)"}
                """.utf8)
        )
    }

    let request = HttpRequest(method: .get, path: "/nonexistent")
    let response = servlet.handleRequest(request)

    #expect(response.status == .notFound)
    #expect(response.headers["Content-Type"] == "application/json")
    #expect(response.body != nil)

    let responseString = String(data: response.body ?? Data(), encoding: .utf8) ?? ""
    #expect(responseString.contains("Resource not found"))
    #expect(responseString.contains("/nonexistent"))
}

@Test
func testMiddlewareRequestModification() {
    let servlet = DispatcherServlet()

    // Middleware that adds authentication info
    servlet.registerMiddleware { request, next in
        var modifiedRequest = request
        modifiedRequest.headers["Authorization"] = "Bearer token123"
        return next(modifiedRequest)
    }

    // Handler that checks for auth header
    servlet.registerHandler(path: "/secure") { request in
        if request.headers["Authorization"] == "Bearer token123" {
            return HttpResponse(status: .ok, body: Data("Authenticated".utf8))
        } else {
            return HttpResponse(status: .unauthorized)
        }
    }

    let request = HttpRequest(method: .get, path: "/secure")
    let response = servlet.handleRequest(request)

    #expect(response.status == .ok)
    #expect(String(data: response.body ?? Data(), encoding: .utf8) == "Authenticated")
}
