import Foundation
import Synchronization
import Observation

// MARK: - Asynchronous Task System (Java/C# Inspired)

/// Represents the status of an asynchronous task
public enum TaskStatus {
    case notStarted
    case running
    case succeeded
    case failed
    case cancelled

    public var isCompleted: Bool {
        self == .succeeded || self == .failed || self == .cancelled
    }
}

/// Result of an asynchronous task execution
public enum TaskResult<T> {
    case success(T)
    case failure(Error)

    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    public func getOrThrow() throws -> T {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }
}

/// Represents an asynchronous computation with Java-like Future semantics
public final class Future<T> {
    private let lock = NSLock()
    private var result: TaskResult<T>?
    private var completionHandlers: [(TaskResult<T>) -> Void] = []
    private var status: TaskStatus = .notStarted

    public init() {}

    public func complete(with result: TaskResult<T>) {
        lock.lock()
        defer { lock.unlock() }

        guard self.result == nil else { return }
        self.result = result
        self.status = result.isSuccess ? .succeeded : .failed

        completionHandlers.forEach { $0(result) }
        completionHandlers.removeAll()
    }

    public func onComplete(handler: @escaping (TaskResult<T>) -> Void) {
        lock.lock()
        defer { lock.unlock() }

        if let result = self.result {
            handler(result)
        } else {
            completionHandlers.append(handler)
        }
    }

    public func get(timeout: TimeInterval? = nil) throws -> T {
        let semaphore = DispatchSemaphore(value: 0)
        var localResult: TaskResult<T>?

        onComplete { result in
            localResult = result
            semaphore.signal()
        }

        if let timeout = timeout {
            guard semaphore.wait(timeout: .now() + timeout) != .timedOut else {
                throw LavaError.operationTimeout("Future.get() timed out after \(timeout) seconds")
            }
        } else {
            semaphore.wait()
        }

        guard let result = localResult else {
            throw LavaError.invalidState("Future result not available")
        }

        return try result.getOrThrow()
    }

    public func isCompleted() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return result != nil
    }

    public func getStatus() -> TaskStatus {
        lock.lock()
        defer { lock.unlock() }
        return status
    }
}

/// Java-like Task Executor service
public final class TaskExecutor {
    public enum ExecutorType {
        case singleThread
        case fixedThreadPool(Int)
        case cachedThreadPool
        case scheduledThreadPool(Int)
    }

    private let queue: DispatchQueue
    private let type: ExecutorType
    private let maxConcurrentTasks: Int?
    private let semaphore: DispatchSemaphore?

    public static func newSingleThreadExecutor() -> TaskExecutor {
        TaskExecutor(type: .singleThread)
    }

    public static func newFixedThreadPool(nThreads: Int) -> TaskExecutor {
        TaskExecutor(type: .fixedThreadPool(nThreads))
    }

    public static func newCachedThreadPool() -> TaskExecutor {
        TaskExecutor(type: .cachedThreadPool)
    }

    public static func newScheduledThreadPool(corePoolSize: Int) -> TaskExecutor {
        TaskExecutor(type: .scheduledThreadPool(corePoolSize))
    }

    private init(type: ExecutorType) {
            self.type = type

            // Create appropriate dispatch queue and semaphore configuration based on executor type
            switch type {
            case .singleThread:
                self.queue = DispatchQueue(label: "com.lava.executor.single", qos: .userInitiated)
                self.maxConcurrentTasks = 1
                self.semaphore = DispatchSemaphore(value: 1)
                LavaLogger.debug("Created single thread executor")

            case .fixedThreadPool(let count):
                let actualCount = max(1, count) // Ensure at least 1 thread
                self.queue = DispatchQueue(label: "com.lava.executor.fixed", qos: .userInitiated, attributes: .concurrent)
                self.maxConcurrentTasks = actualCount
                self.semaphore = DispatchSemaphore(value: actualCount)
                LavaLogger.debug("Created fixed thread pool with \(actualCount) threads")

            case .cachedThreadPool:
                self.queue = DispatchQueue(label: "com.lava.executor.cached", qos: .userInitiated, attributes: .concurrent)
                self.maxConcurrentTasks = nil
                self.semaphore = nil
                LavaLogger.debug("Created cached thread pool")

            case .scheduledThreadPool(let coreSize):
                let actualSize = max(1, coreSize) // Ensure at least 1 thread
                self.queue = DispatchQueue(label: "com.lava.executor.scheduled", qos: .userInitiated, attributes: .concurrent)
                self.maxConcurrentTasks = actualSize
                self.semaphore = DispatchSemaphore(value: actualSize)
                LavaLogger.debug("Created scheduled thread pool with \(actualSize) core threads")
            }
    }

    public func submit<T>(_ task: @escaping () throws -> T) -> Future<T> {
        let future = Future<T>()

        let executeTask = {
            do {
                future.complete(with: .success(try task()))
            } catch {
                future.complete(with: .failure(error))
            }

            self.semaphore?.signal()
        }

        if let semaphore = self.semaphore {
            queue.async {
                semaphore.wait()
                executeTask()
            }
        } else {
            queue.async(execute: executeTask)
        }

        return future
    }

    public func schedule<T>(_ task: @escaping () throws -> T, delay: TimeInterval) -> Future<T> {
        let future = Future<T>()

        let executeTask = {
            do {
                future.complete(with: .success(try task()))
            } catch {
                future.complete(with: .failure(error))
            }

            self.semaphore?.signal()
        }

        if let semaphore = self.semaphore {
            queue.asyncAfter(deadline: .now() + delay) {
                semaphore.wait()
                executeTask()
            }
        } else {
            queue.asyncAfter(deadline: .now() + delay, execute: executeTask)
        }

        return future
    }

    public func shutdown() {
        LavaLogger.info("TaskExecutor shutting down")
    }

    public func shutdownNow() {
        LavaLogger.info("TaskExecutor immediate shutdown requested")
    }
}

/// Java CompletableFuture-like implementation
public final class CompletableFuture<T> {
    private let future = Future<T>()
    private let executor: TaskExecutor

    public init(executor: TaskExecutor = TaskExecutor.newCachedThreadPool()) {
        self.executor = executor
    }

    public static func completedFuture(_ value: T) -> CompletableFuture<T> {
        let future = CompletableFuture<T>()
        future.complete(value)
        return future
    }

    public static func failedFuture(_ error: Error) -> CompletableFuture<T> {
        let future = CompletableFuture<T>()
        future.completeExceptionally(error)
        return future
    }

    public static func supplyAsync(_ supplier: @escaping () throws -> T, executor: TaskExecutor? = nil) -> CompletableFuture<T> {
        let future = CompletableFuture<T>(executor: executor ?? TaskExecutor.newCachedThreadPool())

        (executor ?? future.executor).submit {
            do {
                future.complete(try supplier())
            } catch {
                future.completeExceptionally(error)
            }
            return Void()
        }

        return future
    }

    public func complete(_ value: T) {
        future.complete(with: .success(value))
    }

    public func completeExceptionally(_ error: Error) {
        future.complete(with: .failure(error))
    }

    public func thenApply<U>(_ fn: @escaping (T) throws -> U) -> CompletableFuture<U> {
        let resultFuture = CompletableFuture<U>(executor: executor)

        future.onComplete { result in
            switch result {
            case .success(let value):
                self.executor.submit {
                    do {
                        resultFuture.complete(try fn(value))
                    } catch {
                        resultFuture.completeExceptionally(error)
                    }
                    return Void()
                }
            case .failure(let error):
                resultFuture.completeExceptionally(error)
            }
        }

        return resultFuture
    }

    public func thenAccept(_ consumer: @escaping (T) throws -> Void) -> CompletableFuture<Void> {
        thenApply { value in
            try consumer(value)
            return ()
        }
    }

    public func exceptionally(_ handler: @escaping (Error) throws -> T) -> CompletableFuture<T> {
        let resultFuture = CompletableFuture<T>(executor: executor)

        future.onComplete { result in
            switch result {
            case .success(let value):
                resultFuture.complete(value)
            case .failure(let error):
                self.executor.submit {
                    do {
                        resultFuture.complete(try handler(error))
                    } catch {
                        resultFuture.completeExceptionally(error)
                    }
                    return Void()
                }
            }
        }

        return resultFuture
    }

    public func get(timeout: TimeInterval? = nil) throws -> T {
        try future.get(timeout: timeout)
    }

    public func join() -> T? {
        do {
            return try get()
        } catch {
            LavaLogger.error("Error joining CompletableFuture: \(error)")
            return nil
        }
    }

    public func isCompleted() -> Bool {
        future.isCompleted()
    }
}
