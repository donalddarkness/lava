// LavaUnified.swift
// Provides a single, organized namespace for all Lava APIs.

import Foundation
import Observation

/// Unified entrypoint for all Lava module features
public enum Lava {
    /// Async utilities: task status, futures, executors
    public enum Async {
        public typealias TaskStatus = TaskStatus
        public typealias TaskResult<T> = TaskResult<T>
        public typealias Future<T> = Future<T>
        public typealias Executor = TaskExecutor
        public typealias ExecutorType = TaskExecutor.ExecutorType

        /// Creates a single-thread executor
        public static func newSingleThreadExecutor() -> Executor {
            TaskExecutor.newSingleThreadExecutor()
        }
        /// Creates a fixed-size thread pool executor
        public static func newFixedThreadPool(nThreads: Int) -> Executor {
            TaskExecutor.newFixedThreadPool(nThreads: nThreads)
        }
        /// Creates a cached thread pool executor
        public static func newCachedThreadPool() -> Executor {
            TaskExecutor.newCachedThreadPool()
        }
        /// Creates a scheduled thread pool executor
        public static func newScheduledThreadPool(corePoolSize: Int) -> Executor {
            TaskExecutor.newScheduledThreadPool(corePoolSize: corePoolSize)
        }
    }

    /// Serialization utilities and adapters
    public enum Serialization {
        public typealias JavaSerializable = JavaSerializable
        public typealias Helper = SerializationHelper
        public typealias Adapter<T: Codable> = SerializationHelper.JavaSerializableCodableAdapter<T>
    }

    /// Synchronization (actor-based and global helpers)
    public enum Sync {
        public typealias Synchronization = Synchronization

        /// Executes an async closure with exclusive access
        @discardableResult
        public static func synchronized<T>(_ block: () async throws -> T) async rethrows -> T {
            try await Synchronization().synchronized(block)
        }

        /// Executes a synchronous closure with exclusive access
        @discardableResult
        public static func synchronized<T>(_ block: () throws -> T) async rethrows -> T {
            try await Synchronization().synchronized(block)
        }
    }

    /// MVC utilities: commands, HTTP, servlets
    public enum MVC {
        public typealias Command = Command
        public typealias CompositeCommand = CompositeCommand
        public typealias CommandManager = CommandManager
        public typealias HttpMethod = HttpMethod
        public typealias HttpStatus = HttpStatus
        public typealias HttpRequest = HttpRequest
        public typealias HttpResponse = HttpResponse
        public typealias DispatcherServlet = DispatcherServlet
        public typealias RequestInterceptor = DispatcherServlet.RequestInterceptor
    }

    /// Error types and helpers
    public enum Error {
        public typealias Lava = LavaError
    }
}

// MARK: - Flat aliases

/// Flat aliases for unified Lava API types
public typealias LavaFuture<T> = Lava.Async.Future<T>
public typealias LavaExecutor = Lava.Async.Executor
public typealias LavaExecutorType = Lava.Async.ExecutorType
public typealias LavaTaskStatus = Lava.Async.TaskStatus
public typealias LavaTaskResult<T> = Lava.Async.TaskResult<T>

public typealias LavaJavaSerializable = Lava.Serialization.JavaSerializable
public typealias LavaSerializationHelper = Lava.Serialization.Helper
public typealias LavaCodableAdapter<T: Codable> = Lava.Serialization.Adapter<T>

public typealias LavaSynchronization = Lava.Sync.Synchronization

public typealias LavaCommand = Lava.MVC.Command
public typealias LavaCompositeCommand = Lava.MVC.CompositeCommand
public typealias LavaCommandManager = Lava.MVC.CommandManager
public typealias LavaHttpMethod = Lava.MVC.HttpMethod
public typealias LavaHttpStatus = Lava.MVC.HttpStatus
public typealias LavaHttpRequest = Lava.MVC.HttpRequest
public typealias LavaHttpResponse = Lava.MVC.HttpResponse
public typealias LavaDispatcherServlet = Lava.MVC.DispatcherServlet
public typealias LavaRequestInterceptor = Lava.MVC.RequestInterceptor
public typealias LavaError = Lava.Error.Lava 