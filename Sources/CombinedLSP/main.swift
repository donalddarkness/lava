/// Combined LSP server handling both `.ouro` and `.lava` files.
///
/// Instantiates the OuroLang and Lava language servers, dispatching JSON-RPC requests
/// based on file extensions and forwarding responses over standard output.
/// Logging is directed to `combined-lsp.log` in the user's home directory.
import Foundation
import OuroLangLSP
import LavaLSP

print("CombinedLSP starting...")

// Setup logging to capture diagnostics
let logFile = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("combined-lsp.log")
freopen(logFile.path, "a", stderr)

// Helper to extract URI from LSP message
func extractURI(from message: [String: Any]) -> String? {
    if let params = message["params"] as? [String: Any],
       let textDoc = params["textDocument"] as? [String: Any],
       let uri = textDoc["uri"] as? String {
        return uri
    }
    return nil
}

// Helper to send JSON-RPC responses
func sendResponse(_ response: [String: Any]) {
    guard let data = try? JSONSerialization.data(withJSONObject: response, options: []),
          let content = String(data: data, encoding: .utf8) else {
        print("CombinedLSP: failed to serialize response", to: &StandardErrorOutputStream.instance)
        return
    }
    let header = "Content-Length: \(content.utf8.count)\r\n\r\n"
    FileHandle.standardOutput.write(Data(header.utf8))
    FileHandle.standardOutput.write(Data(content.utf8))
    FileHandle.standardOutput.synchronizeFile()
}

// Create instances of the LSP servers
let ouroServer = LSPServer()
let lavaServer = LavaLanguageServer.shared

// Main loop: read, dispatch, write
while true {
    // Read LSP message headers
    var contentLength: Int? = nil
    while let line = readLine(), !line.isEmpty {
        if line.lowercased().hasPrefix("content-length: ") {
            let value = line.dropFirst("Content-Length: ".count)
            contentLength = Int(value)
        }
    }
    guard let length = contentLength,
          let input = FileHandle.standardInput.readData(ofLength: length) as Data?,
          let json = try? JSONSerialization.jsonObject(with: input) as? [String: Any] else {
        break
    }
    // Dispatch based on URI
    if let uri = extractURI(from: json) {
        if uri.hasSuffix(".ouro") {
            let response = ouroServer.handleMessage(json)
            sendResponse(response)
        } else if uri.hasSuffix(".lava") {
            let response = lavaServer.handleMessage(json)
            sendResponse(response)
        } else {
            print("CombinedLSP: Skipping unsupported URI: \(uri)", to: &StandardErrorOutputStream.instance)
        }
    } else {
        print("CombinedLSP: Invalid LSP request: missing URI header", to: &StandardErrorOutputStream.instance)
    }
} 