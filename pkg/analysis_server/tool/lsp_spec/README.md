# Language Server Protocol

[Language Server Protocol](https://microsoft.github.io/language-server-protocol/) (LSP) support is available in the Dart analysis server from version 2.2.0 of the SDK (which was included in version 1.2.1 of Flutter). The supported messages are detailed below (for the version of the SDK that matches this README).

## Using the Dart LSP server in editors

- [Using LSP with Dart-Vim](https://github.com/dart-lang/dart-vim-plugin/blob/master/README.md#how-do-i-configure-an-lsp-plugin-to-start-the-analysis-server)

## Running the Server

The analysis server snapshot is included in the `bin/snapshots` folder of the Dart SDK. Pass the `--lsp` flag to start the server in LSP mode:

```
dart bin/snapshots/analysis_server.dart.snapshot --lsp
```

Note: In LSP the client makes the first request so there is no obvious confirmation that the server is working correctly until the client sends an `initialize` request. Unlike standard JSON RPC, [LSP requires that headers are sent](https://microsoft.github.io/language-server-protocol/specification).

## Initialization Options

- `onlyAnalyzeProjectsWithOpenFiles`: When set to `true`, analysis will only be performed for projects that have open files rather than the root workspace folder. Defaults to `false`.
- `suggestFromUnimportedLibraries`: When set to `false`, completion will not include synbols that are not already imported into the current file. Defaults to `true`, though the client must additionally support `workspace/applyEdit` for these completions to be included.
- `closingLabels`: When set to `true`, `dart/textDocument/publishClosingLabels` notifications will be sent with information to render editor closing labels.
- `outline`: When set to `true`, `dart/textDocument/publishOutline` notifications will be sent with outline information for open files.
- `flutterOutline`: When set to `true`, `dart/textDocument/publishFlutterOutline` notifications will be sent with Flutter outline information for open files.

## Method Status

Below is a list of LSP methods and their implementation status.

- Method: The LSP method name
- Basic Impl: This method has an implementation but may assume some client capabilities
- Capabilities: Only types from the original spec or as advertised in client capabilities are returned
- Tests: Has automated tests
- Tested Client: Has been manually tested in at least one LSP client editor

| Method | Basic Impl | Capabilities | Tests | Tested Client | Notes |
| - | - | - | - | - | - |
| initialize | ✅ | ✅ | ✅ | ✅ | trace and other options NYI
| initialized | ✅ | ✅ | ✅ | ✅ |
| shutdown | ✅ | ✅ | ✅ | ✅ | supported but does nothing |
| exit | ✅ | ✅ | ✅ | ✅ |
| $/cancelRequest | ✅ | ✅ | ✅ | ✅ |
| window/showMessage | ✅ | | | |
| window/showMessageRequest | | | | |
| window/logMessage | ✅ | | | |
| telemetry/event | | | | |
| client/registerCapability | ✅ | ✅ | ✅ | ✅ |
| client/unregisterCapability | | | | | (unused, capabilities don't change currently)
| workspace/workspaceFolders | | | | |
| workspace/didChangeWorkspaceFolders | ✅ | ✅ | ✅ | ✅ |
| workspace/configuration | | | | |
| workspace/didChangeWatchedFiles | | | | | unused, server does own watching |
| workspace/symbol | ✅ | ✅ | ✅ | ✅ |
| workspace/executeCommand | ✅ | ✅ | ✅ | ✅ |
| workspace/applyEdit | ✅ | ✅ | ✅ | ✅ |
| textDocument/didOpen | ✅ | ✅ | ✅ | ✅ |
| textDocument/didChange | ✅ | ✅ | ✅ | ✅ |
| textDocument/willSave | | | | |
| textDocument/willSaveWaitUntil | | | | |
| textDocument/didClose | ✅ | ✅ | ✅ | ✅ |
| textDocument/publishDiagnostics | ✅ | ✅ | ✅ | ✅ |
| textDocument/completion | ✅ | ✅ | ✅ | ✅ |
| completionItem/resolve | ✅ | ✅ | ✅ | ✅ |
| textDocument/hover | ✅ | ✅ | ✅ | ✅ |
| textDocument/signatureHelp | ✅ | ✅ | ✅ | ✅ | trigger character handling outstanding
| textDocument/declaration | | | | |
| textDocument/definition | ✅ | ✅ | ✅ | ✅ |
| textDocument/typeDefinition | | | | |
| textDocument/implementation | ✅ | ✅ | ✅ | ✅ |
| textDocument/references | ✅ | ✅ | ✅ | ✅ |
| textDocument/documentHighlight | ✅ | ✅ | ✅ | ✅ |
| textDocument/documentSymbol | ✅ | ✅ | ✅ | ✅ |
| textDocument/codeAction (sortMembers) | ✅ | ✅ | ✅ | ✅ |
| textDocument/codeAction (organiseImports) | ✅ | ✅ | ✅ | ✅ |
| textDocument/codeAction (refactors) | ✅ | ✅ | ✅ | ✅ |
| textDocument/codeAction (assists) | ✅ | ✅ | ✅ | ✅ | Only if the client advertises `codeActionLiteralSupport` with `Refactor`
| textDocument/codeAction (fixes) | ✅ | ✅ | ✅ | ✅ | Only if the client advertises `codeActionLiteralSupport` with `QuickFix`
| textDocument/codeLens | | | | |
| codeLens/resolve | | | | |
| textDocument/documentLink | | | | |
| documentLink/resolve | | | | |
| textDocument/documentColor | | | | |
| textDocument/colorPresentation | | | | |
| textDocument/formatting | ✅ | ✅ | ✅ | ✅ |
| textDocument/rangeFormatting | | | | | requires support from dart_style?
| textDocument/onTypeFormatting | ✅ | ✅ | ✅ | ✅ |
| textDocument/rename | ✅ | ✅ | ✅ | ✅ |
| textDocument/prepareRename | ✅ | ✅ | ✅ | ✅ |
| textDocument/foldingRange | ✅ | ✅ | ✅ | ✅ |

## Custom Methods

The following custom methods are also provided by the Dart LSP server:

### dart/diagnosticServer Method

Direction: Client -> Server
Params: None
Returns: `{ port: number }`

Starts the analzyer diagnostics server (if not already running) and returns the port number it's listening on.

### dart/textDocument/super Method

Direction: Client -> Server
Params: `TextDocumentPositionParams`
Returns: `Location | null`

Returns the location of the super definition of the class or method at the provided position or `null` if there isn't one.

### $/analyzerStatus Notification

Direction: Server -> Client
Params: `{ isAnalyzing: boolean }`

Notifies the client when analysis starts/completes.

### dart/textDocument/publishClosingLabels Notification

Direction: Server -> Client
Params: `{ uri: string, labels: { label: string, range: Range }[] }`

Notifies the client when closing label information is available (or updated) for a file.

### dart/textDocument/publishOutline Notification

Direction: Server -> Client
Params: `{ uri: string, outline: Outline }`
Outline: `{ element: Element, range: Range, codeRange: Range, children: Outline[] }`
Element: `{ name: string, range: Range, kind: string, parameters: string | undefined, typeParameters: string | undefined, returnType: string | undefined }`

Notifies the client when outline information is available (or updated) for a file.

Nodes contains multiple ranges:

- `element.range` - the range of the name in the declaration of the element
- `range` - the entire range of the declaration including dartdocs
- `codeRange` - the range of code part of the declaration (excluding dartdocs and annotations) - typically used when navigating to the declaration

### dart/textDocument/publishFlutterOutline Notification

Direction: Server -> Client
Params: `{ uri: string, outline: FlutterOutline }`
FlutterOutline: `{ dartElement: Element | undefined, range: Range, codeRange: Range, children: Outline[], kind: string, label: string | undefined, className: string | undefined, variableName: string | undefined, attributes: FlutterOutlineAttribute[] | undefined }`
FlutterOutlineAttribute: `{ name: string, label: string }`
Element: as defined for the `dart/textDocument/publishOutline` notification.

Notifies the client when Flutter outline information is available (or updated) for a file.

Nodes contains multiple ranges as desribed for the `dart/textDocument/publishOutline` notification.
