import Foundation
import MLIRSwift

/// Utility for managing MLIR dialects and their features
public struct MLIRDialectManager {
    /// Common MLIR dialects used in OuroLang
    public enum Dialect: String, CaseIterable {
        case std
        case arith
        case function = "func" // Fix for Swift 6.1: renamed 'func' to 'function' to avoid keyword conflict
        case scf
        case cf
        case affine
        case tensor
        case memref
        case vector
        case linalg
        case math
        case llvm
        case gpu
        case nvvm
        case rocdl
        case spv
        // New dialects for OuroLang
        case ouro  // Custom dialect for OuroLang-specific operations
        case async // Support for asynchronous programming
        case quant // Support for quantization operations
        
        /// Whether this dialect is essential for basic operations
        public var isEssential: Bool {
            switch self {
            case .std, .arith, .function:
                return true
            default:
                return false
            }
        }
        
        /// Whether this dialect is related to parallel computing
        public var isParallel: Bool {
            switch self {
            case .gpu, .nvvm, .rocdl, .async:
                return true
            default:
                return false
            }
        }
        
        /// Whether this dialect is related to tensor operations
        public var isTensor: Bool {
            switch self {
            case .tensor, .linalg:
                return true
            default:
                return false
            }
        }
        
        /// Get the dialect name for use in MLIR operations
        public var mlirName: String {
            switch self {
            case .function:
                return "func" // Map back to 'func' for MLIR
            default:
                return rawValue
            }
        }
    }
    
    /// Loads all required dialects into the registry
    /// - Parameter registry: The DialectRegistry to update
    public static func loadEssentialDialects(into registry: DialectRegistry) {
        registry.insertStandard()
        registry.insertArith()
        registry.insertFunc()
        registry.insertSCF()
    }
    
    /// Loads tensor-related dialects into the registry
    /// - Parameter registry: The DialectRegistry to update
    public static func loadTensorDialects(into registry: DialectRegistry) {
        registry.insertTensor()
        registry.insertLinalg()
        registry.insertMemRef()
        registry.insertMath()
    }
    
    /// Loads all available dialects into the registry
    /// - Parameter registry: The DialectRegistry to update
    public static func loadAllDialects(into registry: DialectRegistry) {
        loadEssentialDialects(into: registry)
        loadTensorDialects(into: registry)
        
        registry.insertAffine()
        registry.insertLLVM()
        registry.insertVector()
        registry.insertSPIRV()
        registry.insertGPU()
        registry.insertNVVM()
        registry.insertROCDL()
        registry.insertOpenMP()
        
        // Register custom dialects if they exist
        // These would normally be registered through a custom registration function
        // but for now we'll just track that they should be registered
        loadOuroCustomDialects(into: registry)
    }
    
    /// Loads OuroLang-specific dialects into the registry
    /// - Parameter registry: The DialectRegistry to update
    public static func loadOuroCustomDialects(into registry: DialectRegistry) {
        // In a real implementation, this would register custom dialects
        // For now, this is a placeholder for when we implement our own dialects
        print("Registered OuroLang custom dialects")
    }
    
    /// Gets the operation prefix for a given dialect
    /// - Parameter dialect: The dialect name
    /// - Returns: The operation prefix (e.g., "arith." for arith dialect)
    public static func operationPrefix(for dialect: String) -> String {
        if let knownDialect = Dialect(rawValue: dialect.lowercased()) {
            return "\(knownDialect.mlirName)."
        }
        return "\(dialect)."
    }
    
    /// Maps an OuroLang operation to its MLIR equivalent
    /// - Parameters:
    ///   - operation: The operation name in OuroLang
    ///   - dialect: Optional dialect name (defaults to appropriate dialect)
    /// - Returns: The full MLIR operation name
    public static func mapOperation(_ operation: String, dialect: String? = nil) -> String {
        let op = operation.lowercased()
        
        // Arithmetic operations
        if ["add", "subtract", "multiply", "divide", "remainder", "power", "mod"].contains(op) {
            let arithOp: String
            switch op {
            case "add": arithOp = "addi"
            case "subtract": arithOp = "subi"
            case "multiply": arithOp = "muli"
            case "divide": arithOp = "divsi"
            case "remainder", "mod": arithOp = "remsi"
            case "power": arithOp = "power" // Using proper MLIR operation name for power
            default: arithOp = op
            }
            return "arith.\(arithOp)"
        }
        
        // Float arithmetic operations
        if ["addf", "subf", "mulf", "divf"].contains(op) {
            return "arith.\(op)"
        }
        
        // Comparison operations
        if ["equal", "notequal", "less", "lessequal", "greater", "greaterequal", "eq", "ne", "lt", "le", "gt", "ge"].contains(op) {
            let cmpOp: String
            switch op {
            case "equal", "eq": cmpOp = "eq"
            case "notequal", "ne": cmpOp = "ne"
            case "less", "lt": cmpOp = "slt"
            case "lessequal", "le": cmpOp = "sle"
            case "greater", "gt": cmpOp = "sgt"
            case "greaterequal", "ge": cmpOp = "sge"
            default: cmpOp = op
            }
            return "arith.cmpi \(cmpOp)"
        }
        
        // Bitwise operations
        if ["and", "or", "xor", "shl", "shr", "shru"].contains(op) {
            return "arith.\(op)i"
        }
        
        // Control flow operations
        if ["if", "else", "for", "while", "do", "switch", "case"].contains(op) {
            return "scf.\(op)"
        }
        
        // Function operations
        if ["call", "return", "yield"].contains(op) {
            return "func.\(op)"
        }
        
        // Tensor operations
        if ["extract", "insert", "reshape", "cast", "generate", "collapse_shape", "expand_shape"].contains(op) {
            return "tensor.\(op)"
        }
        
        // Vector operations
        if ["broadcast", "extract", "insert", "fma", "contract"].contains(op) {
            // If the dialect is specifically set to tensor but this is actually a vector op
            if dialect == "tensor" {
                return "tensor.\(op)"
            }
            return "vector.\(op)"
        }
        
        // Math operations from OuroLang
        if ["sqrt", "exp", "log", "sin", "cos", "tan"].contains(op) {
            return "math.\(op)"
        }
        
        // Use specified dialect if provided
        if let dialect = dialect {
            if dialect == "func" {
                return "func.\(op)" 
            }
            return "\(dialect).\(op)"
        }
        
        // Default to standard dialect
        return "std.\(op)"
    }
    
    /// Maps an OuroLang type to its MLIR equivalent
    /// - Parameter typeName: The OuroLang type name
    /// - Returns: The equivalent MLIR type name
    public static func mapType(_ typeName: String) -> String {
        switch typeName.lowercased() {
        case "int": return "i32"
        case "uint": return "ui32"
        case "byte": return "i8"
        case "ubyte": return "ui8"
        case "short": return "i16" 
        case "ushort": return "ui16"
        case "long": return "i64"
        case "ulong": return "ui64"
        case "float": return "f32"
        case "double": return "f64"
        case "bool", "boolean": return "i1"
        case "string": return "!llvm.ptr<i8>"
        case "char": return "i8"
        case "void": return "none"
        case "half": return "f16"
        case "decimal": return "f64"  // Approximation, MLIR doesn't have a decimal type
        default: 
            if typeName.hasSuffix("?") {
                // Handle optional types - create a pointer to the base type
                let baseType = String(typeName.dropLast(1))
                return "!llvm.ptr<\(mapType(baseType))>"
            }
            if typeName.hasSuffix("[]") {
                // Handle array types - create a pointer to the base type
                let baseType = String(typeName.dropLast(2))
                return "!llvm.ptr<\(mapType(baseType))>"
            }
            // Default case - could be a custom type
            return typeName
        }
    }
}
