//
//  TypeResolver.swift
//  OuroLangCore
//
//  Created on June 3, 2025.
//

import Foundation

/// Error types that can occur during type resolution
public enum TypeResolutionError: Error, CustomStringConvertible {
    case undefinedType(String, line: Int, column: Int)
    case invalidTypeArguments(String, expected: Int, got: Int, line: Int, column: Int)
    case ambiguousType(String, candidates: [String], line: Int, column: Int)
    case incompatibleTypes(String, String, operation: String, line: Int, column: Int)
    case invalidTypeConversion(String, String, line: Int, column: Int)
    case circularTypeReference(String, line: Int, column: Int)
    case invalidGenericParameter(String, line: Int, column: Int)
    case unsatisfiedConstraint(String, constraint: String, line: Int, column: Int)
    
    public var description: String {
        switch self {
        case .undefinedType(let name, let line, let column):
            return "Undefined type '\(name)' at line \(line), column \(column)"
        case .invalidTypeArguments(let name, let expected, let got, let line, let column):
            return "Invalid type arguments for '\(name)' at line \(line), column \(column): expected \(expected), got \(got)"
        case .ambiguousType(let name, let candidates, let line, let column):
            return "Ambiguous type '\(name)' at line \(line), column \(column). Candidates: \(candidates.joined(separator: ", "))"
        case .incompatibleTypes(let left, let right, let operation, let line, let column):
            return "Incompatible types '\(left)' and '\(right)' for operation '\(operation)' at line \(line), column \(column)"
        case .invalidTypeConversion(let source, let target, let line, let column):
            return "Cannot convert from '\(source)' to '\(target)' at line \(line), column \(column)"
        case .circularTypeReference(let name, let line, let column):
            return "Circular type reference detected for '\(name)' at line \(line), column \(column)"
        case .invalidGenericParameter(let name, let line, let column):
            return "Invalid generic parameter '\(name)' at line \(line), column \(column)"
        case .unsatisfiedConstraint(let typeName, let constraint, let line, let column):
            return "Type '\(typeName)' does not satisfy constraint '\(constraint)' at line \(line), column \(column)"
        }
    }
}

/// Type resolution context stores information needed during type resolution
public class TypeResolutionContext {
    /// Available type parameters in the current scope
    public var typeParameters: [String: TypeNode] = [:]
    
    /// Available type definitions in the current scope
    public var types: [String: TypeDefinition] = [:]
    
    /// Parent scope context, if any
    public var parent: TypeResolutionContext?
    
    public init(parent: TypeResolutionContext? = nil) {
        self.parent = parent
    }
    
    /// Look up a type parameter in the current context or parent contexts
    public func lookupTypeParameter(_ name: String) -> TypeNode? {
        if let typeParam = typeParameters[name] {
            return typeParam
        }
        
        return parent?.lookupTypeParameter(name)
    }
    
    /// Look up a type definition in the current context or parent contexts
    public func lookupType(_ name: String) -> TypeDefinition? {
        if let type = types[name] {
            return type
        }
        
        return parent?.lookupType(name)
    }
    
    /// Add a type parameter to the current context
    public func addTypeParameter(_ name: String, type: TypeNode) {
        typeParameters[name] = type
    }
    
    /// Add a type definition to the current context
    public func addType(_ name: String, definition: TypeDefinition) {
        types[name] = definition
    }
    
    /// Create a new child context with this as parent
    public func createChildContext() -> TypeResolutionContext {
        return TypeResolutionContext(parent: self)
    }
}

/// Type definition holds information about user-defined types
public class TypeDefinition {
    /// Name of the type
    public let name: String
    
    /// Type parameters for generic types
    public let typeParameters: [String]
    
    /// Whether this type is an interface
    public let isInterface: Bool
    
    /// Whether this type is abstract
    public let isAbstract: Bool
    
    /// Whether this type is sealed (cannot be extended)
    public let isSealed: Bool
    
    /// Whether this type is a primitive (built-in) type
    public let isPrimitive: Bool
    
    /// Line where this type is defined
    public let line: Int
    
    /// Column where this type is defined
    public let column: Int
    
    /// Supertype, if any
    public var superType: TypeDefinition?
    
    /// Implemented interfaces
    public var interfaces: [TypeDefinition] = []
    
    public init(name: String, typeParameters: [String] = [], isInterface: Bool = false, isAbstract: Bool = false, isSealed: Bool = false, isPrimitive: Bool = false, line: Int, column: Int) {
        self.name = name
        self.typeParameters = typeParameters
        self.isInterface = isInterface
        self.isAbstract = isAbstract
        self.isSealed = isSealed
        self.isPrimitive = isPrimitive
        self.line = line
        self.column = column
    }
}

/// Type resolver handles type resolution and validation
public actor TypeResolver {
    /// Global type resolution context
    private var globalContext: TypeResolutionContext
    
    /// Type registry for looking up types
    private var registry: TypeRegistry
    
    public init() {
        self.globalContext = TypeResolutionContext()
        self.registry = TypeRegistry.shared
        
        // Initialize with primitive types
        setupPrimitiveTypes()
    }
    
    /// Setup primitive types in the global context
    private func setupPrimitiveTypes() {
        // Integer types
        registerPrimitiveType("Int", line: 0, column: 0)
        registerPrimitiveType("Int8", line: 0, column: 0)
        registerPrimitiveType("Int16", line: 0, column: 0)
        registerPrimitiveType("Int32", line: 0, column: 0)
        registerPrimitiveType("Int64", line: 0, column: 0)
        
        // Unsigned integer types
        registerPrimitiveType("UInt", line: 0, column: 0)
        registerPrimitiveType("UInt8", line: 0, column: 0)
        registerPrimitiveType("UInt16", line: 0, column: 0)
        registerPrimitiveType("UInt32", line: 0, column: 0)
        registerPrimitiveType("UInt64", line: 0, column: 0)
        
        // Floating point types
        registerPrimitiveType("Float", line: 0, column: 0)
        registerPrimitiveType("Double", line: 0, column: 0)
        registerPrimitiveType("Float16", line: 0, column: 0)
        registerPrimitiveType("Float32", line: 0, column: 0)
        registerPrimitiveType("Float64", line: 0, column: 0)
        
        // Other primitive types
        registerPrimitiveType("Bool", line: 0, column: 0)
        registerPrimitiveType("Character", line: 0, column: 0)
        registerPrimitiveType("String", line: 0, column: 0)
        registerPrimitiveType("Void", line: 0, column: 0)
        
        // OuroLang special types
        registerPrimitiveType("Any", line: 0, column: 0)
        registerPrimitiveType("Never", line: 0, column: 0)
        registerPrimitiveType("Decimal", line: 0, column: 0)
        
        // Aliases for compatibility
        registerTypeAlias("byte", target: "Int8", line: 0, column: 0)
        registerTypeAlias("ubyte", target: "UInt8", line: 0, column: 0)
        registerTypeAlias("short", target: "Int16", line: 0, column: 0)
        registerTypeAlias("ushort", target: "UInt16", line: 0, column: 0)
        registerTypeAlias("long", target: "Int64", line: 0, column: 0)
        registerTypeAlias("ulong", target: "UInt64", line: 0, column: 0)
        registerTypeAlias("float", target: "Float", line: 0, column: 0)
        registerTypeAlias("double", target: "Double", line: 0, column: 0)
        registerTypeAlias("boolean", target: "Bool", line: 0, column: 0)
        registerTypeAlias("char", target: "Character", line: 0, column: 0)
        registerTypeAlias("void", target: "Void", line: 0, column: 0)
    }
    
    /// Register a primitive type in the global context
    private func registerPrimitiveType(_ name: String, line: Int, column: Int) {
        let def = TypeDefinition(name: name, isPrimitive: true, line: line, column: column)
        globalContext.addType(name, definition: def)
        
        let token = Token(type: .identifier, lexeme: name, line: line, column: column)
        let typeNode = NamedType(name: token, line: line, column: column)
        Task {
            await registry.register(type: typeNode, name: name)
        }
    }
    
    /// Register a type alias in the global context
    private func registerTypeAlias(_ alias: String, target: String, line: Int, column: Int) {
        if let targetDef = globalContext.lookupType(target) {
            let def = TypeDefinition(name: alias, isPrimitive: targetDef.isPrimitive, line: line, column: column)
            def.superType = targetDef
            globalContext.addType(alias, definition: def)
            
            let token = Token(type: .identifier, lexeme: alias, line: line, column: column)
            let typeNode = NamedType(name: token, line: line, column: column)
            Task {
                await registry.register(type: typeNode, name: alias)
            }
        }
    }
    
    /// Resolve a type node to ensure it refers to a valid type
    public func resolveType(_ type: TypeNode, context: TypeResolutionContext? = nil) async throws -> TypeNode {
        let ctx = context ?? globalContext
        
        switch type {
        case let namedType as NamedType:
            return try await resolveNamedType(namedType, context: ctx)
            
        case let arrayType as ArrayType:
            let resolvedElementType = try await resolveType(arrayType.elementType, context: ctx)
            return ArrayType(elementType: resolvedElementType, line: arrayType.line, column: arrayType.column)
            
        case let dictionaryType as DictionaryType:
            let resolvedKeyType = try await resolveType(dictionaryType.keyType, context: ctx)
            let resolvedValueType = try await resolveType(dictionaryType.valueType, context: ctx)
            return DictionaryType(keyType: resolvedKeyType, valueType: resolvedValueType, line: dictionaryType.line, column: dictionaryType.column)
            
        case let setType as SetType:
            let resolvedElementType = try await resolveType(setType.elementType, context: ctx)
            return SetType(elementType: resolvedElementType, line: setType.line, column: setType.column)
            
        case let tupleType as TupleType:
            let resolvedElementTypes = try await tupleType.elementTypes.asyncMap { elementType in
                try await resolveType(elementType, context: ctx)
            }
            return TupleType(elementTypes: resolvedElementTypes, line: tupleType.line, column: tupleType.column)
            
        case let functionType as FunctionType:
            let resolvedParamTypes = try await functionType.parameterTypes.asyncMap { paramType in
                try await resolveType(paramType, context: ctx)
            }
            let resolvedReturnType = try await resolveType(functionType.returnType, context: ctx)
            return FunctionType(parameterTypes: resolvedParamTypes, returnType: resolvedReturnType, line: functionType.line, column: functionType.column)
            
        case let optionalType as OptionalType:
            let resolvedWrappedType = try await resolveType(optionalType.wrappedType, context: ctx)
            return OptionalType(wrappedType: resolvedWrappedType, line: optionalType.line, column: optionalType.column)
            
        case let unionType as UnionType:
            let resolvedTypes = try await unionType.types.asyncMap { memberType in
                try await resolveType(memberType, context: ctx)
            }
            return UnionType(types: resolvedTypes, line: unionType.line, column: unionType.column)
            
        case let intersectionType as IntersectionType:
            let resolvedTypes = try await intersectionType.types.asyncMap { memberType in
                try await resolveType(memberType, context: ctx)
            }
            return IntersectionType(types: resolvedTypes, line: intersectionType.line, column: intersectionType.column)
            
        case let constrainedType as ConstrainedType:
            let resolvedBaseType = try await resolveType(constrainedType.baseType, context: ctx)
            let resolvedConstraints = try await constrainedType.constraints.asyncMap { constraint in
                try await resolveConstraint(constraint, context: ctx)
            }
            return ConstrainedType(baseType: resolvedBaseType, constraints: resolvedConstraints, line: constrainedType.line, column: constrainedType.column)
            
        case let tensorType as TensorType:
            let resolvedElementType = try await resolveType(tensorType.elementType, context: ctx)
            return TensorType(dimensions: tensorType.dimensions, elementType: resolvedElementType, line: tensorType.line, column: tensorType.column)
            
        case let genericParamType as GenericParameterType:
            // Look up the type parameter in the context
            if let resolvedParam = ctx.lookupTypeParameter(genericParamType.name) {
                return resolvedParam
            }
            
            throw TypeResolutionError.invalidGenericParameter(genericParamType.name, line: genericParamType.line, column: genericParamType.column)
            
        case let neverType as NeverType:
            return neverType
            
        default:
            throw TypeResolutionError.undefinedType("Unknown type kind: \(type)", line: type.line, column: type.column)
        }
    }
    
    /// Resolve a named type to ensure it refers to a valid type
    private func resolveNamedType(_ namedType: NamedType, context: TypeResolutionContext) async throws -> TypeNode {
        let name = namedType.name.lexeme
        
        // Check if it's a generic type parameter
        if let typeParam = context.lookupTypeParameter(name) {
            return typeParam
        }
        
        // Check if it's a defined type
        if let _ = context.lookupType(name) {
            return namedType
        }
        
        // If not found, throw an error
        throw TypeResolutionError.undefinedType(name, line: namedType.line, column: namedType.column)
    }
    
    /// Resolve a type constraint to ensure it refers to a valid type
    private func resolveConstraint(_ constraint: TypeConstraint, context: TypeResolutionContext) async throws -> TypeConstraint {
        let resolvedType = try await resolveType(constraint.type, context: context)
        return TypeConstraint(kind: constraint.kind, type: resolvedType)
    }
    
    /// Register a new type definition
    public func registerType(_ name: String, definition: TypeDefinition) {
        globalContext.addType(name, definition: definition)
    }
    
    /// Create a new type resolution context (e.g. for a function, class or scope)
    public func createContext() -> TypeResolutionContext {
        return globalContext.createChildContext()
    }
    
    /// Check if two types are compatible for assignment or comparison
    public func areCompatibleTypes(_ sourceType: TypeNode, _ targetType: TypeNode) async -> Bool {
        // Check if the source can be implicitly converted to the target
        if let sourceBehavior = sourceType as? TypeSystemBehavior,
           let targetBehavior = targetType as? TypeSystemBehavior {
            return sourceBehavior.canImplicitlyConvertTo(targetBehavior)
        }
        
        return sourceType.isCompatibleWith(targetType)
    }
    
    /// Check if a type satisfies a constraint
    public func doesSatisfyConstraint(_ type: TypeNode, constraint: TypeConstraint) async throws -> Bool {
        switch constraint.kind {
        case .conformsTo:
            return await areCompatibleTypes(type, constraint.type)
            
        case .equalTo, .same:
            return type == constraint.type
            
        case .subtypeOf:
            return await areCompatibleTypes(type, constraint.type)
            
        case .superTypeOf:
            return await areCompatibleTypes(constraint.type, type)
        }
    }
}

// MARK: - Helper Extensions

extension Array {
    /// Async version of map that preserves order
    func asyncMap<T>(_ transform: (Element) async throws -> T) async throws -> [T] {
        var results = [T]()
        results.reserveCapacity(count)
        
        for element in self {
            try await results.append(transform(element))
        }
        
        return results
    }
}
