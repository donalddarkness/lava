import Foundation
import Lava

/// ModernDemo - Main entry point for the Lava framework demo
/// Demonstrates modern Swift syntax and patterns
///
/// This demo showcases:
/// - Modern Swift concurrency with async/await
/// - Result builders for fluent APIs
/// - Actors for thread safety
/// - Property wrappers for access control
/// - Modern Swift documentation style
public actor ModernDemo {

    /// Shared counter for concurrency demonstration
    @ThreadSafe private var counter: Int = 0

    /// Document builder using result builder pattern
    @resultBuilder
    public struct DocumentBuilder {
        public static func buildBlock(_ components: String...) -> String {
            components.joined(separator: "\n")
        }

        public static func buildExpression(_ expression: String) -> String {
            expression
        }
    }

    /// Creates a document using the result builder pattern
    public static func document(@DocumentBuilder content: () -> String) -> Document {
        Document(content: content())
    }

    /// Modern document type using Swift property wrappers
    public struct Document {
        @Published private(set) var content: String

        public init(content: String) {
            self.content = content
        }

        public var description: String {
            content
        }
    }

    /// Thread-safe task manager using modern Swift concurrency
    public actor TaskManager {
        private var tasks: [String: Task<Void, Error>] = [:]

        public func executeTask(
            name: String, priority: TaskPriority? = nil,
            operation: @escaping () async throws -> Void
        ) async {
            let task = Task(priority: priority) {
                try await operation()
            }
            tasks[name] = task
        }

        public func waitForAllTasks(timeout: Duration) async throws -> Bool {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for (name, task) in tasks {
                    group.addTask {
                        try await withTimeout(timeout) {
                            _ = try await task.value
                            print("Task \(name) completed")
                        }
                    }
                }

                do {
                    try await group.waitForAll()
                    return true
                } catch {
                    print("Some tasks did not complete within timeout: \(error)")
                    return false
                }
            }
        }

        private func withTimeout<T>(_ timeout: Duration, operation: @escaping () async throws -> T)
            async throws -> T
        {
            try await withThrowingTaskGroup(of: T.self) { group in
                group.addTask {
                    try await operation()
                }

                group.addTask {
                    try await Task.sleep(for: timeout)
                    throw TimeoutError()
                }

                let result = try await group.next()!
                group.cancelAll()
                return result
            }
        }

        struct TimeoutError: Error {
            var localizedDescription: String {
                "Operation timed out"
            }
        }
    }

    /// Main entry point demonstrating modern Swift features
    public static func main() async throws {
        print("Starting ModernDemo with modern Swift syntax...")

        // Create document using result builder
        let document = document {
            "# Thread Demo"
            ""
            "## Modern Swift Concurrency"
            ""
            "This example demonstrates modern Swift concurrency patterns"
        }

        print(document.description)

        // Create task manager instance
        let taskManager = TaskManager()

        // Start multiple concurrent tasks
        for i in 1...5 {
            await taskManager.executeTask(name: "Worker-\(i)") {
                try await Task.sleep(for: .milliseconds(100))
                print("Task \(i) starting work")

                let instance = ModernDemo()
                await instance.incrementCounter()

                print("Task \(i) completed work")
            }
        }

        // Wait for tasks with timeout
        print("Waiting for all tasks to complete...")
        let allTasksCompleted = try await taskManager.waitForAllTasks(timeout: .seconds(3))

        let demo = ModernDemo()
        let finalCount = await demo.counter

        if allTasksCompleted {
            print("All tasks completed successfully. Final counter value: \(finalCount)")
        } else {
            print("Some tasks did not complete within timeout. Final counter value: \(finalCount)")
        }

        // Demonstrate modern reflection
        print("Type information via KeyPath: \(String(reflecting: ModernDemo.self))")
    }

    /// Thread-safe counter increment
    private func incrementCounter() async {
        print("Entering critical section")
        let oldValue = counter
        counter = oldValue + 1
        print("Updated counter: \(oldValue) -> \(counter)")
    }
}

// Property wrapper for thread-safe variables
@propertyWrapper
public struct ThreadSafe<Value> {
    private var value: Value
    private let lock = NSLock()

    public init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    public var wrappedValue: Value {
        get {
            lock.lock()
            defer { lock.unlock() }
            return value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            value = newValue
        }
    }
}

// Start the program with modern async/await
@main
struct ModernDemoRunner {
    static func main() async throws {
        try await ModernDemo.main()
    }
}
