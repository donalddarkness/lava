import CMLIR

/// Wraps an MLIR DialectRegistry for registering dialects in Swift
public class DialectRegistry {
    /// Raw MLIR registry handle
    public let raw: MlirDialectRegistry

    /// Create a new empty registry
    public init() {
        raw = mlirDialectRegistryCreate()
    }

    /// Insert a dialect by its namespace
    public func insertDialect(byNamespace namespace: String) {
        namespace.withCString { ptr in
            mlirDialectRegistryInsert(raw, ptr)
        }
    }

    /// Insert the Standard dialect
    public func insertStandard() {
        insertDialect(byNamespace: mlirStandardDialectGetDialectNamespace())
    }

    /// Insert the Affine dialect
    public func insertAffine() {
        insertDialect(byNamespace: mlirAffineDialectGetDialectNamespace())
    }

    /// Insert the LLVM dialect
    public func insertLLVM() {
        insertDialect(byNamespace: mlirLLVMDialectGetDialectNamespace())
    }

    /// Insert the SCF dialect
    public func insertSCF() {
        insertDialect(byNamespace: mlirSCFDialectGetDialectNamespace())
    }

    /// Insert the Func dialect
    public func insertFunc() {
        insertDialect(byNamespace: mlirFuncDialectGetDialectNamespace())
    }

    /// Insert the Arith dialect
    public func insertArith() {
        insertDialect(byNamespace: mlirArithDialectGetDialectNamespace())
    }

    /// Insert the MemRef dialect
    public func insertMemRef() {
        insertDialect(byNamespace: mlirMemRefDialectGetDialectNamespace())
    }

    /// Insert the Tensor dialect
    public func insertTensor() {
        insertDialect(byNamespace: mlirTensorDialectGetDialectNamespace())
    }

    /// Insert the Linalg dialect
    public func insertLinalg() {
        insertDialect(byNamespace: mlirLinalgDialectGetDialectNamespace())
    }

    /// Insert the Vector dialect
    public func insertVector() {
        insertDialect(byNamespace: mlirVectorDialectGetDialectNamespace())
    }

    /// Insert the Math dialect
    public func insertMath() {
        insertDialect(byNamespace: mlirMathDialectGetDialectNamespace())
    }

    /// Insert the SPIR-V dialect
    public func insertSPIRV() {
        insertDialect(byNamespace: mlirSPIRVDialectGetDialectNamespace())
    }

    /// Insert the OpenMP dialect
    public func insertOpenMP() {
        insertDialect(byNamespace: mlirOpenMPDialectGetDialectNamespace())
    }

    /// Insert the GPU dialect
    public func insertGPU() {
        insertDialect(byNamespace: mlirGPUDialectGetDialectNamespace())
    }

    /// Insert the NVVM dialect
    public func insertNVVM() {
        insertDialect(byNamespace: mlirNVVMDialectGetDialectNamespace())
    }

    /// Insert the ROCDL dialect
    public func insertROCDL() {
        insertDialect(byNamespace: mlirROCDLDialectGetDialectNamespace())
    }
}

public extension DialectRegistry {
    /// Load all registered dialects into a context
    /// - Parameter context: the MLIR context to load dialects into
    func loadAll(into context: MlirContext) {
        mlirDialectRegistryLoadAll(raw, context.raw)
    }
} 