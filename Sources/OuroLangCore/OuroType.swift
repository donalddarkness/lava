import Foundation

/// Represents OuroLang types and their MLIR representations
public enum OuroType {
    case primitive(PrimitiveType)
    case array(OuroType)
    case optional(OuroType)
    case tensor(TensorShape, OuroType)
    case vector(TensorShape, OuroType)
    case function([OuroType], OuroType)
    case dictionary(OuroType, OuroType) // Map/dictionary with key and value types
    case set(OuroType)                 // Set with element type
    case tuple([OuroType])             // Tuple with element types
    case map(OuroType, OuroType)       // Map with key and value types (alias for dictionary)
    case custom(String)                // Custom types like classes/interfaces
    
    /// Primitive types in OuroLang as specified in migration.md
    public enum PrimitiveType: String {
        // Standard types
        case int
        case uint
        case float
        case double
        case bool
        case boolean  // Alias for bool
        case string
        case char
        case void
        
        // Integer types with explicit sizes
        case byte     // 8-bit signed
        case ubyte    // 8-bit unsigned
        case short    // 16-bit signed
        case ushort   // 16-bit unsigned
        case long     // 64-bit signed
        case ulong    // 64-bit unsigned
        
        // Additional types from migration.md
        case decimal  // 128-bit high-precision decimal
        case half     // 16-bit floating-point
        
        /// Get the corresponding MLIR type string
        public var mlirType: String {
            switch self {
            case .int: return "i32"
            case .uint: return "ui32"
            case .float: return "f32"
            case .double: return "f64"
            case .bool, .boolean: return "i1"
            case .string: return "!llvm.ptr<i8>"
            case .char: return "i8"
            case .void: return "none"
            case .byte: return "i8"
            case .ubyte: return "ui8"
            case .short: return "i16"
            case .ushort: return "ui16"
            case .long: return "i64"
            case .ulong: return "ui64"
            case .decimal: return "f128" // Using f128 as best approximation in MLIR
            case .half: return "f16"
            }
        }
    }
      /// Create an OuroType from a string representation
    /// - Parameter typeName: The OuroLang type name string
    /// - Returns: The corresponding OuroType
    public static func from(typeName: String) -> OuroType {
        let lowerTypeName = typeName.lowercased()
        
        // Handle array types
        if typeName.hasSuffix("[]") {
            let baseTypeName = String(typeName.dropLast(2))
            return .array(from(typeName: baseTypeName))
        }
        
        // Handle optional types
        if typeName.hasSuffix("?") {
            let baseTypeName = String(typeName.dropLast(1))
            return .optional(from(typeName: baseTypeName))
        }
        
        // Handle tensor types
        if lowerTypeName.starts(with: "tensor<") && lowerTypeName.contains(">") {
            let dimensions = parseTensorDimensions(typeName)
            let elementType = parseTensorElementType(typeName)
            return .tensor(dimensions, from(typeName: elementType))
        }
        
        // Handle vector types
        if lowerTypeName.starts(with: "vector<") && lowerTypeName.contains(">") {
            let dimensions = parseTensorDimensions(typeName)
            let elementType = parseTensorElementType(typeName)
            return .vector(dimensions, from(typeName: elementType))
        }
        
        // Handle Map/Dictionary types
        if let mapMatch = parseGenericType(lowerTypeName, prefix: "map<") {
            guard mapMatch.count == 2 else {
                return .custom(typeName)
            }
            return .map(from(typeName: mapMatch[0]), from(typeName: mapMatch[1]))
        }
        
        // Handle Dictionary types
        if let dictMatch = parseGenericType(lowerTypeName, prefix: "dictionary<") {
            guard dictMatch.count == 2 else {
                return .custom(typeName)
            }
            return .dictionary(from(typeName: dictMatch[0]), from(typeName: dictMatch[1]))
        }
        
        // Handle Set types
        if let setMatch = parseGenericType(lowerTypeName, prefix: "set<") {
            guard setMatch.count == 1 else {
                return .custom(typeName)
            }
            return .set(from(typeName: setMatch[0]))
        }
        
        // Handle Tuple types
        if lowerTypeName.starts(with: "(") && lowerTypeName.hasSuffix(")") {
            // Extract types between parentheses
            let innerPart = String(lowerTypeName.dropFirst().dropLast())
            let typeStrings = splitGenericParameters(innerPart)
            let types = typeStrings.map { from(typeName: $0) }
            return .tuple(types)
        }
        
        // Handle Function types
        if lowerTypeName.contains("->") {
            let parts = lowerTypeName.split(separator: "->").map { String($0).trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2 else {
                return .custom(typeName)
            }
            
            // Process parameter types
            let paramPart = parts[0].trimmingCharacters(in: CharacterSet(charactersIn: "()"))
            let paramTypes = paramPart.isEmpty ? [] : splitGenericParameters(paramPart).map { from(typeName: $0) }
            
            // Process return type
            let returnType = from(typeName: parts[1])
            return .function(paramTypes, returnType)
        }
        
        // Handle primitive types
        if let primitiveType = PrimitiveType(rawValue: lowerTypeName) {
            return .primitive(primitiveType)
        }
        
        // Default to custom type
        return .custom(typeName)
    }
    
    /// Splits parameters in generic type declarations, respecting nested generics
    /// - Parameter paramString: The parameter string to split
    /// - Returns: Array of parameter type strings
    private static func splitGenericParameters(_ paramString: String) -> [String] {
        var result = [String]()
        var currentParam = ""
        var depth = 0
        
        for char in paramString {
            switch char {
            case "<", "(", "[":
                depth += 1
                currentParam.append(char)
            case ">", ")", "]":
                depth -= 1
                currentParam.append(char)
            case ",":
                if depth == 0 {
                    result.append(currentParam.trimmingCharacters(in: .whitespaces))
                    currentParam = ""
                } else {
                    currentParam.append(char)
                }
            default:
                currentParam.append(char)
            }
        }
        
        if !currentParam.isEmpty {
            result.append(currentParam.trimmingCharacters(in: .whitespaces))
        }
        
        return result
    }
    
    /// Parse generic type parameters like Map<K,V>, List<T>, etc.
    /// - Parameters:
    ///   - typeName: The type string to parse
    ///   - prefix: The prefix to look for (e.g., "map<")
    /// - Returns: Array of type parameters or nil if format doesn't match
    private static func parseGenericType(_ typeName: String, prefix: String) -> [String]? {
        guard typeName.starts(with: prefix), typeName.hasSuffix(">") else {
            return nil
        }
        
        let innerPart = String(typeName.dropFirst(prefix.count).dropLast())
        return splitGenericParameters(innerPart)
    }
    
    /// Parse tensor dimensions from a tensor type string
    /// - Parameter typeName: The tensor type string (e.g., "tensor<2x3xfloat>")
    /// - Returns: A TensorShape representing the dimensions
    private static func parseTensorDimensions(_ typeName: String) -> TensorShape {
        guard let start = typeName.firstIndex(of: "<"), 
              let end = typeName.lastIndex(of: ">") else {
            return TensorShape([])
        }
        
        let dimensionsStr = String(typeName[typeName.index(after: start)..<end])
        if let xIndex = dimensionsStr.lastIndex(of: "x") {
            // Extract just the dimensions part (e.g., "2x3" from "2x3xfloat")
            let dimPart = String(dimensionsStr[..<xIndex])
            let dims = dimPart.split(separator: "x").compactMap { dim -> TensorDimension? in
                if dim == "?" {
                    return .dynamic
                } else if let size = Int(dim) {
                    return .fixed(size)
                }
                return nil
            }
            return TensorShape(dims)
        }
        
        return TensorShape([])
    }
    
    /// Parse element type from a tensor type string
    /// - Parameter typeName: The tensor type string (e.g., "tensor<2x3xfloat>")
    /// - Returns: The element type string
    private static func parseTensorElementType(_ typeName: String) -> String {
        guard let start = typeName.firstIndex(of: "<"),
              let end = typeName.lastIndex(of: ">"),
              let xIndex = typeName[typeName.index(after: start)..<end].lastIndex(of: "x") else {
            return "float"  // Default
        }
        
        let dimensionsStr = String(typeName[typeName.index(after: start)..<end])
        let elementType = String(dimensionsStr[dimensionsStr.index(after: xIndex)...])
        return elementType
    }
      /// Convert the OuroType to its MLIR representation
    /// - Returns: The MLIR type string
    public var mlirType: String {
        switch self {
        case .primitive(let primitiveType):
            return primitiveType.mlirType
            
        case .array(let elementType):
            return "!llvm.ptr<\(elementType.mlirType)>"
            
        case .optional(let wrappedType):
            return "!llvm.ptr<\(wrappedType.mlirType)>"
            
        case .tensor(let shape, let elementType):
            return "tensor<\(shape.description)x\(elementType.mlirType)>"
            
        case .vector(let shape, let elementType):
            return "vector<\(shape.description)x\(elementType.mlirType)>"
            
        case .function(let paramTypes, let returnType):
            let paramTypeStr = paramTypes.map { $0.mlirType }.joined(separator: ", ")
            return "(\(paramTypeStr)) -> \(returnType.mlirType)"
            
        case .dictionary(let keyType, let valueType), .map(let keyType, let valueType):
            // Maps and dictionaries are represented as specialized structs in MLIR
            return "!llvm.struct<(ptr<\(keyType.mlirType)>, ptr<\(valueType.mlirType)>, i32)>"
            
        case .set(let elementType):
            // Sets are represented as specialized structs in MLIR
            return "!llvm.struct<(ptr<\(elementType.mlirType)>, i32)>"
            
        case .tuple(let elementTypes):
            let typeStr = elementTypes.map { $0.mlirType }.joined(separator: ", ")
            return "!llvm.struct<(\(typeStr))>"
            
        case .custom(let typeName):
            // Handle custom types (like classes)
            if typeName.contains(".") {
                return "!class.\(typeName)"
            }
            return "!\(typeName)"
        }
    }
    
    /// Get a string representation of the OuroType
    public var description: String {
        switch self {
        case .primitive(let primitiveType):
            return primitiveType.rawValue
            
        case .array(let elementType):
            return "\(elementType.description)[]"
            
        case .optional(let wrappedType):
            return "\(wrappedType.description)?"
            
        case .tensor(let shape, let elementType):
            return "tensor<\(shape.description)x\(elementType.description)>"
            
        case .vector(let shape, let elementType):
            return "vector<\(shape.description)x\(elementType.description)>"
            
        case .function(let paramTypes, let returnType):
            let paramTypeStr = paramTypes.map { $0.description }.joined(separator: ", ")
            return "(\(paramTypeStr)) -> \(returnType.description)"
            
        case .dictionary(let keyType, let valueType):
            return "Dictionary<\(keyType.description), \(valueType.description)>"
            
        case .map(let keyType, let valueType):
            return "Map<\(keyType.description), \(valueType.description)>"
            
        case .set(let elementType):
            return "Set<\(elementType.description)>"
            
        case .tuple(let elementTypes):
            let typeStr = elementTypes.map { $0.description }.joined(separator: ", ")
            return "(\(typeStr))"
            
        case .custom(let typeName):
            return typeName
        }
    }
}

// MARK: - Type Conversion Extensions

extension String {
    /// Convert an OuroLang type string to its MLIR representation
    /// - Returns: The MLIR type string
    public func toMLIRType() -> String {
        let ouroType = OuroType.from(typeName: self)
        return ouroType.mlirType
    }
    
    /// Check if this type string represents a tensor type
    public var isTensorType: Bool {
        self.starts(with: "tensor<") && self.contains(">")
    }
    
    /// Check if this type string represents a vector type
    public var isVectorType: Bool {
        self.starts(with: "vector<") && self.contains(">")
    }
    
    /// Check if this type string represents an array type
    public var isArrayType: Bool {
        self.hasSuffix("[]")
    }
    
    /// Check if this type string represents an optional type
    public var isOptionalType: Bool {
        self.hasSuffix("?") && !self.hasSuffix("[]?")
    }
}
