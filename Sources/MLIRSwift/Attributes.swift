import CMLIR

/// Affine map attribute in MLIR
public struct AffineMapAttr {
    public let raw: MlirAttribute

    /// Create a new AffineMapAttr from an MlirAffineMap
    public static func get(map: MlirAffineMap) -> AffineMapAttr {
        AffineMapAttr(raw: mlirAffineMapAttrGet(map))
    }
}

/// Integer set attribute in MLIR
public struct IntegerSetAttr {
    public let raw: MlirAttribute

    /// Create a new IntegerSetAttr from an MlirIntegerSet
    public static func get(set: MlirIntegerSet) -> IntegerSetAttr {
        IntegerSetAttr(raw: mlirIntegerSetAttrGet(set))
    }
}

/// Boolean attribute in MLIR
public struct BoolAttr {
    public let raw: MlirAttribute

    /// Create a new BoolAttr with a given boolean value
    public static func get(_ value: Bool, in context: MlirContext) -> BoolAttr {
        BoolAttr(raw: mlirBoolAttrGet(context.raw, value ? 1 : 0))
    }
}

/// Float attribute in MLIR
public struct FloatAttr {
    public let raw: MlirAttribute

    /// Create a new FloatAttr with a given double value and type
    public static func get(_ value: Double, type: MlirType) -> FloatAttr {
        FloatAttr(raw: mlirFloatAttrGet(type, value))
    }
}

/// Integer attribute in MLIR
public struct IntegerAttr {
    public let raw: MlirAttribute

    /// Create a new IntegerAttr with a given 64-bit integer value and type
    public static func get(_ value: Int64, type: MlirType) -> IntegerAttr {
        IntegerAttr(raw: mlirIntegerAttrGet(type, value))
    }
}

/// String attribute in MLIR
public struct StringAttr {
    public let raw: MlirAttribute

    /// Create a new StringAttr with a given string value
    public static func get(_ value: String, in context: MlirContext) -> StringAttr {
        let valueRef = value.withCString { ptr in
            MlirStringRef(str: ptr, length: value.utf8.count)
        }
        return StringAttr(raw: mlirStringAttrGet(context.raw, valueRef))
    }
}

/// Type attribute in MLIR
public struct TypeAttr {
    public let raw: MlirAttribute

    /// Create a new TypeAttr with a given MLIR type
    public static func get(type: MlirType) -> TypeAttr {
        TypeAttr(raw: mlirTypeAttrGet(type))
    }
}

/// Unit attribute in MLIR (a singleton attribute)
public struct UnitAttr {
    public let raw: MlirAttribute

    /// Create a new UnitAttr in the given context
    public static func get(in context: MlirContext) -> UnitAttr {
        UnitAttr(raw: mlirUnitAttrGet(context.raw))
    }
}

/// Array attribute in MLIR
public struct ArrayAttr {
    public let raw: MlirAttribute

    /// Create a new ArrayAttr with given elements
    public static func get(elements: [MlirAttribute], in context: MlirContext) -> ArrayAttr {
        let elementCount = UInt(elements.count)
        return ArrayAttr(raw: mlirArrayAttrGet(context.raw, elementCount, elements))
    }
}

/// Dictionary attribute in MLIR
public struct DictionaryAttr {
    public let raw: MlirAttribute

    /// Create a new DictionaryAttr with given named attributes
    public static func get(elements: [MlirNamedAttribute], in context: MlirContext) -> DictionaryAttr {
        let elementCount = UInt(elements.count)
        return DictionaryAttr(raw: mlirDictionaryAttrGet(context.raw, elementCount, elements))
    }
}

/// Flat symbol reference attribute in MLIR
public struct FlatSymbolRefAttr {
    public let raw: MlirAttribute

    /// Create a new FlatSymbolRefAttr with a given symbol name
    public static func get(_ value: String, in context: MlirContext) -> FlatSymbolRefAttr {
        let valueRef = value.withCString { ptr in
            MlirStringRef(str: ptr, length: value.utf8.count)
        }
        return FlatSymbolRefAttr(raw: mlirFlatSymbolRefAttrGet(context.raw, valueRef))
    }
}

/// Symbol reference attribute in MLIR
public struct SymbolRefAttr {
    public let raw: MlirAttribute

    /// Create a new SymbolRefAttr with a given symbol name and optional references
    public static func get(_ value: String, refs: [MlirAttribute], in context: MlirContext) -> SymbolRefAttr {
        let valueRef = value.withCString { ptr in
            MlirStringRef(str: ptr, length: value.utf8.count)
        }
        let refsCount = UInt(refs.count)
        return SymbolRefAttr(raw: mlirSymbolRefAttrGet(context.raw, valueRef, refsCount, refs))
    }
}

/// Opaque attribute in MLIR
public struct OpaqueAttr {
    public let raw: MlirAttribute

    /// Create a new OpaqueAttr with given dialect namespace and attribute data
    public static func get(dialectNamespace: String, attrData: String, type: MlirType, in context: MlirContext) -> OpaqueAttr {
        let namespaceRef = dialectNamespace.withCString { ptr in
            MlirStringRef(str: ptr, length: dialectNamespace.utf8.count)
        }
        let attrDataRef = attrData.withCString { ptr in
            MlirStringRef(str: ptr, length: attrData.utf8.count)
        }
        return OpaqueAttr(raw: mlirOpaqueAttrGet(context.raw, namespaceRef, attrDataRef, type))
    }
}

/// Strided layout attribute in MLIR
public struct StridedLayoutAttr {
    public let raw: MlirAttribute

    /// Create a new StridedLayoutAttr with a given offset and strides
    public static func get(context: MlirContext, offset: Int64, strides: [Int64]) -> StridedLayoutAttr {
        let stridesCount = UInt(strides.count)
        return strides.withUnsafeBufferPointer { stridesPtr in
            StridedLayoutAttr(raw: mlirStridedLayoutAttrGet(context.raw, offset, stridesPtr.baseAddress, stridesCount))
        }
    }
}

/// Dense elements attribute in MLIR
public struct DenseElementsAttr {
    public let raw: MlirAttribute

    /// Create a new DenseElementsAttr with given element type and raw buffer
    public static func get(type: MlirType, data: UnsafeBufferPointer<UInt8>) -> DenseElementsAttr {
        DenseElementsAttr(raw: mlirDenseElementsAttrGet(type, data.baseAddress, data.count))
    }

    /// Create a new DenseElementsAttr with a splat value
    public static func getSplat(type: MlirType, value: MlirAttribute) -> DenseElementsAttr {
        DenseElementsAttr(raw: mlirDenseElementsAttrSplatGet(type, value))
    }
}

/// Dense boolean elements attribute in MLIR
public struct DenseBoolElementsAttr {
    public let raw: MlirAttribute

    /// Create a new DenseBoolElementsAttr with given type and boolean array
    public static func get(type: MlirType, values: [Bool]) -> DenseBoolElementsAttr {
        let boolValues = values.map { $0 ? 1 : 0 }
        let count = UInt(boolValues.count)
        return boolValues.withUnsafeBufferPointer { ptr in
            DenseBoolElementsAttr(raw: mlirDenseBoolElementsAttrGet(type, ptr.baseAddress, count))
        }
    }
}

/// Dense 8-bit integer elements attribute in MLIR
public struct DenseI8ElementsAttr {
    public let raw: MlirAttribute

    /// Create a new DenseI8ElementsAttr with given type and 8-bit integer array
    public static func get(type: MlirType, values: [Int8]) -> DenseI8ElementsAttr {
        let count = UInt(values.count)
        return values.withUnsafeBufferPointer { ptr in
            DenseI8ElementsAttr(raw: mlirDenseI8ElementsAttrGet(type, ptr.baseAddress, count))
        }
    }
}

/// Dense 16-bit integer elements attribute in MLIR
public struct DenseI16ElementsAttr {
    public let raw: MlirAttribute

    /// Create a new DenseI16ElementsAttr with given type and 16-bit integer array
    public static func get(type: MlirType, values: [Int16]) -> DenseI16ElementsAttr {
        let count = UInt(values.count)
        return values.withUnsafeBufferPointer { ptr in
            DenseI16ElementsAttr(raw: mlirDenseI16ElementsAttrGet(type, ptr.baseAddress, count))
        }
    }
}

/// Dense 32-bit integer elements attribute in MLIR
public struct DenseI32ElementsAttr {
    public let raw: MlirAttribute

    /// Create a new DenseI32ElementsAttr with given type and 32-bit integer array
    public static func get(type: MlirType, values: [Int32]) -> DenseI32ElementsAttr {
        let count = UInt(values.count)
        return values.withUnsafeBufferPointer { ptr in
            DenseI32ElementsAttr(raw: mlirDenseI32ElementsAttrGet(type, ptr.baseAddress, count))
        }
    }
}

/// Dense 64-bit integer elements attribute in MLIR
public struct DenseI64ElementsAttr {
    public let raw: MlirAttribute

    /// Create a new DenseI64ElementsAttr with given type and 64-bit integer array
    public static func get(type: MlirType, values: [Int64]) -> DenseI64ElementsAttr {
        let count = UInt(values.count)
        return values.withUnsafeBufferPointer { ptr in
            DenseI64ElementsAttr(raw: mlirDenseI64ElementsAttrGet(type, ptr.baseAddress, count))
        }
    }
}

/// Dense 32-bit float elements attribute in MLIR
public struct DenseF32ElementsAttr {
    public let raw: MlirAttribute

    /// Create a new DenseF32ElementsAttr with given type and 32-bit float array
    public static func get(type: MlirType, values: [Float]) -> DenseF32ElementsAttr {
        let count = UInt(values.count)
        return values.withUnsafeBufferPointer { ptr in
            DenseF32ElementsAttr(raw: mlirDenseF32ElementsAttrGet(type, ptr.baseAddress, count))
        }
    }
}

/// Dense 64-bit float elements attribute in MLIR
public struct DenseF64ElementsAttr {
    public let raw: MlirAttribute

    /// Create a new DenseF64ElementsAttr with given type and 64-bit float array
    public static func get(type: MlirType, values: [Double]) -> DenseF64ElementsAttr {
        let count = UInt(values.count)
        return values.withUnsafeBufferPointer { ptr in
            DenseF64ElementsAttr(raw: mlirDenseF64ElementsAttrGet(type, ptr.baseAddress, count))
        }
    }
}

// TODO: add wrappers for other DenseElementsAttr specializations (e.g., DenseFPElementsAttr, DenseIntElementsAttr, DenseResourceElementsAttr) 