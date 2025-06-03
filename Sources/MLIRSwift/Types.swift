import CMLIR

/// Integer type in MLIR
public struct IntegerType {
    public let raw: MlirType

    /// Create a new IntegerType with given bitwidth
    public static func get(width: UInt32, in context: MlirContext) -> IntegerType {
        IntegerType(raw: mlirIntegerTypeGet(width, context.raw))
    }
}

/// Floating-point types in MLIR
public enum FloatType {
    case f16(MlirType)
    case f32(MlirType)
    case f64(MlirType)

    /// Raw MLIR type
    public var raw: MlirType {
        switch self {
        case .f16(let t): return t
        case .f32(let t): return t
        case .f64(let t): return t
        }
    }

    /// 32-bit float
    public static func f32(in context: MlirContext) -> FloatType {
        .f32(mlirFloatTypeGetF32(context.raw))
    }

    /// 64-bit float
    public static func f64(in context: MlirContext) -> FloatType {
        .f64(mlirFloatTypeGetF64(context.raw))
    }

    /// 16-bit float
    public static func f16(in context: MlirContext) -> FloatType {
        .f16(mlirFloatTypeGetF16(context.raw))
    }

    /// BFloat16 float
    public static func bf16(in context: MlirContext) -> FloatType {
        .f16(mlirBFloat16TypeGet(context.raw))
    }
}

/// Index type in MLIR
public struct IndexType {
    public let raw: MlirType

    /// Create an index type in the given context
    public static func get(in context: MlirContext) -> IndexType {
        IndexType(raw: mlirIndexTypeGet(context.raw))
    }
}

/// Function type in MLIR
public struct FunctionType {
    public let raw: MlirType

    /// Construct a function type with given inputs and results
    public static func get(inputs: [MlirType], results: [MlirType], in context: MlirContext) -> FunctionType {
        let inputCount = UInt(inputs.count)
        let resultCount = UInt(results.count)
        return FunctionType(raw: mlirFunctionTypeGet(context.raw, inputCount, inputs, resultCount, results))
    }
}

/// Vector type in MLIR
public struct VectorType {
    public let raw: MlirType

    /// Create a new VectorType with given element type and shape
    public static func get(shape: [Int64], elementType: MlirType, in context: MlirContext) -> VectorType {
        let shapeCount = UInt(shape.count)
        return shape.withUnsafeBufferPointer { shapePtr in
            VectorType(raw: mlirVectorTypeGet(shapeCount, shapePtr.baseAddress, elementType))
        }
    }
}

/// MemRef type in MLIR
public struct MemRefType {
    public let raw: MlirType

    /// Create a new MemRefType with given element type, shape, and optional layout map and memory space
    public static func get(elementType: MlirType, shape: [Int64], layout: MlirAttribute? = nil, memorySpace: MlirAttribute? = nil) -> MemRefType {
        let shapeCount = UInt(shape.count)
        return shape.withUnsafeBufferPointer { shapePtr in
            MemRefType(raw: mlirMemRefTypeGet(elementType, shapePtr.baseAddress, shapeCount, layout ?? MlirAttribute(), memorySpace ?? MlirAttribute()))
        }
    }
}

/// Tuple type in MLIR
public struct TupleType {
    public let raw: MlirType

    /// Create a new TupleType with given element types
    public static func get(elements: [MlirType], in context: MlirContext) -> TupleType {
        let elementCount = UInt(elements.count)
        return TupleType(raw: mlirTupleTypeGet(context.raw, elementCount, elements))
    }
}

/// Complex type in MLIR
public struct ComplexType {
    public let raw: MlirType

    /// Create a new ComplexType with given element type
    public static func get(elementType: MlirType) -> ComplexType {
        ComplexType(raw: mlirComplexTypeGet(elementType))
    }
}

/// None type in MLIR
public struct NoneType {
    public let raw: MlirType

    /// Create a new NoneType in the given context
    public static func get(in context: MlirContext) -> NoneType {
        NoneType(raw: mlirNoneTypeGet(context.raw))
    }
}

/// Opaque type in MLIR (used for dialect types that don't have custom formatters)
public struct OpaqueType {
    public let raw: MlirType

    /// Create a new OpaqueType with given dialect namespace and type data
    public static func get(dialectNamespace: String, typeData: String, in context: MlirContext) -> OpaqueType {
        let namespaceRef = dialectNamespace.withCString { ptr in
            MlirStringRef(str: ptr, length: dialectNamespace.utf8.count)
        }
        let typeDataRef = typeData.withCString { ptr in
            MlirStringRef(str: ptr, length: typeData.utf8.count)
        }
        return OpaqueType(raw: mlirOpaqueTypeGet(context.raw, namespaceRef, typeDataRef))
    }
}

/// Ranked Tensor type in MLIR
public struct RankedTensorType {
    public let raw: MlirType

    /// Create a new RankedTensorType with given shape, element type, and optional encoding
    public static func get(shape: [Int64], elementType: MlirType, encoding: MlirAttribute? = nil) -> RankedTensorType {
        let shapeCount = UInt(shape.count)
        return shape.withUnsafeBufferPointer { shapePtr in
            RankedTensorType(raw: mlirRankedTensorTypeGet(shapeCount, shapePtr.baseAddress, elementType, encoding ?? MlirAttribute()))
        }
    }
}

/// Unranked Tensor type in MLIR
public struct UnrankedTensorType {
    public let raw: MlirType

    /// Create a new UnrankedTensorType with given element type
    public static func get(elementType: MlirType) -> UnrankedTensorType {
        UnrankedTensorType(raw: mlirUnrankedTensorTypeGet(elementType))
    }
}

/// Unranked MemRef type in MLIR
public struct UnrankedMemRefType {
    public let raw: MlirType

    /// Create a new UnrankedMemRefType with given element type and optional memory space
    public static func get(elementType: MlirType, memorySpace: MlirAttribute? = nil) -> UnrankedMemRefType {
        UnrankedMemRefType(raw: mlirUnrankedMemRefTypeGet(elementType, memorySpace ?? MlirAttribute()))
    }
}

// TODO: add wrappers for all other MLIR types 