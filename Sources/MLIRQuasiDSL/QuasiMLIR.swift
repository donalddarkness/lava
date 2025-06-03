import Foundation
import OuroLangCore

// MARK: - MLIR Domain-Specific Language Implementation

/**
 Result builder for creating MLIR code blocks in a declarative way.
 
 This result builder allows for clean syntax when defining MLIR operations
 by automatically joining string components with newlines.
 
 Example usage:
 ```swift
 let mlirCode = MLIR.module {
     MLIR.funcOp(name: "main") {
         MLIR.constantOp(name: "result", value: 42)
         MLIR.ret("result")
     }
 }
 ```
 */
@resultBuilder
public struct MLIRBuilder {
    /// Builds a block from an array of string components
    /// - Parameter parts: The string components to join
    /// - Returns: A single string with all parts joined by newlines
    public static func buildBlock(_ parts: String...) -> String {
        parts.joined(separator: "\n")
    }
    
    /// Builds a block from an array of string components
    /// - Parameter parts: The string components to join
    /// - Returns: A single string with all parts joined by newlines
    public static func buildArray(_ parts: [String]) -> String {
        parts.joined(separator: "\n")
    }
    
    /// Conditionally includes content based on a Boolean condition
    /// - Parameters:
    ///   - condition: The condition to evaluate
    ///   - trueContent: The content to include if the condition is true
    /// - Returns: The content if condition is true, or an empty string
    public static func buildIf(_ condition: Bool, _ trueContent: () -> String) -> String {
        condition ? trueContent() : ""
    }
    
    /// Handles optional content by unwrapping it or providing an empty string
    /// - Parameter content: The optional content to unwrap
    /// - Returns: The unwrapped content or an empty string
    public static func buildOptional(_ content: String?) -> String {
        content ?? ""
    }
    
    /// Creates an either-or branch based on a condition
    /// - Parameters:
    ///   - condition: The condition to evaluate
    ///   - trueContent: Content to include if condition is true
    ///   - falseContent: Content to include if condition is false
    /// - Returns: The appropriate content based on the condition
    public static func buildEither(first trueContent: String, second falseContent: String, for condition: Bool) -> String {
        condition ? trueContent : falseContent
    }
    
    /// Handles error-throwing expressions by returning an empty string if an error occurs
    /// - Parameter content: A closure that may throw an error when generating content
    /// - Returns: The generated content or an empty string if an error occurred
    public static func buildErrorCatching(_ content: () throws -> String) -> String {
        (try? content()) ?? ""
    }
}

/**
 High-level Swift DSL for generating MLIR text representation.
 
 This namespace provides structured builders for common MLIR operations
 including modules, functions, control flow, and constants.
 */
public enum MLIR {
    // MARK: - Module Structure
    
    /**
     Constructs an MLIR module with the provided body content.
     
     - Parameter body: A closure that returns the module's content
     - Returns: A string representing an MLIR module
     */
    public static func module(@MLIRBuilder _ body: () -> String) -> String {
        "module {\n" + body() + "\n}\n"
    }
    
    // MARK: - Function Operations
    
    /**
     Defines a function in the `func` dialect with specified name and return type.
     
     - Parameters:
        - name: The function name (will be prefixed with `@`)
        - returnType: The function's return type (defaults to "void")
        - args: Optional function arguments as (name, type) pairs
        - body: A closure that returns the function's body content
     - Returns: A string representing an MLIR function
     */
    public static func funcOp(
        name: String, 
        returnType: String = "void",
        args: [(String, String)] = [],
        @MLIRBuilder _ body: () -> String
    ) -> String {
        let argsStr = args.isEmpty ? "" : 
            args.map { name, type in "%\(name): \(type)" }.joined(separator: ", ")
        return "func.func @\(name)(\(argsStr)) -> \(returnType) {\n" + body() + "\n}"
    }
    
    /**
     Defines an external function declaration in the `func` dialect.
     
     - Parameters:
        - name: The function name (will be prefixed with `@`)
        - returnType: The function's return type (defaults to "void")
        - args: Optional function arguments as (name, type) pairs
     - Returns: A string representing an MLIR external function declaration
     */
    public static func externFuncOp(
        name: String, 
        returnType: String = "void",
        args: [(String, String)] = []
    ) -> String {
        let argsStr = args.isEmpty ? "" : 
            args.map { _, type in type }.joined(separator: ", ")
        return "func.func @\(name)(\(argsStr)) -> \(returnType)"
    }
    
    // MARK: - Return Operations
    
    /**
     Creates a return operation with no value.
     
     - Returns: A string representing an MLIR void return operation
     */
    public static func ret() -> String {
        "func.return"
    }
    
    /**
     Creates a return operation with the specified value.
     
     - Parameter value: The value to return
     - Parameter type: The value's type (defaults to "i32")
     - Returns: A string representing an MLIR return operation with value
     */
    public static func ret(_ value: String, type: String = "i32") -> String {
        "func.return \(value) : \(type)"
    }
    
    // MARK: - Control Flow Operations
    
    /**
     Creates an unconditional branch to a target block.
     
     - Parameter target: The target block name
     - Returns: A string representing an MLIR branch operation
     */
    public static func br(_ target: String) -> String {
        "cf.br ^\(target)"
    }
    
    /**
     Creates a conditional branch operation.
     
     - Parameters:
        - cond: The condition value
        - trueBlock: The block to branch to if condition is true
        - falseBlock: The block to branch to if condition is false
     - Returns: A string representing an MLIR conditional branch operation
     */
    public static func condBr(cond: String, trueBlock: String, falseBlock: String) -> String {
        "cf.cond_br \(cond), ^\(trueBlock), ^\(falseBlock)"
    }
    
    /**
     Creates a complete if-then-else structure using blocks.
     
     - Parameters:
        - condition: The condition value
        - thenBody: The body of the "then" block
        - elseBody: The optional body of the "else" block
     - Returns: A string representing an MLIR if-then-else structure
     */
    public static func ifThenElse(
        condition: String,
        @MLIRBuilder thenBody: () -> String,
        @MLIRBuilder elseBody: () -> String = { "" }
    ) -> String {
        """
        \(condBr(cond: condition, trueBlock: "then", falseBlock: "else"))
        ^then:
          \(thenBody())
          \(br("end"))
        ^else:
          \(elseBody())
          \(br("end"))
        ^end:
        """
    }
    
    /**
     Creates a loop structure with condition at the beginning.
     
     - Parameters:
        - conditionGenerator: Generator for the loop condition
        - bodyGenerator: Generator for the loop body
     - Returns: A string representing an MLIR while loop structure
     */
    public static func whileLoop(
        @MLIRBuilder condition: () -> String,
        @MLIRBuilder body: () -> String
    ) -> String {
        """
        cf.br ^condition
        ^condition:
          \(condition())
          cf.cond_br %cond, ^body, ^end
        ^body:
          \(body())
          cf.br ^condition
        ^end:
        """
    }
    
    // MARK: - Value Operations
    
    /**
     Creates a constant operation with a specified name and value.
     
     - Parameters:
        - name: The name of the constant
        - value: The integer value
        - type: The type of the constant (defaults to "i32")
     - Returns: A string representing an MLIR constant operation
     */
    public static func constantOp(name: String, value: Int, type: String = "i32") -> String {
        "%\(name) = \"std.constant\"() { value = \(value) : \(type) } : () -> \(type)"
    }
    
    /**
     Creates a floating point constant operation.
     
     - Parameters:
        - name: The name of the constant
        - value: The float value
        - type: The type of the constant (defaults to "f32")
     - Returns: A string representing an MLIR floating point constant
     */
    public static func floatConstantOp(name: String, value: Float, type: String = "f32") -> String {
        "%\(name) = \"std.constant\"() { value = \(value) : \(type) } : () -> \(type)"
    }
    
    /**
     Creates a boolean constant operation.
     
     - Parameters:
        - name: The name of the constant
        - value: The boolean value
     - Returns: A string representing an MLIR boolean constant
     */
    public static func boolConstantOp(name: String, value: Bool) -> String {
        "%\(name) = \"std.constant\"() { value = \(value ? 1 : 0) : i1 } : () -> i1"
    }
    
    /**
     Creates a string constant operation.
     
     - Parameters:
        - name: The name of the constant
        - value: The string value
     - Returns: A string representing an MLIR string constant
     */
    public static func stringConstantOp(name: String, value: String) -> String {
        "%\(name) = \"std.constant\"() { value = \"\(value.replacingOccurrences(of: "\"", with: "\\\""))\" } : () -> !llvm.ptr<i8>"
    }
    
    // MARK: - Arithmetic Operations
    
    /**
     Creates an addition operation.
     
     - Parameters:
        - name: The result variable name
        - lhs: Left-hand side operand
        - rhs: Right-hand side operand
        - type: The type of the operation (defaults to "i32")
     - Returns: A string representing an MLIR addition operation
     */
    public static func addOp(name: String, lhs: String, rhs: String, type: String = "i32") -> String {
        "%\(name) = arith.addi \(lhs), \(rhs) : \(type)"
    }
    
    /**
     Creates a subtraction operation.
     
     - Parameters:
        - name: The result variable name
        - lhs: Left-hand side operand
        - rhs: Right-hand side operand
        - type: The type of the operation (defaults to "i32")
     - Returns: A string representing an MLIR subtraction operation
     */
    public static func subOp(name: String, lhs: String, rhs: String, type: String = "i32") -> String {
        "%\(name) = arith.subi \(lhs), \(rhs) : \(type)"
    }
    
    /**
     Creates a multiplication operation.
     
     - Parameters:
        - name: The result variable name
        - lhs: Left-hand side operand
        - rhs: Right-hand side operand
        - type: The type of the operation (defaults to "i32")
     - Returns: A string representing an MLIR multiplication operation
     */
    public static func mulOp(name: String, lhs: String, rhs: String, type: String = "i32") -> String {
        "%\(name) = arith.muli \(lhs), \(rhs) : \(type)"
    }
    
    /**
     Creates a division operation.
     
     - Parameters:
        - name: The result variable name
        - lhs: Left-hand side operand
        - rhs: Right-hand side operand
        - type: The type of the operation (defaults to "i32")
     - Returns: A string representing an MLIR division operation
     */
    public static func divOp(name: String, lhs: String, rhs: String, type: String = "i32") -> String {
        "%\(name) = arith.divsi \(lhs), \(rhs) : \(type)"
    }
    
    // MARK: - Block Operations
    
    /**
     Defines a basic block label.
     
     - Parameter name: The block name
     - Returns: A string representing an MLIR block label
     */
    public static func block(_ name: String) -> String {
        "^\(name):"
    }
}