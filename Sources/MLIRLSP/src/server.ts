import {
    createConnection,
    TextDocuments,
    Diagnostic,
    DiagnosticSeverity,
    ProposedFeatures,
    InitializeParams,
    DidChangeConfigurationNotification,
    CompletionItem,
    CompletionItemKind,
    TextDocumentPositionParams,
    TextDocumentSyncKind,
    InitializeResult,
    Hover,
    MarkupContent,
    MarkupKind
} from 'vscode-languageserver/node';

import {
    TextDocument
} from 'vscode-languageserver-textdocument';

// Create a connection for the server
const connection = createConnection(ProposedFeatures.all);

// Create a text document manager
const documents: TextDocuments<TextDocument> = new TextDocuments(TextDocument);

// MLIR type definitions for completion
const mlirTypes = [
    { label: 'i1', kind: CompletionItemKind.Type, detail: '1-bit integer' },
    { label: 'i8', kind: CompletionItemKind.Type, detail: '8-bit integer' },
    { label: 'i16', kind: CompletionItemKind.Type, detail: '16-bit integer' },
    { label: 'i32', kind: CompletionItemKind.Type, detail: '32-bit integer' },
    { label: 'i64', kind: CompletionItemKind.Type, detail: '64-bit integer' },
    { label: 'f16', kind: CompletionItemKind.Type, detail: '16-bit float' },
    { label: 'f32', kind: CompletionItemKind.Type, detail: '32-bit float' },
    { label: 'f64', kind: CompletionItemKind.Type, detail: '64-bit float' },
    { label: 'index', kind: CompletionItemKind.Type, detail: 'Index type' },
    { label: 'memref', kind: CompletionItemKind.Type, detail: 'Memory reference type' },
    { label: 'tensor', kind: CompletionItemKind.Type, detail: 'Tensor type' },
    { label: 'vector', kind: CompletionItemKind.Type, detail: 'Vector type' }
];

// MLIR operation keywords for completion
const mlirOperations = [
    { label: 'func', kind: CompletionItemKind.Keyword, detail: 'Function definition' },
    { label: 'module', kind: CompletionItemKind.Keyword, detail: 'Module definition' },
    { label: 'return', kind: CompletionItemKind.Keyword, detail: 'Return operation' },
    { label: 'arith.addi', kind: CompletionItemKind.Function, detail: 'Integer addition' },
    { label: 'arith.subi', kind: CompletionItemKind.Function, detail: 'Integer subtraction' },
    { label: 'arith.muli', kind: CompletionItemKind.Function, detail: 'Integer multiplication' },
    { label: 'arith.divi', kind: CompletionItemKind.Function, detail: 'Integer division' }
];

let hasConfigurationCapability = false;
let hasWorkspaceFolderCapability = false;
let hasDiagnosticRelatedInformationCapability = false;

connection.onInitialize((params: InitializeParams) => {
    const capabilities = params.capabilities;

    // Does the client support the `workspace/configuration` request?
    hasConfigurationCapability = !!(
        capabilities.workspace && !!capabilities.workspace.configuration
    );
    hasWorkspaceFolderCapability = !!(
        capabilities.workspace && !!capabilities.workspace.workspaceFolders
    );
    hasDiagnosticRelatedInformationCapability = !!(
        capabilities.textDocument &&
        capabilities.textDocument.publishDiagnostics &&
        capabilities.textDocument.publishDiagnostics.relatedInformation
    );

    const result: InitializeResult = {
        capabilities: {
            textDocumentSync: TextDocumentSyncKind.Incremental,
            // Tell the client that this server supports code completion
            completionProvider: {
                resolveProvider: true,
                triggerCharacters: ['.', ':', '<', '>', '!', '%']
            },
            // Tell the client that this server supports hover
            hoverProvider: true
        }
    };

    if (hasWorkspaceFolderCapability) {
        result.capabilities.workspace = {
            workspaceFolders: {
                supported: true
            }
        };
    }

    return result;
});

connection.onInitialized(() => {
    if (hasConfigurationCapability) {
        // Register for all configuration changes
        connection.client.register(DidChangeConfigurationNotification.type, undefined);
    }
    if (hasWorkspaceFolderCapability) {
        connection.workspace.onDidChangeWorkspaceFolders(_event => {
            connection.console.log('Workspace folder change event received.');
        });
    }
});

// The example settings
interface ExampleSettings {
    maxNumberOfProblems: number;
}

// The global settings, used when the `workspace/configuration` request is not supported by the client
const defaultSettings: ExampleSettings = { maxNumberOfProblems: 1000 };
let globalSettings: ExampleSettings = defaultSettings;

// Cache the settings of all open documents
const documentSettings: Map<string, Thenable<ExampleSettings>> = new Map();

connection.onDidChangeConfiguration(change => {
    if (hasConfigurationCapability) {
        // Reset all cached document settings
        documentSettings.clear();
    } else {
        globalSettings = <ExampleSettings>(
            (change.settings.mlirLsp || defaultSettings)
        );
    }

    // Revalidate all open text documents
    documents.all().forEach(validateTextDocument);
});

function getDocumentSettings(resource: string): Thenable<ExampleSettings> {
    if (!hasConfigurationCapability) {
        return Promise.resolve(globalSettings);
    }
    let result = documentSettings.get(resource);
    if (!result) {
        result = connection.workspace.getConfiguration({
            scopeUri: resource,
            section: 'mlirLsp'
        });
        documentSettings.set(resource, result);
    }
    return result;
}

// Only keep settings for open documents
documents.onDidClose(e => {
    documentSettings.delete(e.document.uri);
});

// The content of a text document has changed. This event is emitted by the client
documents.onDidChangeContent(change => {
    validateTextDocument(change.document);
});

async function validateTextDocument(textDocument: TextDocument): Promise<void> {
    // In this simple example we get the settings for every validate run
    const settings = await getDocumentSettings(textDocument.uri);

    // The validator creates diagnostics for all uppercase words length 2 and more
    const text = textDocument.getText();
    const pattern = /\b[A-Z]{2,}\b/g;
    let m: RegExpExecArray | null;

    let problems = 0;
    const diagnostics: Diagnostic[] = [];
    while ((m = pattern.exec(text)) && problems < settings.maxNumberOfProblems) {
        problems++;
        const diagnostic: Diagnostic = {
            severity: DiagnosticSeverity.Warning,
            range: {
                start: textDocument.positionAt(m.index),
                end: textDocument.positionAt(m.index + m[0].length)
            },
            message: `${m[0]} is all uppercase.`,
            source: 'MLIR LSP'
        };
        if (hasDiagnosticRelatedInformationCapability) {
            diagnostic.relatedInformation = [
                {
                    location: {
                        uri: textDocument.uri,
                        range: Object.assign({}, diagnostic.range)
                    },
                    message: 'Spelling matters'
                }
            ];
        }
        diagnostics.push(diagnostic);
    }

    // Send the computed diagnostics to VSCode
    connection.sendDiagnostics({ uri: textDocument.uri, diagnostics });
}

connection.onDidChangeWatchedFiles(_change => {
    // Monitored files have change in VSCode
    connection.console.log('We received a file change event');
});

// This handler provides the initial list of completion items
connection.onCompletion(
    (_textDocumentPosition: TextDocumentPositionParams): CompletionItem[] => {
        // The pass parameter contains the position of the text document in
        // which code complete got requested. For the example we ignore this
        // info and always provide the same completion items.
        return [...mlirTypes, ...mlirOperations];
    }
);

// This handler resolves additional information for the item selected in
// the completion list
connection.onCompletionResolve(
    (item: CompletionItem): CompletionItem => {
        if (item.data === 1) {
            item.detail = 'MLIR type';
            item.documentation = 'A MLIR type definition';
        } else if (item.data === 2) {
            item.detail = 'MLIR operation';
            item.documentation = 'A MLIR operation definition';
        }
        return item;
    }
);

// This handler provides hover information
connection.onHover(
    (_textDocumentPosition: TextDocumentPositionParams): Hover | null => {
        const text = documents.get(_textDocumentPosition.textDocument.uri)?.getText();
        if (!text) return null;

        const position = _textDocumentPosition.position;
        const offset = documents.get(_textDocumentPosition.textDocument.uri)?.offsetAt(position);
        if (offset === undefined) return null;

        // Simple hover implementation - show type information for known types
        for (const type of mlirTypes) {
            const index = text.indexOf(type.label, offset - type.label.length);
            if (index !== -1 && index <= offset && index + type.label.length >= offset) {
                const contents: MarkupContent = {
                    kind: MarkupKind.Markdown,
                    value: `**${type.label}**\n\n${type.detail}`
                };
                return {
                    contents,
                    range: {
                        start: documents.get(_textDocumentPosition.textDocument.uri)!.positionAt(index),
                        end: documents.get(_textDocumentPosition.textDocument.uri)!.positionAt(index + type.label.length)
                    }
                };
            }
        }

        return null;
    }
);

// Make the text document manager listen on the connection
// for open, change and close text document events
documents.listen(connection);

// Listen on the connection
connection.listen(); 