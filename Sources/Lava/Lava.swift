// Lava DSL implementation with Java and C# features
// Using Swift macros to mimic Java and C# conventions
import Foundation
import Synchronization

/// Production configuration for managing runtime behavior
@frozen public struct ProductionConfig {
    public let enableTelemetry: Bool
    public let errorReportingLevel: ErrorReportingLevel
    public let performanceLoggingThreshold: UInt64  // in nanoseconds
    public let cacheSize: Int
    public let maxConcurrentOperations: Int
    public let customLogHandlers: [LogHandler]?

    public static let `default` = ProductionConfig {
        enableTelemetry(true)
        errorReportingLevel(.warning)
        performanceLoggingThreshold(1_000_000)  // 1ms
        cacheSize(2048)
        maxConcurrentOperations(8)
        customLogHandlers(nil)
    }

    public enum ErrorReportingLevel: Int, Codable {
        case none = 0
        case critical = 1
        case error = 2
        case warning = 3
        case info = 4
        case debug = 5

        public var description: String {
            switch self {
            case .none: return "None"
            case .critical: return "Critical"
            case .error: return "Error"
            case .warning: return "Warning"
            case .info: return "Info"
            case .debug: return "Debug"
            }
        }
    }

    public init(
        enableTelemetry: Bool = true,
        errorReportingLevel: ErrorReportingLevel = .warning,
        performanceLoggingThreshold: UInt64 = 1_000_000,
        cacheSize: Int = 2048,
        maxConcurrentOperations: Int = 8,
        customLogHandlers: [LogHandler]? = nil
    ) {
        self.enableTelemetry = enableTelemetry
        self.errorReportingLevel = errorReportingLevel
        self.performanceLoggingThreshold = performanceLoggingThreshold
        self.cacheSize = cacheSize
        self.maxConcurrentOperations = maxConcurrentOperations
        self.customLogHandlers = customLogHandlers
    }

    /// Creates a configuration for high-performance environments
    public static func highPerformance() -> ProductionConfig {
        ProductionConfig {
            enableTelemetry(true)
            errorReportingLevel(.error)
            performanceLoggingThreshold(5_000_000)  // 5ms
            cacheSize(8192)
            maxConcurrentOperations(16)
        }
    }

    /// Creates a configuration for debugging environments
    public static func debug() -> ProductionConfig {
        ProductionConfig {
            enableTelemetry(true)
            errorReportingLevel(.debug)
            performanceLoggingThreshold(100_000)  // 0.1ms
            cacheSize(1024)
            maxConcurrentOperations(4)
        }
    }
}

/// Log handler protocol for custom logging implementations
public protocol LogHandler {
    func log(level: ProductionConfig.ErrorReportingLevel, message: String, file: String, line: Int)
    func logTelemetry(eventName: String, metadata: [String: Any])
    func logPerformance(operation: String, durationNs: UInt64, durationMs: Double)
}

/// Logger for production environments with telemetry support
public actor LavaLogger {
    private var telemetryEnabled = true
    private var errorReportingLevel: ProductionConfig.ErrorReportingLevel = .warning
    private var performanceThreshold: UInt64 = 1_000_000
    private var customLogHandlers: [LogHandler] = []

    // File logging support
    private let fileLogger = FileLogger()
    private var enableFileLogging = false

    /// Configure the logger with production settings
    public func configure(config: ProductionConfig) async {
        telemetryEnabled = config.enableTelemetry
        errorReportingLevel = config.errorReportingLevel
        performanceThreshold = config.performanceLoggingThreshold

        if let handlers = config.customLogHandlers {
            customLogHandlers = handlers
        }
    }

    /// Enable logging to file with custom path
    public func enableFileLogging(directory: String? = nil, prefix: String = "lava_log") async {
        enableFileLogging = true
        await fileLogger.configure(directory: directory, filePrefix: prefix)
    }

    /// Disable file logging
    public func disableFileLogging() async {
        enableFileLogging = false
    }

    public func critical(_ message: String, file: String = #file, line: Int = #line) async {
        guard errorReportingLevel.rawValue >= ProductionConfig.ErrorReportingLevel.critical.rawValue else { return }
        let formattedMessage = "\(message) [\(file):\(line)]"
        print("[CRITICAL] \(formattedMessage)")

        if enableFileLogging {
            await fileLogger.log(level: .critical, message: formattedMessage, file: file, line: line)
        }

        for handler in customLogHandlers {
            handler.log(level: .critical, message: message, file: file, line: line)
        }

        #if DEBUG
            assertionFailure(message)
        #endif
    }

    public static func error(_ message: String, file: String = #file, line: Int = #line) {
        if errorReportingLevel.rawValue >= ProductionConfig.ErrorReportingLevel.error.rawValue {
            let formattedMessage = "\(message) [\(file):\(line)]"
            print("[ERROR] \(formattedMessage)")

            if enableFileLogging {
                fileLogger.log(level: .error, message: formattedMessage, file: file, line: line)
            }

            for handler in customLogHandlers {
                handler.log(level: .error, message: message, file: file, line: line)
            }
        }
    }

    public static func warning(_ message: String, file: String = #file, line: Int = #line) {
        if errorReportingLevel.rawValue >= ProductionConfig.ErrorReportingLevel.warning.rawValue {
            let formattedMessage = "\(message) [\(file):\(line)]"
            print("[WARNING] \(formattedMessage)")

            if enableFileLogging {
                fileLogger.log(level: .warning, message: formattedMessage, file: file, line: line)
            }

            for handler in customLogHandlers {
                handler.log(level: .warning, message: message, file: file, line: line)
            }
        }
    }

    public static func info(_ message: String, file: String = #file, line: Int = #line) {
        if errorReportingLevel.rawValue >= ProductionConfig.ErrorReportingLevel.info.rawValue {
            let formattedMessage = "\(message) [\(file):\(line)]"
            print("[INFO] \(formattedMessage)")

            if enableFileLogging {
                fileLogger.log(level: .info, message: formattedMessage, file: file, line: line)
            }

            for handler in customLogHandlers {
                handler.log(level: .info, message: message, file: file, line: line)
            }
        }
    }

    public static func debug(_ message: String, file: String = #file, line: Int = #line) {
        if errorReportingLevel.rawValue >= ProductionConfig.ErrorReportingLevel.debug.rawValue {
            let formattedMessage = "\(message) [\(file):\(line)]"
            print("[DEBUG] \(formattedMessage)")

            if enableFileLogging {
                fileLogger.log(level: .debug, message: formattedMessage, file: file, line: line)
            }

            for handler in customLogHandlers {
                handler.log(level: .debug, message: message, file: file, line: line)
            }
        }
    }

    public func logTelemetry(_ eventName: String, metadata: [String: Any] = [:]) async {
        guard telemetryEnabled else { return }

        let formattedMessage = "[TELEMETRY] Event: \(eventName) Metadata: \(metadata)"
        print(formattedMessage)

        // Log to file if enabled
        if enableFileLogging {
            await fileLogger.logTelemetry(eventName: eventName, metadata: metadata)
        }

        // Log to custom handlers
        for handler in customLogHandlers {
            handler.logTelemetry(eventName: eventName, metadata: metadata)
        }
    }

    /// Logs performance metrics if duration exceeds threshold
    public static func logPerformance(_ operation: String, durationNs: UInt64) {
        guard telemetryEnabled && durationNs > performanceThreshold else { return }
        let ms = Double(durationNs) / 1_000_000.0

        let formattedMessage = "[PERFORMANCE] Operation: \(operation) took \(ms) ms"
        print(formattedMessage)

        // Log to file if enabled
        if enableFileLogging {
            fileLogger.logPerformance(operation: operation, durationNs: durationNs, durationMs: ms)
        }

        // Log to custom handlers
        for handler in customLogHandlers {
            handler.logPerformance(operation: operation, durationNs: durationNs, durationMs: ms)
        }
    }

    /// Measures execution time of a block of code
    @discardableResult
    public static func measure<T>(_ operation: String, block: () throws -> T) rethrows -> T {
        let startTime = DispatchTime.now()
        let result = try block()
        let endTime = DispatchTime.now()
        let durationNs = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
        logPerformance(operation, durationNs: durationNs)
        return result
    }

    /// File-based logger implementation
    private actor FileLogger {
        private var logFileURL: URL?
        private let dateFormatter: DateFormatter
        private let fileManager = FileManager.default

        init() {
            dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        }

        func configure(directory: String?, filePrefix: String) async {
            let logsDirectory: URL

            if let customDir = directory {
                logsDirectory = URL(fileURLWithPath: customDir)
                try? fileManager.createDirectory(
                    at: logsDirectory, withIntermediateDirectories: true)
            } else {
                logsDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
                    .appendingPathComponent("LavaLogs")
                try? fileManager.createDirectory(
                    at: logsDirectory, withIntermediateDirectories: true)
            }

            let dateStr = ISO8601DateFormatter().string(from: Date())
            let fileName = "\(filePrefix)_\(dateStr).log"
            logFileURL = logsDirectory.appendingPathComponent(fileName)
        }

        func log(
            level: ProductionConfig.ErrorReportingLevel, message: String, file: String, line: Int
        ) {
            guard let url = logFileURL else { return }
            let timestamp = dateFormatter.string(from: Date())
            let logMessage = "[\(timestamp)] [\(level.description.uppercased())] \(message)\n"

            logQueue.async {
                if let data = logMessage.data(using: .utf8) {
                    if self.fileManager.fileExists(atPath: url.path) {
                        if let fileHandle = try? FileHandle(forWritingTo: url) {
                            fileHandle.seekToEndOfFile()
                            fileHandle.write(data)
                            try? fileHandle.close()
                        }
                    } else {
                        try? data.write(to: url)
                    }
                }
            }
        }

        func logTelemetry(eventName: String, metadata: [String: Any]) {
            guard let url = logFileURL else { return }
            let timestamp = dateFormatter.string(from: Date())
            let logMessage =
                "[\(timestamp)] [TELEMETRY] Event: \(eventName) Metadata: \(metadata)\n"

            logQueue.async {
                if let data = logMessage.data(using: .utf8) {
                    if self.fileManager.fileExists(atPath: url.path) {
                        if let fileHandle = try? FileHandle(forWritingTo: url) {
                            fileHandle.seekToEndOfFile()
                            fileHandle.write(data)
                            try? fileHandle.close()
                        }
                    } else {
                        try? data.write(to: url)
                    }
                }
            }
        }

        func logPerformance(operation: String, durationNs: UInt64, durationMs: Double) {
            guard let url = logFileURL else { return }
            let timestamp = dateFormatter.string(from: Date())
            let logMessage =
                "[\(timestamp)] [PERFORMANCE] Operation: \(operation) took \(durationMs) ms\n"

            logQueue.async {
                if let data = logMessage.data(using: .utf8) {
                    if self.fileManager.fileExists(atPath: url.path) {
                        if let fileHandle = try? FileHandle(forWritingTo: url) {
                            fileHandle.seekToEndOfFile()
                            fileHandle.write(data)
                            try? fileHandle.close()
                        }
                    } else {
                        try? data.write(to: url)
                    }
                }
            }
        }
    }
}

/// Console log handler implementation
public class ConsoleLogHandler: LogHandler {
    public init() {}

    public func log(
        level: ProductionConfig.ErrorReportingLevel, message: String, file: String, line: Int
    ) {
        let levelString = level.description.uppercased()
        print("[\(levelString)] \(message) [\(file):\(line)]")
    }

    public func logTelemetry(eventName: String, metadata: [String: Any]) {
        print("[TELEMETRY] \(eventName) \(metadata)")
    }

    public func logPerformance(operation: String, durationNs: UInt64, durationMs: Double) {
        print("[PERFORMANCE] \(operation) took \(durationMs) ms")
    }
}
