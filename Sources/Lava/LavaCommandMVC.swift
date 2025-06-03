
import Foundation
import Observation
import Synchronization

/// LavaCommandMVC - Implementation of Command pattern and Spring MVC-like framework
/// Provides robust command execution with undo/redo support and a web application framework

// MARK: - Command Pattern Implementation

/// Protocol defining the core Command pattern interface
/// Supports execute, undo, and redo operations with state tracking
public protocol Command {
    /// Executes the command operation
    /// - Throws: Error if execution fails
    func execute() throws

    /// Undoes the command operation, restoring previous state
    /// - Throws: Error if undo operation fails
    func undo() throws

    /// Redoes a previously undone command
    /// - Throws: Error if redo operation fails
    func redo() throws

    /// Whether the command can be undone in its current state
    var canUndo: Bool { get }

    /// Whether the command can be redone in its current state
    var canRedo: Bool { get }
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
            
        // Apply post-handle interceptors
        for interceptor in interceptors.reversed() {
            finalResponse = interceptor.postHandle(request: request, response: finalResponse)
        }
            
        return finalResponse
    }
}

/// Base implementation of the Command pattern that tracks execution state
/// Provides template methods for subclasses to implement command-specific behavior
open class AbstractCommand: Command {
    private var executed = false
    private var undone = false
    private var executionTimestamp: Date?

    /// Indicates if this command can be undone
    public var canUndo: Bool { executed && !undone }

    /// Indicates if this command can be redone
    public var canRedo: Bool { executed && undone }

    /// Creates a new abstract command
    public init() {}

    /// Executes the command if it hasn't been executed before
    /// - Throws: LavaError.invalidState if command was already executed
    public func execute() throws {
        guard !executed else {
            throw LavaError.invalidState("Command already executed")
        }
        try doExecute()
        executed = true
        undone = false
        executionTimestamp = Date()
    }

    public func undo() throws {
        guard canUndo else {
            throw LavaError.invalidState("Cannot undo command")
        }
        try doUndo()
        undone = true
    }

    public func redo() throws {
        guard canRedo else {
            throw LavaError.invalidState("Cannot redo command")
        }
        try doExecute()
        undone = false
    }

    /// Template method for subclasses to implement command execution logic
    /// - Throws: Any errors that might occur during command execution
    open func doExecute() throws {
        // Default implementation does nothing
        // Subclasses should override this method
    }

    /// Template method for subclasses to implement command undo logic
    /// - Throws: Any errors that might occur during command undo
    open func doUndo() throws {
        // Default implementation does nothing
        // Subclasses should override this method
    }

    /// Returns the time elapsed since this command was executed
    /// - Returns: Time interval since execution or nil if not executed
    public func timeSinceExecution() -> TimeInterval? {
        guard let timestamp = executionTimestamp else { return nil }
        return Date().timeIntervalSince(timestamp)
    }
}

/// A command that contains and manages multiple sub-commands
/// Executes commands sequentially and provides atomic undo/redo operations
public class CompositeCommand: Command {
    private var commands: [Command] = []
    private var executedCommands: [Command] = []
    private var name: String

    /// Whether all executed commands can be undone
    public var canUndo: Bool { !executedCommands.isEmpty && executedCommands.allSatisfy { $0.canUndo } }

    /// Whether all executed commands can be redone
    public var canRedo: Bool { !executedCommands.isEmpty && executedCommands.allSatisfy { $0.canRedo } }

    /// Creates a new composite command
    /// - Parameters:
    ///   - name: Descriptive name for the command group
    ///   - commands: Initial commands to add to the composite
    public init(name: String = "Composite Operation", commands: [Command] = []) {
        self.name = name
        self.commands = commands
    }

    /// Returns the descriptive name of this composite command
    public var compositeName: String {
        return name
    }

    public func add(_ command: Command) {
        commands.append(command)
    }

    public func execute() throws {
        executedCommands = []
        for command in commands {
            do {
                try command.execute()
                executedCommands.append(command)
            } catch {
                try undoExecuted()
                throw error
            }
        }
    }

    public func undo() throws {
        guard canUndo else {
            throw LavaError.invalidState("Cannot undo composite command")
        }
        for cmd in executedCommands.reversed() {
            try cmd.undo()
        }
    }

    public func redo() throws {
        guard canRedo else {
            throw LavaError.invalidState("Cannot redo composite command")
        }
        for cmd in executedCommands {
            try cmd.redo()
        }
    }

    private func undoExecuted() throws {
        for cmd in executedCommands.reversed() {
            if cmd.canUndo {
                try? cmd.undo()
            }
        }
    }
}

/// Manages command execution history and provides undo/redo functionality
/// Supports command history management with configurable history size
public actor CommandManager {
    private var undoStack: [Command] = []
    private var redoStack: [Command] = []
    private let maxStackSize: Int
    private var executionCount: Int = 0

    /// Whether there are commands that can be undone
    public var canUndo: Bool {
        return !undoStack.isEmpty
    }

    /// Whether there are commands that can be redone
    public var canRedo: Bool {
        return !redoStack.isEmpty
    }

    /// Number of commands that can be undone
    public var undoCount: Int {
        return undoStack.count
    }

    /// Number of commands that can be redone
    public var redoCount: Int {
        return redoStack.count
    }

    /// Creates a command manager with specified history limit
    /// - Parameter maxStackSize: Maximum number of commands to keep in history
    public init(maxStackSize: Int = 100) {
        self.maxStackSize = max(1, maxStackSize)
    }

    /// Executes a command and adds it to the undo history
    /// - Parameter command: The command to execute
    /// - Throws: Any errors thrown by the command during execution
    public func execute(_ command: Command) async throws {
        try await command.execute()
        undoStack.append(command)
        executionCount += 1

        // Trim undo stack if it exceeds the maximum size
        if undoStack.count > maxStackSize {
            undoStack.removeFirst()
        }

        // Clear redo stack as new execution changes history trajectory
        redoStack.removeAll()
    }

    public func undo() async throws {
        guard let command = undoStack.popLast() else {
            throw LavaError.invalidState("No command to undo")
        }
        try await command.undo()
        redoStack.append(command)
    }

    public func redo() async throws {
        guard let command = redoStack.popLast() else {
            throw LavaError.invalidState("No command to redo")
        }
        try await command.redo()
        undoStack.append(command)
    }

    /// Clears all command history
    public func clear() async {
        undoStack.removeAll(keepingCapacity: true)
        redoStack.removeAll(keepingCapacity: true)
        await LavaLogger.debug("Command history cleared")
    }

    /// Returns the total number of commands executed during this session
    public var totalExecutedCommands: Int {
        return executionCount
    }

    /// Groups multiple commands into a single composite command and executes it
    /// - Parameters:
    ///   - name: Descriptive name for the command group
    ///   - commands: Array of commands to execute as a single unit
    /// - Throws: Any errors thrown during command execution
    public func executeAsGroup(name: String, commands: [Command]) async throws {
        let composite = CompositeCommand(name: name, commands: commands)
        try await execute(composite)
    }
}

// MARK: - Stub Spring MVC-like Framework

@attached(member)
public macro RestController() = #externalMacro(module: "LavaMacros", type: "RestControllerMacro")

@attached(member)
public macro RequestMapping(_ path: String, method: HttpMethod = .get) = #externalMacro(module: "LavaMacros", type: "RequestMappingMacro")

@attached(peer)
public macro PathVariable(_ name: String = "") = #externalMacro(module: "LavaMacros", type: "PathVariableMacro")

@attached(peer)
public macro RequestParam(_ name: String = "", required: Bool = true) = #externalMacro(module: "LavaMacros", type: "RequestParamMacro")

@attached(peer)
public macro RequestBody(required: Bool = true) = #externalMacro(module: "LavaMacros", type: "RequestBodyMacro")

/// HTTP methods supported by the MVC framework
/// Follows the standard HTTP method definitions from RFC 7231
public enum HttpMethod: String, Codable, CaseIterable {
    /// Retrieve a resource
    case get = "GET"
    /// Submit data to be processed
    case post = "POST"
    /// Update a resource
    case put = "PUT"
    /// Delete a resource
    case delete = "DELETE"
    /// Apply partial modifications
    case patch = "PATCH"
    /// Retrieve headers only
    case head = "HEAD"
    /// Describe communication options
    case options = "OPTIONS"
    /// Loop-back test
    case trace = "TRACE"

    /// Returns whether this method is typically safe (doesn't modify resources)
    public var isSafe: Bool {
        switch self {
        case .get, .head, .options, .trace:
            return true
        default:
            return false
        }
    }

    /// Returns whether this method is typically idempotent
    public var isIdempotent: Bool {
        switch self {
        case .get, .head, .put, .delete, .options, .trace:
            return true
        default:
            return false
        }
    }
}

public enum HttpStatus: Int {
    case ok = 200
    case created = 201
    case accepted = 202
    case noContent = 204
    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
    case methodNotAllowed = 405
    case conflict = 409
    case internalServerError = 500
    case notImplemented = 501
    case serviceUnavailable = 503
    case gatewayTimeout = 504

    public var reason: String {
        switch self {
        case .ok: return "OK"
        case .created: return "Created"
        case .accepted: return "Accepted"
        case .noContent: return "No Content"
        case .badRequest: return "Bad Request"
        case .unauthorized: return "Unauthorized"
        case .forbidden: return "Forbidden"
        case .notFound: return "Not Found"
        case .methodNotAllowed: return "Method Not Allowed"
        case .conflict: return "Conflict"
        case .internalServerError: return "Internal Server Error"
        case .notImplemented: return "Not Implemented"
        case .serviceUnavailable: return "Service Unavailable"
        case .gatewayTimeout: return "Gateway Timeout"
        }
    }
}
