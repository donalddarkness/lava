# MLIR Language Server

A Language Server Protocol (LSP) implementation for MLIR, providing features like code completion, hover information, and syntax highlighting in VS Code.

## Features

- Syntax highlighting for MLIR files
- Code completion for MLIR types and operations
- Hover information for MLIR types and operations
- Basic diagnostics (warnings for uppercase words)
- Support for MLIR-specific language features

## Requirements

- Node.js 16.x or later
- VS Code 1.82.0 or later

## Installation

1. Clone this repository
2. Run `npm install` to install dependencies
3. Run `npm run compile` to build the extension
4. Press F5 in VS Code to start debugging

## Development

1. Make sure you have all the dependencies installed:
   ```bash
   npm install
   ```

2. Compile the extension:
   ```bash
   npm run compile
   ```

3. To start debugging:
   - Open the project in VS Code
   - Press F5 to start debugging
   - A new VS Code window will open with the extension loaded

4. To watch for changes:
   ```bash
   npm run watch
   ```

## Testing

Run the test suite:
```bash
npm test
```

## Extension Settings

This extension contributes the following settings:

* `mlirLsp.maxNumberOfProblems`: Controls the maximum number of problems produced by the server.

## Known Issues

- The current implementation provides basic MLIR support. More advanced features like:
  - Semantic analysis
  - Go to definition
  - Find references
  - Symbol search
  will be added in future versions.

## Release Notes

### 0.1.0

Initial release of MLIR Language Server with:
- Basic syntax highlighting
- Code completion for MLIR types and operations
- Hover information
- Simple diagnostics

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details. 