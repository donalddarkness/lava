import Foundation

/// A utility for thread-safe execution of critical sections.
/// An actor for thread-safe execution of critical sections.
public actor Synchronization {
    public init() {}

    /// Executes an async closure with exclusive access.
    /// - Parameter criticalSection: The async work to perform inside the actor.
    /// - Returns: The result of the critical section.
    public func synchronized<T>(_ criticalSection: () async throws -> T) async rethrows -> T {
        return try await criticalSection()
    }

    /// Executes a synchronous closure with exclusive access.
    /// - Parameter criticalSection: The work to perform inside the actor.
    /// - Returns: The result of the critical section.
    public func synchronized<T>(_ criticalSection: () throws -> T) async rethrows -> T {
        return try criticalSection()
    }
}

/// Global function for convenience, wrapping `Synchronization.synchronized`.
/// - Parameter block: The work to perform inside a lock.
/// - Returns: The result of the block.
/// Global async function for convenience, wrapping actor-based synchronization.
/// - Parameter block: The async work to perform inside a lock.
/// - Returns: The result of the block.
@discardableResult
public func synchronized<T>(_ block: () async throws -> T) async rethrows -> T {
    return try await Synchronization().synchronized(block)
}

/// Global async convenience for synchronous blocks.
/// - Parameter block: The work to perform inside a lock.
/// - Returns: The result of the block.
@discardableResult
public func synchronized<T>(_ block: () throws -> T) async rethrows -> T {
    return try await Synchronization().synchronized(block)
}