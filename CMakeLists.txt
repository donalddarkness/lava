cmake_minimum_required(VERSION 3.22)
project(SwiftMLIR LANGUAGES C CXX Swift)

# Find MLIR via llvm-config
find_package(MLIR REQUIRED CONFIG)
include_directories(${MLIR_INCLUDE_DIRS})

# Include our C modulemap for MLIR C API
include_directories(cmlir)

# Build Swift library wrapping MLIR C API
add_library(MLIRSwift SHARED
    Sources/MLIRSwift/lib.swift
)
# Link against C API IR library
target_link_libraries(MLIRSwift PRIVATE MLIRCAPIIR)

# Example executable that uses MLIRSwift
add_executable(myapp
    Sources/MyMLIRApp/main.swift
)
target_link_libraries(myapp PRIVATE MLIRSwift) 