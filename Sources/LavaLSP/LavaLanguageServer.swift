        // Constants for LSP symbol kinds with proper enum structure
        @Final
        public enum SymbolKind: Int, Codable, CaseIterable {
            case file = 1, module = 2, namespace = 3, package = 4, class_ = 5, method = 6,
                 property = 7, field = 8, constructor = 9, enum_ = 10, interface = 11,
                 function = 12, variable = 13, constant = 14, string = 15, number = 16,
                 boolean = 17, array = 18, object = 19, key = 20, null = 21, enumMember = 22,
                 struct = 23, event = 24, operator_ = 25, typeParameter = 26
        }

        // Constants for LSP completion item kinds with proper enum structure
        @Final
        public enum CompletionItemKind: Int, Codable, CaseIterable {
            case text = 1
            case method = 2
            case function = 3
            case constructor = 4
            case field = 5
            case variable = 6
            case class_ = 7
            case interface = 8
            case module = 9
            case property = 10
            case keyword = 14
            case snippet = 15
        }

        // Constants for LSP diagnostic severity with proper enum structure
        @Final
        public enum DiagnosticSeverity: Int, Codable {
            case error = 1
            case warning = 2
            case information = 3
            case hint = 4
        }

        // Singleton instance with thread-safe lazy initialization
        public static let shared: LavaLanguageServer = {
            let instance = LavaLanguageServer()
            return instance
        }()

        // Connection to the client with thread safety
        private var connection: Connection?

        // Cache to avoid repeating expensive operations
        private var parseCache: NSCache<NSString, AnyObject> = {
            let cache = NSCache<NSString, AnyObject>()
            cache.countLimit = 100 // Limit cache size
            cache.totalCostLimit = 10 * 1024 * 1024 // 10MB limit
            return cache
        }()

        // Document storage with URI indexing using concurrent dictionary for thread safety
        private let documents = ThreadSafeDictionary<String, Document>()

        // Symbol cache for faster lookups with URI indexing
        private let symbolCache = ThreadSafeDictionary<String, [Symbol]>()

        // Document change queue for processing changes in order with QoS
        private let documentChangeQueue = DispatchQueue(label: "com.lava.lsp.documentChanges",
                                                      qos: .userInitiated,
                                                      attributes: .concurrent)

        // Configuration settings with defaults using strongly-typed Storage class
        private var settings = ServerSettings()

        // Keywords and builtin functions for syntax highlighting and completion
        // Organized into categories for better management
        private let keywords: [String: [String]] = #buildDictionary {
            "access": ["public", "private", "protected", "internal", "fileprivate"]
            "declaration": ["class", "struct", "enum", "interface", "extension", "protocol"]
            "storage": ["static", "final", "override", "const", "var", "let"]
            "control": ["if", "else", "for", "while", "do", "switch", "case", "default", "break", "continue", "return", "guard"]
            "exception": ["try", "catch", "throws", "throw", "defer"]
            "other": ["import", "true", "false", "nil", "self", "super", "in", "where", "as", "is", "any", "some"]
        }

        private let builtinFunctions: [String: [String]] = #buildDictionary {
            "text": ["append", "appendLine", "appendStyled", "addPlaceholder", "replacePlaceholder", "clear", "toString"]
            "concurrency": ["synchronized", "runOnMainThread", "runInBackground", "sleep", "await", "async"]
            "reflection": ["getSymbolName", "typeOf", "sizeof"]
            "processing": ["format", "compile", "parse", "execute", "validate"]
        }

        // Regular expressions for syntax analysis compiled once for efficiency
        private lazy var classRegex = #regex("class\\s+([A-Za-z0-9_]+)")
        private lazy var methodRegex = #regex("func\\s+([A-Za-z0-9_]+)")
        private lazy var variableRegex = #regex("(var|let)\\s+([A-Za-z0-9_]+)(?::\\s*([A-Za-z0-9_<>`[\]?\!]+))?")
        private lazy var stringLiteralRegex = #regex("\"(?:[^\"\\\\]|\\\\.)*\""")
        private lazy var commentRegex = #regex("(/\\*[^*]*\\*+(?:[^/*][^*]*\\*+)*/|//.*$)", options: [.anchorsMatchLines])

        // Server settings model
        @JavaBuilder
        public class ServerSettings: JavaSerializable {
            var maxNumberOfProblems: Int = 100
            var tabSize: Int = 4
            var formatOnType: Bool = true
            var formatOnSave: Bool = false
            var cacheEnabled: Bool = true
            var diagnosticsEnabled: Bool = true
            var semanticHighlightingEnabled: Bool = true
            var performanceMode: String = "balanced" // options: minimal, balanced, maximal
            var memoryLimit: Int = 512 // MB
            var maxFileSize: Int = 5 // MB

            func serialize() -> Data? {
                let dict: [String: Any] = #buildDictionary {
                    "maxNumberOfProblems": maxNumberOfProblems
                    "tabSize": tabSize
                    "formatOnType": formatOnType
                    "formatOnSave": formatOnSave
                    "cacheEnabled": cacheEnabled
                    "diagnosticsEnabled": diagnosticsEnabled
                    "semanticHighlightingEnabled": semanticHighlightingEnabled
                    "performanceMode": performanceMode
                    "memoryLimit": memoryLimit
                    "maxFileSize": maxFileSize
                }
                return try? JSONSerialization.data(withJSONObject: dict)
            }

            static func deserialize(from data: Data) -> ServerSettings? {
                guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    return nil
                }

                let settings = ServerSettings()
                settings.maxNumberOfProblems = dict["maxNumberOfProblems"] as? Int ?? 100
                settings.tabSize = dict["tabSize"] as? Int ?? 4
                settings.formatOnType = dict["formatOnType"] as? Bool ?? true
                settings.formatOnSave = dict["formatOnSave"] as? Bool ?? false
                settings.cacheEnabled = dict["cacheEnabled"] as? Bool ?? true
                settings.diagnosticsEnabled = dict["diagnosticsEnabled"] as? Bool ?? true
                settings.semanticHighlightingEnabled = dict["semanticHighlightingEnabled"] as? Bool ?? true
                settings.performanceMode = dict["performanceMode"] as? String ?? "balanced"
                settings.memoryLimit = dict["memoryLimit"] as? Int ?? 512
                settings.maxFileSize = dict["maxFileSize"] as? Int ?? 5

                return settings
            }
        }

        // Symbol structure for code navigation
        public struct Symbol: Codable, Hashable {
            let name: String
            let kind: SymbolKind
            let range: Range<Int>
            let uri: String
            let containerName: String?

            public func hash(into hasher: inout Hasher) {
                hasher.combine(name)
                hasher.combine(uri)
                hasher.combine(range.lowerBound)
            }
        }

        // ThreadSafe dictionary implementation
        public class ThreadSafeDictionary<K: Hashable, V> {
            private var dictionary: [K: V] = [:]
            private let queue = DispatchQueue(label: "com.lava.lsp.threadsafedictionary", attributes: .concurrent)

            public func value(forKey key:combine(range.upperBound)
                hasher.combine(type)
            }
        }

        // Get all word ranges in a line for efficient lookup
        func getWordRangesForLine(line: Int) -> [(range: Range<String.Index>, word: String)] {
            // Check cache first
            if let cached = wordRangesCache?[line] {
                return cached
            }

            // Split by lines only if needed
            let lineContent: String
            if let lineOffsets = self.lineOffsets, line < lineOffsets.count {
                let startOffset = lineOffsets[line]
                let endOffset = line + 1 < lineOffsets.count ? lineOffsets[line + 1] - 1 : content.count
                let startIndex = content.index(content.startIndex, offsetBy: startOffset)
                let endIndex = content.index(content.startIndex, offsetBy: min(endOffset, content.count))
                lineContent = String(content[startIndex..<endIndex])
            } else {
                // Fallback to component splitting (less efficient)
                let lines = content.components(separatedBy: "\n")
                guard line < lines.count else { return [] }
                lineContent = lines[line]
            }

            var ranges: [(Range<String.Index>, String)] = []

            // Use regex for better word boundary detection
            let wordPattern = #regex("\\b[A-Za-z0-9_]+\\b")
            let nsLineContent = lineContent as NSString
            let fullRange = NSRange(location: 0, length: nsLineContent.length)

            if let matches = wordPattern.matches(in: lineContent, options: [], range: fullRange) {
                for match in matches {
                    if let range = Range(match.range, in: lineContent) {
                        let word = String(lineContent[range])
                        ranges.append((range, word))
                    }
                }
            }

            // Cache the result
            if wordRangesCache == nil {
                wordRangesCache = [:]
            }
            wordRangesCache?[line] = ranges

            return ranges
        }
    }
}
// Constants for LSP symbol kinds with proper enum structure
@Final
public enum SymbolKind: Int, Codable, CaseIterable, Sendable {
    case file = 1, module = 2, namespace = 3, package = 4, class_ = 5, method = 6,
         property = 7, field = 8, constructor = 9, enum_ = 10, interface = 11,
         function = 12, variable = 13, constant = 14, string
 = 15, number = 16,
         boolean = 17, array = 18, object = 19, key = 20,
