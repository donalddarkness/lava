import Foundation

/// The entry point for the Lava DSL Language Server.
///
/// Initializes logging to `lava-lsp.log` in the user's home directory and starts the message
/// processing run-loop for `.lava` files over standard input/output.
let logFile = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("lava-lsp.log")
freopen(logFile.path, "a", stderr)

// Start the LavaLanguageServer run-loop
LavaLanguageServer.shared.run() 