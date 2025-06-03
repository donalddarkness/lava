import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

{ { REWRITTEN_CODE } }

/// Implementation of the `@JavaBuilder` macro, which mimics Java builder pattern
public struct JavaBuilderMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            context.diagnose(Diagnostic(node: node, message: MacroError.requiresClass))
            return []
        }

        var members: [DeclSyntax] = []
        let className = classDecl.name.text

        // Add builder factory method
        members.append(
            """
            static func builder() -> Builder {
                return Builder()
            }
            """)

        // Extract properties from the class
        let properties = extractProperties(from: classDecl)

        // Create builder class using string interpolation for better readability
        let builderClass = """
            class Builder {
                private var instance = \(className)()

                \(properties.map { prop in
                """
                func set\(prop.name.capitalized)(_ value: \(prop.type)) -> Builder {
                    instance.\(prop.name) = value
                    return self
                }
                """
            }.joined(separator: "\n\n"))

                func build() -> \(className) {
                    return instance
                }

                func returnThis() -> Self {
                    return self
                }
            }
            """

        members.append(DeclSyntax(stringLiteral: builderClass))

        return members
    }

    private static func extractProperties(from classDecl: ClassDeclSyntax) -> [(
        name: String, type: String
    )] {
        var properties: [(name: String, type: String)] = []

        for member in classDecl.memberBlock.members {
            if let varDecl = member.decl.as(VariableDeclSyntax.self) {
                for binding in varDecl.bindings {
                    if let identifier = binding.pattern.as(IdentifierPatternSyntax.self),
                        let typeAnnotation = binding.typeAnnotation?.type
                    {
                        properties.append(
                            (
                                name: identifier.identifier.text,
                                type: typeAnnotation.description
                            ))
                    }
                }
            }
        }

        return properties
    }

    enum MacroError: String, CustomStringConvertible {
        case requiresClass = "@JavaBuilder can only be applied to classes"

        var description: String { rawValue }
    }
}

/// Implementation of the `@Public` macro for Java-like public access modifiers
public struct PublicMacro: AccessorMacro, MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        // Swift already has public keyword
        return []
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        return [
            AttributeSyntax(attributeName: SimpleTypeIdentifierSyntax(name: .identifier("public")))
        ]
    }
}

/// Implementation of the `@Private` macro for Java-like private access modifiers
public struct PrivateMacro: AccessorMacro, MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        return []
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        return [
            AttributeSyntax(attributeName: SimpleTypeIdentifierSyntax(name: .identifier("private")))
        ]
    }
}

/// Implementation of the `@Protected` macro for Java-like protected access modifiers
public struct ProtectedMacro: AccessorMacro, MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingAccessorsOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AccessorDeclSyntax] {
        return []
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        // In Swift, we simulate protected with fileprivate
        return [
            AttributeSyntax(
                attributeName: SimpleTypeIdentifierSyntax(name: .identifier("fileprivate")))
        ]
    }
}

/// Implementation of the `@JavaDoc` macro for generating JavaDoc-style documentation
public struct JavaDocMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Extract JavaDoc info from attribute arguments if provided
        guard let arguments = node.arguments?.as(LabeledExprListSyntax.self),
            let docStringExpr = arguments.first?.expression,
            let docString = docStringExpr.as(StringLiteralExprSyntax.self)?.segments.first?.as(
                StringSegmentSyntax.self)?.content.text
        else {
            return []
        }

        // Parse JavaDoc format and generate Swift documentation
        let parsedDoc = parseJavaDoc(docString)

        // Create Swift doc comment
        let swiftDocComment =
            "/// \(parsedDoc.description)\n"
            + parsedDoc.params.map { "/// - Parameter \($0.name): \($0.description)" }.joined(
                separator: "\n")
            + (parsedDoc.returns.isEmpty ? "" : "\n/// - Returns: \(parsedDoc.returns)")
            + parsedDoc.thrownErrors.map { "\n/// - Throws: \($0.type): \($0.description)" }.joined(
                separator: "")

        return [DeclSyntax(stringLiteral: swiftDocComment)]
    }

    private static func parseJavaDoc(_ docString: String) -> JavaDocInfo {
        var description = ""
        var params: [(name: String, description: String)] = []
        var returns = ""
        var thrownErrors: [(type: String, description: String)] = []

        let lines = docString.split(separator: "\n").map {
            String($0.trimmingCharacters(in: .whitespaces))
        }

        var currentSection = "description"
        var currentParamName = ""
        var currentThrowsType = ""
        var currentText = ""

        for line in lines {
            if line.hasPrefix("@param") {
                // Process previous section
                finishCurrentSection(
                    &description, &params, &returns, &thrownErrors,
                    currentSection, currentParamName, currentThrowsType, currentText
                )

                // Start new @param section
                let components = line.dropFirst(6).trimmingCharacters(in: .whitespaces).components(
                    separatedBy: " ")
                if !components.isEmpty {
                    currentParamName = components[0]
                    currentText = components.dropFirst().joined(separator: " ")
                    currentSection = "param"
                }
            } else if line.hasPrefix("@return") {
                // Process previous section
                finishCurrentSection(
                    &description, &params, &returns, &thrownErrors,
                    currentSection, currentParamName, currentThrowsType, currentText
                )

                // Start new @return section
                currentText = line.dropFirst(7).trimmingCharacters(in: .whitespaces)
                currentSection = "return"
            } else if line.hasPrefix("@throws") || line.hasPrefix("@exception") {
                // Process previous section
                finishCurrentSection(
                    &description, &params, &returns, &thrownErrors,
                    currentSection, currentParamName, currentThrowsType, currentText
                )

                // Start new @throws section
                let prefix = line.hasPrefix("@throws") ? 7 : 10
                let components = line.dropFirst(prefix).trimmingCharacters(in: .whitespaces)
                    .components(separatedBy: " ")
                if !components.isEmpty {
                    currentThrowsType = components[0]
                    currentText = components.dropFirst().joined(separator: " ")
                    currentSection = "throws"
                }
            } else {
                // Continue current section
                if !currentText.isEmpty {
                    currentText += " "
                }
                currentText += line
            }
        }

        // Process final section
        finishCurrentSection(
            &description, &params, &returns, &thrownErrors,
            currentSection, currentParamName, currentThrowsType, currentText
        )

        return JavaDocInfo(
            description: description,
            params: params,
            returns: returns,
            thrownErrors: thrownErrors
        )
    }

    private static func finishCurrentSection(
        _ description: inout String,
        _ params: inout [(name: String, description: String)],
        _ returns: inout String,
        _ thrownErrors: inout [(type: String, description: String)],
        _ section: String,
        _ paramName: String,
        _ throwsType: String,
        _ text: String
    ) {
        let trimmedText = text.trimmingCharacters(in: .whitespaces)
        if trimmedText.isEmpty { return }

        switch section {
        case "description":
            description = trimmedText
        case "param":
            if !paramName.isEmpty {
                params.append((name: paramName, description: trimmedText))
            }
        case "return":
            returns = trimmedText
        case "throws":
            if !throwsType.isEmpty {
                thrownErrors.append((type: throwsType, description: trimmedText))
            }
        default:
            break
        }
    }

    private struct JavaDocInfo {
        let description: String
        let params: [(name: String, description: String)]
        let returns: String
        let thrownErrors: [(type: String, description: String)]
    }
}

/// Implementation of the `@Thread` macro for mimicking Java thread annotations
/// Enhanced with Swift concurrency features and structured concurrency
public struct ThreadMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Add enhanced thread-related utility methods to the class with modern Swift concurrency
        return [
            // Legacy GCD methods with completion handlers
            """
            func runOnMainThread(_ block: @escaping () -> Void) {
                DispatchQueue.main.async {
                    block()
                }
            }
            """,
            """
            func runOnMainThread<T>(_ block: @escaping () -> T, completion: @escaping (T) -> Void) {
                DispatchQueue.main.async {
                    let result = block()
                    completion(result)
                }
            }
            """,
            """
            func runInBackground(_ block: @escaping () -> Void) {
                DispatchQueue.global(qos: .background).async {
                    block()
                }
            }
            """,
            """
            func runInBackground<T>(_ block: @escaping () -> T, completion: @escaping (T) -> Void) {
                DispatchQueue.global(qos: .background).async {
                    let result = block()
                    DispatchQueue.main.async {
                        completion(result)
                    }
                }
            }
            """,
            // Modern Swift concurrency methods with async/await
            """
            @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
            func runOnMainThreadAsync<T>(_ operation: @escaping () async throws -> T) async throws -> T {
                try await MainActor.run {
                    try await operation()
                }
            }
            """,
            """
            @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
            func runInBackgroundAsync<T>(_ operation: @escaping () async throws -> T, priority: TaskPriority? = nil) async throws -> T {
                try await Task.detached(priority: priority) {
                    try await operation()
                }.value
            }
            """,
            """
            @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
            func withTimeout<T>(_ timeout: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
                try await withThrowingTaskGroup(of: T.self) { group in
                    group.addTask {
                        try await operation()
                    }

                    group.addTask {
                        try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                        throw ThreadTaskError.timeout
                    }

                    // Return the first completed result or throw
                    let result = try await group.next()
                    group.cancelAll()

                    guard let unwrappedResult = result else {
                        throw ThreadTaskError.unknown
                    }

                    return unwrappedResult
                }
            }
            """,
            """
            enum ThreadTaskError: Error {
                case timeout
                case cancelled
                case unknown
            }
            """,
            // Enhanced sleep function with Task sleep
            """
            func sleep(milliseconds: Int) {
                Thread.sleep(forTimeInterval: Double(milliseconds) / 1000.0)
            }
            """,
            """
            @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
            func sleepAsync(milliseconds: Int) async throws {
                try await Task.sleep(nanoseconds: UInt64(milliseconds) * 1_000_000)
            }
            """,
            // QoS handling
            """
            func runWithQoS(qos: DispatchQoS.QoSClass, _ block: @escaping () -> Void) {
                DispatchQueue.global(qos: qos).async {
                    block()
                }
            }
            """,
            """
            @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
            func runWithPriority<T>(priority: TaskPriority, _ operation: @escaping () async throws -> T) async throws -> T {
                try await Task(priority: priority) {
                    try await operation()
                }.value
            }
            """,
            // Legacy Thread creation methods
            """
            func createThread(name: String? = nil, _ block: @escaping () -> Void) -> Thread {
                let thread = Thread {
                    block()
                }
                if let threadName = name {
                    thread.name = threadName
                }
                return thread
            }
            """,
            """
            func startThread(name: String? = nil, _ block: @escaping () -> Void) {
                let thread = createThread(name: name, block)
                thread.start()
            }
            """,
            // Task group management
            """
            @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
            func runConcurrentTasks<T>(operations: [@Sendable () async throws -> T]) async throws -> [T] {
                try await withThrowingTaskGroup(of: T.self) { group in
                    for operation in operations {
                        group.addTask {
                            try await operation()
                        }
                    }

                    var results: [T] = []
                    for try await result in group {
                        results.append(result)
                    }
                    return results
                }
            }
            """,
            // Thread/Task information
            """
            var currentThread: Thread {
                return Thread.current
            }
            """,
            """
            var isMainThread: Bool {
                return Thread.isMainThread
            }
            """,
            """
            @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
            var currentTaskPriority: TaskPriority? {
                return Task.currentPriority
            }
            """,
            """
            @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
            var isTaskCancelled: Bool {
                return Task.isCancelled
            }
            """,
            // Actor support
            """
            @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
            func runIsolated<T, U: Actor>(_ actor: U, _ operation: @escaping (isolated U) throws -> T) async throws -> T {
                return try await actor.runIsolated(operation)
            }
            """,
        ]
    }
}

/// Implementation of the `@Symbol` macro for Java-like symbol references
/// Enhanced with improved type safety and modern Swift reflection
public struct SymbolMacro: MemberMacro, ExpressionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Enhanced reflection capabilities with improved type safety and documentation
        return [
            """
            /// Returns the fully qualified name of this type
            /// - Returns: String representation of the type name
            static func getSymbolName() -> String {
                return String(reflecting: Self.self) // Use reflecting for fully qualified name
            }
            """,
            """
            /// Returns the simple name of this type (without module prefix)
            /// - Returns: String representation of the simple type name
            static func getSimpleTypeName() -> String {
                return String(describing: Self.self)
            }
            """,
            """
            static func getProperties() -> [String] {
                let mirror = Mirror(reflecting: Self.init())
                return mirror.children.compactMap { $0.label }
            }
            """,
            """
            /// Returns property types mapped to their names
            /// - Returns: Dictionary mapping property names to their types
            static func getPropertyTypes() -> [String: Any.Type] {
                let mirror = Mirror(reflecting: Self.init())
                var types: [String: Any.Type] = [:]

                for child in mirror.children {
                    if let label = child.label {
                        types[label] = type(of: child.value)
                    }
                }

                return types
            }
            """,
            """
            /// Retrieves a property value by name using reflection
            /// - Parameters:
            ///   - instance: Instance to inspect
            ///   - propertyName: Name of the property to retrieve
            /// - Returns: Property value if found, nil otherwise
            static func getPropertyValue(instance: Any, propertyName: String) -> Any? {
                let mirror = Mirror(reflecting: instance)

                for child in mirror.children {
                    if child.label == propertyName {
                        return child.value
                    }
                }
                
                // Try superclass if available
                if let superMirror = mirror.superclassMirror {
                    for child in superMirror.children {
                        if child.label == propertyName {
                            return child.value
                        }
                    }
                }

                return nil
            }
            """,
            """
            /// Attempts to set a property value by name (limited by Swift's KVC support)
            /// - Parameters:
            ///   - instance: Instance to modify
            ///   - propertyName: Name of property to set
            ///   - newValue: Value to assign
            /// - Returns: True if successful, false otherwise
            @discardableResult
            static func setPropertyValue(instance: AnyObject, propertyName: String, newValue: Any) -> Bool {
                // First try with KVC if available
                if let key = propertyName as NSString?,
                   instance.responds(to: #selector(NSObject.setValue(_:forKey:))) {
                    do {
                        try instance.setValue(newValue, forKey: key as String)
                        return true
                    } catch {
                        // KVC failed, fall back to selector
                    }
                }
                
                // Try with selector as fallback
                let selectorString = propertyName + ":"
                let selector = NSSelectorFromString(selectorString)
                
                if instance.responds(to: selector) {
                    _ = instance.perform(selector, with: newValue)
                    return true
                }
                
                return false
            }
            """,
            """
            /// Gets method names defined in this type
            /// - Returns: Array of method names
            static func getMethods() -> [String] {
                var methodList: [String] = []
                var methodCount: UInt32 = 0

                if let classObj = Self.self as? AnyClass,
                   let methods = class_copyMethodList(classObj, &methodCount) {

                    for i in 0..<Int(methodCount) {
                        let selector = method_getName(methods[i])
                        let methodName = NSStringFromSelector(selector)
                        methodList.append(methodName)
                    }

                    free(methods)
                }

                return methodList
            }
            """,
            """
            /// Detailed method descriptor providing rich metadata
            struct MethodDescriptor {
                let name: String
                let selector: Selector
                let returnType: String
                let parameterCount: Int
                
                var description: String {
                    return "\(name) -> \(returnType) [params: \(parameterCount)]"
                }
            }
            """,
            """
            /// Gets detailed method descriptors for this type
            /// - Returns: Array of method descriptors
            static func getMethodDescriptors() -> [MethodDescriptor] {
                var descriptors: [MethodDescriptor] = []
                var methodCount: UInt32 = 0

                guard let classObj = Self.self as? AnyClass,
                      let methods = class_copyMethodList(classObj, &methodCount) else {
                    return []
                }

                for i in 0..<Int(methodCount) {
                    let method = methods[i]
                    let selector = method_getName(method)
                    let selectorName = NSStringFromSelector(selector)
                    
                    // Get method return type
                    let returnType = method_copyReturnType(method)
                    let returnTypeString = String(cString: returnType!)
                    free(returnType)
                    
                    // Get parameter count (subtract 2 for implicit self and _cmd)
                    let paramCount = Int(method_getNumberOfArguments(method)) - 2
                    
                    descriptors.append(MethodDescriptor(
                        name: selectorName,
                        selector: selector,
                        returnType: returnTypeString,
                        parameterCount: paramCount
                    ))
                }

                free(methods)
                return descriptors
            }
            """,
            """
            /// Invokes a method on an instance with arguments
            /// - Parameters:
            ///   - instance: Target instance
            ///   - methodName: Method name to invoke
            ///   - arguments: Arguments to pass (limited to single argument)
            /// - Returns: Method result or nil if failed
            static func invokeMethod(instance: AnyObject, methodName: String, withArguments arguments: [Any] = []) -> Any? {
                let selector = NSSelectorFromString(methodName)
                if instance.responds(to: selector) {
                    if arguments.isEmpty {
                        return instance.perform(selector)?.takeUnretainedValue()
                    } else if arguments.count == 1 {
                        return instance.perform(selector, with: arguments[0])?.takeUnretainedValue()
                    } else {
                        // For multiple arguments, we'd need variadic perform which isn't directly supported
                        return nil
                    }
                }
                return nil
            }
            """,
            """
            /// Checks if an object is an instance of this type
            /// - Parameter object: Object to check
            /// - Returns: True if object is an instance of this type
            static func isInstance(_ object: Any) -> Bool {
                return object is Self
            }
            """,
            """
            /// Creates a new instance of this type if it supports default initialization
            /// - Returns: New instance or nil if initialization failed
            static func createNewInstance() -> Self? {
                return Self.init()
            }
            """,
            """
            /// Gets the inheritance hierarchy of this type
            /// - Returns: Array of parent type names, starting with immediate superclass
            static func getInheritanceHierarchy() -> [String] {
                var hierarchy: [String] = []
                var currentMirror: Mirror? = Mirror(reflecting: Self.init())
                
                while let superMirror = currentMirror?.superclassMirror {
                    if let superclassName = superMirror.subjectType as? AnyClass {
                        hierarchy.append(NSStringFromClass(superclassName))
                    }
                    currentMirror = superMirror
                }
                
                return hierarchy
            }
            """,
            """
            /// Gets protocols implemented by this type
            /// - Returns: Array of protocol names
            static func getImplementedProtocols() -> [String] {
                guard let classObj = Self.self as? AnyClass else { return [] }
                
                var protocolList: [String] = []
                var protocolCount: UInt32 = 0
                
                if let protocols = class_copyProtocolList(classObj, &protocolCount) {
                    for i in 0..<Int(protocolCount) {
                        let proto = protocols[i]
                        protocolList.append(String(cString: protocol_getName(proto)))
                    }
                    
                    free(protocols)
                }
                
                return protocolList
            }
            """,
        ]
    }

    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> ExprSyntax {
        // Check for arguments
        if node.argumentList.isEmpty {
            throw SymbolError.missingTypeArgument
        }

        guard let firstArgument = node.argumentList.first?.expression else {
            throw SymbolError.invalidTypeArgument
        }

        return ExprSyntax(stringLiteral: "String(describing: \(firstArgument).self)")
    }

    enum SymbolError: Error, CustomStringConvertible {
        case missingTypeArgument
        case invalidTypeArgument

        var description: String {
            switch self {
            case .missingTypeArgument:
                return "@Symbol requires a type argument"
            case .invalidTypeArgument:
                return "@Symbol requires a valid type reference"
            }
        }
    }
}

/// Implementation of the `@Synchronized` macro for Java-like synchronized blocks
/// Enhanced with modern Swift concurrency and actor-based synchronization
public struct SynchronizedMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Enhanced synchronization utilities with modern alternatives
        return [
            """
            // Traditional synchronization primitives
            private let _lock = NSRecursiveLock()
            private var _waitingThreads = 0
            private let _condition = NSCondition()
            private let _syncQueue = DispatchQueue(label: "com.lava.synchronizedQueue", attributes: [])
            private let _concurrentQueue = DispatchQueue(label: "com.lava.synchronizedConcurrentQueue", attributes: [.concurrent])
            """,
            """
            /// Executes a critical section with exclusive access
            /// - Parameter criticalSection: Code block to execute with synchronization
            /// - Returns: Result of the critical section
            func synchronized<T>(_ criticalSection: () throws -> T) rethrows -> T {
                _lock.lock()
                defer { _lock.unlock() }
                return try criticalSection()
            }
            """,
            """
            /// Executes a critical section asynchronously and calls completion when done
            /// - Parameters:
            ///   - criticalSection: Code block to execute with synchronization
            ///   - completion: Completion handler called with the result
            func synchronizedAsync<T>(_ criticalSection: @escaping () -> T, completion: @escaping (T) -> Void) {
                _concurrentQueue.async { [weak self] in
                    guard let self = self else { return }
                    let result = self.synchronized {
                        criticalSection()
                    }
                    completion(result)
                }
            }
            """,
            """
            /// Modern async/await version of synchronized execution
            /// - Parameter criticalSection: Async code block to execute with synchronization
            /// - Returns: Result of the critical section
            @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
            func synchronizedAsync<T>(_ criticalSection: @escaping () async throws -> T) async throws -> T {
                try await withCheckedThrowingContinuation { continuation in
                    _syncQueue.async { [weak self] in
                        guard let self = self else {
                            continuation.resume(throwing: SynchronizationError.objectDeallocated)
                            return
                        }
                        
                        Task {
                            do {
                                let result = try await criticalSection()
                                continuation.resume(returning: result)
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                }
            }
            """,
            """
            /// Error types for synchronization operations
            enum SynchronizationError: Error {
                case timeout
                case objectDeallocated
                case conditionFailed
                case deadlock
                case interrupted
            }
            """,
            """
            /// Waits indefinitely for a condition to be signaled
            func wait() {
                _condition.lock()
                _waitingThreads += 1
                _condition.wait()
                _waitingThreads -= 1
                _condition.unlock()
            }
            """,
            """
            /// Waits with timeout for a condition to be signaled
            /// - Parameter timeout: Maximum time to wait in seconds
            /// - Returns: True if signaled before timeout, false if timed out
            func wait(timeout: TimeInterval) -> Bool {
                _condition.lock()
                _waitingThreads += 1
                let result = _condition.wait(until: Date(timeIntervalSinceNow: timeout))
                _waitingThreads -= 1
                _condition.unlock()
                return result
            }
            """,
            """
            /// Modern async/await version of wait
            /// - Parameter timeout: Optional timeout in seconds
            /// - Throws: SynchronizationError if timeout occurs
            @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
            func waitAsync(timeout: TimeInterval? = nil) async throws {
                try await withCheckedThrowingContinuation { continuation in
                    _concurrentQueue.async { [weak self] in
                        guard let self = self else {
                            continuation.resume(throwing: SynchronizationError.objectDeallocated)
                            return
                        }
                        
                        if let timeout = timeout {
                            if self.wait(timeout: timeout) {
                                continuation.resume()
                            } else {
                                continuation.resume(throwing: SynchronizationError.timeout)
                            }
                        } else {
                            self.wait()
                            continuation.resume()
                        }
                    }
                }
            }
            """,
            """
            /// Signals one waiting thread to wake up
            func notify() {
                _condition.lock()
                _condition.signal()
                _condition.unlock()
            }
            """,
            """
            /// Signals all waiting threads to wake up
            func notifyAll() {
                _condition.lock()
                _condition.broadcast()
                _condition.unlock()
            }
            """,
            """
            /// Gets the current number of waiting threads
            /// - Returns: Number of threads waiting on this object's condition
            func getWaitingThreadCount() -> Int {
                synchronized { _waitingThreads }
            }
            """,
            """
            /// Attempts to acquire the lock without blocking
            /// - Returns: True if lock was acquired, false otherwise
            func tryLock() -> Bool {
                return _lock.try()
            }
            """,
            """
            /// Acquires the lock, blocking if necessary
            func lock() {
                _lock.lock()
            }
            """,
            """
            /// Releases the lock
            func unlock() {
                _lock.unlock()
            }
            """,
            """
            /// Executes a read operation with multiple reader access
            /// - Parameter readOperation: Code to execute with shared access
            /// - Returns: Result of the read operation
            func read<T>(_ readOperation: () throws -> T) rethrows -> T {
                _syncQueue.sync {
                    try readOperation()
                }
            }
            """,
            """
            /// Executes a write operation with exclusive access
            /// - Parameter writeOperation: Code to execute with exclusive access
            /// - Returns: Result of the write operation
            func write<T>(_ writeOperation: () throws -> T) rethrows -> T {
                _syncQueue.sync(flags: .barrier) {
                    try writeOperation()
                }
            }
            """,
            """
            /// Actor-based synchronized execution pattern (Swift 5.5+)
            /// - Parameter operation: Operation to execute with synchronization
            /// - Returns: Result of the operation
            @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
            func withSynchronizedActor<T>(_ operation: @escaping () async throws -> T) async throws -> T {
                actor SynchronizationActor {
                    func execute<T>(_ operation: () async throws -> T) async throws -> T {
                        try await operation()
                    }
                }
                
                let syncActor = SynchronizationActor()
                return try await syncActor.execute(operation)
            }
            """,
        ]
    }
}

/// Implementation of the `@Override` macro for Java-like method override annotation
public struct OverrideMacro: MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        // Swift doesn't require an explicit @override attribute, but we can add it anyway
        return [
            AttributeSyntax(
                attributeName: SimpleTypeIdentifierSyntax(name: .identifier("override")))
        ]
    }
}

/// Implementation of the `@Final` macro for Java-like final class or method annotation
public struct FinalMacro: MemberAttributeMacro, ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        // Add 'final' keyword as an attribute
        return [
            AttributeSyntax(attributeName: SimpleTypeIdentifierSyntax(name: .identifier("final")))
        ]
    }

    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        // Nothing to add for extensions
        return []
    }
}

/// Implementation of `@Static` macro for Java-like static method/field annotation
public struct StaticMacro: MemberAttributeMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingAttributesFor member: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [AttributeSyntax] {
        // Add 'static' keyword as an attribute
        return [
            AttributeSyntax(attributeName: SimpleTypeIdentifierSyntax(name: .identifier("static")))
        ]
    }
}

@main
struct LavaMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        JavaBuilderMacro.self,
        PublicMacro.self,
        PrivateMacro.self,
        ProtectedMacro.self,
        JavaDocMacro.self,
        ThreadMacro.self,
        SymbolMacro.self,
        SynchronizedMacro.self,
        OverrideMacro.self,
        FinalMacro.self,
        StaticMacro.self,
    ]
}
