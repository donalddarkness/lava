import Foundation
import OuroLangCore

// MARK: - Errors

/// Errors that can occur during AST printing
public enum ASTPrinterError: Error, CustomStringConvertible {
    case invalidSyntax(String)
    case missingRequiredField(String)
    case unsupportedConstruct(String)
    case indentationError(String)
    
    public var description: String {
        switch self {
        case .invalidSyntax(let details):
            return "Invalid syntax in AST node: \(details)"
        case .missingRequiredField(let field):
            return "Missing required field in AST node: \(field)"
        case .unsupportedConstruct(let construct):
            return "Unsupported language construct: \(construct)"
        case .indentationError(let details):
            return "Indentation error: \(details)"
        }
    }
}

// MARK: - AST Printing Configuration

/// Configuration options for the ASTPrinter
public struct ASTPrinterOptions {
    /// The string used for each level of indentation
    public let indentString: String
    
    /// Whether to add newlines after blocks and statements
    public let useExtraNewlines: Bool
    
    /// Whether to add spaces around operators
    public let spaceAroundOperators: Bool
    
    /// Default formatting options
    public static let standard = ASTPrinterOptions(
        indentString: "  ",
        useExtraNewlines: true,
        spaceAroundOperators: true
    )
    
    /// Compact formatting options
    public static let compact = ASTPrinterOptions(
        indentString: "  ",
        useExtraNewlines: false,
        spaceAroundOperators: false
    )
    
    /// Creates a new configuration with custom options
    public init(indentString: String, useExtraNewlines: Bool, spaceAroundOperators: Bool) {
        self.indentString = indentString
        self.useExtraNewlines = useExtraNewlines
        self.spaceAroundOperators = spaceAroundOperators
    }
}

// MARK: - ASTPrinter Implementation

/**
 ASTPrinter implements ASTVisitor to convert AST nodes into code strings
 
 This class provides pretty-printing capabilities for the OuroLang syntax tree.
 It traverses the AST and produces formatted source code, useful for debugging,
 code generation, and source-to-source transpilation.
 
 Example usage:
 ```swift
 let printer = ASTPrinter()
 let sourceCode = try printer.visit(astNode)
 ```
 */
public class ASTPrinter: ASTVisitor {
    public typealias Result = String
    
    /// Current indentation level for pretty-printing
    private var indentLevel = 0
    
    /// Current indentation prefix based on level
    private var currentIndent: String {
        String(repeating: options.indentString, count: indentLevel)
    }
    
    /// Configuration options for the printer
    private let options: ASTPrinterOptions
    
    /// Creates a new ASTPrinter with the specified options
    /// - Parameter options: Configuration options, defaults to standard options
    public init(options: ASTPrinterOptions = .standard) {
        self.options = options
    }
    
    /**
     Executes a block with increased indentation level
     
     - Parameter block: The code block to execute with increased indentation
     - Returns: The result of the block execution
     - Throws: Rethrows any errors from the block
     */
    private func withIndent<T>(_ block: () throws -> T) rethrows -> T {
        indentLevel += 1
        defer { indentLevel -= 1 }
        return try block()
    }
    
    /**
     Returns a properly indented string based on current indentation level
     
     - Parameter text: The text to indent
     - Returns: The indented string
     */
    private func indent(_ text: String) -> String {
        guard !text.isEmpty else { return "" }
        
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        return lines.map { line in
            // Don't add indentation to empty lines
            line.isEmpty ? "" : currentIndent + line
        }.joined(separator: "\n")
    }
    
    /**
     Formats a block of statements with proper indentation
     
     - Parameter statements: The statements to format
     - Returns: The formatted block
     - Throws: If any statement can't be printed
     */
    private func formatBlock(_ statements: [Stmt]) throws -> String {
        if statements.isEmpty {
            return "{\n\(currentIndent)}"
        }
        
        let blockContent = try statements
            .map { stmt in try stmt.accept(visitor: self) }
            .filter { !$0.isEmpty }
            .joined(separator: options.useExtraNewlines ? "\n\n" : "\n")
        
        let indentedContent = withIndent { indent(blockContent) }
        return "{\n\(indentedContent)\n\(currentIndent)}"
    }
    
    /**
     Formats operator with or without spaces based on configuration
     
     - Parameter op: The operator text
     - Returns: Formatted operator
     */
    private func formatOperator(_ op: String) -> String {
        options.spaceAroundOperators ? " \(op) " : op
    }
    
    // MARK: - Expression Nodes
    
    /**
     Converts a literal expression to string representation
     
     - Parameter expr: The literal expression to convert
     - Returns: String representation of the literal value
     */
    public func visitLiteralExpr(_ expr: LiteralExpr) throws -> String {
        guard let value = expr.value else {
            return "null"
        }
        
        // Handle different literal types appropriately
        switch expr.tokenType {
        case .string:
            return "\"\(value)\""
        case .char:
            return "'\(value)'"
        case .true:
            return "true"
        case .false:
            return "false"
        case .nil:
            return "nil"
        default:
            return "\(value)"
        }
    }
    
    /**
     Converts a variable reference to string representation
     
     - Parameter expr: The variable expression to convert
     - Returns: String representation of the variable reference
     */
    public func visitVariableExpr(_ expr: VariableExpr) throws -> String {
        guard !expr.name.text.isEmpty else {
            throw ASTPrinterError.missingRequiredField("variable name")
        }
        return expr.name.text
    }
    
    /**
     Converts a binary expression to string representation
     
     - Parameter expr: The binary expression to convert
     - Returns: String representation of the binary operation
     - Throws: If child expressions can't be printed
     */
    public func visitBinaryExpr(_ expr: BinaryExpr) throws -> String {
        let left = try expr.left.accept(visitor: self)
        let right = try expr.right.accept(visitor: self)
        let op = formatOperator(expr.op.text)
        return "(\(left)\(op)\(right))"
    }
    
    /**
     Converts a grouping expression to string representation
     
     - Parameter expr: The grouping expression to convert
     - Returns: String representation with parentheses
     - Throws: If inner expression can't be printed
     */
    public func visitGroupingExpr(_ expr: GroupingExpr) throws -> String {
        let inner = try expr.expression.accept(visitor: self)
        return "(\(inner))"
    }
    
    /**
     Converts a unary expression to string representation
     
     - Parameter expr: The unary expression to convert
     - Returns: String representation of the unary operation
     - Throws: If operand can't be printed
     */
    public func visitUnaryExpr(_ expr: UnaryExpr) throws -> String {
        let right = try expr.right.accept(visitor: self)
        return "(\(expr.op.text)\(right))"
    }
    
    /**
     Converts a function call to string representation
     
     - Parameter expr: The call expression to convert
     - Returns: String representation of the function call
     - Throws: If callee or arguments can't be printed
     */
    public func visitCallExpr(_ expr: CallExpr) throws -> String {
        guard let callee = try? expr.callee.accept(visitor: self) else {
            throw ASTPrinterError.missingRequiredField("function callee")
        }
        
        let args = try expr.arguments.map { 
            try $0.accept(visitor: self) 
        }.joined(separator: ", ")
        
        return "\(callee)(\(args))"
    }
    
    /**
     Converts a property access to string representation
     
     - Parameter expr: The property access expression to convert
     - Returns: String representation using dot notation
     - Throws: If object expression can't be printed
     */
    public func visitGetExpr(_ expr: GetExpr) throws -> String {
        guard let obj = try? expr.object.accept(visitor: self) else {
            throw ASTPrinterError.missingRequiredField("object reference")
        }
        
        guard !expr.name.text.isEmpty else {
            throw ASTPrinterError.missingRequiredField("property name")
        }
        
        return "\(obj).\(expr.name.text)"
    }
    
    /**
     Converts a property assignment to string representation
     
     - Parameter expr: The property assignment expression to convert
     - Returns: String representation of the assignment
     - Throws: If object or value expressions can't be printed
     */
    public func visitSetExpr(_ expr: SetExpr) throws -> String {
        guard let obj = try? expr.object.accept(visitor: self) else {
            throw ASTPrinterError.missingRequiredField("object reference")
        }
        
        guard !expr.name.text.isEmpty else {
            throw ASTPrinterError.missingRequiredField("property name")
        }
        
        guard let value = try? expr.value.accept(visitor: self) else {
            throw ASTPrinterError.missingRequiredField("assigned value")
        }
        
        let op = formatOperator("=")
        return "\(obj).\(expr.name.text)\(op)\(value)"
    }
    
    /**
     Converts a this expression to string representation
     
     - Parameter expr: The this expression to convert
     - Returns: String "this"
     */
    public func visitThisExpr(_ expr: ThisExpr) throws -> String {
        return "this"
    }
    
    /**
     Converts a super expression to string representation
     
     - Parameter expr: The super expression to convert
     - Returns: String representation using super keyword
     */
    public func visitSuperExpr(_ expr: SuperExpr) throws -> String {
        guard !expr.method.text.isEmpty else {
            throw ASTPrinterError.missingRequiredField("super method name")
        }
        
        return "super.\(expr.method.text)"
    }
    
    /**
     Converts an array literal to string representation
     
     - Parameter expr: The array expression to convert
     - Returns: String representation with square brackets
     - Throws: If elements can't be printed
     */
    public func visitArrayExpr(_ expr: ArrayExpr) throws -> String {
        let elements = try expr.elements.map { 
            try $0.accept(visitor: self) 
        }.joined(separator: ", ")
        
        return "[\(elements)]"
    }
    
    /**
     Converts an assignment expression to string representation
     
     - Parameter expr: The assignment expression to convert
     - Returns: String representation of the assignment
     - Throws: If variable or value expressions can't be printed
     */
    public func visitAssignExpr(_ expr: AssignExpr) throws -> String {
        guard !expr.name.text.isEmpty else {
            throw ASTPrinterError.missingRequiredField("variable name")
        }
        
        guard let value = try? expr.value.accept(visitor: self) else {
            throw ASTPrinterError.missingRequiredField("assigned value")
        }
        
        let op = formatOperator("=")
        return "\(expr.name.text)\(op)\(value)"
    }
    
    /**
     Converts a logical expression to string representation
     
     - Parameter expr: The logical expression to convert
     - Returns: String representation of the logical operation
     - Throws: If operands can't be printed
     */
    public func visitLogicalExpr(_ expr: LogicalExpr) throws -> String {
        let left = try expr.left.accept(visitor: self)
        let right = try expr.right.accept(visitor: self)
        let op = formatOperator(expr.op.text)
        
        return "(\(left)\(op)\(right))"
    }
    
    // MARK: - Statement Nodes
    
    /**
     Converts an expression statement to string representation
     
     - Parameter stmt: The expression statement to convert
     - Returns: String representation ending with semicolon
     - Throws: If the expression can't be printed
     */
    public func visitExpressionStmt(_ stmt: ExpressionStmt) throws -> String {
        guard let exprStr = try? stmt.expression.accept(visitor: self) else {
            throw ASTPrinterError.missingRequiredField("expression in statement")
        }
        
        return "\(currentIndent)\(exprStr);"
    }
    
    /**
     Converts a print statement to string representation
     
     - Parameter stmt: The print statement to convert
     - Returns: String representation of the print statement
     - Throws: If the expression can't be printed
     */
    public func visitPrintStmt(_ stmt: PrintStmt) throws -> String {
        guard let exprStr = try? stmt.expression.accept(visitor: self) else {
            throw ASTPrinterError.missingRequiredField("expression to print")
        }
        
        return "\(currentIndent)print \(exprStr);"
    }
    
    /**
     Converts a variable declaration to string representation
     
     - Parameter decl: The variable declaration to convert
     - Returns: String representation of the variable definition
     - Throws: If initializer expressions can't be printed
     */
    public func visitVarDecl(_ decl: VarDecl) throws -> String {
        guard !decl.name.text.isEmpty else {
            throw ASTPrinterError.missingRequiredField("variable name")
        }
        
        var result = "\(currentIndent)var \(decl.name.text)"
        
        // Add type annotation if present
        if let type = decl.type {
            result += ": \(type.name.text)"
        }
        
        // Add initializer if present
        if let initializer = decl.initializer {
            let initStr = try initializer.accept(visitor: self)
            let op = formatOperator("=")
            result += "\(op)\(initStr)"
        }
        
        return result + ";"
    }
    
    /**
     Converts a block statement to string representation
     
     - Parameter stmt: The block statement to convert
     - Returns: String representation with braces
     - Throws: If any statement in the block can't be printed
     */
    public func visitBlockStmt(_ stmt: BlockStmt) throws -> String {
        return try formatBlock(stmt.statements)
    }
    
    /**
     Converts an if statement to string representation
     
     - Parameter stmt: The if statement to convert
     - Returns: String representation with condition and branches
     - Throws: If condition or branches can't be printed
     */
    public func visitIfStmt(_ stmt: IfStmt) throws -> String {
        let condition = try stmt.condition.accept(visitor: self)
        let thenBranch = try stmt.thenBranch.accept(visitor: self)
        
        var result = "\(currentIndent)if (\(condition)) \(thenBranch)"
        
        // Handle the else branch if present
        if let elseBranch = stmt.elseBranch {
            let elseStr = try elseBranch.accept(visitor: self)
            result += "\n\(currentIndent)else \(elseStr)"
        }
        
        return result
    }
    
    /**
     Converts a while loop to string representation
     
     - Parameter stmt: The while statement to convert
     - Returns: String representation of the loop
     - Throws: If condition or body can't be printed
     */
    public func visitWhileStmt(_ stmt: WhileStmt) throws -> String {
        guard let condition = try? stmt.condition.accept(visitor: self) else {
            throw ASTPrinterError.missingRequiredField("while condition")
        }
        
        let body = try stmt.body.accept(visitor: self)
        return "\(currentIndent)while (\(condition)) \(body)"
    }
    
    /**
     Converts a for loop to string representation
     
     - Parameter stmt: The for statement to convert
     - Returns: String representation of the loop
     - Throws: If initializer, condition, increment or body can't be printed
     */
    public func visitForStmt(_ stmt: ForStmt) throws -> String {
        // Format each optional component of the for loop
        let initializer = try stmt.initializer?.accept(visitor: self) ?? ""
        let condition = try stmt.condition?.accept(visitor: self) ?? ""
        let increment = try stmt.increment?.accept(visitor: self) ?? ""
        
        // Build the for header with proper semicolons
        let forHeader = "for (\(initializer); \(condition); \(increment))"
        
        // Format the body
        let body = try stmt.body.accept(visitor: self)
        
        return "\(currentIndent)\(forHeader) \(body)"
    }
    
    /**
     Converts a return statement to string representation
     
     - Parameter stmt: The return statement to convert
     - Returns: String representation of the return
     - Throws: If return value expression can't be printed
     */
    public func visitReturnStmt(_ stmt: ReturnStmt) throws -> String {
        var result = "\(currentIndent)return"
        
        if let value = stmt.value {
            let valueStr = try value.accept(visitor: self)
            result += " \(valueStr)"
        }
        
        return result + ";"
    }
    
    /**
     Converts a break statement to string representation
     
     - Parameter stmt: The break statement to convert
     - Returns: String "break;"
     */
    public func visitBreakStmt(_ stmt: BreakStmt) throws -> String {
        return "\(currentIndent)break;"
    }
    
    /**
     Converts a continue statement to string representation
     
     - Parameter stmt: The continue statement to convert
     - Returns: String "continue;"
     */
    public func visitContinueStmt(_ stmt: ContinueStmt) throws -> String {
        return "\(currentIndent)continue;"
    }
    
    // MARK: - Declaration Nodes
    
    /**
     Converts a variable declaration to string representation
     
     - Parameter decl: The variable declaration to convert
     - Returns: String representation with type and initializer if present
     - Throws: If initializer can't be printed
     */
    public func visitVarDecl(_ decl: VarDecl) throws -> String {
        let name = decl.name.text
        let typeAnnotation = decl.type != nil ? ": \(try decl.type!.accept(visitor: self))" : ""
        
        if let initExpr = decl.initializer {
            let value = try initExpr.accept(visitor: self)
            return "var \(name)\(typeAnnotation) = \(value);"
        }
        
        return "var \(name)\(typeAnnotation);"
    }
    
    /**
     Converts a function declaration to string representation
     
     - Parameter decl: The function declaration to convert
     - Returns: String representation of the function
     - Throws: If parameters or body can't be printed
     */
    public func visitFunctionDecl(_ decl: FunctionDecl) throws -> String {
        guard !decl.name.text.isEmpty else {
            throw ASTPrinterError.missingRequiredField("function name")
        }
        
        // Format parameters
        let params = decl.params.map { param -> String in
            var paramStr = param.name.text
            if let type = param.type {
                paramStr += ": \(type.name.text)"
            }
            return paramStr
        }.joined(separator: ", ")
        
        // Add return type if present
        var header = "\(currentIndent)func \(decl.name.text)(\(params))"
        if let returnType = decl.returnType {
            header += " -> \(returnType.name.text)"
        }
        
        // Format the body
        let body = try formatBlock(decl.body.statements)
        
        return "\(header) \(body)"
    }
    
    /**
     Converts a class declaration to string representation
     
     - Parameter decl: The class declaration to convert
     - Returns: String representation of the class
     - Throws: If methods can't be printed
     */
    public func visitClassDecl(_ decl: ClassDecl) throws -> String {
        guard !decl.name.text.isEmpty else {
            throw ASTPrinterError.missingRequiredField("class name")
        }
        
        // Add superclass if present
        var header = "\(currentIndent)class \(decl.name.text)"
        if let superclass = decl.superclass {
            header += " : \(superclass.name.text)"
        }
        
        // If the class has no methods or properties, return a simple declaration
        if decl.methods.isEmpty && decl.properties.isEmpty {
            return "\(header) {}"
        }
        
        // Format properties
        let properties = try decl.properties.map { 
            try visitVarDecl($0)
        }.joined(separator: "\n\n")
        
        // Format methods
        let methods = try decl.methods.map { method -> String
            // Temporarily reduce indent level for method declarations
            // since they will be indented within the class body
            indentLevel -= 1
            defer { indentLevel += 1 }
            return try visitFunctionDecl(method)
        }.joined(separator: "\n\n")
        
        // Combine all parts
        var result = "\(header) {\n"
        
        if !properties.isEmpty {
            result += withIndent { properties }
        }
        
        if !properties.isEmpty && !methods.isEmpty {
            result += "\n\n"
        }
        
        if !methods.isEmpty {
            result += withIndent { methods }
        }
        
        result += "\n\(currentIndent)}"
        
        return result
    }
    
    /**
     Converts an import declaration to string representation
     
     - Parameter decl: The import declaration to convert
     - Returns: String representation of the import
     */
    public func visitImportDecl(_ decl: ImportDecl) throws -> String {
        guard !decl.path.text.isEmpty else {
            throw ASTPrinterError.missingRequiredField("import path")
        }
        
        return "\(currentIndent)import \(decl.path.text);"
    }
    
    /**
     Formats a sequence of declarations or statements
     
     - Parameter nodes: The nodes to format
     - Returns: Formatted text for all nodes
     - Throws: If any node can't be printed
     */
    public func format<T: ASTNode>(nodes: [T]) throws -> String {
        try nodes.map { 
            try $0.accept(visitor: self) 
        }.joined(separator: options.useExtraNewlines ? "\n\n" : "\n")
    }
    
    /**
     Applies proper indentation to a multiline string
     
     - Parameters:
        - text: The text to format
        - preserveIndent: Whether to preserve existing indentation
     - Returns: The formatted text
     */
    public func formatMultilineString(_ text: String, preserveIndent: Bool = false) -> String {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        
        return lines.enumerated().map { index, line in
            if index == 0 {
                // First line gets no extra indent
                return String(line)
            } else if line.isEmpty && !preserveIndent {
                // Empty lines get no indentation unless requested
                return ""
            } else {
                // Other lines get indentation
                return currentIndent + String(line)
            }
        }.joined(separator: "\n")
    }
    
    // MARK: - Type Nodes
    
    /**
     Converts a named type to string representation
     
     - Parameter type: The named type to convert
     - Returns: String representation of the type name
     */
    public func visitNamedType(_ type: NamedType) throws -> String {
        return type.name.text
    }
    
    /**
     Converts an array type to string representation
     
     - Parameter type: The array type to convert
     - Returns: String representation with element type in brackets
     - Throws: If element type can't be printed
     */
    public func visitArrayType(_ type: ArrayType) throws -> String {
        let elem = try type.elementType.accept(visitor: self)
        return "[\(elem)]"
    }
    
    /**
     Converts a generic type to string representation
     
     - Parameter type: The generic type to convert
     - Returns: String representation with type arguments in angle brackets
     - Throws: If base type or type arguments can't be printed
     */
    public func visitGenericType(_ type: GenericType) throws -> String {
        let base = try type.baseType.accept(visitor: self)
        let args = try type.typeArguments.map { try $0.accept(visitor: self) }.joined(separator: ", ")
        return "\(base)<\(args)>"
    }
}