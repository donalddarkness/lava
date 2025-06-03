import Foundation

/// Represents errors that can occur in Lava framework
public enum LavaError: Error, CustomStringConvertible, Hashable {
    /// Operation timed out
    case operationTimeout(String)
    
    /// Invalid state error
    case invalidState(String)
    
    /// Invalid parameter error
    case invalidParameter(String)
    
    /// Network related error
    case networkError(String)
    
    /// File I/O error
    case fileError(String)
    
    /// Parsing error
    case parseError(String)
    
    /// Custom error with code and message
    case custom(code: String, message: String)
    
    /// Not implemented error
    case notImplemented(String)
    
    /// Operation not supported
    case notSupported(String)
    
    /// Authorization error
    case authorizationError(String)
    
    /// User-readable description of the error
    public var description: String {
        switch self {
        case .operationTimeout(let message):
            return "Operation timeout: \(message)"
        case .invalidState(let message):
            return "Invalid state: \(message)"
        case .invalidParameter(let message):
            return "Invalid parameter: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .fileError(let message):
            return "File error: \(message)"
        case .parseError(let message):
            return "Parse error: \(message)"
        case .custom(let code, let message):
            return "[\(code)] \(message)"
        case .notImplemented(let message):
            return "Not implemented: \(message)"
        case .notSupported(let message):
            return "Not supported: \(message)"
        case .authorizationError(let message):
            return "Authorization error: \(message)"
        }
    }
    
    /// Returns a localized description for this error
    public var localizedDescription: String {
        return description
    }
    
    /// Constructs a new LavaError with the same type but a different message
    public func withMessage(_ message: String) -> LavaError {
        switch self {
        case .operationTimeout:
            return .operationTimeout(message)
        case .invalidState:
            return .invalidState(message)
        case .invalidParameter:
            return .invalidParameter(message)
        case .networkError:
            return .networkError(message)
        case .fileError:
            return .fileError(message)
        case .parseError:
            return .parseError(message)
        case .custom(let code, _):
            return .custom(code: code, message: message)
        case .notImplemented:
            return .notImplemented(message)
        case .notSupported:
            return .notSupported(message)
        case .authorizationError:
            return .authorizationError(message)
        }
    }
    
    /// Returns the error code as a string
    public var errorCode: String {
        switch self {
        case .operationTimeout:
            return "TIMEOUT"
        case .invalidState:
            return "INVALID_STATE"
        case .invalidParameter:
            return "INVALID_PARAMETER"
        case .networkError:
            return "NETWORK_ERROR"
        case .fileError:
            return "FILE_ERROR"
        case .parseError:
            return "PARSE_ERROR"
        case .custom(let code, _):
            return code
        case .notImplemented:
            return "NOT_IMPLEMENTED"
        case .notSupported:
            return "NOT_SUPPORTED"
        case .authorizationError:
            return "AUTHORIZATION_ERROR"
        }
    }
}

extension LavaError {
    /// Converts standard NSError to LavaError
    public static func from(_ error: NSError) -> LavaError {
        switch error.domain {
        case NSURLErrorDomain:
            return .networkError(error.localizedDescription)
        case NSCocoaErrorDomain where error.code == NSFileNoSuchFileError:
            return .fileError("File not found: \(error.localizedDescription)")
        case NSCocoaErrorDomain where error.code == NSFileReadNoPermissionError:
            return .fileError("Permission denied: \(error.localizedDescription)")
        case NSCocoaErrorDomain:
            return .fileError(error.localizedDescription)
        default:
            return .custom(code: "\(error.domain).\(error.code)", message: error.localizedDescription)
        }
    }
    
    /// Creates an error for when a required feature is not available
    public static func featureNotAvailable(_ feature: String, minimumOSVersion: String? = nil) -> LavaError {
        if let version = minimumOSVersion {
            return .notSupported("Feature '\(feature)' requires iOS \(version) or later")
        } else {
            return .notSupported("Feature '\(feature)' is not available")
        }
    }
}