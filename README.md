# OuroLang

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
│   ├── OuroLangCore/       # Core compiler components
│   │   ├── Lexer.swift     # Lexical analysis
│   │   ├── Token.swift     # Token definitions
│   │   ├── AST.swift       # Abstract Syntax Tree
│   │   └── Parser.swift    # Syntax analysis
│   ├── OuroCompiler/       # Compiler executable
│   ├── OuroTranspiler/     # Source-to-source translator
│   └── OuroLangLSP/        # Language Server Protocol implementation
├── Tests/
│   └── OuroLangCoreTests/  # Unit tests for compiler components
└── docs/                   # Documentation
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

Transpile OuroLang to another language:

```bash
swift run OuroTranspiler -t swift path/to/source.ouro
```

Use with your favorite editor through the Language Server:

```bash
swift run OuroLangLSP
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

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add some amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Swift compiler team for their excellent work on Swift
- The LLVM Project for their compiler infrastructure

---

© 2023 OuroLang Team