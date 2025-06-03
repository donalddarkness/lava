//
//  TypeOperations.swift
//  OuroLangCore
//
//  Created on June 3, 2025.
//

import Foundation

/// Provides extended operations on types like subtyping, unification, and distribution
public actor TypeOperations {
    /// The type resolver instance for resolving types
    private let resolver: TypeResolver
    
    /// Memoization cache for subtype relationship checks
    private var subtypingCache: [String: Bool] = [:]
    
    /// Create a new TypeOperations instance with a resolver
    public init(resolver: TypeResolver) {
        self.resolver = resolver
    }
    
    /// Check if `source` is a subtype of `target`
    public func isSubtype(source: TypeNode, target: TypeNode) async -> Bool {
        // Create a cache key
        let cacheKey = "\(source.description):<\(target.description)"
        
        // Check cache
        if let result = subtypingCache[cacheKey] {
            return result
        }
        
        // Calculate the result
        let result = await calculateSubtyping(source: source, target: target)
        
        // Cache the result
        subtypingCache[cacheKey] = result
        
        return result
    }
    
    /// Internal implementation of subtyping relationship
    private func calculateSubtyping(source: TypeNode, target: TypeNode) async -> Bool {
        // Handle union types
        if let unionSource = source as? UnionType {
            // A union is a subtype if all its members are subtypes
            for type in unionSource.types {
                if !await self.isSubtype(source: type, target: target) {
                    return false
                }
            }
            return true
        }
        
        if let unionTarget = target as? UnionType {
            // A type is a subtype of a union if it's a subtype of any union member
            for type in unionTarget.types {
                if await isSubtype(source: source, target: type) {
                    return true
                }
            }
            return false
        }
        
        // Handle intersection types
        if let intersectionSource = source as? IntersectionType {
            // An intersection is a subtype if any of its members is a subtype
            for type in intersectionSource.types {
                if await isSubtype(source: type, target: target) {
                    return true
                }
            }
            return false
        }
        
        if let intersectionTarget = target as? IntersectionType {
            // A type is a subtype of an intersection if it's a subtype of all its members
            for type in intersectionTarget.types {
                if !await isSubtype(source: source, target: type) {
                    return false
                }
            }
            return true
        }
        
        // Handle array types
        if let arraySource = source as? ArrayType, let arrayTarget = target as? ArrayType {
            return await isSubtype(source: arraySource.elementType, target: arrayTarget.elementType)
        }
        
        // Handle dictionary types
        if let dictSource = source as? DictionaryType, let dictTarget = target as? DictionaryType {
            return await isSubtype(source: dictSource.keyType, target: dictTarget.keyType) &&
                   await isSubtype(source: dictSource.valueType, target: dictTarget.valueType)
        }
        
        // Handle set types
        if let setSource = source as? SetType, let setTarget = target as? SetType {
            return await isSubtype(source: setSource.elementType, target: setTarget.elementType)
        }
        
        // Handle tuple types
        if let tupleSource = source as? TupleType, let tupleTarget = target as? TupleType {
            if tupleSource.elementTypes.count != tupleTarget.elementTypes.count {
                return false
            }
            
            for i in 0..<tupleSource.elementTypes.count {
                if !await isSubtype(source: tupleSource.elementTypes[i], target: tupleTarget.elementTypes[i]) {
                    return false
                }
            }
            
            return true
        }
        
        // Handle function types
        if let funcSource = source as? FunctionType, let funcTarget = target as? FunctionType {
            // Return type is covariant (source is subtype iff return type is subtype)
            if !await isSubtype(source: funcSource.returnType, target: funcTarget.returnType) {
                return false
            }
            
            // Parameter types are contravariant (source is subtype iff target params are subtypes of source params)
            if funcSource.parameterTypes.count != funcTarget.parameterTypes.count {
                return false
            }
            
            for i in 0..<funcSource.parameterTypes.count {
                if !await isSubtype(source: funcTarget.parameterTypes[i], target: funcSource.parameterTypes[i]) {
                    return false
                }
            }
            
            return true
        }
        
        // Handle optional types
        if let optSource = source as? OptionalType {
            if let optTarget = target as? OptionalType {
                // T? is subtype of U? iff T is subtype of U
                return await isSubtype(source: optSource.wrappedType, target: optTarget.wrappedType)
            }
            
            // T? is never a subtype of non-optional U
            return false
        }
        
        if let optTarget = target as? OptionalType {
            // Non-optional T is always a subtype of T?
            return await isSubtype(source: source, target: optTarget.wrappedType)
        }
        
        // Handle never type (bottom type)
        if source is NeverType {
            // Never is a subtype of any type
            return true
        }
        
        // Handle Any type (top type)
        if let namedTarget = target as? NamedType, namedTarget.name.lexeme == "Any" {
            // Any type is a supertype of all types
            return true
        }
        
        // Named types: exact equality for now (can be extended with class hierarchy)
        if let namedSource = source as? NamedType, let namedTarget = target as? NamedType {
            return namedSource.name.lexeme == namedTarget.name.lexeme
        }
        
        // By default, types are only subtypes of themselves
        return source == target
    }
    
    /// Calculate the nearest common supertype (least upper bound) of two types
    public func findCommonSupertype(_ type1: TypeNode, _ type2: TypeNode) async -> TypeNode {
        // If one is a subtype of the other, the supertype is the answer
        if await isSubtype(source: type1, target: type2) {
            return type2
        }
        
        if await isSubtype(source: type2, target: type1) {
            return type1
        }
        
        // Handle optional types
        if let opt1 = type1 as? OptionalType, let opt2 = type2 as? OptionalType {
            // The common supertype of T? and U? is (common_supertype(T, U))?
            let innerSupertype = await findCommonSupertype(opt1.wrappedType, opt2.wrappedType)
            return OptionalType(wrappedType: innerSupertype, line: type1.line, column: type1.column)
        }
        
        if let opt1 = type1 as? OptionalType {
            // The common supertype of T? and U is (common_supertype(T, U))?
            let innerSupertype = await findCommonSupertype(opt1.wrappedType, type2)
            return OptionalType(wrappedType: innerSupertype, line: type1.line, column: type1.column)
        }
        
        if let opt2 = type2 as? OptionalType {
            // The common supertype of T and U? is (common_supertype(T, U))?
            let innerSupertype = await findCommonSupertype(type1, opt2.wrappedType)
            return OptionalType(wrappedType: innerSupertype, line: type1.line, column: type1.column)
        }
        
        // Handle array types
        if let arr1 = type1 as? ArrayType, let arr2 = type2 as? ArrayType {
            // The common supertype of T[] and U[] is (common_supertype(T, U))[]
            let elementSupertype = await findCommonSupertype(arr1.elementType, arr2.elementType)
            return ArrayType(elementType: elementSupertype, line: type1.line, column: type1.column)
        }
        
        // Handle special numeric conversions
        if let named1 = type1 as? NamedType, let named2 = type2 as? NamedType {
            let name1 = named1.name.lexeme
            let name2 = named2.name.lexeme
            
            // Integer + Float = Float
            if isIntegerType(name1) && isFloatType(name2) {
                return type2
            }
            if isIntegerType(name2) && isFloatType(name1) {
                return type1
            }
            
            // Int8 + Int16 = Int16, etc.
            if let supertype = findNumericSupertype(name1, name2) {
                return NamedType(name: Token(type: .identifier, lexeme: supertype, line: type1.line, column: type1.column), 
                               line: type1.line, column: type1.column)
            }
        }
        
        // If no more specific supertype is found, return a union type
        return UnionType(types: [type1, type2], line: type1.line, column: type1.column)
    }
    
    /// Helper method to check if a type name is an integer type
    private func isIntegerType(_ name: String) -> Bool {
        let integers = ["Int", "Int8", "Int16", "Int32", "Int64", "UInt", "UInt8", "UInt16", "UInt32", "UInt64"]
        return integers.contains(name)
    }
    
    /// Helper method to check if a type name is a floating-point type
    private func isFloatType(_ name: String) -> Bool {
        let floats = ["Float", "Double", "Float16", "Float32", "Float64"]
        return floats.contains(name)
    }
    
    /// Helper method to find the common supertype of two numeric types
    private func findNumericSupertype(_ type1: String, _ type2: String) -> String? {
        // Define a hierarchy for numeric types
        let numericHierarchy: [String: Int] = [
            "Int8": 1, "UInt8": 1,
            "Int16": 2, "UInt16": 2,
            "Int32": 3, "UInt32": 3, "Int": 3,
            "Int64": 4, "UInt64": 4,
            "Float16": 5, "Half": 5,
            "Float": 6, "Float32": 6,
            "Double": 7, "Float64": 7
        ]
        
        // Get the rank of each type in the hierarchy
        guard let rank1 = numericHierarchy[type1], let rank2 = numericHierarchy[type2] else {
            return nil
        }
        
        // Return the type with the higher rank
        if rank1 >= rank2 {
            return type1
        } else {
            return type2
        }
    }
    
    /// Try to unify two types (find a substitution that makes them equal)
    public func unify(_ type1: TypeNode, _ type2: TypeNode, context: TypeResolutionContext) async throws -> [String: TypeNode] {
        var substitutions: [String: TypeNode] = [:]
        
        // If types are already equal, no substitution needed
        if type1 == type2 {
            return [:]
        }
        
        // Handle generic type parameters
        if let generic1 = type1 as? GenericParameterType {
            if let existing = substitutions[generic1.name] {
                // If we already have a substitution for this parameter, it must be equal to type2
                if existing != type2 {
                    throw TypeResolutionError.incompatibleTypes(
                        existing.description,
                        type2.description,
                        operation: "unification",
                        line: type2.line,
                        column: type2.column
                    )
                }
            } else {
                // Add a new substitution
                substitutions[generic1.name] = type2
            }
            return substitutions
        }
        
        if let generic2 = type2 as? GenericParameterType {
            if let existing = substitutions[generic2.name] {
                // If we already have a substitution for this parameter, it must be equal to type1
                if existing != type1 {
                    throw TypeResolutionError.incompatibleTypes(
                        existing.description,
                        type1.description,
                        operation: "unification",
                        line: type1.line,
                        column: type1.column
                    )
                }
            } else {
                // Add a new substitution
                substitutions[generic2.name] = type1
            }
            return substitutions
        }
        
        // Handle compound types
        
        // Arrays
        if let arr1 = type1 as? ArrayType, let arr2 = type2 as? ArrayType {
            return try await unify(arr1.elementType, arr2.elementType, context: context)
        }
        
        // Dictionaries
        if let dict1 = type1 as? DictionaryType, let dict2 = type2 as? DictionaryType {
            let keySubst = try await unify(dict1.keyType, dict2.keyType, context: context)
            let valueSubst = try await unify(dict1.valueType, dict2.valueType, context: context)
            
            // Merge substitutions, checking for conflicts
            return try mergeSubstitutions(keySubst, valueSubst)
        }
        
        // Functions
        if let func1 = type1 as? FunctionType, let func2 = type2 as? FunctionType {
            if func1.parameterTypes.count != func2.parameterTypes.count {
                throw TypeResolutionError.incompatibleTypes(
                    type1.description,
                    type2.description,
                    operation: "unification",
                    line: type1.line,
                    column: type1.column
                )
            }
            
            // Unify return types
            var allSubst = try await unify(func1.returnType, func2.returnType, context: context)
            
            // Unify parameter types
            for i in 0..<func1.parameterTypes.count {
                let paramSubst = try await unify(func1.parameterTypes[i], func2.parameterTypes[i], context: context)
                allSubst = try mergeSubstitutions(allSubst, paramSubst)
            }
            
            return allSubst
        }
        
        // If we can't unify, throw an error
        throw TypeResolutionError.incompatibleTypes(
            type1.description,
            type2.description,
            operation: "unification",
            line: type1.line,
            column: type1.column
        )
    }
    
    /// Merge two substitution maps, checking for conflicts
    private func mergeSubstitutions(_ s1: [String: TypeNode], _ s2: [String: TypeNode]) throws -> [String: TypeNode] {
        var result = s1
        
        for (name, type) in s2 {
            if let existingType = result[name], existingType != type {
                throw TypeResolutionError.incompatibleTypes(
                    existingType.description,
                    type.description,
                    operation: "substitution",
                    line: type.line,
                    column: type.column
                )
            }
            
            result[name] = type
        }
        
        return result
    }
    
    /// Apply substitutions to a type
    public func applySubstitutions(_ type: TypeNode, substitutions: [String: TypeNode]) -> TypeNode {
        switch type {
        case let generic as GenericParameterType:
            if let replacement = substitutions[generic.name] {
                return replacement
            }
            return generic
            
        case let arrayType as ArrayType:
            let newElementType = applySubstitutions(arrayType.elementType, substitutions: substitutions)
            return ArrayType(elementType: newElementType, line: arrayType.line, column: arrayType.column)
            
        case let dictType as DictionaryType:
            let newKeyType = applySubstitutions(dictType.keyType, substitutions: substitutions)
            let newValueType = applySubstitutions(dictType.valueType, substitutions: substitutions)
            return DictionaryType(keyType: newKeyType, valueType: newValueType, line: dictType.line, column: dictType.column)
            
        case let setType as SetType:
            let newElementType = applySubstitutions(setType.elementType, substitutions: substitutions)
            return SetType(elementType: newElementType, line: setType.line, column: setType.column)
            
        case let tupleType as TupleType:
            let newElementTypes = tupleType.elementTypes.map { applySubstitutions($0, substitutions: substitutions) }
            return TupleType(elementTypes: newElementTypes, line: tupleType.line, column: tupleType.column)
            
        case let functionType as FunctionType:
            let newParamTypes = functionType.parameterTypes.map { applySubstitutions($0, substitutions: substitutions) }
            let newReturnType = applySubstitutions(functionType.returnType, substitutions: substitutions)
            return FunctionType(parameterTypes: newParamTypes, returnType: newReturnType, line: functionType.line, column: functionType.column)
            
        case let optionalType as OptionalType:
            let newWrappedType = applySubstitutions(optionalType.wrappedType, substitutions: substitutions)
            return OptionalType(wrappedType: newWrappedType, line: optionalType.line, column: optionalType.column)
            
        case let unionType as UnionType:
            let newTypes = unionType.types.map { applySubstitutions($0, substitutions: substitutions) }
            return UnionType(types: newTypes, line: unionType.line, column: unionType.column)
            
        case let intersectionType as IntersectionType:
            let newTypes = intersectionType.types.map { applySubstitutions($0, substitutions: substitutions) }
            return IntersectionType(types: newTypes, line: intersectionType.line, column: intersectionType.column)
            
        default:
            return type
        }
    }
}
