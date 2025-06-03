//
//  main.swift
//  OuroLangLSP
//
//  Created by YourName on TodayDate.
//

import Foundation
import OuroLangCore

print("OuroLang Language Server starting...")

// Setup logging
let logFile = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("ouro-lsp.log")
freopen(logFile.path, "a", stderr)

class LSPServer {
    let standardInput = FileHandle.standardInput
    let standardOutput = FileHandle.standardOutput
    
    func run() {
        print("LSP server running...", to: &StandardErrorOutputStream.instance)
        
        do {
            while true {
                guard let message = readMessage() else {
                    print("End of input, shutting down server", to: &StandardErrorOutputStream.instance)
                    break
                }
                
                let response = handleMessage(message)
                try writeMessage(response)
            }
        } catch {
            print("Error: \(error)", to: &StandardErrorOutputStream.instance)
            exit(1)
        }
    }
    
    private func readMessage() -> [String: Any]? {
        // Read header
        var contentLength: Int? = nil
        
        while true {
            guard let line = readLine() else { return nil }
            
            if line.isEmpty {
                break // End of headers
            }
            
            if line.lowercased().hasPrefix("content-length: ") {
                let value = line.dropFirst("Content-Length: ".count)
                contentLength = Int(value)
            }
        }
        
        guard let length = contentLength else {
            print("Missing Content-Length header", to: &StandardErrorOutputStream.instance)
            return nil
        }
        
        // Read content
        guard let data = try? standardInput.read(upToCount: length),
              let content = String(data: data, encoding: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            print("Failed to parse JSON content", to: &StandardErrorOutputStream.instance)
            return nil
        }
        
        print("Received: \(content)", to: &StandardErrorOutputStream.instance)
        return json
    }
    
    private func handleMessage(_ message: [String: Any]) -> [String: Any] {
        // Extract the method and handle accordingly
        guard let method = message["method"] as? String else {
            return createErrorResponse(id: message["id"], code: -32600, message: "Invalid Request: Missing method")
        }
        
        print("Processing method: \(method)", to: &StandardErrorOutputStream.instance)
        
        switch method {
        case "initialize":
            return handleInitialize(message)
        case "initialized":
            return [:] // No response needed for notification
        case "shutdown":
            return ["id": message["id"] ?? NSNull(), "result": [:]]
        case "exit":
            exit(0)
        case "textDocument/didOpen":
            handleDidOpenTextDocument(message)
            return [:] // No response needed for notification
        case "textDocument/didChange":
            handleDidChangeTextDocument(message)
            return [:] // No response needed for notification
        case "textDocument/didClose":
            handleDidCloseTextDocument(message)
            return [:] // No response needed for notification
        case "textDocument/completion":
            return handleCompletion(message)
        case "textDocument/hover":
            return handleHover(message)
        default:
            print("Unhandled method: \(method)", to: &StandardErrorOutputStream.instance)
            return createErrorResponse(id: message["id"], code: -32601, message: "Method not found: \(method)")
        }
    }
    
    private func handleInitialize(_ message: [String: Any]) -> [String: Any] {
        // Send back server capabilities
        return [
            "id": message["id"] ?? NSNull(),
            "result": [
                "capabilities": [
                    "textDocumentSync": [
                        "openClose": true,
                        "change": 2 // Incremental
                    ],
                    "completionProvider": [
                        "resolveProvider": false,
                        "triggerCharacters": [".", ":"]
                    ],
                    "hoverProvider": true,
                    "definitionProvider": true
                ],
                "serverInfo": [
                    "name": "OuroLang Language Server",
                    "version": "0.1.0"
                ]
            ]
        ]
    }
    
    private func handleDidOpenTextDocument(_ message: [String: Any]) {
        // Process a document that was opened in the editor
        guard let params = message["params"] as? [String: Any],
              let textDocument = params["textDocument"] as? [String: Any],
              let uri = textDocument["uri"] as? String,
              let text = textDocument["text"] as? String else {
            return
        }
        
        // For now, just parse the document and report any syntax errors
        do {
            let lexer = Lexer(source: text)
            let tokens = try lexer.scanTokens()
            let parser = Parser(tokens: tokens)
            let _ = try parser.parse()
            
            // No errors, send empty diagnostics
            sendDiagnostics(uri: uri, diagnostics: [])
        } catch let error as LexerError {
            sendDiagnostics(uri: uri, diagnostics: [
                createDiagnostic(message: error.description, range: [0, 0, 0, 0], severity: 1) // 1 = Error
            ])
        } catch let error as ParserError {
            sendDiagnostics(uri: uri, diagnostics: [
                createDiagnostic(message: error.description, range: [0, 0, 0, 0], severity: 1)
            ])
        } catch {
            sendDiagnostics(uri: uri, diagnostics: [
                createDiagnostic(message: "Unknown error: \(error)", range: [0, 0, 0, 0], severity: 1)
            ])
        }
    }
    
    private func handleDidChangeTextDocument(_ message: [String: Any]) {
        // Process document changes
        // Similar to didOpen but with incremental changes
    }
    
    private func handleDidCloseTextDocument(_ message: [String: Any]) {
        // Clear any state for the document that was closed
    }
    
    private func handleCompletion(_ message: [String: Any]) -> [String: Any] {
        // Return completion items
        return [
            "id": message["id"] ?? NSNull(),
            "result": [
                // Example completions
                [
                    "label": "if",
                    "kind": 14,  // Keyword
                    "detail": "Control flow",
                    "insertText": "if ($1) {\n\t$0\n}"
                ],
                [
                    "label": "for",
                    "kind": 14,  // Keyword
                    "detail": "Loop",
                    "insertText": "for ($1 in $2) {\n\t$0\n}"
                ]
            ]
        ]
    }
    
    private func handleHover(_ message: [String: Any]) -> [String: Any] {
        // Return hover information
        return [
            "id": message["id"] ?? NSNull(),
            "result": [
                "contents": "Hover information would go here"
            ]
        ]
    }
    
    private func sendDiagnostics(uri: String, diagnostics: [[String: Any]]) {
        let notification: [String: Any] = [
            "jsonrpc": "2.0",
            "method": "textDocument/publishDiagnostics",
            "params": [
                "uri": uri,
                "diagnostics": diagnostics
            ]
        ]
        
        try? writeMessage(notification)
    }
    
    private func createDiagnostic(message: String, range: [Int], severity: Int) -> [String: Any] {
        return [
            "range": [
                "start": [
                    "line": range[0],
                    "character": range[1]
                ],
                "end": [
                    "line": range[2],
                    "character": range[3]
                ]
            ],
            "severity": severity,
            "message": message
        ]
    }
    
    private func createErrorResponse(id: Any?, code: Int, message: String) -> [String: Any] {
        return [
            "id": id ?? NSNull(),
            "error": [
                "code": code,
                "message": message
            ]
        ]
    }
    
    private func writeMessage(_ message: [String: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: message, options: [])
        let content = String(data: data, encoding: .utf8)!
        
        let header = "Content-Length: \(content.utf8.count)\r\n\r\n"
        standardOutput.write(header.data(using: .utf8)!)
        standardOutput.write(content.data(using: .utf8)!)
        standardOutput.synchronize()
        
        print("Sent: \(content)", to: &StandardErrorOutputStream.instance)
    }
    
    private func readLine() -> String? {
        var line = ""
        var byte = [UInt8](repeating: 0, count: 1)
        
        while true {
            let bytesRead = standardInput.read(&byte, maxLength: 1)
            if bytesRead == 0 {
                return nil // EOF
            }
            
            if byte[0] == 13 { // CR
                continue // Skip CR
            }
            
            if byte[0] == 10 { // LF
                return line // End of line
            }
            
            line.append(Character(UnicodeScalar(byte[0])))
        }
    }
}

// For logging to stderr
class StandardErrorOutputStream: TextOutputStream {
    static var instance = StandardErrorOutputStream()
    private init() {}
    
    func write(_ string: String) {
        fputs(string, stderr)
    }
}

// Start the server
let server = LSPServer()
server.run()