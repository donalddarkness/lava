import Foundation
import Synchronization
import Observation // Needed for @Observable, if used in web-related structures

// MARK: - HttpMethod

/// Represents HTTP methods supported by the framework.
public enum HttpMethod: String, Codable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case head = "HEAD"
    case options = "OPTIONS"
    case connect = "CONNECT"
    case trace = "TRACE"
}

// MARK: - HttpStatus

/// Represents HTTP status codes and their reason phrases.
public struct HttpStatus: Equatable, Hashable {
    public let code: Int
    public let reasonPhrase: String

    public static let `continue` = HttpStatus(code: 100, reasonPhrase: "Continue")
    public static let switchingProtocols = HttpStatus(code: 101, reasonPhrase: "Switching Protocols")
    public static let processing = HttpStatus(code: 102, reasonPhrase: "Processing")

    public static let ok = HttpStatus(code: 200, reasonPhrase: "OK")
    public static let created = HttpStatus(code: 201, reasonPhrase: "Created")
    public static let accepted = HttpStatus(code: 202, reasonPhrase: "Accepted")
    public static let nonAuthoritativeInformation = HttpStatus(code: 203, reasonPhrase: "Non-Authoritative Information")
    public static let noContent = HttpStatus(code: 204, reasonPhrase: "No Content")
    public static let resetContent = HttpStatus(code: 205, reasonPhrase: "Reset Content")
    public static let partialContent = HttpStatus(code: 206, reasonPhrase: "Partial Content")
    public static let multiStatus = HttpStatus(code: 207, reasonPhrase: "Multi-Status")
    public static let alreadyReported = HttpStatus(code: 208, reasonPhrase: "Already Reported")
    public static let imUsed = HttpStatus(code: 226, reasonPhrase: "IM Used")

    public static let multipleChoices = HttpStatus(code: 300, reasonPhrase: "Multiple Choices")
    public static let movedPermanently = HttpStatus(code: 301, reasonPhrase: "Moved Permanently")
    public static let found = HttpStatus(code: 302, reasonPhrase: "Found")
    public static let seeOther = HttpStatus(code: 303, reasonPhrase: "See Other")
    public static let notModified = HttpStatus(code: 304, reasonPhrase: "Not Modified")
    public static let useProxy = HttpStatus(code: 305, reasonPhrase: "Use Proxy")
    public static let temporaryRedirect = HttpStatus(code: 307, reasonPhrase: "Temporary Redirect")
    public static let permanentRedirect = HttpStatus(code: 308, reasonPhrase: "Permanent Redirect")

    public static let badRequest = HttpStatus(code: 400, reasonPhrase: "Bad Request")
    public static let unauthorized = HttpStatus(code: 401, reasonPhrase: "Unauthorized")
    public static let paymentRequired = HttpStatus(code: 402, reasonPhrase: "Payment Required")
    public static let forbidden = HttpStatus(code: 403, reasonPhrase: "Forbidden")
    public static let notFound = HttpStatus(code: 404, reasonPhrase: "Not Found")
    public static let methodNotAllowed = HttpStatus(code: 405, reasonPhrase: "Method Not Allowed")
    public static let notAcceptable = HttpStatus(code: 406, reasonPhrase: "Not Acceptable")
    public static let proxyAuthenticationRequired = HttpStatus(code: 407, reasonPhrase: "Proxy Authentication Required")
    public static let requestTimeout = HttpStatus(code: 408, reasonPhrase: "Request Timeout")
    public static let conflict = HttpStatus(code: 409, reasonPhrase: "Conflict")
    public static let gone = HttpStatus(code: 410, reasonPhrase: "Gone")
    public static let lengthRequired = HttpStatus(code: 411, reasonPhrase: "Length Required")
    public static let preconditionFailed = HttpStatus(code: 412, reasonPhrase: "Precondition Failed")
    public static let payloadTooLarge = HttpStatus(code: 413, reasonPhrase: "Payload Too Large")
    public static let uriTooLong = HttpStatus(code: 414, reasonPhrase: "URI Too Long")
    public static let unsupportedMediaType = HttpStatus(code: 415, reasonPhrase: "Unsupported Media Type")
    public static let rangeNotSatisfiable = HttpStatus(code: 416, reasonPhrase: "Range Not Satisfiable")
    public static let expectationFailed = HttpStatus(code: 417, reasonPhrase: "Expectation Failed")
    public static let teapot = HttpStatus(code: 418, reasonPhrase: "I'm a teapot")
    public static let misdirectedRequest = HttpStatus(code: 421, reasonPhrase: "Misdirected Request")
    public static let unprocessableEntity = HttpStatus(code: 422, reasonPhrase: "Unprocessable Entity")
    public static let locked = HttpStatus(code: 423, reasonPhrase: "Locked")
    public static let failedDependency = HttpStatus(code: 424, reasonPhrase: "Failed Dependency")
    public static let upgradeRequired = HttpStatus(code: 426, reasonPhrase: "Upgrade Required")
    public static let preconditionRequired = HttpStatus(code: 428, reasonPhrase: "Precondition Required")
    public static let tooManyRequests = HttpStatus(code: 429, reasonPhrase: "Too Many Requests")
    public static let requestHeaderFieldsTooLarge = HttpStatus(code: 431, reasonPhrase: "Request Header Fields Too Large")
    public static let unavailableForLegalReasons = HttpStatus(code: 451, reasonPhrase: "Unavailable For Legal Reasons")

    public static let internalServerError = HttpStatus(code: 500, reasonPhrase: "Internal Server Error")
    public static let notImplemented = HttpStatus(code: 501, reasonPhrase: "Not Implemented")
    public static let badGateway = HttpStatus(code: 502, reasonPhrase: "Bad Gateway")
    public static let serviceUnavailable = HttpStatus(code: 503, reasonPhrase: "Service Unavailable")
    public static let gatewayTimeout = HttpStatus(code: 504, reasonPhrase: "Gateway Timeout")
    public static let httpVersionNotSupported = HttpStatus(code: 505, reasonPhrase: "HTTP Version Not Supported")
    public static let variantAlsoNegotiates = HttpStatus(code: 506, reasonPhrase: "Variant Also Negotiates")
    public static let insufficientStorage = HttpStatus(code: 507, reasonPhrase: "Insufficient Storage")
    public static let loopDetected = HttpStatus(code: 508, reasonPhrase: "Loop Detected")
    public static let notExtended = HttpStatus(code: 510, reasonPhrase: "Not Extended")
    public static let networkAuthenticationRequired = HttpStatus(code: 511, reasonPhrase: "Network Authentication Required")
}

// MARK: - HttpRequest and HttpResponse

/// Represents an HTTP request in the MVC framework
public struct HttpRequest {
    /// The HTTP method
    public let method: HttpMethod
    /// The request path
    public let path: String
    /// HTTP headers as key-value pairs
    public let headers: [String: String]
    /// Optional request body data
    public let body: Data?
    /// Query parameters extracted from the URL
    public let queryParams: [String: String]
    /// Path variables extracted from the URL
    public var pathVariables: [String: String] = [:] // Added for @PathVariable support
    /// Timestamp when the request was created
    public let timestamp: Date

    /// Creates a new HTTP request
    /// - Parameters:
    ///   - method: The HTTP method
    ///   - path: The request path
    ///   - headers: HTTP headers
    ///   - body: Request body data
    ///   - queryParams: Query parameters
    public init(
        method: HttpMethod,
        path: String,
        headers: [String: String] = [:],
        body: Data? = nil,
        queryParams: [String: String] = [:]
    ) {
        self.method = method
        self.path = path
        self.headers = headers
        self.body = body
        self.queryParams = queryParams
        self.timestamp = Date()
    }

    /// Retrieves a query parameter value by name
    /// - Parameter name: Parameter name
    /// - Returns: Parameter value or nil if not found
    public func queryParam(_ name: String) async -> String? {
        return queryParams[name]
    }

    /// Retrieves a path variable value by name
    /// - Parameter name: Parameter name
    /// - Returns: Parameter value or nil if not found
    public func pathVariable(_ name: String) async -> String? {
        return pathVariables[name]
    }

    /// Retrieves a header value by name
    /// - Parameter name: Header name
    /// - Returns: Header value or nil if not found
    public func header(_ name: String) async -> String? {
        return headers[name]
    }
}

/// Represents an HTTP response in the MVC framework
public struct HttpResponse {
    /// HTTP status code and reason
    public var status: HttpStatus
    /// HTTP headers as key-value pairs
    public var headers: [String: String]
    /// Optional response body data
    public var body: Data?
    /// Content type of the response
    public var contentType: String? {
        get { headers["Content-Type"] }
        set {
            if let newValue = newValue {
                headers["Content-Type"] = newValue
            } else {
                headers.removeValue(forKey: "Content-Type")
            }
        }
    }

    /// Creates a new HTTP response
    /// - Parameters:
    ///   - status: HTTP status
    ///   - headers: HTTP headers
    ///   - body: Response body data
    public init(status: HttpStatus, headers: [String: String] = [:], body: Data? = nil) {
        self.status = status
        self.headers = headers
        self.body = body
    }

    /// Creates a new JSON response
    /// - Parameters:
    ///   - json: JSON object to serialize
    ///   - status: HTTP status (default: .ok)
    /// - Returns: Configured HTTP response
    public static func json(_ json: Any, status: HttpStatus = .ok) async -> HttpResponse {
        var response = HttpResponse(status: status)
        if let jsonData = try? JSONSerialization.data(withJSONObject: json) {
            response.body = jsonData
            response.contentType = "application/json; charset=utf-8"
        }
        return response
    }

    /// Creates a new text response
    /// - Parameters:
    ///   - text: Text content
    ///   - status: HTTP status (default: .ok)
    /// - Returns: Configured HTTP response
    public static func text(_ text: String, status: HttpStatus = .ok) async -> HttpResponse {
        let response = HttpResponse(
            status: status,
            headers: ["Content-Type": "text/plain; charset=utf-8"],
            body: Data(text.utf8)
        )
        return response
    }
}

// MARK: - DispatcherServlet

/// Spring-inspired servlet that dispatches HTTP requests to appropriate handlers
/// Supports middleware for cross-cutting concerns like logging, authentication, etc.
public actor DispatcherServlet {
    private var handlers: [String: (HttpRequest) async -> HttpResponse] = [:]
    private var middleware: [(HttpRequest, @escaping (HttpRequest) async -> HttpResponse) async -> HttpResponse] = []
    private var interceptors: [RequestInterceptor] = []

    /// Interceptor for pre/post request processing
    public protocol RequestInterceptor {
        /// Called before request processing
        /// - Parameter request: The incoming request
        /// - Returns: Modified request or nil to short-circuit
        func preHandle(request: HttpRequest) -> HttpRequest?

        /// Called after request processing
        /// - Parameters:
        ///   - request: The original request
        ///   - response: The response to be sent
        /// - Returns: Modified response
        func postHandle(request: HttpRequest, response: HttpResponse) -> HttpResponse
    }

    /// Creates a new dispatcher servlet
    public init() {}

    /// Registers a handler for a specific path
    /// - Parameters:
    ///   - path: URL path to handle
    ///   - handler: Function that processes the request
    public func registerHandler(path: String, handler: @escaping (HttpRequest) async -> HttpResponse) async {
        handlers[path] = handler
        await LavaLogger.debug("Registered handler for path: \(path)")
    }

    /// Registers a middleware function
    /// - Parameter middlewareHandler: Middleware function
    public func registerMiddleware(_ middlewareHandler: @escaping (HttpRequest, @escaping (HttpRequest) async -> HttpResponse) async -> HttpResponse) async {
        middleware.append(middlewareHandler)
        await LavaLogger.debug("Registered middleware handler")
    }

    /// Adds a request interceptor
    /// - Parameter interceptor: The interceptor to add
    public func addInterceptor(_ interceptor: RequestInterceptor) async {
        interceptors.append(interceptor)
        await LavaLogger.debug("Added request interceptor")
    }

    /// Handles an incoming HTTP request
    /// - Parameter request: The request to process
    /// - Returns: The response to return
    public func handleRequest(_ request: HttpRequest) async -> HttpResponse {
        var currentRequest = request
        let startTime = DispatchTime.now()

        // Run pre-handle interceptors
        for interceptor in interceptors {
            guard let modifiedRequest = interceptor.preHandle(request: currentRequest) else {
                return HttpResponse(status: .forbidden, body: Data("Request rejected by interceptor".utf8))
            }
            currentRequest = modifiedRequest
        }

        // Find handler and apply middleware
        let handler: (HttpRequest) -> HttpResponse
        if let pathHandler = handlers[currentRequest.path] {
            handler = pathHandler
        } else {
            let response = HttpResponse(
                status: .notFound,
                body: Data("Resource not found: \(currentRequest.path)".utf8)
            )
            return await finalizeResponse(request: request, response: response)
        }

        // Create handler chain with middleware
        let finalHandler: (HttpRequest) async -> HttpResponse = { req in
            await handler(req)
        }

        // Apply middleware chain
        let middlewareChain = middleware.reversed().reduce(finalHandler) { next, middlewareHandler in
            { req in await middlewareHandler(req, next) }
        }
            
        // Execute handler chain
        var response = await middlewareChain(currentRequest)
            
        // Process response through interceptors
        response = await finalizeResponse(request: request, response: response)
            
        // Log request handling time
        let endTime = DispatchTime.now()
        let timeElapsed = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000 // ms
        await LavaLogger.debug("Request to \(request.path) processed in \(String(format: "%.2f", timeElapsed))ms")
            
        return response
    }
        
    private func finalizeResponse(request: HttpRequest, response: HttpResponse) async -> HttpResponse {
        var finalResponse = response
            
        for interceptor in interceptors {
            finalResponse = interceptor.postHandle(request: request, response: finalResponse)
        }

        return finalResponse
    }
} 