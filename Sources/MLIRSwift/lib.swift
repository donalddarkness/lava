// Swift wrapper around MLIR C API
import CMLIR

public func makeContext() -> MlirContext {
    // Create and return a new MLIR context
    return mlirContextCreate()
}

/// Parse MLIR text into a module
public func parseModule(_ text: String, context: MlirContext) -> MlirModule {
    return text.withCString { ptr in
        var sref = MlirStringRef(str: ptr, length: text.utf8.count)
        return mlirParseSourceString(sref, context)
    }
}

/// Print a module to stdout
public func printModule(_ module: MlirModule) {
    mlirModulePrint(module, { (cstr, length, _) in
        let data = Data(bytes: cstr!, count: Int(length))
        if let s = String(data: data, encoding: .utf8) {
            print(s, terminator: "")
        }
    }, nil)
}

/// Create an OpBuilder at a location (default unknown)
public func makeBuilder(_ context: MlirContext, location: MlirLocation = mlirLocationUnknown()) -> MlirOpBuilder {
    return mlirOpBuilderCreate(context, location)
}

/// Create an empty MLIR module
public func createModule(_ name: String, context: MlirContext) -> MlirModule {
    return name.withCString { ptr in
        let sref = MlirStringRef(str: ptr, length: name.utf8.count)
        return mlirModuleCreateEmpty(sref, context)
    }
}

/// Append a new block to the module's body region and return it
public func appendBlock(to module: MlirModule) -> MlirBlock {
    let body = mlirModuleGetBody(module)
    let block = mlirBlockCreate(nil, 0)
    mlirRegionAppendOwnedBlock(body, block)
    return block
}

/// Set builder insertion point to the end of a block
public func setInsertionPoint(to block: MlirBlock, with builder: MlirOpBuilder) {
    mlirOpBuilderSetInsertionPointToEnd(builder, block)
}

/// Create a generic operation with operands, results, and attributes
public func createOp(
    builder: MlirOpBuilder,
    name: String,
    operands: [MlirValue] = [],
    results: [MlirType] = [],
    attributes: [(String, MlirAttribute)] = []
) -> MlirOperation {
    // Initialize operation state
    let nameRef = name.withCString { ptr in
        MlirStringRef(str: ptr, length: name.utf8.count)
    }
    var state = MlirOperationState(name: nameRef)
    mlirOperationStateInit(&state, nameRef)
    
    // Add operands
    if !operands.isEmpty {
        mlirOperationStateAddOperands(&state, operands, Int64(operands.count))
    }
    // Add results
    if !results.isEmpty {
        mlirOperationStateAddResults(&state, results, Int64(results.count))
    }
    // Add attributes
    if !attributes.isEmpty {
        var namedAttrs: [MlirNamedAttribute] = []
        namedAttrs.reserveCapacity(attributes.count)
        for (key, attr) in attributes {
            let keyRef = key.withCString { p in MlirStringRef(str: p, length: key.utf8.count) }
            namedAttrs.append(mlirNamedAttributeGet(keyRef, attr))
        }
        mlirOperationStateAddAttributes(&state, namedAttrs, Int64(namedAttrs.count))
    }
    return mlirOpBuilderCreateOperation(builder, state)
}

/// Helper: create an integer type in MLIR
public func integerType(_ context: MlirContext, width: UInt32) -> MlirType {
    return mlirIntegerTypeGet(context, width)
}

/// Helper: create a 32-bit float type in MLIR
public func f32Type(_ context: MlirContext) -> MlirType {
    return mlirF32TypeGet(context)
}

/// Helper: create an integer attribute
public func integerAttr(type: MlirType, value: Int64) -> MlirAttribute {
    return mlirIntegerAttrGet(type, value)
} 