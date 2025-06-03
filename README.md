OuroLang
CI Pipeline

OuroLang is a modern programming language designed for computational graphics, AI-driven visualizations, and high-performance applications with an elegant, expressive syntax.

⸻
🚀 Project Status
Early Development 🚧
This project is actively being developed and is not yet production-ready.

⸻
🌟 Overview
OuroLang bridges the performance of low-level languages with the clarity of high-level languages, making it ideal for:
Graphics Programming
Scientific Computing
AI Applications

🔑 Key Features
High Performance: Compiled for C++-level speed
Modern Syntax: Clean, expressive, and readable
Type Safety: Strong static typing with advanced inference
Memory Safety: Secure memory management without GC overhead
Concurrency: Built-in support for concurrent & parallel programming
Graphics Focus: Native support for computational graphics & visualization

⸻
📂 Project Structure
lava/
├── Sources/
│   ├── Lava/              # Core DSL implementation
│   ├── LavaDemo/          # Demo application
│   ├── OuroLangCore/      # Core compiler components
│   ├── OuroCompiler/      # Compiler executable
│   ├── OuroTranspiler/    # Source-to-source translator
│   ├── OuroLangLSP/       # Language Server Protocol for .ouro files
│   ├── LavaLSP/           # Language Server Protocol for .lava DSL files
│   └── CombinedLSP/       # Handles both .ouro & .lava files
├── Tests/
│   └── OuroLangCoreTests/ # Unit tests for compiler components
└── docs/                  # Documentation

⸻
⚡ Getting Started
✅ Prerequisites
Swift 6.0+
Xcode 15+ (macOS) or Swift Toolchain (Linux/Windows)

📥 Installation
git clone https://github.com/yourusername/lava.git
cd lava
swift build
swift test

🗒️ Usage
Compile OuroLang Source
swift run OuroCompiler path/to/source.ouro

Transpile to Other Languages
# Swift
swift run OuroTranspiler -t swift path/to/source.ouro

# C (ISO C11)
swift run OuroTranspiler -t c path/to/source.ouro

# C++23
swift run OuroTranspiler -t cpp path/to/source.ouro

Language Server Setup
swift run CombinedLSP  # Supports both .ouro & .lava

⸻
💡 Language Examples
👋 Hello World
func main() {
    print("Hello, world!")
}

📊 Variables & Types
var name = "John"        // Type inferred
var age: Int = 30        // Explicit type
const PI = 3.14159       // Constants

📦 Functions
func greet(name: String) -> String {
    return "Hello, ${name}!"
}

func square(x: Int) => x * x   // Expression-bodied

func first<T>(array: [T]) -> T? {
    return array.isEmpty ? null : array[0]
}

🏗️ Classes & Structures
class Person {
    var name: String
    var age: Int
    
    init(name: String, age: Int) {
        this.name = name
        this.age = age
    }
    
    func greet() -> String {
        return "Hello, I'm ${name}!"
    }
}

🌐 Simple Web Server
import "WebServer"

async func startServer() {
    let server = WebServer(port: 8080)
    await server.route("/", req => "Hello, Web!")
    await server.listen()
}

startServer()

⸻
🔍 Continuous Integration (CI Pipeline)
Triggers: On push & pull requests to main
Build/Test: macOS & Ubuntu with Swift 6.1
Linting: SwiftLint in strict mode (macOS)

⸻
📖 Documentation
API Reference & Tutorials: Auto-generated via DocC
Live Docs: https://donalddarkness.github.io/lava