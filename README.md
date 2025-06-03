# OuroLang
[![CI Pipeline](https://github.com/yourusername/lava/actions/workflows/ci.yml/badge.svg)](https://github.com/yourusername/lava/actions/workflows/ci.yml)

OuroLang is a modern programming language designed for computational graphics, AI-driven visualizations, and high-performance applications with an elegant, expressive syntax.

## Project Status

> 🚧 **Early Development** - This project is in active development and not yet ready for production use.

## Overview

OuroLang combines the performance of low-level languages with the expressiveness of high-level languages, making it ideal for graphics programming, scientific computing, and AI applications. It features a clean, readable syntax inspired by modern programming languages.

Key features:

- **High Performance**: Compiled language with performance comparable to C++
- **Modern Syntax**: Clean, expressive, and easy to read
- **Type Safety**: Strong static typing with powerful type inference
- **Memory Safety**: Safe memory management without garbage collection overhead
- **Concurrency**: First-class support for concurrent and parallel programming
- **Graphics Focus**: Built-in primitives for computational graphics and visualization

## Project Structure

```
lava/
├── Sources/
│   ├── Lava/              # Core DSL implementation
│   ├── LavaDemo/          # Demo application
│   ├── OuroLangCore/      # Core compiler components
│   ├── OuroCompiler/      # Compiler executable
│   ├── OuroTranspiler/    # Source-to-source translator
│   ├── OuroLangLSP/       # Language Server Protocol for .ouro files
│   ├── LavaLSP/           # Language Server Protocol for .lava DSL files
│   └── CombinedLSP/       # Combined LSP handling both .ouro and .lava
│   ├── Tests/
│   │   └── OuroLangCoreTests/  # Unit tests for compiler components
│   └── docs/                   # Documentation
```

## Getting Started

### Prerequisites

- Swift 6.0 or higher
- Xcode 15+ (macOS) or Swift toolchain (Linux/Windows)

### Installation

Clone the repository:

```bash
git clone https://github.com/yourusername/lava.git
cd lava
```

Build the project:

```bash
swift build
```

Run the tests:

```bash
swift test
```

### Usage

Compile an OuroLang source file:

```bash
swift run OuroCompiler path/to/source.ouro
```

Transpile OuroLang to another language (Swift or C):

```bash
# Transpile to Swift
swift run OuroTranspiler -t swift path/to/source.ouro

# Transpile to C (ISO C11)
swift run OuroTranspiler -t c path/to/source.ouro

# Alternatively, use explicit C11 flag
swift run OuroTranspiler -t c11 path/to/source.ouro

# Transpile to C++23
swift run OuroTranspiler -t cpp path/to/source.ouro

# Alternatively, use explicit C++23 flag
swift run OuroTranspiler -t cpp23 path/to/source.ouro
```

Use with your favorite editor through the Language Server:

```bash
swift run OuroLangLSP
```

## Usage (Language Server)

Use the language server implementation for editor integrations:

```bash
# Run the OuroLang-only LSP server
swift run OuroLSP

# Run the Lava DSL-only LSP server
swift run LavaLSP

# Run the combined LSP server (handles both .ouro and .lava files)
swift run CombinedLSP
```

## Language Examples

### Hello World

```ouro
func main() {
    print("Hello, world!")
}
```

### Variables and Types

```ouro
// Type inference
var name = "John"
var age = 30

// Explicit typing
var height: Double = 1.85
var isActive: Bool = true

// Constants
const PI = 3.14159
```

### Functions

```ouro
func greet(name: String) -> String {
    return "Hello, ${name}!"
}

// Expression-bodied function
func square(x: Int) => x * x

// Generic function
func first<T>(array: [T]) -> T? {
    if (array.isEmpty) {
        return null
    }
    return array[0]
}
```

### Classes and Structures

```ouro
class Person {
    var name: String
    var age: Int
    
    init(name: String, age: Int) {
        this.name = name
        this.age = age
    }
    
    func greet() -> String {
        return "Hello, my name is ${name}!"
    }
}

struct Point {
    var x: Double
    var y: Double
    
    func distance(to other: Point) -> Double {
        return ((x - other.x) ** 2 + (y - other.y) ** 2).sqrt()
    }
}
```

### Codebase Integration
```ouro
// Import core modules from the codebase
import "Lava"
import "OuroLangCore"

func main() {
    let users = ["Alice", "Bob", "Charlie"]
    users.forEach(user => print("Hello, ${user}!"))
}
```

### Linter Errors
```ouro
// This example shows common linter errors detected
func calculateSum(a, b) { // Error: Missing type annotations for parameters
    return a + b
}

missingVar = 10 // Error: 'missingVar' is not declared
```

### Web Example
```ouro
// Simple HTTP server example
import "WebServer"

async func startServer() {
    let server = WebServer(port: 8080)
    await server.route("/", req => {
        return "Hello, .ouro Web!"
    })
    await server.listen()
}

startServer()
```

### Recent Changes
```ouro
// Demonstrates new 'async' and 'await' syntax from recent updates
async func fetchData() {
    let data = await HttpClient.get("https://api.example.com/data")
    print("Received: ${data}")
}

fetchData()
```

## Unified `Lava` API Examples

```

## Full README Walkthrough

This walkthrough will guide you through each part of this README:

- **Project Status**: Describes the current development phase and readiness of OuroLang.

- **Overview**: Explains the language goals, key features, and primary use cases (graphics, AI, high performance).

- **Project Structure**: Shows the directory layout under `lava/`, with core compiler components, executables, tests, and documentation.

- **Getting Started**:
  - *Prerequisites*: Software and toolchain requirements (Swift 6.0+, Xcode, etc.).
  - *Installation*: How to clone, build, and test the project using `swift build` and `swift test`.

- **Usage**: Commands to:
  - Compile a `.ouro` file with `OuroCompiler`.
  - Transpile to another language with `OuroTranspiler`.
  - Run the language server via `OuroLangLSP`.

- **Language Examples**: Code samples demonstrating:
  - Hello World
  - Variables, types, and constants
  - Functions (including generics and expression bodies)
  - Classes and structures

- **Codebase Integration**: Shows how to import the `Lava` and `OuroLangCore` modules and iterate over collections.

- **Linter Errors**: Illustrates common linting mistakes (missing type annotations, undeclared variables) and their error messages.

- **Web Example**: A minimal `WebServer` snippet using `async`/`

## Continuous Integration (CI Pipeline)

This project uses GitHub Actions to:
- Run on pushes and pull requests against `main`.
- Build and test on both macOS and Ubuntu using Swift 6.1.
- Run SwiftLint in strict mode on macOS.

## Documentation

The API reference and tutorials are automatically generated using DocC and published via GitHub Pages:

[https://yourusername.github.io/lava](https://yourusername.github.io/lava)