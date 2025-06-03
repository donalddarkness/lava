import Foundation

/// Represents a tensor dimension in OuroLang MLIR integration
public enum TensorDimension: CustomStringConvertible {
    case fixed(Int)
    case dynamic
    
    public var description: String {
        switch self {
        case .fixed(let size):
            return String(size)
        case .dynamic:
            return "?"
        }
    }
}

/// Represents tensor shape specifications
public struct TensorShape: CustomStringConvertible {
    public let dimensions: [TensorDimension]
    
    public init(_ dimensions: [TensorDimension]) {
        self.dimensions = dimensions
    }
    
    public init(_ fixedDimensions: [Int]) {
        self.dimensions = fixedDimensions.map { .fixed($0) }
    }
    
    public init(rank: Int, dynamic: Bool = true) {
        self.dimensions = Array(repeating: dynamic ? .dynamic : .fixed(1), count: rank)
    }
    
    public var description: String {
        dimensions.map { $0.description }.joined(separator: "x")
    }
    
    public var isStatic: Bool {
        !dimensions.contains(where: {
            if case .dynamic = $0 { return true }
            return false
        })
    }
    
    public var rank: Int {
        dimensions.count
    }
}

/// Represents common tensor operations in the MLIR dialect system
public struct TensorOperation {
    public enum OpType: String {
        case extract
        case insert
        case reshape
        case cast
        case generate
        case collapseShape = "collapse_shape"
        case expandShape = "expand_shape"
        case fromElements = "from_elements"
        case pad
        case rank
        case matmul
        case transpose
        
        public var dialectName: String {
            switch self {
            case .matmul:
                return "linalg"
            default:
                return "tensor"
            }
        }
    }
    
    public let type: OpType
    public let inputShape: TensorShape
    public let outputShape: TensorShape?
    public let elementType: String
    
    public var name: String {
        type.rawValue
    }
    
    public var dialect: String {
        type.dialectName
    }
    
    public var isSupported: Bool {
        // This could be expanded to check dimensions compatibility, etc.
        true
    }
    
    public init(type: OpType, inputShape: TensorShape, outputShape: TensorShape? = nil, elementType: String) {
        self.type = type
        self.inputShape = inputShape
        self.outputShape = outputShape
        self.elementType = elementType
    }
    
    public var description: String {
        if let outputShape {
            return "\(inputShape.description) -> \(outputShape.description), \(elementType)"
        }
        return "\(inputShape.description), \(elementType)"
    }
}

/// Represents an affine map in OuroLang MLIR integration
public struct AffineMap {
    public struct Expression {
        public enum Term {
            case dimension(Int, Int?)  // dimension index, coefficient (nil = 1)
            case symbol(Int, Int?)     // symbol index, coefficient (nil = 1)
            case constant(Int)
        }
        
        public let terms: [Term]
        
        public init(_ terms: [Term]) {
            self.terms = terms
        }
        
        public var description: String {
            if terms.isEmpty {
                return "0"
            }
            
            return terms.enumerated().map { index, term -> String in
                let prefix = index > 0 ? " + " : ""
                switch term {
                case .dimension(let idx, let coef):
                    if let coef = coef {
                        return "\(prefix)\(coef) * d\(idx)"
                    }
                    return "\(prefix)d\(idx)"
                case .symbol(let idx, let coef):
                    if let coef = coef {
                        return "\(prefix)\(coef) * s\(idx)"
                    }
                    return "\(prefix)s\(idx)"
                case .constant(let value):
                    return "\(prefix)\(value)"
                }
            }.joined()
        }
    }
    
    public let dimensions: Int
    public let symbols: Int
    public let expressions: [Expression]
    
    public init(dimensions: Int, symbols: Int, expressions: [Expression]) {
        self.dimensions = dimensions
        self.symbols = symbols
        self.expressions = expressions
    }
    
    public var isValid: Bool {
        // Basic validation logic
        dimensions >= 0 && symbols >= 0 && !expressions.isEmpty
    }
    
    public var description: String {
        let dimStr = (0..<dimensions).map { "d\($0)" }.joined(separator: ", ")
        let symStr = (0..<symbols).map { "s\($0)" }.joined(separator: ", ")
        let expStr = expressions.map { $0.description }.joined(separator: ", ")
        
        var mapStr = "("
        if dimensions > 0 {
            mapStr += dimStr
        }
        if symbols > 0 {
            if dimensions > 0 {
                mapStr += ", "
            }
            mapStr += "[\(symStr)]"
        }
        mapStr += ") -> (\(expStr))"
        
        return mapStr
    }
}
