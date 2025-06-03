//
//  SymbolTable.swift
//  OuroLangCore
//
//  Created by OuroLang Team on TodayDate.
//

import Foundation

/// Error types that can occur during symbol resolution
public enum SymbolError: Error, CustomStringConvertible {
    case symbolNotFound(String, line: Int, column: Int)
    case symbolRedefinition(String, previousLine: Int, previousColumn: Int, line: Int, column: Int)
    case typeMismatch(expected: String, got: String, line: Int, column: Int)
    case incompatibleTypes(String, String, line: Int, column: Int)
    case invalidOperation(String, line: Int, column: Int)
    case abstractMethodCall(String, line: Int, column: Int)
    case invalidOverride(String, line: Int, column: Int)
    case circularReference(String, line: Int, column: Int)
    case inaccessibleMember(String, line: Int, column: Int)
    
    public var description: String {
        switch self {
        case .symbolNotFound(let name, let line, let column):
            return "Symbol '\(name)' not found at line \(line), column \(column)"
        case .symbolRedefinition(let name, let prevLine, let prevColumn, let line, let column):
            return "Symbol '\(name)' at line \(line), column \(column) was already defined at line \(prevLine), column \(prevColumn)"
        case .typeMismatch(let expected, let got, let line, let column):
            return "Type mismatch at line \(line), column \(column): expected '\(expected)', got '\(got)'"
        case .incompatibleTypes(let type1, let type2, let line, let column):
            return "Incompatible types '\(type1)' and '\(type2)' at line \(line), column \(column)"
        case .invalidOperation(let operation, let line, let column):
            return "Invalid operation '\(operation)' at line \(line), column \(column)"
        case .abstractMethodCall(let method, let line, let column):
            return "Cannot call abstract method '\(method)' at line \(line), column \(column)"
        case .invalidOverride(let method, let line, let column):
            return "Invalid override of method '\(method)' at line \(line), column \(column)"
        case .circularReference(let type, let line, let column):
            return "Circular reference detected in type '\(type)' at line \(line), column \(column)"
        case .inaccessibleMember(let member, let line, let column):
            return "Member '\(member)' is not accessible at line \(line), column \(column)"
        }
    }
}

/// A type definition in OuroLang
public class TypeDefinition {
    /// Name of the type
    public let name: String
    
    /// Type parameters for generic types
    public let typeParameters: [String]
    
    /// Supertype, if any
    public var superType: TypeDefinition?
    
    /// Implemented interfaces
    public var interfaces: [TypeDefinition] = []
    
    /// Methods defined in this type
    public var methods: [MethodSymbol] = []
    
    /// Properties defined in this type
    public var properties: [VariableSymbol] = []
    
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
    
    /// Returns true if this type extends or implements the given type
    public func isSubtypeOf(_ type: TypeDefinition) -> Bool {
        if self == type {
            return true
        }
        
        if let superType = superType, superType.isSubtypeOf(type) {
            return true
        }
        
        for interface in interfaces {
            if interface.isSubtypeOf(type) {
                return true
            }
        }
        
        return false
    }
    
    public func findMethod(name: String) -> MethodSymbol? {
        // First look in this type's methods
        if let method = methods.first(where: { $0.name == name }) {
            return method
        }
        
        // Then check supertype
        if let superType = superType, let method = superType.findMethod(name: name) {
            return method
        }
        
        // Finally check interfaces
        for interface in interfaces {
            if let method = interface.findMethod(name: name) {
                return method
            }
        }
        
        return nil
    }
    
    public func findProperty(name: String) -> VariableSymbol? {
        // First look in this type's properties
        if let property = properties.first(where: { $0.name == name }) {
            return property
        }
        
        // Then check supertype
        if let superType = superType, let property = superType.findProperty(name: name) {
            return property
        }
        
        return nil
    }
}

extension TypeDefinition: Equatable {
    public static func == (lhs: TypeDefinition, rhs: TypeDefinition) -> Bool {
        // For primitive and named types, just compare names
        if lhs.isPrimitive || rhs.isPrimitive || lhs.typeParameters.isEmpty && rhs.typeParameters.isEmpty {
            return lhs.name == rhs.name
        }
        
        // For generic types, compare names and type parameters
        return lhs.name == rhs.name && lhs.typeParameters == rhs.typeParameters
    }
}

/// Access modifier for symbols
public enum AccessModifier {
    case `public`
    case `private`
    case `protected`
    case `internal`
    case `fileprivate`
}

/// Base class for all symbols in the symbol table
public class Symbol {
    /// Name of the symbol
    public let name: String
    
    /// Line where the symbol is defined
    public let line: Int
    
    /// Column where the symbol is defined
    public let column: Int
    
    /// Access modifier for this symbol
    public let accessModifier: AccessModifier
    
    public init(name: String, line: Int, column: Int, accessModifier: AccessModifier = .internal) {
        self.name = name
        self.line = line
        self.column = column
        self.accessModifier = accessModifier
    }
}

/// A variable or property symbol
public class VariableSymbol: Symbol {
    /// Type of the variable
    public let type: TypeDefinition
    
    /// Whether the variable is mutable (var) or immutable (let/const)
    public let isMutable: Bool
    
    /// Whether the variable is a class property (static)
    public let isStatic: Bool
    
    public init(name: String, type: TypeDefinition, isMutable: Bool, isStatic: Bool = false, line: Int, column: Int, accessModifier: AccessModifier = .internal) {
        self.type = type
        self.isMutable = isMutable
        self.isStatic = isStatic
        super.init(name: name, line: line, column: column, accessModifier: accessModifier)
    }
}

/// Parameter definition for methods
public class ParameterSymbol: Symbol {
    /// Type of the parameter
    public let type: TypeDefinition
    
    /// Default value for the parameter, if any
    public let hasDefaultValue: Bool
    
    public init(name: String, type: TypeDefinition, hasDefaultValue: Bool = false, line: Int, column: Int) {
        self.type = type
        self.hasDefaultValue = hasDefaultValue
        super.init(name: name, line: line, column: column)
    }
}

/// A method or function symbol
public class MethodSymbol: Symbol {
    /// Return type of the method
    public let returnType: TypeDefinition?
    
    /// Parameters of the method
    public let parameters: [ParameterSymbol]
    
    /// Whether the method is static (class method)
    public let isStatic: Bool
    
    /// Whether the method is abstract
    public let isAbstract: Bool
    
    /// Whether the method overrides a superclass method
    public let isOverride: Bool
    
    /// Whether the method is a constructor
    public let isConstructor: Bool
    
    /// Whether the method is async
    public let isAsync: Bool
    
    /// Type parameters for generic methods
    public let typeParameters: [String]
    
    public init(name: String, returnType: TypeDefinition?, parameters: [ParameterSymbol], isStatic: Bool = false, isAbstract: Bool = false, isOverride: Bool = false, isConstructor: Bool = false, isAsync: Bool = false, typeParameters: [String] = [], line: Int, column: Int, accessModifier: AccessModifier = .internal) {
        self.returnType = returnType
        self.parameters = parameters
        self.isStatic = isStatic
        self.isAbstract = isAbstract
        self.isOverride = isOverride
        self.isConstructor = isConstructor
        self.isAsync = isAsync
        self.typeParameters = typeParameters
        super.init(name: name, line: line, column: column, accessModifier: accessModifier)
    }
    
    /// Check if this method signature matches another method
    public func signatureMatches(_ other: MethodSymbol) -> Bool {
        if name != other.name || parameters.count != other.parameters.count {
            return false
        }
        
        // Check each parameter type
        for i in 0..<parameters.count {
            if parameters[i].type != other.parameters[i].type {
                return false
            }
        }
        
        // Check return type
        if let thisReturn = returnType, let otherReturn = other.returnType {
            return thisReturn == otherReturn
        } else {
            return returnType == nil && other.returnType == nil
        }
    }
}

/// A scope represents a lexical block with its own symbol table
public class Scope {
    /// Parent scope, if any
    public weak var parent: Scope?
    
    /// Symbol table for this scope
    private var symbols: [String: Symbol] = [:]
    
    /// Child scopes
    private var children: [Scope] = []
    
    /// The type this scope belongs to, if any (for class/struct/enum scopes)
    public var enclosingType: TypeDefinition?
    
    public init(parent: Scope? = nil, enclosingType: TypeDefinition? = nil) {
        self.parent = parent
        self.enclosingType = enclosingType
    }
    
    /// Create a new child scope
    public func createChild(enclosingType: TypeDefinition? = nil) -> Scope {
        let child = Scope(parent: self, enclosingType: enclosingType ?? self.enclosingType)
        children.append(child)
        return child
    }
    
    /// Define a symbol in the current scope
    public func define(_ symbol: Symbol) throws {
        if let existing = symbols[symbol.name] {
            throw SymbolError.symbolRedefinition(
                symbol.name,
                previousLine: existing.line,
                previousColumn: existing.column,
                line: symbol.line,
                column: symbol.column
            )
        }
        
        symbols[symbol.name] = symbol
    }
    
    /// Look up a symbol by name in the current scope and parent scopes
    public func resolve(_ name: String) -> Symbol? {
        if let symbol = symbols[name] {
            return symbol
        }
        
        return parent?.resolve(name)
    }
    
    /// Look up a variable by name
    public func resolveVariable(_ name: String) -> VariableSymbol? {
        return resolve(name) as? VariableSymbol
    }
    
    /// Look up a method by name
    public func resolveMethod(_ name: String) -> MethodSymbol? {
        return resolve(name) as? MethodSymbol
    }
    
    /// Look up a type by name
    public func resolveType(_ name: String) -> TypeDefinition? {
        if let typeSymbol = resolve(name) as? TypeDefinition {
            return typeSymbol
        }
        
        // If not found in symbol table, check if the enclosing type has it as a property
        if let enclosingType = enclosingType {
            // Look for inner types (classes, interfaces, etc.)
            // This would be implemented if OuroLang supports nested types
            
            // Look for type parameters in generic types
            if enclosingType.typeParameters.contains(name) {
                // For simplicity, treat type parameters as object type
                // In a real implementation, we would track actual type arguments
                return TypeDefinition(name: name, isPrimitive: false, line: 0, column: 0)
            }
        }
        
        return nil
    }
    
    /// Get all symbols defined in this scope
    public func getSymbols() -> [Symbol] {
        return Array(symbols.values)
    }
}

/// Global symbol table manager
public class SymbolTable {
    /// Global scope
    public let globalScope: Scope
    
    /// Current scope being processed
    public private(set) var currentScope: Scope
    
    /// The list of primitive types
    public let primitiveTypes: [TypeDefinition]
    
    public init() {
        globalScope = Scope()
        currentScope = globalScope
        
        // Initialize primitive types
        primitiveTypes = [
            TypeDefinition(name: "Int", isPrimitive: true, line: 0, column: 0),
            TypeDefinition(name: "Float", isPrimitive: true, line: 0, column: 0),
            TypeDefinition(name: "Double", isPrimitive: true, line: 0, column: 0),
            TypeDefinition(name: "Bool", isPrimitive: true, line: 0, column: 0),
            TypeDefinition(name: "Char", isPrimitive: true, line: 0, column: 0),
            TypeDefinition(name: "String", isPrimitive: true, line: 0, column: 0),
            TypeDefinition(name: "Void", isPrimitive: true, line: 0, column: 0)
        ]
        
        // Add primitive types to global scope
        for type in primitiveTypes {
            try! globalScope.define(type)
        }
    }
    
    /// Enter a new scope
    public func enterScope(enclosingType: TypeDefinition? = nil) {
        currentScope = currentScope.createChild(enclosingType: enclosingType)
    }
    
    /// Exit the current scope
    public func exitScope() {
        if let parent = currentScope.parent {
            currentScope = parent
        } else {
            // We're already at the global scope
            // This is usually an error in the compiler itself
            assertionFailure("Attempted to exit global scope")
        }
    }
    
    /// Define a symbol in the current scope
    public func define(_ symbol: Symbol) throws {
        try currentScope.define(symbol)
    }
    
    /// Look up a symbol by name in the current scope and parent scopes
    public func resolve(_ name: String) -> Symbol? {
        return currentScope.resolve(name)
    }
    
    /// Look up a variable by name
    public func resolveVariable(_ name: String) -> VariableSymbol? {
        return currentScope.resolveVariable(name)
    }
    
    /// Look up a method by name
    public func resolveMethod(_ name: String) -> MethodSymbol? {
        return currentScope.resolveMethod(name)
    }
    
    /// Look up a type by name
    public func resolveType(_ name: String) -> TypeDefinition? {
        return currentScope.resolveType(name)
    }
    
    /// Get a primitive type by name
    public func getPrimitiveType(_ name: String) -> TypeDefinition? {
        return primitiveTypes.first { $0.name == name }
    }
}