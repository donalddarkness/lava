//
//  TypeChecker.swift
//  OuroLangCore
//
//  Created by OuroLang Team on 2025-06-04.
//

import Foundation

/// TypeChecker performs comprehensive type checking on the AST
/// It validates type correctness, resolves symbols, and applies language rules
public class TypeChecker {
    /// Shared instance for convenient access
    public static let shared = TypeChecker()
    
    /// The symbol table for resolving symbols
    private let symbolTable: SymbolTable
    
    /// The type resolver for resolving and analyzing types
    private let typeResolver: TypeResolver
    
    /// The type operations for performing advanced type operations
    internal let typeOperations: TypeOperations
    
    /// Collected errors during type checking
    private var errors: [Error] = []
    
    /// Current return type for function body analysis
    private var currentReturnType: TypeNode?
    
    /// Whether we're currently in a loop (for break/continue validation)
    private var isInLoop = false
    
    /// Whether we're currently in an async context
    private var isAsyncContext = false
    
    /// Whether we're currently in a constructor
    private var isInConstructor = false
    
    /// Stack of types being checked (for circular reference detection)
    private var typeCheckStack: [String] = []
    
    /// Create a new TypeChecker with the given symbol table
    public init(symbolTable: SymbolTable = SymbolTable()) {
        self.symbolTable = symbolTable
        self.typeResolver = TypeResolver()
        self.typeOperations = TypeOperations(resolver: typeResolver)
        
        // Register primitive types
        registerPrimitiveTypes()
    }
    
    /// Register all primitive types with the type resolver
    private func registerPrimitiveTypes() {
        // Register basic primitive types
        typeResolver.registerPrimitiveType("Int", mlirType: "i32")
        typeResolver.registerPrimitiveType("Double", mlirType: "f64")
        typeResolver.registerPrimitiveType("Float", mlirType: "f32")
        typeResolver.registerPrimitiveType("Bool", mlirType: "i1")
        typeResolver.registerPrimitiveType("String", mlirType: "!llvm.struct<(ptr<i8>, i64)>")
        typeResolver.registerPrimitiveType("Void", mlirType: "!llvm.void")
        typeResolver.registerPrimitiveType("Any", mlirType: "!llvm.ptr")
        typeResolver.registerPrimitiveType("Never", mlirType: "!llvm.void")
        typeResolver.registerPrimitiveType("UInt", mlirType: "i32")
        typeResolver.registerPrimitiveType("Char", mlirType: "i8")
    }
    
    /// Check an entire program's AST for semantic errors
    /// - Parameter declarations: The list of top-level declarations from the parser
    /// - Returns: Any semantic errors found during the check
    public func check(_ declarations: [Decl]) async -> [Error] {
        errors.removeAll()
        
        // First pass: Declare all types to allow for forward references
        for declaration in declarations {
            try? await declareTypes(declaration)
        }
        
        // Second pass: Check each declaration
        for declaration in declarations {
            try? await checkDeclaration(declaration)
        }
        
        return errors
    }
    
    // MARK: - Type Declaration Pass
    
    private func declareTypes(_ declaration: Decl) async throws {
        if let classDecl = declaration as? ClassDecl {
            // Create a type definition for the class
            let typeDefinition = TypeDefinition(
                name: classDecl.name.lexeme,
                isInterface: false,
                isAbstract: false,
                isSealed: false,
                isPrimitive: false,
                line: classDecl.line, 
                column: classDecl.column
            )
            
            try symbolTable.define(typeDefinition)
        } 
        else if let structDecl = declaration as? StructDecl {
            // Create a type definition for the struct
            let typeDefinition = TypeDefinition(
                name: structDecl.name.lexeme,
                isInterface: false,
                isAbstract: false,
                isSealed: false,
                isPrimitive: false,
                line: structDecl.line,
                column: structDecl.column
            )
            
            try symbolTable.define(typeDefinition)
        }
        else if let interfaceDecl = declaration as? InterfaceDecl {
            // Create a type definition for the interface
            let typeDefinition = TypeDefinition(
                name: interfaceDecl.name.lexeme,
                isInterface: true,
                isAbstract: true,
                isSealed: false,
                isPrimitive: false,
                line: interfaceDecl.line,
                column: interfaceDecl.column
            )
            
            try symbolTable.define(typeDefinition)
        }
        else if let enumDecl = declaration as? EnumDecl {
            // Create a type definition for the enum
            let typeDefinition = TypeDefinition(
                name: enumDecl.name.lexeme,
                isInterface: false,
                isAbstract: false,
                isSealed: true,
                isPrimitive: false,
                line: enumDecl.line,
                column: enumDecl.column
            )
            
            try symbolTable.define(typeDefinition)
        }
    }
    
    // MARK: - Declaration Checking
    
    private func checkDeclaration(_ declaration: Decl) async throws {
        switch declaration {
        case let classDecl as ClassDecl:
            try checkClassDeclaration(classDecl)
        case let structDecl as StructDecl:
            try checkStructDeclaration(structDecl)
        case let interfaceDecl as InterfaceDecl:
            try checkInterfaceDeclaration(interfaceDecl)
        case let enumDecl as EnumDecl:
            try checkEnumDeclaration(enumDecl)
        case let funcDecl as FunctionDecl:
            try checkFunctionDeclaration(funcDecl)
        case let varDecl as VarDecl:
            try checkVarDeclaration(varDecl)
        default:
            // This should never happen if the parser is correct
            errors.append(CompilerError.compileError("Unknown declaration type: \(type(of: declaration))"))
        }
    }
    
    private func checkClassDeclaration(_ classDecl: ClassDecl) throws {
        guard let classType = symbolTable.resolveType(classDecl.name.lexeme) else {
            throw SymbolError.symbolNotFound(classDecl.name.lexeme, line: classDecl.line, column: classDecl.column)
        }
        
        // Enter class scope
        symbolTable.enterScope(enclosingType: classType)
        defer { symbolTable.exitScope() }
        
        // Check superclass if any
        if let superclass = classDecl.superclass {
            let superType = try resolveTypeNode(superclass)
            if superType.isInterface {
                errors.append(SymbolError.typeMismatch(
                    expected: "class",
                    got: "interface",
                    line: superclass.line,
                    column: superclass.column
                ))
            } else {
                classType.superType = superType
            }
        }
        
        // Check interfaces
        for interface in classDecl.interfaces {
            let interfaceType = try resolveTypeNode(interface)
            if !interfaceType.isInterface {
                errors.append(SymbolError.typeMismatch(
                    expected: "interface",
                    got: "class",
                    line: interface.line,
                    column: interface.column
                ))
            } else {
                classType.interfaces.append(interfaceType)
            }
        }
        
        // Check properties
        for property in classDecl.properties {
            try checkVarDeclaration(property)
            
            // Add property to class type
            if let varSymbol = symbolTable.resolveVariable(property.name.lexeme) {
                classType.properties.append(varSymbol)
            }
        }
        
        // Check methods
        for method in classDecl.methods {
            try checkFunctionDeclaration(method)
            
            // Add method to class type
            if let methodSymbol = symbolTable.resolveMethod(method.name.lexeme) {
                classType.methods.append(methodSymbol)
            }
        }
        
        // Check that the class implements all interface methods
        for interface in classType.interfaces {
            for interfaceMethod in interface.methods {
                if !classType.methods.contains(where: { $0.signatureMatches(interfaceMethod) }) {
                    errors.append(SymbolError.symbolNotFound(
                        interfaceMethod.name,
                        line: classDecl.line,
                        column: classDecl.column
                    ))
                }
            }
        }
    }
    
    private func checkStructDeclaration(_ structDecl: StructDecl) throws {
        guard let structType = symbolTable.resolveType(structDecl.name.lexeme) else {
            throw SymbolError.symbolNotFound(structDecl.name.lexeme, line: structDecl.line, column: structDecl.column)
        }
        
        // Enter struct scope
        symbolTable.enterScope(enclosingType: structType)
        defer { symbolTable.exitScope() }
        
        // Check interfaces
        for interface in structDecl.interfaces {
            let interfaceType = try resolveTypeNode(interface)
            if !interfaceType.isInterface {
                errors.append(SymbolError.typeMismatch(
                    expected: "interface",
                    got: "class or struct",
                    line: interface.line,
                    column: interface.column
                ))
            } else {
                structType.interfaces.append(interfaceType)
            }
        }
        
        // Check properties
        for property in structDecl.properties {
            try checkVarDeclaration(property)
            
            // Add property to struct type
            if let varSymbol = symbolTable.resolveVariable(property.name.lexeme) {
                structType.properties.append(varSymbol)
            }
        }
        
        // Check methods
        for method in structDecl.methods {
            try checkFunctionDeclaration(method)
            
            // Add method to struct type
            if let methodSymbol = symbolTable.resolveMethod(method.name.lexeme) {
                structType.methods.append(methodSymbol)
            }
        }
        
        // Check that the struct implements all interface methods
        for interface in structType.interfaces {
            for interfaceMethod in interface.methods {
                if !structType.methods.contains(where: { $0.signatureMatches(interfaceMethod) }) {
                    errors.append(SymbolError.symbolNotFound(
                        interfaceMethod.name,
                        line: structDecl.line,
                        column: structDecl.column
                    ))
                }
            }
        }
    }
    
    private func checkInterfaceDeclaration(_ interfaceDecl: InterfaceDecl) throws {
        guard let interfaceType = symbolTable.resolveType(interfaceDecl.name.lexeme) else {
            throw SymbolError.symbolNotFound(interfaceDecl.name.lexeme, line: interfaceDecl.line, column: interfaceDecl.column)
        }
        
        // Enter interface scope
        symbolTable.enterScope(enclosingType: interfaceType)
        defer { symbolTable.exitScope() }
        
        // Check extended interfaces
        for extendedInterface in interfaceDecl.extendedInterfaces {
            let extendedType = try resolveTypeNode(extendedInterface)
            if !extendedType.isInterface {
                errors.append(SymbolError.typeMismatch(
                    expected: "interface",
                    got: "class or struct",
                    line: extendedInterface.line,
                    column: extendedInterface.column
                ))
            } else {
                interfaceType.interfaces.append(extendedType)
            }
        }
        
        // Check methods (only signatures in interfaces)
        for method in interfaceDecl.methods {
            try checkFunctionDeclaration(method, isInterfaceMethod: true)
            
            // Add method to interface type
            if let methodSymbol = symbolTable.resolveMethod(method.name.lexeme) {
                interfaceType.methods.append(methodSymbol)
            }
        }
    }
    
    private func checkEnumDeclaration(_ enumDecl: EnumDecl) throws {
        guard let enumType = symbolTable.resolveType(enumDecl.name.lexeme) else {
            throw SymbolError.symbolNotFound(enumDecl.name.lexeme, line: enumDecl.line, column: enumDecl.column)
        }
        
        // Enter enum scope
        symbolTable.enterScope(enclosingType: enumType)
        defer { symbolTable.exitScope() }
        
        // Check raw type if specified
        var rawValueType: TypeDefinition?
        if let rawType = enumDecl.rawType {
            rawValueType = try resolveTypeNode(rawType)
            
            // Raw value type should be a primitive or String
            if !rawValueType!.isPrimitive && rawValueType!.name != "String" {
                errors.append(SymbolError.typeMismatch(
                    expected: "primitive type or String",
                    got: rawValueType!.name,
                    line: rawType.line,
                    column: rawType.column
                ))
            }
        }
        
        // Check cases and their raw values
        for enumCase in enumDecl.cases {
            // Define case as static property
            let caseSymbol = VariableSymbol(
                name: enumCase.name.lexeme,
                type: enumType,
                isMutable: false,
                isStatic: true,
                line: enumCase.name.line,
                column: enumCase.name.column,
                accessModifier: .public
            )
            
            try symbolTable.define(caseSymbol)
            
            // Check raw value if provided
            if let rawValue = enumCase.rawValue {
                if rawValueType == nil {
                    errors.append(SymbolError.invalidOperation(
                        "Raw value provided but enum has no raw value type",
                        line: rawValue.line,
                        column: rawValue.column
                    ))
                } else {
                    let rawValueExprType = try typeCheckExpression(rawValue)
                    if rawValueExprType != rawValueType {
                        errors.append(SymbolError.typeMismatch(
                            expected: rawValueType!.name,
                            got: rawValueExprType.name,
                            line: rawValue.line,
                            column: rawValue.column
                        ))
                    }
                }
            }
        }
        
        // Check methods
        for method in enumDecl.methods {
            try checkFunctionDeclaration(method)
            
            // Add method to enum type
            if let methodSymbol = symbolTable.resolveMethod(method.name.lexeme) {
                enumType.methods.append(methodSymbol)
            }
        }
    }
    
    private func checkFunctionDeclaration(_ funcDecl: FunctionDecl, isInterfaceMethod: Bool = false) throws {
        // Resolve return type
        var returnType: TypeDefinition? = nil
        if let returnTypeNode = funcDecl.returnType {
            returnType = try resolveTypeNode(returnTypeNode)
        }
        
        // Process parameters
        var parameterSymbols: [ParameterSymbol] = []
        
        for param in funcDecl.params {
            let paramType = try resolveTypeNode(param.type)
            let paramSymbol = ParameterSymbol(
                name: param.name.lexeme,
                type: paramType,
                hasDefaultValue: param.defaultValue != nil,
                line: param.name.line,
                column: param.name.column
            )
            
            parameterSymbols.append(paramSymbol)
        }
        
        // Create method symbol
        let methodSymbol = MethodSymbol(
            name: funcDecl.name.lexeme,
            returnType: returnType,
            parameters: parameterSymbols,
            isStatic: false, // Would be determined from modifiers
            isAbstract: isInterfaceMethod,
            isOverride: false, // Would be determined from modifiers
            isConstructor: funcDecl.name.lexeme == "init",
            isAsync: false, // Would be determined from modifiers
            line: funcDecl.name.line,
            column: funcDecl.name.column,
            accessModifier: .public // Would be determined from modifiers
        )
        
        // Add method to symbol table
        try symbolTable.define(methodSymbol)
        
        // Skip body check for interface methods
        if isInterfaceMethod {
            return
        }
        
        // Check function body
        let previousReturnType = currentReturnType
        currentReturnType = returnType
        
        symbolTable.enterScope()
        defer { 
            symbolTable.exitScope()
            currentReturnType = previousReturnType
        }
        
        // Add parameters to function scope
        for param in funcDecl.params {
            let paramType = try resolveTypeNode(param.type)
            let paramSymbol = VariableSymbol(
                name: param.name.lexeme,
                type: paramType,
                isMutable: false, // Parameters are immutable by default
                line: param.name.line,
                column: param.name.column
            )
            
            try symbolTable.define(paramSymbol)
            
            // Check default value if provided
            if let defaultValue = param.defaultValue {
                let defaultValueType = try typeCheckExpression(defaultValue)
                if !isAssignable(from: defaultValueType, to: paramType) {
                    errors.append(SymbolError.typeMismatch(
                        expected: paramType.name,
                        got: defaultValueType.name,
                        line: defaultValue.line,
                        column: defaultValue.column
                    ))
                }
            }
        }
        
        // Check function body
        try checkBlockStatement(funcDecl.body)
    }
    
    private func checkVarDeclaration(_ varDecl: VarDecl) throws {
        // Resolve variable type
        var variableType: TypeDefinition
        
        // If type annotation is provided, use that
        if let typeAnnotation = varDecl.typeAnnotation {
            variableType = try resolveTypeNode(typeAnnotation)
        } 
        // Otherwise, infer type from initializer
        else if let initializer = varDecl.initializer {
            variableType = try typeCheckExpression(initializer)
        }
        // Error: neither type annotation nor initializer
        else {
            throw SymbolError.invalidOperation(
                "Variable must have either a type annotation or an initializer",
                line: varDecl.line,
                column: varDecl.column
            )
        }
        
        // Create variable symbol
        let variableSymbol = VariableSymbol(
            name: varDecl.name.lexeme,
            type: variableType,
            isMutable: true, // Assuming 'var' keyword, would be false for 'const' or 'let'
            line: varDecl.name.line,
            column: varDecl.name.column
        )
        
        // Add variable to symbol table
        try symbolTable.define(variableSymbol)
        
        // Check initializer if provided
        if let initializer = varDecl.initializer {
            let initializerType = try typeCheckExpression(initializer)
            
            // Check if initializer type is compatible with variable type
            if !isAssignable(from: initializerType, to: variableType) {
                errors.append(SymbolError.typeMismatch(
                    expected: variableType.name,
                    got: initializerType.name,
                    line: initializer.line,
                    column: initializer.column
                ))
            }
        }
    }
    
    // MARK: - Statement Checking
    
    private func checkStatement(_ stmt: Stmt) throws {
        switch stmt {
        case let exprStmt as ExpressionStmt:
            try typeCheckExpression(exprStmt.expression)
        case let blockStmt as BlockStmt:
            try checkBlockStatement(blockStmt)
        case let ifStmt as IfStmt:
            try checkIfStatement(ifStmt)
        case let whileStmt as WhileStmt:
            try checkWhileStatement(whileStmt)
        case let forStmt as ForStmt:
            try checkForStatement(forStmt)
        case let returnStmt as ReturnStmt:
            try checkReturnStatement(returnStmt)
        case let breakStmt as BreakStmt:
            try checkBreakStatement(breakStmt)
        case let continueStmt as ContinueStmt:
            try checkContinueStatement(continueStmt)
        default:
            // This should never happen if the parser is correct
            errors.append(CompilerError.compileError("Unknown statement type: \(type(of: stmt))"))
        }
    }
    
    private func checkBlockStatement(_ stmt: BlockStmt) throws {
        symbolTable.enterScope()
        defer { symbolTable.exitScope() }
        
        for statement in stmt.statements {
            try checkStatement(statement)
        }
    }
    
    private func checkIfStatement(_ stmt: IfStmt) throws {
        // Check condition is a boolean
        let conditionType = try typeCheckExpression(stmt.condition)
        if conditionType.name != "Bool" {
            errors.append(SymbolError.typeMismatch(
                expected: "Bool",
                got: conditionType.name,
                line: stmt.condition.line,
                column: stmt.condition.column
            ))
        }
        
        // Check then branch
        try checkStatement(stmt.thenBranch)
        
        // Check else branch if present
        if let elseBranch = stmt.elseBranch {
            try checkStatement(elseBranch)
        }
    }
    
    private func checkWhileStatement(_ stmt: WhileStmt) throws {
        // Check condition is a boolean
        let conditionType = try typeCheckExpression(stmt.condition)
        if conditionType.name != "Bool" {
            errors.append(SymbolError.typeMismatch(
                expected: "Bool",
                got: conditionType.name,
                line: stmt.condition.line,
                column: stmt.condition.column
            ))
        }
        
        // Check body
        let wasInLoop = isInLoop
        isInLoop = true
        try checkStatement(stmt.body)
        isInLoop = wasInLoop
    }
    
    private func checkForStatement(_ stmt: ForStmt) throws {
        symbolTable.enterScope()
        defer { symbolTable.exitScope() }
        
        // Check initializer if present
        if let initializer = stmt.initializer {
            try checkStatement(initializer)
        }
        
        // Check condition if present
        if let condition = stmt.condition {
            let conditionType = try typeCheckExpression(condition)
            if conditionType.name != "Bool" {
                errors.append(SymbolError.typeMismatch(
                    expected: "Bool",
                    got: conditionType.name,
                    line: condition.line,
                    column: condition.column
                ))
            }
        }
        
        // Check increment if present
        if let increment = stmt.increment {
            try typeCheckExpression(increment)
        }
        
        // Check body
        let wasInLoop = isInLoop
        isInLoop = true
        try checkStatement(stmt.body)
        isInLoop = wasInLoop
    }
    
    private func checkReturnStatement(_ stmt: ReturnStmt) throws {
        // Check that we're in a function
        if currentReturnType == nil {
            errors.append(SymbolError.invalidOperation(
                "Return statement outside of function",
                line: stmt.line,
                column: stmt.column
            ))
            return
        }
        
        // Check return value matches function return type
        if let value = stmt.value {
            let valueType = try typeCheckExpression(value)
            
            if let expectedType = currentReturnType {
                if !isAssignable(from: valueType, to: expectedType) {
                    errors.append(SymbolError.typeMismatch(
                        expected: expectedType.name,
                        got: valueType.name,
                        line: value.line,
                        column: value.column
                    ))
                }
            } else {
                // Function has void return type but a value is provided
                errors.append(SymbolError.invalidOperation(
                    "Return value in a void function",
                    line: value.line,
                    column: value.column
                ))
            }
        } else {
            // No return value, but function expects one
            if let expectedType = currentReturnType {
                errors.append(SymbolError.invalidOperation(
                    "Missing return value, expected " + expectedType.name,
                    line: stmt.line,
                    column: stmt.column
                ))
            }
        }
    }
    
    private func checkBreakStatement(_ stmt: BreakStmt) throws {
        if !isInLoop {
            errors.append(SymbolError.invalidOperation(
                "Break statement outside of loop",
                line: stmt.line,
                column: stmt.column
            ))
        }
    }
    
    private func checkContinueStatement(_ stmt: ContinueStmt) throws {
        if !isInLoop {
            errors.append(SymbolError.invalidOperation(
                "Continue statement outside of loop",
                line: stmt.line,
                column: stmt.column
            ))
        }
    }
    
    // MARK: - Expression Checking
    
    private func typeCheckExpression(_ expr: Expr) throws -> TypeDefinition {
        switch expr {
        case let binaryExpr as BinaryExpr:
            return try typeCheckBinaryExpression(binaryExpr)
        case let groupingExpr as GroupingExpr:
            return try typeCheckExpression(groupingExpr.expression)
        case let literalExpr as LiteralExpr:
            return try typeCheckLiteralExpression(literalExpr)
        case let unaryExpr as UnaryExpr:
            return try typeCheckUnaryExpression(unaryExpr)
        case let variableExpr as VariableExpr:
            return try typeCheckVariableExpression(variableExpr)
        case let callExpr as CallExpr:
            return try typeCheckCallExpression(callExpr)
        case let getExpr as GetExpr:
            return try typeCheckGetExpression(getExpr)
        case let setExpr as SetExpr:
            return try typeCheckSetExpression(setExpr)
        case let thisExpr as ThisExpr:
            return try typeCheckThisExpression(thisExpr)
        case let superExpr as SuperExpr:
            return try typeCheckSuperExpression(superExpr)
        case let arrayExpr as ArrayExpr:
            return try typeCheckArrayExpression(arrayExpr)
        case let indexExpr as IndexExpr:
            return try typeCheckIndexExpression(indexExpr)
        default:
            // This should never happen if the parser is correct
            throw CompilerError.compileError("Unknown expression type: \(type(of: expr))")
        }
    }
    
    private func typeCheckBinaryExpression(_ expr: BinaryExpr) throws -> TypeDefinition {
        let leftType = try typeCheckExpression(expr.left)
        let rightType = try typeCheckExpression(expr.right)
        
        // Type checking depends on operator
        switch expr.operator.type {
        // Arithmetic operators
        case .plus:
            // String concatenation
            if leftType.name == "String" || rightType.name == "String" {
                return symbolTable.getPrimitiveType("String")!
            }
            // Numeric addition
            fallthrough
        case .minus, .star, .slash, .percent:
            if isNumeric(leftType) && isNumeric(rightType) {
                // Return the "wider" numeric type
                if leftType.name == "Double" || rightType.name == "Double" {
                    return symbolTable.getPrimitiveType("Double")!
                } else if leftType.name == "Float" || rightType.name == "Float" {
                    return symbolTable.getPrimitiveType("Float")!
                } else {
                    return symbolTable.getPrimitiveType("Int")!
                }
            } else {
                errors.append(SymbolError.invalidOperation(
                    "Operator \(expr.operator.lexeme) cannot be applied to types \(leftType.name) and \(rightType.name)",
                    line: expr.operator.line,
                    column: expr.operator.column
                ))
                return symbolTable.getPrimitiveType("Int")! // Default to Int for error recovery
            }
            
        // Comparison operators
        case .equalEqual, .bangEqual:
            if isAssignable(from: leftType, to: rightType) || isAssignable(from: rightType, to: leftType) {
                return symbolTable.getPrimitiveType("Bool")!
            } else {
                errors.append(SymbolError.invalidOperation(
                    "Cannot compare values of types \(leftType.name) and \(rightType.name)",
                    line: expr.operator.line,
                    column: expr.operator.column
                ))
                return symbolTable.getPrimitiveType("Bool")! // Default to Bool for error recovery
            }
            
        case .less, .lessEqual, .greater, .greaterEqual:
            if (isNumeric(leftType) && isNumeric(rightType)) || (leftType.name == "String" && rightType.name == "String") {
                return symbolTable.getPrimitiveType("Bool")!
            } else {
                errors.append(SymbolError.invalidOperation(
                    "Operator \(expr.operator.lexeme) cannot be applied to types \(leftType.name) and \(rightType.name)",
                    line: expr.operator.line,
                    column: expr.operator.column
                ))
                return symbolTable.getPrimitiveType("Bool")! // Default to Bool for error recovery
            }
            
        // Logical operators
        case .and, .or:
            if leftType.name == "Bool" && rightType.name == "Bool" {
                return symbolTable.getPrimitiveType("Bool")!
            } else {
                errors.append(SymbolError.typeMismatch(
                    expected: "Bool",
                    got: leftType.name != "Bool" ? leftType.name : rightType.name,
                    line: expr.operator.line,
                    column: expr.operator.column
                ))
                return symbolTable.getPrimitiveType("Bool")! // Default to Bool for error recovery
            }
            
        default:
            errors.append(SymbolError.invalidOperation(
                "Unsupported binary operator: \(expr.operator.lexeme)",
                line: expr.operator.line,
                column: expr.operator.column
            ))
            return symbolTable.getPrimitiveType("Int")! // Default to Int for error recovery
        }
    }
    
    private func typeCheckLiteralExpression(_ expr: LiteralExpr) throws -> TypeDefinition {
        switch expr.tokenType {
        case .integer:
            return symbolTable.getPrimitiveType("Int")!
        case .float:
            return symbolTable.getPrimitiveType("Double")!
        case .string:
            return symbolTable.getPrimitiveType("String")!
        case .char:
            return symbolTable.getPrimitiveType("Char")!
        case .true, .false:
            return symbolTable.getPrimitiveType("Bool")!
        case .null:
            // For null, we need a context type. Default to a generic "Object" type.
            // In a real implementation, this would be handled better.
            return TypeDefinition(name: "Object", isPrimitive: false, line: expr.line, column: expr.column)
        default:
            throw CompilerError.compileError("Unsupported literal type: \(expr.tokenType)")
        }
    }
    
    private func typeCheckUnaryExpression(_ expr: UnaryExpr) throws -> TypeDefinition {
        let rightType = try typeCheckExpression(expr.right)
        
        switch expr.operator.type {
        case .minus:
            if isNumeric(rightType) {
                return rightType
            } else {
                errors.append(SymbolError.typeMismatch(
                    expected: "numeric type",
                    got: rightType.name,
                    line: expr.operator.line,
                    column: expr.operator.column
                ))
                return symbolTable.getPrimitiveType("Int")! // Default to Int for error recovery
            }
            
        case .bang:
            if rightType.name == "Bool" {
                return symbolTable.getPrimitiveType("Bool")!
            } else {
                errors.append(SymbolError.typeMismatch(
                    expected: "Bool",
                    got: rightType.name,
                    line: expr.operator.line,
                    column: expr.operator.column
                ))
                return symbolTable.getPrimitiveType("Bool")! // Default to Bool for error recovery
            }
            
        default:
            throw CompilerError.compileError("Unsupported unary operator: \(expr.operator.lexeme)")
        }
    }
    
    private func typeCheckVariableExpression(_ expr: VariableExpr) throws -> TypeDefinition {
        guard let varSymbol = symbolTable.resolveVariable(expr.name.lexeme) else {
            errors.append(SymbolError.symbolNotFound(
                expr.name.lexeme,
                line: expr.name.line,
                column: expr.name.column
            ))
            // Return a dummy type for error recovery
            return TypeDefinition(name: "Error", isPrimitive: false, line: expr.line, column: expr.column)
        }
        
        return varSymbol.type
    }
    
    private func typeCheckCallExpression(_ expr: CallExpr) throws -> TypeDefinition {
        // First handle the case where we're calling a method on an object
        if let getExpr = expr.callee as? GetExpr {
            let objectType = try typeCheckExpression(getExpr.object)
            let methodName = getExpr.name.lexeme
            
            guard let method = objectType.findMethod(methodName) else {
                errors.append(SymbolError.symbolNotFound(
                    methodName,
                    line: getExpr.name.line,
                    column: getExpr.name.column
                ))
                // Return a dummy type for error recovery
                return TypeDefinition(name: "Error", isPrimitive: false, line: expr.line, column: expr.column)
            }
            
            // Check arguments match parameters
            try checkArguments(expr.arguments, parameters: method.parameters, callSite: expr)
            
            // Return method return type or void
            return method.returnType ?? symbolTable.getPrimitiveType("Void")!
        }
        // Case where we're calling a function directly
        else if let varExpr = expr.callee as? VariableExpr {
            let functionName = varExpr.name.lexeme
            
            guard let method = symbolTable.resolveMethod(functionName) else {
                errors.append(SymbolError.symbolNotFound(
                    functionName,
                    line: varExpr.name.line,
                    column: varExpr.name.column
                ))
                // Return a dummy type for error recovery
                return TypeDefinition(name: "Error", isPrimitive: false, line: expr.line, column: expr.column)
            }
            
            // Check arguments match parameters
            try checkArguments(expr.arguments, parameters: method.parameters, callSite: expr)
            
            // Return method return type or void
            return method.returnType ?? symbolTable.getPrimitiveType("Void")!
        }
        // More complex case (e.g., function returned from another function)
        else {
            // Future enhancement: support first-class functions
            errors.append(SymbolError.invalidOperation(
                "Unsupported callee expression type",
                line: expr.callee.line,
                column: expr.callee.column
            ))
            
            // Return a dummy type for error recovery
            return TypeDefinition(name: "Error", isPrimitive: false, line: expr.line, column: expr.column)
        }
    }
    
    private func checkArguments(_ arguments: [Expr], parameters: [ParameterSymbol], callSite: CallExpr) throws {
        // Check argument count
        if arguments.count > parameters.count {
            errors.append(SymbolError.invalidOperation(
                "Too many arguments: expected \(parameters.count), got \(arguments.count)",
                line: callSite.line,
                column: callSite.column
            ))
        } else if arguments.count < parameters.count {
            // Check if missing parameters have default values
            let nonDefaultParams = parameters.suffix(from: arguments.count).filter { !$0.hasDefaultValue }
            if !nonDefaultParams.isEmpty {
                errors.append(SymbolError.invalidOperation(
                    "Too few arguments: missing required parameters",
                    line: callSite.line,
                    column: callSite.column
                ))
            }
        }
        
        // Check argument types
        for i in 0..<min(arguments.count, parameters.count) {
            let argType = try typeCheckExpression(arguments[i])
            let paramType = parameters[i].type
            
            if !isAssignable(from: argType, to: paramType) {
                errors.append(SymbolError.typeMismatch(
                    expected: paramType.name,
                    got: argType.name,
                    line: arguments[i].line,
                    column: arguments[i].column
                ))
            }
        }
    }
    
    private func typeCheckGetExpression(_ expr: GetExpr) throws -> TypeDefinition {
        let objectType = try typeCheckExpression(expr.object)
        let propertyName = expr.name.lexeme
        
        // Check if it's a property
        if let property = objectType.findProperty(propertyName) {
            return property.type
        }
        
        // Check if it might be a parameterless method (getter)
        if let method = objectType.findMethod(propertyName) {
            if method.parameters.isEmpty {
                return method.returnType ?? symbolTable.getPrimitiveType("Void")!
            }
        }
        
        errors.append(SymbolError.symbolNotFound(
            propertyName,
            line: expr.name.line,
            column: expr.name.column
        ))
        
        // Return a dummy type for error recovery
        return TypeDefinition(name: "Error", isPrimitive: false, line: expr.line, column: expr.column)
    }
    
    private func typeCheckSetExpression(_ expr: SetExpr) throws -> TypeDefinition {
        let objectType = try typeCheckExpression(expr.object)
        let propertyName = expr.name.lexeme
        
        // Find the property
        guard let property = objectType.findProperty(propertyName) else {
            errors.append(SymbolError.symbolNotFound(
                propertyName,
                line: expr.name.line,
                column: expr.name.column
            ))
            
            // Return a dummy type for error recovery
            return TypeDefinition(name: "Error", isPrimitive: false, line: expr.line, column: expr.column)
        }
        
        // Check if property is mutable
        if !property.isMutable {
            errors.append(SymbolError.invalidOperation(
                "Cannot assign to immutable property '\(propertyName)'",
                line: expr.name.line,
                column: expr.name.column
            ))
        }
        
        // Check value type
        let valueType = try typeCheckExpression(expr.value)
        if !isAssignable(from: valueType, to: property.type) {
            errors.append(SymbolError.typeMismatch(
                expected: property.type.name,
                got: valueType.name,
                line: expr.value.line,
                column: expr.value.column
            ))
        }
        
        return valueType
    }
    
    private func typeCheckThisExpression(_ expr: ThisExpr) throws -> TypeDefinition {
        // Find the enclosing type
        if let enclosingType = symbolTable.currentScope.enclosingType {
            return enclosingType
        } else {
            errors.append(SymbolError.invalidOperation(
                "'this' used outside of a class or struct context",
                line: expr.line,
                column: expr.column
            ))
            
            // Return a dummy type for error recovery
            return TypeDefinition(name: "Error", isPrimitive: false, line: expr.line, column: expr.column)
        }
    }
    
    private func typeCheckSuperExpression(_ expr: SuperExpr) throws -> TypeDefinition {
        // Find the enclosing type
        guard let enclosingType = symbolTable.currentScope.enclosingType else {
            errors.append(SymbolError.invalidOperation(
                "'super' used outside of a class context",
                line: expr.line,
                column: expr.column
            ))
            
            // Return a dummy type for error recovery
            return TypeDefinition(name: "Error", isPrimitive: false, line: expr.line, column: expr.column)
        }
        
        // Make sure there's a superclass
        guard let superType = enclosingType.superType else {
            errors.append(SymbolError.invalidOperation(
                "'super' used in a class with no superclass",
                line: expr.line,
                column: expr.column
            ))
            
            // Return a dummy type for error recovery
            return TypeDefinition(name: "Error", isPrimitive: false, line: expr.line, column: expr.column)
        }
        
        // Check if the method exists in the superclass
        guard let method = superType.findMethod(expr.method.lexeme) else {
            errors.append(SymbolError.symbolNotFound(
                expr.method.lexeme,
                line: expr.method.line,
                column: expr.method.column
            ))
            
            // Return a dummy type for error recovery
            return TypeDefinition(name: "Error", isPrimitive: false, line: expr.line, column: expr.column)
        }
        
        return method.returnType ?? symbolTable.getPrimitiveType("Void")!
    }
    
    private func typeCheckArrayExpression(_ expr: ArrayExpr) throws -> TypeDefinition {
        if expr.elements.isEmpty {
            // Empty array, assume Object[] for now
            // In a real implementation, we would infer from context
            return TypeDefinition(
                name: "Array",
                typeParameters: ["Object"],
                isPrimitive: false,
                line: expr.line,
                column: expr.column
            )
        }
        
        // Check all elements have the same type
        let firstType = try typeCheckExpression(expr.elements[0])
        
        for i in 1..<expr.elements.count {
            let elementType = try typeCheckExpression(expr.elements[i])
            if !isAssignable(from: elementType, to: firstType) && !isAssignable(from: firstType, to: elementType) {
                errors.append(SymbolError.typeMismatch(
                    expected: firstType.name,
                    got: elementType.name,
                    line: expr.elements[i].line,
                    column: expr.elements[i].column
                ))
            }
        }
        
        // Return array type with element type
        return TypeDefinition(
            name: "Array",
            typeParameters: [firstType.name],
            isPrimitive: false,
            line: expr.line,
            column: expr.column
        )
    }
    
    private func typeCheckIndexExpression(_ expr: IndexExpr) throws -> TypeDefinition {
        let arrayType = try typeCheckExpression(expr.array)
        let indexType = try typeCheckExpression(expr.index)
        
        // Check that the array is actually an array type
        if arrayType.name != "Array" {
            errors.append(SymbolError.typeMismatch(
                expected: "Array",
                got: arrayType.name,
                line: expr.array.line,
                column: expr.array.column
            ))
            
            // Return a dummy type for error recovery
            return TypeDefinition(name: "Error", isPrimitive: false, line: expr.line, column: expr.column)
        }
        
        // Check that the index is an integer
        if indexType.name != "Int" {
            errors.append(SymbolError.typeMismatch(
                expected: "Int",
                got: indexType.name,
                line: expr.index.line,
                column: expr.index.column
            ))
        }
        
        // Return the element type of the array
        if !arrayType.typeParameters.isEmpty {
            let elementTypeName = arrayType.typeParameters[0]
            if let elementType = symbolTable.resolveType(elementTypeName) {
                return elementType
            }
        }
        
        // Default element type if we couldn't determine it
        return TypeDefinition(name: "Object", isPrimitive: false, line: expr.line, column: expr.column)
    }
    
    // MARK: - Type Resolution
    
    private func resolveTypeNode(_ typeNode: TypeNode) throws -> TypeDefinition {
        switch typeNode {
        case let namedType as NamedType:
            guard let type = symbolTable.resolveType(namedType.name.lexeme) else {
                throw SymbolError.symbolNotFound(
                    namedType.name.lexeme,
                    line: namedType.line,
                    column: namedType.column
                )
            }
            return type
            
        case let arrayType as ArrayType:
            let elementType = try resolveTypeNode(arrayType.elementType)
            return TypeDefinition(
                name: "Array",
                typeParameters: [elementType.name],
                isPrimitive: false,
                line: arrayType.line,
                column: arrayType.column
            )
            
        case let genericType as GenericType:
            let baseType = try resolveTypeNode(genericType.baseType)
            
            // Check number of type arguments matches type parameters
            let typeArguments = try genericType.typeArguments.map { try resolveTypeNode($0) }
            
            return TypeDefinition(
                name: baseType.name,
                typeParameters: typeArguments.map { $0.name },
                isInterface: baseType.isInterface,
                isAbstract: baseType.isAbstract,
                isSealed: baseType.isSealed,
                isPrimitive: baseType.isPrimitive,
                line: genericType.line,
                column: genericType.column
            )
            
        default:
            throw CompilerError.compileError("Unknown type node: \(type(of: typeNode))")
        }
    }
    
    // MARK: - Helper Methods
    
    private func isNumeric(_ type: TypeDefinition) -> Bool {
        return type.name == "Int" || type.name == "Float" || type.name == "Double"
    }
    
    private func isAssignable(from sourceType: TypeDefinition, to targetType: TypeDefinition) -> Bool {
        // Same type
        if sourceType == targetType {
            return true
        }
        
        // Inheritance-based assignment compatibility
        if sourceType.isSubtypeOf(targetType) {
            return true
        }
        
        // Numeric widening conversions
        if isNumeric(sourceType) && isNumeric(targetType) {
            if targetType.name == "Double" {
                return true // Any numeric can be assigned to Double
            }
            if targetType.name == "Float" && (sourceType.name == "Int") {
                return true // Int can be assigned to Float
            }
        }
        
        return false
    }
}

/// Compiler errors that aren't specifically related to symbols
public enum CompilerError: Error, CustomStringConvertible {
    case compileError(String)
    
    public var description: String {
        switch self {
        case .compileError(let message):
            return "Compiler error: \(message)"
        }
    }
}