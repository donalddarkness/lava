import Foundation

/// Protocol for objects that can be serialized in a Java-like fashion
public protocol JavaSerializable {
    /// Serializes the object to binary data
    /// - Returns: Serialized data or nil if serialization failed
    func serialize() -> Data?
    
    /// Creates an instance from serialized data
    /// - Parameter data: The serialized data to deserialize
    /// - Returns: An instance of the type or nil if deserialization failed
    static func deserialize(from data: Data) -> Self?
}

/// Provides utility methods for serialization and deserialization of JavaSerializable objects
public struct SerializationHelper {
    /// Writes a JavaSerializable object to a file as JSON
    /// - Parameters:
    ///   - object: The object to serialize
    ///   - filePath: The path to write the file to
    /// - Throws: File I/O errors or serialization errors
    public static func writeJson<T: JavaSerializable>(_ object: T, to filePath: String) throws {
        guard let data = object.serialize() else {
            throw LavaError.serializationFailed("Failed to serialize object")
        }
        
        // Create directory if it doesn't exist
        let directory = (filePath as NSString).deletingLastPathComponent
        try FileManager.default.createDirectory(
            atPath: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        // Write data to file
        try data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
    }
    
    /// Reads a JavaSerializable object from a JSON file
    /// - Parameter filePath: The path to read from
    /// - Returns: The deserialized object
    /// - Throws: File I/O errors or deserialization errors
    public static func readJson<T: JavaSerializable>(from filePath: String) throws -> T {
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw LavaError.fileNotFound("File not found at path: \(filePath)")
        }
        
        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        guard let object = T.deserialize(from: data) else {
            throw LavaError.deserializationFailed("Failed to deserialize object from \(filePath)")
        }
        
        return object
    }
    
    /// Clones a JavaSerializable object through serialization and deserialization
    /// - Parameter object: Object to clone
    /// - Returns: A deep copy of the object
    /// - Throws: Serialization errors
    public static func deepClone<T: JavaSerializable>(_ object: T) throws -> T {
        guard let data = object.serialize() else {
            throw LavaError.serializationFailed("Failed to serialize object for cloning")
        }
        
        guard let clone = T.deserialize(from: data) else {
            throw LavaError.deserializationFailed("Failed to deserialize cloned object")
        }
        
        return clone
    }
    
    /// Converts a JavaSerializable object to a JSON string
    /// - Parameter object: The object to convert
    /// - Returns: JSON string representation or nil if serialization failed
    public static func toJsonString<T: JavaSerializable>(_ object: T) -> String? {
        guard let data = object.serialize() else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Creates a JavaSerializable object from a JSON string
    /// - Parameters:
    ///   - jsonString: The JSON string to parse
    ///   - type: The type to deserialize to
    /// - Returns: Deserialized object or nil if parsing failed
    public static func fromJsonString<T: JavaSerializable>(_ jsonString: String, type: T.Type) -> T? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return T.deserialize(from: data)
    }
    
    /// Reads multiple objects from a JSON array in a file
    /// - Parameter filePath: Path to the JSON array file
    /// - Returns: Array of deserialized objects
    /// - Throws: File I/O or deserialization errors
    public static func readJsonArray<T: JavaSerializable>(from filePath: String) throws -> [T] {
        guard FileManager.default.fileExists(atPath: filePath) else {
            throw LavaError.fileNotFound("File not found at path: \(filePath)")
        }
        
        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        guard let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw LavaError.deserializationFailed("Failed to parse JSON array")
        }
        
        // Convert each dictionary to data and deserialize
        return jsonArray.compactMap { dictionary in
            guard let itemData = try? JSONSerialization.data(withJSONObject: dictionary) else {
                return nil
            }
            return T.deserialize(from: itemData)
        }
    }
    
    /// Writes multiple objects as a JSON array to a file
    /// - Parameters:
    ///   - objects: Array of JavaSerializable objects
    ///   - filePath: Path to write to
    /// - Throws: Serialization or file I/O errors
    public static func writeJsonArray<T: JavaSerializable>(_ objects: [T], to filePath: String) throws {
        var jsonArray: [[String: Any]] = []
        
        for object in objects {
            guard let objectData = object.serialize(),
                  let dictionary = try? JSONSerialization.jsonObject(with: objectData) as? [String: Any] else {
                throw LavaError.serializationFailed("Failed to serialize array item")
            }
            jsonArray.append(dictionary)
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
        try jsonData.write(to: URL(fileURLWithPath: filePath), options: .atomic)
    }
}

/// Extension to support Codable objects as JavaSerializable
extension SerializationHelper {
    /// Converts any Codable to JavaSerializable via adapter
    public static func asJavaSerializable<T: Codable>(_ codable: T) -> JavaSerializableCodableAdapter<T> {
        return JavaSerializableCodableAdapter(codable)
    }
    
    /// Adapter class to bridge Codable types to JavaSerializable
    public class JavaSerializableCodableAdapter<T: Codable>: JavaSerializable {
        private let wrappedValue: T
        
        public init(_ value: T) {
            self.wrappedValue = value
        }
        
        public func serialize() -> Data? {
            return try? JSONEncoder().encode(wrappedValue)
        }
        
        public static func deserialize(from data: Data) -> JavaSerializableCodableAdapter<T>? {
            guard let decoded = try? JSONDecoder().decode(T.self, from: data) else {
                return nil
            }
            return JavaSerializableCodableAdapter(decoded)
        }
        
        public var value: T {
            return wrappedValue
        }
    }
}

/// Error type definition for serialization errors
public extension LavaError {
    static func serializationFailed(_ message: String) -> LavaError {
        return .custom(code: "SERIALIZATION_FAILED", message: message)
    }
    
    static func deserializationFailed(_ message: String) -> LavaError {
        return .custom(code: "DESERIALIZATION_FAILED", message: message)
    }
    
    static func fileNotFound(_ message: String) -> LavaError {
        return .custom(code: "FILE_NOT_FOUND", message: message)
    }
}