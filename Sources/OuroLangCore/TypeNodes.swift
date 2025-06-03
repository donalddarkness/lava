//
//  TypeNodes.swift
//  OuroLangCore
//
//  Created on June 3, 2025.
//

import Foundation

/// Protocol for type system behaviors with modern Swift 6.1 features
///
/// This protocol uses Swift 6.1's improved protocol capabilities to define
/// type-related behaviors that can be implemented by type nodes.
public protocol TypeSystemBehavior: Sendable {
    /// Check if this type is compatible with another type
    func isCompatible(with other: any TypeSystemBehavior) -> Bool
    
    /// Get the MLIR representation of this type
    var mlirRepresentation: String { get }
    
    /// Get any constraints applied to this type
    var typeConstraints: [TypeConstraint] { get }
    
    /// Check if this type can be implicitly converted to another type
    func canImplicitlyConvertTo(_ other: any TypeSystemBehavior) -> Bool
}

/// Default implementation for TypeSystemBehavior
extension TypeSystemBehavior {
    /// Type constraints for this type
    public var typeConstraints: [TypeConstraint] { [] }
    
    /// Check if this type can be implicitly converted to another type
    public func canImplicitlyConvertTo(_ other: any TypeSystemBehavior) -> Bool {
        return isCompatible(with: other)
    }
}

// MARK: - Type Node Classes

/// Dictionary type (e.g., [String: Int])
public class DictionaryType: TypeNode {
    public let keyType: TypeNode
    public let valueType: TypeNode
    
    public init(keyType: TypeNode, valueType: TypeNode, line: Int, column: Int) {
        self.keyType = keyType
        self.valueType = valueType
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitDictionaryType(self)
    }
}

extension DictionaryType: TypeSystemBehavior {
    public var mlirRepresentation: String {
        "!llvm.struct<(ptr<\(keyType.mlirTypeName)>, ptr<\(valueType.mlirTypeName)>, i32)>"
    }
    
    public func isCompatible(with other: any TypeSystemBehavior) -> Bool {
        guard let otherDict = other as? DictionaryType else { return false }
        
        // Dictionary types are compatible if their key and value types are compatible
        guard let keyBehavior = keyType as? TypeSystemBehavior,
              let valueTypeBehavior = valueType as? TypeSystemBehavior,
              let otherKeyBehavior = otherDict.keyType as? TypeSystemBehavior,
              let otherValueBehavior = otherDict.valueType as? TypeSystemBehavior else {
            return keyType.isCompatibleWith(otherDict.keyType) && 
                   valueType.isCompatibleWith(otherDict.valueType)
        }
        
        return keyBehavior.isCompatible(with: otherKeyBehavior) && 
               valueTypeBehavior.isCompatible(with: otherValueBehavior)
    }
}

/// Set type (e.g., Set<Int>)
public class SetType: TypeNode {
    public let elementType: TypeNode
    
    public init(elementType: TypeNode, line: Int, column: Int) {
        self.elementType = elementType
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitSetType(self)
    }
}

extension SetType: TypeSystemBehavior {
    public var mlirRepresentation: String {
        "!llvm.struct<(ptr<\(elementType.mlirTypeName)>, i32)>"
    }
    
    public func isCompatible(with other: any TypeSystemBehavior) -> Bool {
        guard let otherSet = other as? SetType else { return false }
        
        // Set types are compatible if their element types are compatible
        guard let elementBehavior = elementType as? TypeSystemBehavior,
              let otherElementBehavior = otherSet.elementType as? TypeSystemBehavior else {
            return elementType.isCompatibleWith(otherSet.elementType)
        }
        
        return elementBehavior.isCompatible(with: otherElementBehavior)
    }
}

/// Tuple type (e.g., (Int, String, Bool))
public class TupleType: TypeNode {
    public let elementTypes: [TypeNode]
    
    public init(elementTypes: [TypeNode], line: Int, column: Int) {
        self.elementTypes = elementTypes
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitTupleType(self)
    }
}

extension TupleType: TypeSystemBehavior {
    public var mlirRepresentation: String {
        let typeStr = elementTypes
            .compactMap { ($0 as? TypeSystemBehavior)?.mlirRepresentation ?? $0.mlirTypeName }
            .joined(separator: ", ")
        return "!llvm.struct<(\(typeStr))>"
    }
    
    public func isCompatible(with other: any TypeSystemBehavior) -> Bool {
        guard let otherTuple = other as? TupleType else { return false }
        
        // Tuples must have same number of elements
        guard elementTypes.count == otherTuple.elementTypes.count else { return false }
        
        // Each element type must be compatible with the corresponding element in the other tuple
        for (index, elementType) in elementTypes.enumerated() {
            let otherElementType = otherTuple.elementTypes[index]
            
            if let elementBehavior = elementType as? TypeSystemBehavior,
               let otherElementBehavior = otherElementType as? TypeSystemBehavior {
                if !elementBehavior.isCompatible(with: otherElementBehavior) {
                    return false
                }
            } else if !elementType.isCompatibleWith(otherElementType) {
                return false
            }
        }
        
        return true
    }
}

/// Function type (e.g., (Int, String) -> Bool)
public class FunctionType: TypeNode {
    public let parameterTypes: [TypeNode]
    public let returnType: TypeNode
    
    public init(parameterTypes: [TypeNode], returnType: TypeNode, line: Int, column: Int) {
        self.parameterTypes = parameterTypes
        self.returnType = returnType
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitFunctionType(self)
    }
}

extension FunctionType: TypeSystemBehavior {
    public var mlirRepresentation: String {
        let paramTypesStr = parameterTypes
            .compactMap { ($0 as? TypeSystemBehavior)?.mlirRepresentation ?? $0.mlirTypeName }
            .joined(separator: ", ")
        
        let returnTypeStr = (returnType as? TypeSystemBehavior)?.mlirRepresentation 
            ?? returnType.mlirTypeName
        
        return "!llvm.func<(\(paramTypesStr)) -> \(returnTypeStr)>"
    }
    
    public func isCompatible(with other: any TypeSystemBehavior) -> Bool {
        guard let otherFunc = other as? FunctionType else { return false }
        
        // Return type must be compatible
        if let returnBehavior = returnType as? TypeSystemBehavior,
           let otherReturnBehavior = otherFunc.returnType as? TypeSystemBehavior {
            guard returnBehavior.isCompatible(with: otherReturnBehavior) else {
                return false
            }
        } else {
            guard returnType.isCompatibleWith(otherFunc.returnType) else {
                return false
            }
        }
        
        // Must have same number of parameters
        guard parameterTypes.count == otherFunc.parameterTypes.count else {
            return false
        }
        
        // Each parameter type must be compatible
        for (index, paramType) in parameterTypes.enumerated() {
            let otherParamType = otherFunc.parameterTypes[index]
            
            if let paramBehavior = paramType as? TypeSystemBehavior,
               let otherParamBehavior = otherParamType as? TypeSystemBehavior {
                if !paramBehavior.isCompatible(with: otherParamBehavior) {
                    return false
                }
            } else if !paramType.isCompatibleWith(otherParamType) {
                return false
            }
        }
        
        return true
    }
}

/// Optional type (e.g., String?)
public class OptionalType: TypeNode {
    public let wrappedType: TypeNode
    
    public init(wrappedType: TypeNode, line: Int, column: Int) {
        self.wrappedType = wrappedType
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitOptionalType(self)
    }
}

extension OptionalType: TypeSystemBehavior {
    public var mlirRepresentation: String {
        let wrappedTypeStr = (wrappedType as? TypeSystemBehavior)?.mlirRepresentation 
            ?? wrappedType.mlirTypeName
        return "!llvm.struct<(i1, \(wrappedTypeStr))>"
    }
    
    public func isCompatible(with other: any TypeSystemBehavior) -> Bool {
        if let otherOptional = other as? OptionalType {
            // Optional types are compatible if their wrapped types are compatible
            if let wrappedBehavior = wrappedType as? TypeSystemBehavior,
               let otherWrappedBehavior = otherOptional.wrappedType as? TypeSystemBehavior {
                return wrappedBehavior.isCompatible(with: otherWrappedBehavior)
            } else {
                return wrappedType.isCompatibleWith(otherOptional.wrappedType)
            }
        }
        
        // An optional type can be assigned from nil
        if let neverType = other as? NeverType {
            return true
        }
        
        return false
    }
}

/// Union type (e.g., Int | String)
public class UnionType: TypeNode {
    public let types: [TypeNode]
    
    public init(types: [TypeNode], line: Int, column: Int) {
        self.types = types
        super.init(line: line, column: column)
    }
    
    public override func accept<V: ASTVisitor>(visitor: V) throws -> V.Result {
        return try visitor.visitUnionType(self)
    }
}

extension UnionType: TypeSystemBehavior {
    public var mlirRepresentation: String {
        // Union types are represented as a tagged union in MLIR
        let typeStr = types
            .enumerated()
            .map { index, type in
                let typeRepr = (type as? TypeSystemBehavior)?.mlirRepresentation ?? type.mlirTypeName
                return typeRepr
            }
            .joined(separator: ", ")
        
        return "!llvm.struct<(i8, {\(typeStr)})>"
    }
    
    public func isCompatible(with other: any TypeSystemBehavior) -> Bool {
        // A union type is compatible with another type if any of its member types is compatible
        if let otherUnion = other as? UnionType {
            // Check if any type in this union is compatible with any type in the other union
            for type in types {
                if let typeBehavior = type as? TypeSystemBehavior {
                    for otherType in otherUnion.types {
                        if let otherTypeBehavior = otherType as? TypeSystemBehavior {
                            if typeBehavior.isCompatible(with: otherTypeBehavior) {
                                return true
                            }
                        } else if type.isCompatibleWith(otherType) {
                            return true
                        }
                    }
                }
            }
            return false
        }
        
        // Check if any of this union's types is compatible with the other type
        for type in types {
            if let typeBehavior = type as? TypeSystemBehavior {
                if typeBehavior.isCompatible(with: other) {
                    return true
                }
            } else if let otherNode = other as? TypeNode, type.isCompatibleWith(otherNode) {
                return true
            }
        }
        
        return false
    }
}

extension IntersectionType: TypeSystemBehavior {
    public var mlirRepresentation: String {
        // Intersection types are represented as a struct in MLIR
        let typeStr = types
            .compactMap { ($0 as? TypeSystemBehavior)?.mlirRepresentation ?? $0.mlirTypeName }
            .joined(separator: ", ")
        
        return "!llvm.struct<(\(typeStr))>"
    }
    
    public func isCompatible(with other: any TypeSystemBehavior) -> Bool {
        if let otherIntersection = other as? IntersectionType {
            // Check if all types in the other intersection are compatible with this one
            for otherType in otherIntersection.types {
                var foundCompatible = false
                
                if let otherTypeBehavior = otherType as? TypeSystemBehavior {
                    for type in types {
                        if let typeBehavior = type as? TypeSystemBehavior {
                            if typeBehavior.isCompatible(with: otherTypeBehavior) {
                                foundCompatible = true
                                break
                            }
                        } else if let otherNode = otherType as? TypeNode, type.isCompatibleWith(otherNode) {
                            foundCompatible = true
                            break
                        }
                    }
                } else if let otherNode = otherType as? TypeNode {
                    for type in types {
                        if type.isCompatibleWith(otherNode) {
                            foundCompatible = true
                            break
                        }
                    }
                }
                
                if !foundCompatible {
                    return false
                }
            }
            
            return true
        }
        
        // An intersection type is compatible with another type if all
        // of its member types are compatible with the other type
        for type in types {
            if let typeBehavior = type as? TypeSystemBehavior {
                if !typeBehavior.isCompatible(with: other) {
                    return false
                }
            } else if let otherNode = other as? TypeNode, !type.isCompatibleWith(otherNode) {
                return false
            }
        }
        
        return true
    }
}

extension ConstrainedType: TypeSystemBehavior {
    public var mlirRepresentation: String {
        return (baseType as? TypeSystemBehavior)?.mlirRepresentation ?? baseType.mlirTypeName
    }
    
    public var typeConstraints: [TypeConstraint] {
        return constraints
    }
    
    public func isCompatible(with other: any TypeSystemBehavior) -> Bool {
        guard let baseBehavior = baseType as? TypeSystemBehavior else { 
            return baseType.isCompatibleWith(other as? TypeNode ?? TypeNode(line: 0, column: 0)) 
        }
        
        // A constrained type is compatible with another type if its base type is compatible
        // and the other type satisfies all constraints
        if let otherConstrained = other as? ConstrainedType {
            guard baseBehavior.isCompatible(with: otherConstrained) else { return false }
            
            // Check that all constraints from this type are satisfied by the other type
            for constraint in constraints {
                if !otherConstrained.constraints.contains(constraint) {
                    return false
                }
            }
            
            return true
        }
        
        return baseBehavior.isCompatible(with: other)
    }
}

extension TensorType: TypeSystemBehavior {
    public var mlirRepresentation: String {
        let elementTypeStr = (elementType as? TypeSystemBehavior)?.mlirRepresentation 
            ?? elementType.mlirTypeName
        return "tensor<\(dimensions.description)x\(elementTypeStr)>"
    }
    
    public func isCompatible(with other: any TypeSystemBehavior) -> Bool {
        guard let otherTensor = other as? TensorType else { return false }
        
        // Check that dimensions match
        if dimensions.sizes.count != otherTensor.dimensions.sizes.count {
            return false
        }
        
        // Check each dimension
        for (i, size) in dimensions.sizes.enumerated() {
            let otherSize = otherTensor.dimensions.sizes[i]
            switch (size, otherSize) {
            case (.dynamic, _), (_, .dynamic):
                // Dynamic dimensions are compatible with anything
                continue
            case (.fixed(let s1), .fixed(let s2)):
                if s1 != s2 {
                    return false
                }
            }
        }
        
        // Check element type compatibility
        if let elementBehavior = elementType as? TypeSystemBehavior,
           let otherElementBehavior = otherTensor.elementType as? TypeSystemBehavior {
            return elementBehavior.isCompatible(with: otherElementBehavior)
        } else {
            return elementType.isCompatibleWith(otherTensor.elementType)
        }
    }
}

extension NeverType: TypeSystemBehavior {
    public var mlirRepresentation: String {
        return "!llvm.void"
    }
    
    public func isCompatible(with other: any TypeSystemBehavior) -> Bool {
        // Never is assignable to any type (bottom type)
        return true
    }
}

extension GenericParameterType: TypeSystemBehavior {
    public var mlirRepresentation: String {
        return "!any"
    }
    
    public var typeConstraints: [TypeConstraint] {
        return constraints
    }
    
    public func isCompatible(with other: any TypeSystemBehavior) -> Bool {
        // A generic parameter is compatible with another type if all its constraints are satisfied
        for constraint in constraints {
            guard let constraintType = constraint.type as? TypeSystemBehavior else {
                continue
            }
            
            switch constraint.kind {
            case .conformsTo:
                if !other.isCompatible(with: constraintType) {
                    return false
                }
            case .subtypeOf:
                if !other.isCompatible(with: constraintType) {
                    return false
                }
            case .equalTo, .same:
                if !other.isCompatible(with: constraintType) || 
                   !constraintType.isCompatible(with: other) {
                    return false
                }
            case .superTypeOf:
                if !constraintType.isCompatible(with: other) {
                    return false
                }
            }
        }
        
        return true
    }
}

// MARK: - Visitor Protocol Extensions

public extension ASTVisitor {
    // Default implementations for visiting type nodes
    func visitGenericParameterType(_ type: GenericParameterType) throws -> Result {
        throw ASTPrinterError.unsupportedConstruct("GenericParameterType visitor not implemented")
    }
    
    func visitOptionalType(_ type: OptionalType) throws -> Result {
        throw ASTPrinterError.unsupportedConstruct("OptionalType visitor not implemented")
    }
    
    func visitUnionType(_ type: UnionType) throws -> Result {
        throw ASTPrinterError.unsupportedConstruct("UnionType visitor not implemented")
    }
    
    func visitIntersectionType(_ type: IntersectionType) throws -> Result {
        throw ASTPrinterError.unsupportedConstruct("IntersectionType visitor not implemented")
    }
    
    func visitConstrainedType(_ type: ConstrainedType) throws -> Result {
        throw ASTPrinterError.unsupportedConstruct("ConstrainedType visitor not implemented")
    }
    
    func visitTensorType(_ type: TensorType) throws -> Result {
        throw ASTPrinterError.unsupportedConstruct("TensorType visitor not implemented")
    }
    
    func visitNeverType(_ type: NeverType) throws -> Result {
        throw ASTPrinterError.unsupportedConstruct("NeverType visitor not implemented")
    }
}

// MARK: - Type Registry

/// Singleton registry for type lookup and management
public actor TypeRegistry {
    public static let shared = TypeRegistry()
    
    private var types: [String: TypeNode] = [:]
    private var primitiveTypes: Set<String> = [
        "Int", "Float", "Double", "Bool", "String", 
        "Char", "Void", "UInt", "Int8", "UInt8", 
        "Int16", "UInt16", "Int32", "UInt32", 
        "Int64", "UInt64", "Float16", "Float32", 
        "Float64", "Decimal"
    ]
    
    private init() {}
    
    /// Register a new type with the system
    public func register(type: TypeNode, name: String) {
        types[name] = type
    }
    
    /// Look up a type by name
    public func lookup(name: String) -> TypeNode? {
        return types[name]
    }
    
    /// Check if a type is a primitive type
    public func isPrimitive(name: String) -> Bool {
        return primitiveTypes.contains(name)
    }
    
    /// Get all registered types
    public func allTypes() -> [String: TypeNode] {
        return types
    }
}

// MARK: - Swift 6.1 Type Extensions

/// Convert TypeNodes to MLIR type strings for code generation
extension TypeNode {
    /// Default MLIR type name representation
    public var mlirTypeName: String {
        switch self {
        case let namedType as NamedType:
            return mapToMLIRTypeName(namedType.name.lexeme)
        case let arrayType as ArrayType:
            let elementTypeName = arrayType.elementType.mlirTypeName
            return "!llvm.ptr<\(elementTypeName)>"
        case let dictionaryType as DictionaryType:
            return (dictionaryType as TypeSystemBehavior).mlirRepresentation
        case let setType as SetType:
            return (setType as TypeSystemBehavior).mlirRepresentation
        case let tupleType as TupleType:
            return (tupleType as TypeSystemBehavior).mlirRepresentation
        case let functionType as FunctionType:
            return (functionType as TypeSystemBehavior).mlirRepresentation
        case let optionalType as OptionalType:
            return (optionalType as TypeSystemBehavior).mlirRepresentation
        case let unionType as UnionType:
            return (unionType as TypeSystemBehavior).mlirRepresentation
        case let intersectionType as IntersectionType:
            return (intersectionType as TypeSystemBehavior).mlirRepresentation
        case let constrainedType as ConstrainedType:
            return (constrainedType as TypeSystemBehavior).mlirRepresentation
        case let tensorType as TensorType:
            return (tensorType as TypeSystemBehavior).mlirRepresentation
        case let neverType as NeverType:
            return (neverType as TypeSystemBehavior).mlirRepresentation
        case let genericParamType as GenericParameterType:
            return (genericParamType as TypeSystemBehavior).mlirRepresentation
        default:
            return "!unknown"
        }
    }
    
    /// Map OuroLang primitive type names to MLIR type names
    private func mapToMLIRTypeName(_ typeName: String) -> String {
        switch typeName.lowercased() {
        case "int": return "i32"
        case "int8": return "i8"
        case "int16": return "i16"
        case "int32": return "i32"
        case "int64": return "i64"
        case "uint", "uinteger": return "ui32"
        case "uint8", "ubyte", "byte": return "ui8"
        case "uint16", "ushort": return "ui16"
        case "uint32": return "ui32"
        case "uint64", "ulong": return "ui64"
        case "float", "float32": return "f32"
        case "double", "float64": return "f64"
        case "float16", "half": return "f16"
        case "bool", "boolean": return "i1"
        case "char": return "i8"
        case "string": return "!llvm.ptr<i8>"
        case "void": return "none"
        case "any": return "!any"
        case "never": return "!llvm.void"
        case "decimal", "decimal128": return "f128"
        default:
            // May be a user-defined type
            return "!\(typeName.lowercased())"
        }
    }
    
    /// Check if this type is compatible with another type
    public func isCompatibleWith(_ other: TypeNode) -> Bool {
        if let selfBehavior = self as? TypeSystemBehavior,
           let otherBehavior = other as? TypeSystemBehavior {
            return selfBehavior.isCompatible(with: otherBehavior)
        }
        
        // Default compatibility for non-behavior types
        if type(of: self) == type(of: other) {
            switch (self, other) {
            case (let t1 as NamedType, let t2 as NamedType):
                return t1.name.lexeme == t2.name.lexeme
                
            case (let t1 as ArrayType, let t2 as ArrayType):
                return t1.elementType.isCompatibleWith(t2.elementType)
                
            default:
                return false
            }
        }
        
        return false
    }
}

// MARK: - Type Utility Extensions

/// Type checking utility functions
extension TypeNode {
    /// Check if this type is numeric (int, float, etc.)
    public var isNumeric: Bool {
        if let namedType = self as? NamedType {
            let name = namedType.name.lexeme.lowercased()
            return name == "int" || name == "float" || name == "double" ||
                   name == "int8" || name == "int16" || name == "int32" || name == "int64" ||
                   name == "uint" || name == "uint8" || name == "uint16" || name == "uint32" || name == "uint64" ||
                   name == "byte" || name == "short" || name == "long" || name == "decimal" ||
                   name == "half" || name == "float16" || name == "float32" || name == "float64"
        }
        return false
    }
    
    /// Check if this type is an integer type
    public var isInteger: Bool {
        if let namedType = self as? NamedType {
            let name = namedType.name.lexeme.lowercased()
            return name == "int" || 
                   name == "int8" || name == "int16" || name == "int32" || name == "int64" ||
                   name == "uint" || name == "uint8" || name == "uint16" || name == "uint32" || name == "uint64" ||
                   name == "byte" || name == "short" || name == "long"
        }
        return false
    }
    
    /// Check if this type is a floating-point type
    public var isFloatingPoint: Bool {
        if let namedType = self as? NamedType {
            let name = namedType.name.lexeme.lowercased()
            return name == "float" || name == "double" || name == "decimal" ||
                   name == "half" || name == "float16" || name == "float32" || name == "float64"
        }
        return false
    }
    
    /// Check if this type is a string type
    public var isString: Bool {
        if let namedType = self as? NamedType {
            let name = namedType.name.lexeme.lowercased()
            return name == "string"
        }
        return false
    }
    
    /// Check if this type is a boolean type
    public var isBoolean: Bool {
        if let namedType = self as? NamedType {
            let name = namedType.name.lexeme.lowercased()
            return name == "bool" || name == "boolean"
        }
        return false
    }
    
    /// Check if this type is a character type
    public var isCharacter: Bool {
        if let namedType = self as? NamedType {
            let name = namedType.name.lexeme.lowercased()
            return name == "char"
        }
        return false
    }
    
    /// Check if this type is a reference type (not a value type)
    public var isReferenceType: Bool {
        if let namedType = self as? NamedType {
            let name = namedType.name.lexeme.lowercased()
            // Primitive value types
            if name == "int" || name == "float" || name == "double" || name == "bool" || 
               name == "byte" || name == "short" || name == "long" || name == "char" ||
               name == "boolean" || name == "void" || name == "half" || 
               name == "int8" || name == "int16" || name == "int32" || name == "int64" ||
               name == "uint" || name == "uint8" || name == "uint16" || name == "uint32" || name == "uint64" {
                return false
            }
            // Everything else is a reference type by default
            return true
        }
        
        // Arrays, dictionaries, functions, etc. are reference types
        return self is ArrayType || self is DictionaryType || self is FunctionType
    }
    
    /// Check if this type is an optional type
    public var isOptional: Bool {
        return self is OptionalType
    }
    
    /// Check if this type is a collection type
    public var isCollectionType: Bool {
        return self is ArrayType || self is DictionaryType || self is SetType
    }
    
    /// Get a human-readable name for this type
    public var typeName: String {
        switch self {
        case let namedType as NamedType:
            return namedType.name.lexeme
            
        case let arrayType as ArrayType:
            return "\(arrayType.elementType.typeName)[]"
            
        case let dictionaryType as DictionaryType:
            return "[" + dictionaryType.keyType.typeName + ": " + dictionaryType.valueType.typeName + "]"
            
        case let setType as SetType:
            return "Set<" + setType.elementType.typeName + ">"
            
        case let tupleType as TupleType:
            return "(" + tupleType.elementTypes.map { $0.typeName }.joined(separator: ", ") + ")"
            
        case let functionType as FunctionType:
            let params = functionType.parameterTypes.map { $0.typeName }.joined(separator: ", ")
            return "(\(params)) -> \(functionType.returnType.typeName)"
            
        case let optionalType as OptionalType:
            return optionalType.wrappedType.typeName + "?"
            
        case let unionType as UnionType:
            return unionType.types.map { $0.typeName }.joined(separator: " | ")
            
        case let intersectionType as IntersectionType:
            return intersectionType.types.map { $0.typeName }.joined(separator: " & ")
            
        case let constrainedType as ConstrainedType:
            let constraints = constrainedType.constraints.map { $0.description }.joined(separator: " & ")
            return "\(constrainedType.baseType.typeName) where \(constraints)"
            
        case let tensorType as TensorType:
            return "tensor<\(tensorType.dimensions.description)x\(tensorType.elementType.typeName)>"
            
        case _ as NeverType:
            return "never"
            
        case let genericParamType as GenericParameterType:
            return genericParamType.name
            
        default:
            return "unknown"
        }
    }
    
    /// Try to infer the type of a literal value
    public static func inferType(forLiteral literal: Any?, line: Int, column: Int) -> TypeNode {
        switch literal {
        case is Int:
            return NamedType(
                name: Token(type: .identifier, lexeme: "Int", line: line, column: column),
                line: line, 
                column: column
            )
        case is Double:
            return NamedType(
                name: Token(type: .identifier, lexeme: "Double", line: line, column: column),
                line: line, 
                column: column
            )
        case is String:
            return NamedType(
                name: Token(type: .identifier, lexeme: "String", line: line, column: column),
                line: line, 
                column: column
            )
        case is Bool:
            return NamedType(
                name: Token(type: .identifier, lexeme: "Bool", line: line, column: column),
                line: line, 
                column: column
            )
        case is Character:
            return NamedType(
                name: Token(type: .identifier, lexeme: "Char", line: line, column: column),
                line: line, 
                column: column
            )
        case nil:
            return NeverType(line: line, column: column)
        default:
            return NamedType(
                name: Token(type: .identifier, lexeme: "Any", line: line, column: column),
                line: line, 
                column: column
            )
        }
    }
}

// MARK: - Swift 6.1 Async Type Operations

/// Modern Swift 6.1 async type analysis
public actor TypeAnalyzer {
    private var errors: [Error] = []
    
    /// Analyze the compatibility between two types
    public func analyzeCompatibility(_ sourceType: TypeNode, _ targetType: TypeNode) async -> Bool {
        if let sourceBehavior = sourceType as? TypeSystemBehavior,
           let targetBehavior = targetType as? TypeSystemBehavior {
            return sourceBehavior.isCompatible(with: targetBehavior)
        }
        
        return sourceType.isCompatibleWith(targetType)
    }
    
    /// Check if source type can be implicitly converted to target type
    public func canImplicitlyConvert(_ sourceType: TypeNode, to targetType: TypeNode) async -> Bool {
        if let sourceBehavior = sourceType as? TypeSystemBehavior,
           let targetBehavior = targetType as? TypeSystemBehavior {
            return sourceBehavior.canImplicitlyConvertTo(targetBehavior)
        }
        
        // Handle numeric conversions (widening only)
        if sourceType.isInteger && targetType.isFloatingPoint {
            return true
        }
        
        // Int8 can convert to Int16, Int32, Int64
        if sourceType is NamedType && targetType is NamedType {
            let sourceName = (sourceType as! NamedType).name.lexeme.lowercased()
            let targetName = (targetType as! NamedType).name.lexeme.lowercased()
            
            if sourceName == "int8" && (targetName == "int16" || targetName == "int32" || targetName == "int64" || targetName == "int") {
                return true
            }
            
            if sourceName == "int16" && (targetName == "int32" || targetName == "int64" || targetName == "int") {
                return true
            }
            
            if sourceName == "int32" && (targetName == "int64" || targetName == "int") {
                return true
            }
            
            if sourceName == "float" && targetName == "double" {
                return true
            }
        }
        
        return await analyzeCompatibility(sourceType, targetType)
    }
    
    /// Determine the common type between two types (for binary operations)
    public func findCommonType(_ type1: TypeNode, _ type2: TypeNode) async -> TypeNode? {
        // If types are compatible, return the more general type
        if await analyzeCompatibility(type1, type2) {
            return type2
        }
        
        if await analyzeCompatibility(type2, type1) {
            return type1
        }
        
        // For numeric types, use promotion rules
        if type1.isNumeric && type2.isNumeric {
            // Float + Int = Float
            if type1.isFloatingPoint && type2.isInteger {
                return type1
            }
            
            if type2.isFloatingPoint && type1.isInteger {
                return type2
            }
            
            // Double + Float = Double
            if let named1 = type1 as? NamedType, let named2 = type2 as? NamedType {
                let name1 = named1.name.lexeme.lowercased()
                let name2 = named2.name.lexeme.lowercased()
                
                if name1 == "double" && name2 == "float" {
                    return type1
                }
                
                if name2 == "double" && name1 == "float" {
                    return type2
                }
                
                // Int64 + Int32 = Int64, etc.
                if name1 == "int64" && (name2 == "int32" || name2 == "int16" || name2 == "int8" || name2 == "int") {
                    return type1
                }
                
                if name2 == "int64" && (name1 == "int32" || name1 == "int16" || name1 == "int8" || name1 == "int") {
                    return type2
                }
            }
        }
        
        // String + Any = String
        if type1.isString || type2.isString {
            return type1.isString ? type1 : type2
        }
        
        return nil
    }
}

// MARK: - Advanced Type Features

/// Namespace for specialized type operations
public enum OuroTypes {
    /// Create a union type from two or more types
    public static func union(_ types: [TypeNode], line: Int = 0, column: Int = 0) -> TypeNode {
        return UnionType(types: types, line: line, column: column)
    }
    
    /// Create an intersection type from two or more types
    public static func intersection(_ types: [TypeNode], line: Int = 0, column: Int = 0) -> TypeNode {
        return IntersectionType(types: types, line: line, column: column)
    }
    
    /// Create a tensor type with given dimensions and element type
    public static func tensor(dimensions: TensorType.Dimension, elementType: TypeNode, line: Int = 0, column: Int = 0) -> TypeNode {
        return TensorType(dimensions: dimensions, elementType: elementType, line: line, column: column)
    }
    
    /// Get builtin types from the registry
    public static func builtinType(_ name: String, line: Int = 0, column: Int = 0) -> TypeNode {
        let token = Token(type: .identifier, lexeme: name, line: line, column: column)
        return NamedType(name: token, line: line, column: column)
    }
    
    /// Helper to create tensor dimensions
    public static func dimensions(_ dims: [TensorType.Dimension.Size]) -> TensorType.Dimension {
        return TensorType.Dimension(dims)
    }
    
    /// Helper to create a fixed dimension size
    public static func fixed(_ size: Int) -> TensorType.Dimension.Size {
        return .fixed(size)
    }
    
    /// Create a dynamic dimension size
    public static var dynamic: TensorType.Dimension.Size {
        return .dynamic
    }
}

// MARK: - Type Comparison Extensions

/// Add equality operator for type nodes
extension TypeNode: Equatable {
    public static func == (lhs: TypeNode, rhs: TypeNode) -> Bool {
        if type(of: lhs) != type(of: rhs) {
            return false
        }
        
        switch (lhs, rhs) {
        case (let lhs as NamedType, let rhs as NamedType):
            return lhs.name.lexeme == rhs.name.lexeme
            
        case (let lhs as ArrayType, let rhs as ArrayType):
            return lhs.elementType == rhs.elementType
            
        case (let lhs as DictionaryType, let rhs as DictionaryType):
            return lhs.keyType == rhs.keyType && lhs.valueType == rhs.valueType
            
        case (let lhs as SetType, let rhs as SetType):
            return lhs.elementType == rhs.elementType
            
        case (let lhs as TupleType, let rhs as TupleType):
            guard lhs.elementTypes.count == rhs.elementTypes.count else { return false }
            for i in 0..<lhs.elementTypes.count {
                if lhs.elementTypes[i] != rhs.elementTypes[i] {
                    return false
                }
            }
            return true
            
        case (let lhs as FunctionType, let rhs as FunctionType):
            guard lhs.parameterTypes.count == rhs.parameterTypes.count else { return false }
            guard lhs.returnType == rhs.returnType else { return false }
            
            for i in 0..<lhs.parameterTypes.count {
                if lhs.parameterTypes[i] != rhs.parameterTypes[i] {
                    return false
                }
            }
            return true
            
        case (let lhs as OptionalType, let rhs as OptionalType):
            return lhs.wrappedType == rhs.wrappedType
            
        case (let lhs as UnionType, let rhs as UnionType):
            guard lhs.types.count == rhs.types.count else { return false }
            // Compare sets of types to handle ordering differences
            let lhsSet = Set(lhs.types.map { $0.description })
            let rhsSet = Set(rhs.types.map { $0.description })
            return lhsSet == rhsSet
            
        case (let lhs as IntersectionType, let rhs as IntersectionType):
            guard lhs.types.count == rhs.types.count else { return false }
            // Compare sets of types to handle ordering differences
            let lhsSet = Set(lhs.types.map { $0.description })
            let rhsSet = Set(rhs.types.map { $0.description })
            return lhsSet == rhsSet
            
        case (let lhs as TensorType, let rhs as TensorType):
            guard lhs.dimensions.sizes.count == rhs.dimensions.sizes.count else { return false }
            for i in 0..<lhs.dimensions.sizes.count {
                if lhs.dimensions.sizes[i] != rhs.dimensions.sizes[i] {
                    return false
                }
            }
            return lhs.elementType == rhs.elementType
            
        case (is NeverType, is NeverType):
            return true
            
        case (let lhs as GenericParameterType, let rhs as GenericParameterType):
            return lhs.name == rhs.name
            
        default:
            return false
        }
    }
}

/// Add hashable conformance for type nodes
extension TypeNode: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
        
        switch self {
        case let named as NamedType:
            hasher.combine(named.name.lexeme)
            
        case let array as ArrayType:
            hasher.combine("array")
            hasher.combine(array.elementType)
            
        case let dict as DictionaryType:
            hasher.combine("dictionary")
            hasher.combine(dict.keyType)
            hasher.combine(dict.valueType)
            
        case let set as SetType:
            hasher.combine("set")
            hasher.combine(set.elementType)
            
        case let tuple as TupleType:
            hasher.combine("tuple")
            tuple.elementTypes.forEach { hasher.combine($0) }
            
        case let function as FunctionType:
            hasher.combine("function")
            function.parameterTypes.forEach { hasher.combine($0) }
            hasher.combine(function.returnType)
            
        case let optional as OptionalType:
            hasher.combine("optional")
            hasher.combine(optional.wrappedType)
            
        case let union as UnionType:
            hasher.combine("union")
            union.types.forEach { hasher.combine($0) }
            
        case let intersection as IntersectionType:
            hasher.combine("intersection")
            intersection.types.forEach { hasher.combine($0) }
            
        case let tensor as TensorType:
            hasher.combine("tensor")
            hasher.combine(tensor.dimensions.description)
            hasher.combine(tensor.elementType)
            
        case is NeverType:
            hasher.combine("never")
            
        case let generic as GenericParameterType:
            hasher.combine("generic")
            hasher.combine(generic.name)
            
        default:
            hasher.combine(String(describing: type(of: self)))
        }
    }
}

// MARK: - Description Protocol Implementation

extension TypeNode: CustomStringConvertible {
    /// A human-readable description of the type
    public var description: String {
        switch self {
        case let namedType as NamedType:
            return namedType.name.lexeme
            
        case let arrayType as ArrayType:
            return "\(arrayType.elementType.description)[]"
            
        case let dictionaryType as DictionaryType:
            return "[\(dictionaryType.keyType.description): \(dictionaryType.valueType.description)]"
            
        case let setType as SetType:
            return "Set<\(setType.elementType.description)>"
            
        case let tupleType as TupleType:
            let types = tupleType.elementTypes.map { $0.description }.joined(separator: ", ")
            return "(\(types))"
            
        case let functionType as FunctionType:
            let params = functionType.parameterTypes.map { $0.description }.joined(separator: ", ")
            return "(\(params)) -> \(functionType.returnType.description)"
            
        case let optionalType as OptionalType:
            return "\(optionalType.wrappedType.description)?"
            
        case let unionType as UnionType:
            return unionType.types.map { $0.description }.joined(separator: " | ")
            
        case let intersectionType as IntersectionType:
            return intersectionType.types.map { $0.description }.joined(separator: " & ")
            
        case let constrainedType as ConstrainedType:
            let constraints = constrainedType.constraints.map { $0.description }.joined(separator: " & ")
            return "\(constrainedType.baseType.description) where \(constraints)"
            
        case let tensorType as TensorType:
            return "tensor<\(tensorType.dimensions.description)x\(tensorType.elementType.description)>"
            
        case is NeverType:
            return "never"
            
        case let generic as GenericParameterType:
            if generic.constraints.isEmpty {
                return generic.name
            } else {
                let constraints = generic.constraints.map { $0.description }.joined(separator: " & ")
                return "\(generic.name) where \(constraints)"
            }
            
        default:
            return "unknown"
        }
    }
}

// MARK: - Type Construction DSL

/// DSL for constructing type expressions
public struct TypeDSL {
    /// Create an array type
    public static func array(of elementType: TypeNode, line: Int = 0, column: Int = 0) -> TypeNode {
        return ArrayType(elementType: elementType, line: line, column: column)
    }
    
    /// Create a dictionary type
    public static func dictionary(key keyType: TypeNode, value valueType: TypeNode, line: Int = 0, column: Int = 0) -> TypeNode {
        return DictionaryType(keyType: keyType, valueType: valueType, line: line, column: column)
    }
    
    /// Create a set type
    public static func set(of elementType: TypeNode, line: Int = 0, column: Int = 0) -> TypeNode {
        return SetType(elementType: elementType, line: line, column: column)
    }
    
    /// Create a tuple type
    public static func tuple(of elementTypes: [TypeNode], line: Int = 0, column: Int = 0) -> TypeNode {
        return TupleType(elementTypes: elementTypes, line: line, column: column)
    }
    
    /// Create a function type
    public static func function(params: [TypeNode], returns returnType: TypeNode, line: Int = 0, column: Int = 0) -> TypeNode {
        return FunctionType(parameterTypes: params, returnType: returnType, line: line, column: column)
    }
    
    /// Create an optional type
    public static func optional(_ wrappedType: TypeNode, line: Int = 0, column: Int = 0) -> TypeNode {
        return OptionalType(wrappedType: wrappedType, line: line, column: column)
    }
    
    /// Create a never type
    public static func never(line: Int = 0, column: Int = 0) -> TypeNode {
        return NeverType(line: line, column: column)
    }
    
    /// Create a named type
    public static func named(_ name: String, line: Int = 0, column: Int = 0) -> TypeNode {
        let token = Token(type: .identifier, lexeme: name, line: line, column: column)
        return NamedType(name: token, line: line, column: column)
    }
}
