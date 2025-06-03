import Foundation
import OuroLangCore
import MLIRQuasiDSL

// MARK: - Errors

/// Errors that can occur during MLIR printing
public enum MLIRPrinterError: Error, CustomStringConvertible {
    case invalidOperator(String)
    case unsupportedType(String)
    case unsupportedExpression(String)
    case missingExpression(String)
    case invalidLiteral(String)
    case typeConversionFailure(String)
    case undefinedVariable(String)
    
    public var description: String {
        switch self {
        case .invalidOperator(let op):
            return "Invalid MLIR operator: \(op)"
        case .unsupportedType(let type):
            return "Unsupported MLIR type: \(type)"
        case .unsupportedExpression(let expr):
            return "Unsupported expression in MLIR context: \(expr)"
        case .missingExpression(let context):
            return "Missing required expression in context: \(context)"
        case .invalidLiteral(let value):
            return "Cannot convert literal value to MLIR: \(value)"
        case .typeConversionFailure(let type):
            return "Failed to convert type to MLIR representation: \(type)"
        case .undefinedVariable(let name):
            return "Reference to undefined variable: \(name)"
        }
    }
}

// MARK: - Enhanced Error Handling

/// Extended errors for MLIR printing
public enum ExtendedMLIRPrinterError: Error, CustomStringConvertible {
    case invalidAffineMap(String)
    case tensorOperationFailure(String)
    case unsupportedControlFlow(String)
    case invalidDialect(String)

    public var description: String {
        switch self {
        case .invalidAffineMap(let map):
            return "Invalid affine map in MLIR: \(map)"
        case .tensorOperationFailure(let operation):
            return "Tensor operation failed in MLIR: \(operation)"
        case .unsupportedControlFlow(let flow):
            return "Unsupported control flow construct in MLIR: \(flow)"
        case .invalidDialect(let dialect):
            return "Invalid MLIR dialect: \(dialect)"
        }
    }
}

// MARK: - Type Mappings

/// Utility structures for mapping OuroLang types to MLIR types
private struct MLIRTypeMapping {
    static let defaultIntType = "i32"
    static let defaultFloatType = "f32"
    static let defaultBoolType = "i1"
    static let defaultStringType = "!llvm.ptr<i8>"
    static let voidType = "void"
    
    /// Maps OuroLang type names to MLIR type names
    static let typeMap: [String: String] = [
        "int": defaultIntType,
        "float": defaultFloatType,
        "double": "f64",
        "bool": defaultBoolType,
        "boolean": defaultBoolType,
        "string": defaultStringType,
        "void": voidType,
        "char": "i8",
        "byte": "i8",
        "short": "i16",
        "long": "i64"
    ]
    
    /// Converts an OuroLang type name to its MLIR equivalent
    /// - Parameter typeName: The OuroLang type name
    /// - Returns: The corresponding MLIR type name
    /// - Throws: If the type cannot be converted
    static func mapType(_ typeName: String?) -> String {
        guard let typeName = typeName, !typeName.isEmpty else {
            return defaultIntType
        }
        
        if let mlirType = typeMap[typeName.lowercased()] {
            return mlirType
        }
        
        // Handle array types
        if typeName.hasSuffix("[]") {
            let baseType = String(typeName.dropLast(2))
            if let mappedBaseType = typeMap[baseType.lowercased()] {
                return "!llvm.ptr<\(mappedBaseType)>"
            }
        }
        
        // Default to the original type if no mapping exists
        return typeName
    }
}

// MARK: - Extended Type Mappings

/// Extended utility structures for mapping advanced OuroLang types to MLIR types
private struct ExtendedMLIRTypeMapping {
    static let tensorType = "tensor"
    static let affineMapType = "affine_map"
    static let dialectType = "dialect"

    /// Maps advanced OuroLang type names to MLIR type names
    static let extendedTypeMap: [String: String] = [
        "tensor": tensorType,
        "affine_map": affineMapType,
        "dialect": dialectType
    ]
}

// MARK: - MLIRPrinter Optimization

/// Optimized MLIRPrinter implementation
public class MLIRPrinter: ASTVisitor {
    private var typeMappings: [String: String] = MLIRTypeMapping.typeMap.merging(ExtendedMLIRTypeMapping.extendedTypeMap) { _, new in new }

    public func visit(_ node: ASTNode) throws -> String {
        // Optimized visit logic for AST nodes
        switch node {
        case let expr as Expr:
            return try visitExpression(expr)
        case let stmt as Stmt:
            return try visitStatement(stmt)
        default:
            throw MLIRPrinterError.unsupportedExpression("Unsupported AST node type: \(type(of: node))")
        }
    }

    private func visitExpression(_ expr: Expr) throws -> String {
        // Handle expressions with extended type mappings
        guard let type = typeMappings[expr.typeName] else {
            throw MLIRPrinterError.typeConversionFailure("Unknown type: \(expr.typeName)")
        }
        return "mlir.expr \(type)"
    }

    private func visitStatement(_ stmt: Stmt) throws -> String {
        // Handle statements with optimized logic
        return "mlir.stmt \(stmt.description)"
    }
}

// MARK: - MLIRPrinter Implementation

/**
 MLIRPrinter converts AST nodes into MLIR text representation
 
 This class traverses the AST and generates equivalent MLIR operations for each node.
 It implements the ASTVisitor protocol to handle all node types in the OuroLang syntax tree.
 
 Example usage:
 ```swift
 let printer = MLIRPrinter()
 let mlirCode = try printer.visit(astNode)
 ```
 */
public class MLIRPrinter: ASTVisitor {
    public typealias Result = String
    
    /// Maps variables to their types for type tracking
    private var variableTypes: [String: String] = [:]
    
    /// Creates a new MLIRPrinter instance
    public init() {}
    
    /**
     Registers a variable with its type in the type tracking system
     
     - Parameters:
        - name: The variable name
        - type: The MLIR type
     */
    private func registerVariable(_ name: String, type: String) {
        variableTypes[name] = type
    }
    
    /**
     Resolves the MLIR type of an expression
     
     - Parameter expr: The expression to analyze
     - Returns: The determined MLIR type
     */
    private func resolveExpressionType(_ expr: Expr?) -> String {
        guard let expr = expr else {
            return MLIRTypeMapping.defaultIntType
        }
        
        if let literalExpr = expr as? LiteralExpr {
            return resolveTypeForLiteral(literalExpr)
        } else if let varExpr = expr as? VariableExpr {
            return variableTypes[varExpr.name.text] ?? MLIRTypeMapping.defaultIntType
        } else if let binaryExpr = expr as? BinaryExpr {
            // For arithmetic operations, use the type of the left operand
            // A more sophisticated implementation would handle type promotion
            return resolveExpressionType(binaryExpr.left)
        }
        
        // Default type for expressions we can't analyze
        return MLIRTypeMapping.defaultIntType
    }
    
    /**
     Determines the MLIR type for a literal expression
     
     - Parameter expr: The literal expression
     - Returns: The corresponding MLIR type
     */
    private func resolveTypeForLiteral(_ expr: LiteralExpr) -> String {
        switch expr.tokenType {
        case .number:
            if let valueStr = expr.value as? String, valueStr.contains(".") {
                return MLIRTypeMapping.defaultFloatType
            }
            return MLIRTypeMapping.defaultIntType
        case .string:
            return MLIRTypeMapping.defaultStringType
        case .true, .false:
            return MLIRTypeMapping.defaultBoolType
        case .nil:
            return MLIRTypeMapping.defaultIntType
        default:
            return MLIRTypeMapping.defaultIntType
        }
    }
    
    /**
     Maps an OuroLang operator to its MLIR arithmetic operation
     
     - Parameter op: The operator token
     - Returns: The corresponding MLIR operation name
     - Throws: If the operator is not supported
     */
    private func mapArithmeticOperator(_ op: Token) throws -> String {
        switch op.type {
        case .plus:
            return "arith.addi"
        case .minus:
            return "arith.subi"
        case .star:
            return "arith.muli"
        case .slash:
            return "arith.divsi"
        case .percent:
            return "arith.remsi"
        default:
            throw MLIRPrinterError.invalidOperator(op.text)
        }
    }
    
    /**
     Maps an OuroLang comparison operator to its MLIR equivalent
     
     - Parameter op: The operator token
     - Returns: The corresponding MLIR comparison operation
     - Throws: If the operator is not supported
     */
    private func mapComparisonOperator(_ op: Token) throws -> String {
        switch op.type {
        case .equalEqual:
            return "arith.cmpi eq"
        case .bangEqual:
            return "arith.cmpi ne"
        case .less:
            return "arith.cmpi slt"
        case .lessEqual:
            return "arith.cmpi sle"
        case .greater:
            return "arith.cmpi sgt"
        case .greaterEqual:
            return "arith.cmpi sge"
        default:
            throw MLIRPrinterError.invalidOperator(op.text)
        }
    }
    
    // MARK: - Declaration Nodes
    
    /**
     Converts a function declaration to MLIR representation
     
     - Parameter decl: The function declaration to convert
     - Returns: MLIR text for the function
     - Throws: If any child expressions can't be converted
     */
    public func visitFunctionDecl(_ decl: FunctionDecl) throws -> String {
        let name = decl.name.text
        let returnType = MLIRTypeMapping.mapType(decl.returnType?.name.text)
        
        // Generate arguments if present
        let args = decl.params.map { param -> (String, String) in
            let paramName = param.name.text
            let typeName = MLIRTypeMapping.mapType(param.type?.name.text)
            return (paramName, typeName)
        }
        
        // Register parameter variables with their types
        for (name, type) in args {
            registerVariable(name, type: type)
        }
        
        // Build function body: statements plus a return if needed
        let stmtLines = try decl.body.statements
            .map { try $0.accept(visitor: self) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
        
        // If function is non-void and there's no explicit return, add a default return
        let needsDefaultReturn = returnType != MLIRTypeMapping.voidType && 
                                (decl.body.statements.isEmpty || 
                                 !(decl.body.statements.last is ReturnStmt))
        
        let content: String
        if stmtLines.isEmpty {
            content = needsDefaultReturn ? "  \(MLIR.ret())" : ""
        } else {
            content = stmtLines + (needsDefaultReturn ? "\n  \(MLIR.ret())" : "")
        }
        
        return MLIR.funcOp(name: name, returnType: returnType, args: args) {
            content
        }
    }
    
    /**
     Converts a variable declaration to MLIR representation
     
     - Parameter decl: The variable declaration to convert
     - Returns: MLIR text for the variable definition
     - Throws: If initializer expressions can't be converted
     */
    public func visitVarDecl(_ decl: VarDecl) throws -> String {
        let name = decl.name.text
        let typeName = MLIRTypeMapping.mapType(decl.type?.name.text)
        
        // Register the variable with its type
        registerVariable(name, type: typeName)
        
        if let initExpr = decl.initializer {
            // Handle different types of initializers
            if let literalExpr = initExpr as? LiteralExpr {
                return try handleLiteralInitialization(name: name, expr: literalExpr, type: typeName)
            } else if initExpr is BinaryExpr || initExpr is CallExpr {
                // For binary expressions and function calls, evaluate them separately and assign
                let value = try initExpr.accept(visitor: self)
                return value
            } else {
                // Default handling for other expressions
                let value = try initExpr.accept(visitor: self)
                return "%\(name) = \"std.assign\"() { value = \(value) } : () -> \(typeName)"
            }
        }
        
        // Uninitialized variables get a placeholder with default value
        return "%\(name) = \"std.undefined\"() : () -> \(typeName)"
    }
    
    /**
     Handles initialization with literal values based on their type
     
     - Parameters:
        - name: The variable name
        - expr: The literal expression
        - type: The MLIR type name
     - Returns: MLIR code for the initialization
     - Throws: If the literal cannot be handled
     */
    private func handleLiteralInitialization(name: String, expr: LiteralExpr, type: String) throws -> String {
        guard let value = expr.value else {
            return "%\(name) = \"std.constant\"() { value = 0 : \(type) } : () -> \(type)"
        }
        
        switch expr.tokenType {
        case .number:
            // Determine if it's an integer or float
            if type == MLIRTypeMapping.defaultFloatType || type == "f64" {
                if let floatValue = value as? Float {
                    return MLIR.floatConstantOp(name: name, value: floatValue, type: type)
                } else if let doubleValue = value as? Double {
                    return MLIR.floatConstantOp(name: name, value: Float(doubleValue), type: type)
                } else if let stringValue = value as? String, let floatValue = Float(stringValue) {
                    return MLIR.floatConstantOp(name: name, value: floatValue, type: type)
                }
            } 
            
            // Default to integer
            if let intValue = value as? Int {
                return MLIR.constantOp(name: name, value: intValue, type: type)
            } else if let stringValue = value as? String, let intValue = Int(stringValue) {
                return MLIR.constantOp(name: name, value: intValue, type: type)
            }
            
        case .string:
            if let stringValue = value as? String {
                return MLIR.stringConstantOp(name: name, value: stringValue) 
            }
            
        case .true:
            return MLIR.boolConstantOp(name: name, value: true)
            
        case .false:
            return MLIR.boolConstantOp(name: name, value: false)
            
        default:
            break
        }
        
        // Fallback for unsupported literals
        throw MLIRPrinterError.invalidLiteral("\(value)")
    }
    
    // MARK: - Statement Nodes
    
    /**
     Converts a return statement to MLIR representation
     
     - Parameter stmt: The return statement to convert
     - Returns: MLIR text for the return operation
     - Throws: If the return value expression can't be converted
     */
    public func visitReturnStmt(_ stmt: ReturnStmt) throws -> String {
        if let value = stmt.value {
            let v = try value.accept(visitor: self)
            let typeName = resolveExpressionType(stmt.value)
            return MLIR.ret(v, type: typeName)
        }
        return MLIR.ret()
    }
    
    /**
     Converts an expression statement to MLIR representation
     
     - Parameter stmt: The expression statement to convert
     - Returns: MLIR text for the statement
     - Throws: If the expression can't be converted
     */
    public func visitExpressionStmt(_ stmt: ExpressionStmt) throws -> String {
        // Some expressions like assignments already generate complete MLIR operations
        return try stmt.expression.accept(visitor: self)
    }
    
    /**
     Converts an if statement to MLIR control flow
     
     - Parameter stmt: The if statement to convert
     - Returns: MLIR text for the conditional branching structure
     - Throws: If any expressions in condition or branches can't be converted
     */
    public func visitIfStmt(_ stmt: IfStmt) throws -> String {
        let condExpr = try stmt.condition.accept(visitor: self)
        let thenBody = try stmt.thenBranch.accept(visitor: self)
        
        // Use the ifThenElse utility if available
        if let elseBranch = stmt.elseBranch {
            let elseBody = try elseBranch.accept(visitor: self)
            
            return MLIR.ifThenElse(condition: condExpr) {
                thenBody
            } elseBody: {
                elseBody
            }
        } else {
            return MLIR.ifThenElse(condition: condExpr) {
                thenBody
            }
        }
    }
    
    /**
     Converts a block statement to MLIR operations
     
     - Parameter stmt: The block statement to convert
     - Returns: MLIR text for the block's operations
     - Throws: If any statement in the block can't be converted
     */
    public func visitBlockStmt(_ stmt: BlockStmt) throws -> String {
        let stmtResults = try stmt.statements.compactMap { statement -> String? in
            let result = try statement.accept(visitor: self)
            return result.isEmpty ? nil : result
        }
        
        return stmtResults.joined(separator: "\n")
    }
    
    /**
     Converts a while loop to MLIR control flow
     
     - Parameter stmt: The while statement to convert
     - Returns: MLIR text for the loop structure
     - Throws: If condition or body expressions can't be converted
     */
    public func visitWhileStmt(_ stmt: WhileStmt) throws -> String {
        let condExprGen = { () -> String in
            guard let condExpr = try? stmt.condition.accept(visitor: self) else {
                return MLIR.boolConstantOp(name: "cond", value: true)
            }
            return condExpr
        }
        
        let bodyCode = try stmt.body.accept(visitor: self)
        
        return MLIR.whileLoop(condition: condExprGen, body: {
            bodyCode
        })
    }
    
    /**
     Converts a for loop to MLIR control flow
     
     - Parameter stmt: The for statement to convert
     - Returns: MLIR text for the loop structure
     - Throws: If initializer, condition, increment or body can't be converted
     */
    public func visitForStmt(_ stmt: ForStmt) throws -> String {
        // Handle each component of the for loop, gracefully handling nil values
        let initCode = try stmt.initializer?.accept(visitor: self) ?? ""
        
        // Create a condition generator closure
        let condExprGen = { () -> String in
            guard let condExpr = try? stmt.condition?.accept(visitor: self) else {
                return MLIR.boolConstantOp(name: "cond", value: true)
            }
            return condExpr
        }
        
        // Get body code
        var bodyCode = try stmt.body.accept(visitor: self)
        
        // Add the increment at the end of the body if present
        if let increment = stmt.increment {
            let incCode = try increment.accept(visitor: self)
            if !incCode.isEmpty {
                bodyCode = bodyCode + "\n" + incCode
            }
        }
        
        // Generate the full for loop structure
        let forLoop = MLIR.whileLoop(condition: condExprGen, body: {
            bodyCode
        })
        
        // Prepend initializer if present
        if !initCode.isEmpty {
            return initCode + "\n" + forLoop
        }
        
        return forLoop
    }
    
    /**
     Converts a break statement to MLIR branch operation
     
     - Parameter stmt: The break statement to convert
     - Returns: MLIR text for the branch operation
     */
    public func visitBreakStmt(_ stmt: BreakStmt) throws -> String {
        // For break statements in MLIR, we branch to the end of the loop
        return MLIR.br("end")
    }
    
    /**
     Converts a continue statement to MLIR branch operation
     
     - Parameter stmt: The continue statement to convert
     - Returns: MLIR text for the branch operation
     */
    public func visitContinueStmt(_ stmt: ContinueStmt) throws -> String {
        // For continue statements in MLIR, we branch to the condition
        return MLIR.br("condition")
    }
    
    // MARK: - Expression Nodes
    
    /**
     Converts a binary expression to MLIR operations
     
     - Parameter expr: The binary expression to convert
     - Returns: MLIR text for the binary operation
     - Throws: If operands can't be converted or operator is unsupported
     */
    public func visitBinaryExpr(_ expr: BinaryExpr) throws -> String {
        let leftExpr = try expr.left.accept(visitor: self)
        let rightExpr = try expr.right.accept(visitor: self)
        let leftType = resolveExpressionType(expr.left)
        let resultType = leftType // Typically binary ops preserve type
        
        // Generate a unique name for the result
        let resultName = "binop_\(UUID().uuidString.prefix(8))"
        
        // Handle different operator types
        switch expr.op.type {
        case .plus:
            return MLIR.addOp(name: resultName, lhs: leftExpr, rhs: rightExpr, type: resultType)
        case .minus:
            return MLIR.subOp(name: resultName, lhs: leftExpr, rhs: rightExpr, type: resultType)
        case .star:
            return MLIR.mulOp(name: resultName, lhs: leftExpr, rhs: rightExpr, type: resultType)
        case .slash:
            return MLIR.divOp(name: resultName, lhs: leftExpr, rhs: rightExpr, type: resultType)
        case .equalEqual, .bangEqual, .less, .lessEqual, .greater, .greaterEqual:
            // Comparison operators produce boolean results
            let opName = try mapComparisonOperator(expr.op)
            return "%\(resultName) = \(opName) \(leftExpr), \(rightExpr) : \(leftType)"
        case .and:
            // Logical AND
            return """
            %and_cond = arith.andi \(leftExpr), \(rightExpr) : i1
            """
        case .or:
            // Logical OR
            return """
            %or_cond = arith.ori \(leftExpr), \(rightExpr) : i1
            """
        default:
            throw MLIRPrinterError.invalidOperator(expr.op.text)
        }
    }
    
    /**
     Converts a literal expression to MLIR constant operation
     
     - Parameter expr: The literal expression to convert
     - Returns: MLIR text for the constant operation
     - Throws: If the literal can't be represented in MLIR
     */
    public func visitLiteralExpr(_ expr: LiteralExpr) throws -> String {
        // Generate a unique name for the literal
        let name = "lit_\(UUID().uuidString.prefix(8))"
        let type = resolveTypeForLiteral(expr)
        
        // Use the handleLiteralInitialization helper for consistency
        return try handleLiteralInitialization(name: name, expr: expr, type: type)
    }
    
    /**
     Converts a grouping expression to its MLIR equivalent
     
     - Parameter expr: The grouping expression to convert
     - Returns: MLIR text for the contained expression
     - Throws: If the inner expression can't be converted
     */
    public func visitGroupingExpr(_ expr: GroupingExpr) throws -> String {
        // Grouping doesn't need special handling in MLIR, just return inner expression
        return try expr.expression.accept(visitor: self)
    }
    
    /**
     Converts a unary expression to MLIR operations
     
     - Parameter expr: The unary expression to convert
     - Returns: MLIR text for the unary operation
     - Throws: If operand can't be converted or operator is unsupported
     */
    public func visitUnaryExpr(_ expr: UnaryExpr) throws -> String {
        let rightExpr = try expr.right.accept(visitor: self)
        let rightType = resolveExpressionType(expr.right)
        
        // Generate a unique name for the result
        let resultName = "unaryop_\(UUID().uuidString.prefix(8))"
        
        switch expr.op.type {
        case .minus:
            // Negate the value
            return "%\(resultName) = arith.negf \(rightExpr) : \(rightType)"
        case .bang:
            // Logical NOT
            return "%\(resultName) = arith.xori \(rightExpr), %true : i1"
        default:
            throw MLIRPrinterError.invalidOperator(expr.op.text)
        }
    }
    
    /**
     Converts a variable expression to MLIR reference
     
     - Parameter expr: The variable expression to convert
     - Returns: MLIR text for the variable reference
     - Throws: If the variable isn't defined
     */
    public func visitVariableExpr(_ expr: VariableExpr) throws -> String {
        let name = expr.name.text
        if !variableTypes.keys.contains(name) {
            throw MLIRPrinterError.undefinedVariable(name)
        }
        return "%\(name)"
    }
    
    /**
     Converts a call expression to MLIR function call
     
     - Parameter expr: The call expression to convert
     - Returns: MLIR text for the function call
     - Throws: If the callee or arguments can't be converted
     */
    public func visitCallExpr(_ expr: CallExpr) throws -> String {
        // Handle the callee
        let callee: String
        if let varExpr = expr.callee as? VariableExpr {
            callee = "@" + varExpr.name.text
        } else {
            callee = try expr.callee.accept(visitor: self)
        }
        
        // Process arguments
        let args = try expr.arguments.map { arg in
            try arg.accept(visitor: self)
        }
        
        // Create a result variable name
        let resultName = "call_\(UUID().uuidString.prefix(8))"
        
        // Build the argument types string
        let argTypes = args.map { arg in
            // This is simplified; in a real implementation you'd track types better
            MLIRTypeMapping.defaultIntType
        }.joined(separator: ", ")
        
        // Build the call
        let argsString = args.joined(separator: ", ")
        return "%\(resultName) = call \(callee)(\(argsString)) : (\(argTypes)) -> \(MLIRTypeMapping.defaultIntType)"
    }
    
    /**
     Converts an assignment expression to MLIR operations
     
     - Parameter expr: The assignment expression to convert
     - Returns: MLIR text for the assignment operation
     - Throws: If variable or value can't be converted
     */
    public func visitAssignExpr(_ expr: AssignExpr) throws -> String {
        let name = expr.name.text
        let value = try expr.value.accept(visitor: self)
        
        // Ensure variable exists
        guard let type = variableTypes[name] else {
            throw MLIRPrinterError.undefinedVariable(name)
        }
        
        // Create an assignment operation
        return """
        %\(name) = "std.assign"() { value = \(value) } : () -> \(type)
        """
    }
    
    /**
     Converts a property access (get) to MLIR operations
     
     - Parameter expr: The get expression to convert
     - Returns: MLIR text for the property access
     - Throws: If object can't be converted
     */
    public func visitGetExpr(_ expr: GetExpr) throws -> String {
        let object = try expr.object.accept(visitor: self)
        let property = expr.name.text
        
        // Create a unique name for the result
        let resultName = "prop_\(UUID().uuidString.prefix(8))"
        
        // Create a property access operation (simplified)
        return """
        %\(resultName) = "std.getfield"(\(object)) { field_name = "\(property)" } : (!llvm.ptr) -> \(MLIRTypeMapping.defaultIntType)
        """
    }
    
    /**
     Converts a property assignment (set) to MLIR operations
     
     - Parameter expr: The set expression to convert
     - Returns: MLIR text for the property assignment
     - Throws: If object or value can't be converted
     */
    public func visitSetExpr(_ expr: SetExpr) throws -> String {
        let object = try expr.object.accept(visitor: self)
        let property = expr.name.text
        let value = try expr.value.accept(visitor: self)
        
        // Create a field set operation (simplified)
        return """
        "std.setfield"(\(object), \(value)) { field_name = "\(property)" } : (!llvm.ptr, \(MLIRTypeMapping.defaultIntType)) -> ()
        """
    }
    
    /**
     Converts a this expression to MLIR reference
     
     - Parameter expr: The this expression to convert
     - Returns: MLIR text for the this reference
     */
    public func visitThisExpr(_ expr: ThisExpr) throws -> String {
        return "%this"
    }
    
    /**
     Converts a super expression to MLIR function call
     
     - Parameter expr: The super expression to convert
     - Returns: MLIR text for the super method call
     */
    public func visitSuperExpr(_ expr: SuperExpr) throws -> String {
        // Create a unique name for the result
        let resultName = "super_\(UUID().uuidString.prefix(8))"
        
        // Create a super method call (simplified)
        return """
        %\(resultName) = call @super_\(expr.method.text)(%this) : (!llvm.ptr) -> \(MLIRTypeMapping.defaultIntType)
        """
    }
    
    /**
     Converts an array literal to MLIR operations
     
     - Parameter expr: The array expression to convert
     - Returns: MLIR text for the array creation
     - Throws: If elements can't be converted
     */
    public func visitArrayExpr(_ expr: ArrayExpr) throws -> String {
        // Process array elements
        let elements = try expr.elements.map { element in
            try element.accept(visitor: self)
        }
        
        // Determine element type (simplified)
        let elementType = MLIRTypeMapping.defaultIntType
        
        // Create array allocation
        let arrayName = "array_\(UUID().uuidString.prefix(8))"
        let size = elements.count
        
        var code = """
        %size_\(arrayName) = "std.constant"() { value = \(size) : i32 } : () -> i32
        %\(arrayName) = "std.alloc"(%size_\(arrayName)) : (i32) -> !llvm.ptr<\(elementType)>
        """
        
        // Initialize array elements
        for (i, element) in elements.enumerated() {
            code += """
            
            %idx_\(i)_\(arrayName) = "std.constant"() { value = \(i) : i32 } : () -> i32
            "std.store"(\(element), %\(arrayName), %idx_\(i)_\(arrayName)) : (\(elementType), !llvm.ptr<\(elementType)>, i32) -> ()
            """
        }
        
        return code
    }
    
    /**
     Converts a logical expression to MLIR operations
     
     - Parameter expr: The logical expression to convert
     - Returns: MLIR text for the logical operation
     - Throws: If operands can't be converted
     */
    public func visitLogicalExpr(_ expr: LogicalExpr) throws -> String {
        let leftExpr = try expr.left.accept(visitor: self)
        let rightExpr = try expr.right.accept(visitor: self)
        
        // Generate a unique name for the result
        let resultName = "logical_\(UUID().uuidString.prefix(8))"
        
        switch expr.op.type {
        case .and:
            return "%\(resultName) = arith.andi \(leftExpr), \(rightExpr) : i1"
        case .or:
            return "%\(resultName) = arith.ori \(leftExpr), \(rightExpr) : i1"
        default:
            throw MLIRPrinterError.invalidOperator(expr.op.text)
        }
    }
    
    /**
     Converts a print statement to MLIR operations
     
     - Parameter stmt: The print statement to convert
     - Returns: MLIR text for the print operation
     - Throws: If expression can't be converted
     */
    public func visitPrintStmt(_ stmt: PrintStmt) throws -> String {
        // Convert the expression to print
        let valueExpr = try stmt.expression.accept(visitor: self)
        let valueType = resolveExpressionType(stmt.expression)
        
        // Create a print operation using external function call
        return """
        "std.call"(\(valueExpr)) { callee = @print_\(valueType) } : (\(valueType)) -> ()
        """
    }
    
    /**
     Converts an import declaration to MLIR module import
     
     - Parameter decl: The import declaration to convert
     - Returns: MLIR text for the import directive
     */
    public func visitImportDecl(_ decl: ImportDecl) throws -> String {
        // In MLIR, imports are typically handled at the module level
        // This is a simplified implementation
        return "\"std.import\"() { path = \"\(decl.path.text)\" } : () -> ()"
    }
    
    /**
     Converts a class declaration to MLIR struct type and operations
     
     - Parameter decl: The class declaration to convert
     - Returns: MLIR text for the class definition
     - Throws: If methods can't be converted
     */
    public func visitClassDecl(_ decl: ClassDecl) throws -> String {
        let className = decl.name.text
        
        // Define struct type for the class
        let fields = decl.properties.map { prop -> String in
            let typeName = MLIRTypeMapping.mapType(prop.type?.name.text)
            return "\"\(prop.name.text)\": \(typeName)"
        }.joined(separator: ", ")
        
        var code = """
        !class.\(className) = type { \(fields) }
        """
        
        // Process methods
        for method in decl.methods {
            // Modify the method name to include class namespace
            let methodName = "\(className)_\(method.name.text)"
            
            // Add "this" as first parameter
            var methodParams = [(String, String)]()
            methodParams.append(("this", "!class.\(className)"))
            
            // Add original parameters
            method.params.forEach { param in
                let paramType = MLIRTypeMapping.mapType(param.type?.name.text)
                methodParams.append((param.name.text, paramType))
            }
            
            // Convert method body
            let returnType = MLIRTypeMapping.mapType(method.returnType?.name.text)
            
            // Generate method
            code += "\n\n" + MLIR.funcOp(
                name: methodName,
                returnType: returnType,
                args: methodParams
            ) {
                try visitBlockStmt(method.body)
            }
        }
        
        return code
    }
    
    // MARK: - Utility Methods
    
    /**
     Wraps the AST traversal process with error handling
     
     - Parameter node: The AST node to process
     - Returns: MLIR text for the node
     - Throws: Rethrows any errors from visitor methods
     */
    public func generateMLIR<T: ASTNode>(_ node: T) throws -> String {
        // Clear variable tracking for a fresh context
        variableTypes.removeAll()
        
        return try node.accept(visitor: self)
    }
    
    /**
     Processes multiple AST nodes and joins their MLIR representations
     
     - Parameter nodes: The AST nodes to process
     - Returns: Combined MLIR text
     - Throws: If any node can't be processed
     */
    public func generateMLIR<T: ASTNode>(fromNodes nodes: [T]) throws -> String {
        // Clear variable tracking for a fresh context
        variableTypes.removeAll()
        
        return try nodes.map { 
            try $0.accept(visitor: self) 
        }.filter { 
            !$0.isEmpty 
        }.joined(separator: "\n\n")
    }
    
    /**
     Wraps MLIR code in a module
     
     - Parameter code: The MLIR code to wrap
     - Returns: Complete MLIR module
     */
    public func wrapInModule(_ code: String) -> String {
        return MLIR.module {
            code
        }
    }
}

// MARK: - Advanced MLIR Features

/// Adds support for advanced MLIR constructs like affine maps and tensor operations
extension MLIRPrinter {
    /// Generates MLIR code for affine maps
    /// - Parameter map: The affine map to convert
    /// - Returns: MLIR representation of the affine map
    /// - Throws: `MLIRPrinterError` if the map is invalid
    public func generateAffineMap(_ map: AffineMap) throws -> String {
        guard map.isValid else {
            throw ExtendedMLIRPrinterError.invalidAffineMap("Invalid affine map: \(map.description)")
        }
        return "affine_map<\(map.description)>"
    }

    /// Generates MLIR code for tensor operations
    /// - Parameter operation: The tensor operation to convert
    /// - Returns: MLIR representation of the tensor operation
    /// - Throws: `MLIRPrinterError` if the operation is unsupported
    public func generateTensorOperation(_ operation: TensorOperation) throws -> String {
        guard operation.isSupported else {
            throw ExtendedMLIRPrinterError.tensorOperationFailure("Unsupported tensor operation: \(operation.name)")
        }
        return "tensor_op<\(operation.name)>"
    }
}

// MARK: - Improved Type Mapping

/// Extends type mapping to include advanced types and better error handling
extension MLIRTypeMapping {
    /// Resolves an OuroLang type to an MLIR type
    /// - Parameter ouroType: The OuroLang type to resolve
    /// - Returns: The corresponding MLIR type
    /// - Throws: `MLIRPrinterError` if the type cannot be resolved
    public static func resolveType(_ ouroType: String) throws -> String {
        guard let mlirType = typeMap[ouroType] ?? extendedTypeMap[ouroType] else {
            throw MLIRPrinterError.unsupportedType("Type \(ouroType) is not supported in MLIR")
        }
        return mlirType
    }
}