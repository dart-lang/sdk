# Language Server Protocol

[Language Server Protocol](https://microsoft.github.io/language-server-protocol/) (LSP) support is available in the Dart analysis server from version 2.2.0 of the SDK (which was included in version 1.2.1 of Flutter). The supported messages are detailed below (for the version of the SDK that matches this README).

## Using the Dart LSP server in editors

- [Using LSP with Dart-Vim](https://github.com/dart-lang/dart-vim-plugin/blob/master/README.md#how-do-i-configure-an-lsp-plugin-to-start-the-analysis-server)
- [Using LSP with Emacs](https://emacs-lsp.github.io/lsp-dart)

## Running the Server

The analysis server snapshot is included in the `bin/snapshots` folder of the Dart SDK. Pass the `--lsp` flag to start the server in LSP mode and the `--client-id` and `--client-version` flags to identify your editor/plugin and version:

```
dart bin/snapshots/analysis_server.dart.snapshot --lsp --client-id my-editor.my-plugin --client-version 1.2
```

Note: In LSP the client makes the first request so there is no obvious confirmation that the server is working correctly until the client sends an `initialize` request. Unlike standard JSON RPC, [LSP requires that headers are sent](https://microsoft.github.io/language-server-protocol/specification).

## Initialization Options

- `onlyAnalyzeProjectsWithOpenFiles`: When set to `true`, analysis will only be performed for projects that have open files rather than the root workspace folder. Defaults to `false`.
- `suggestFromUnimportedLibraries`: When set to `false`, completion will not include synbols that are not already imported into the current file. Defaults to `true`, though the client must additionally support `workspace/applyEdit` for these completions to be included.
- `closingLabels`: When set to `true`, `dart/textDocument/publishClosingLabels` notifications will be sent with information to render editor closing labels.
- `outline`: When set to `true`, `dart/textDocument/publishOutline` notifications will be sent with outline information for open files.
- `flutterOutline`: When set to `true`, `dart/textDocument/publishFlutterOutline` notifications will be sent with Flutter outline information for open files.

## Client Workspace Configuration

Client workspace settings are requested with `workspace/configuration` during initialization and re-requested whenever the client notifies the server with `workspace/didChangeConfiguration`. This allows the settings to take effect without restarting the server.

- `dart.analysisExcludedFolders`: An array of paths (absolute or relative to each workspace folder) that should be excluded from analysis.
- `dart.enableSdkFormatter`: When set to `false`, prevents registration (or unregisters) the SDK formatter. When set to `true` or not supplied, will register/reregister the SDK formatter.
- `dart.lineLength`: The number of characters the formatter should wrap code at. If unspecified, code will be wrapped at `80` characters.
- `dart.completeFunctionCalls`: Completes functions/methods with their required parameters.
- `dart.showTodos`: Whether to generate diagnostics for TODO comments. If unspecified, diagnostics will not be generated.

## Method Status

Below is a list of LSP methods and their implementation status.

- Method: The LSP method name
- Basic Impl: This method has an implementation but may assume some client capabilities
- Capabilities: Only types from the original spec or as advertised in client capabilities are returned
- Plugins: This functionality works with server plugins
- Tests: Has automated tests
- Tested Client: Has been manually tested in at least one LSP client editor

| Method | Basic Impl | Capabilities | Plugins | Tests | Tested Client | Notes |
| - | - | - | - | - | - | - |
| initialize | ✅ | ✅ | N/A | ✅ | ✅ | trace and other options NYI
| initialized | ✅ | ✅ | N/A | ✅ | ✅ |
| shutdown | ✅ | ✅ | N/A | ✅ | ✅ | supported but does nothing |
| exit | ✅ | ✅ | N/A | ✅ | ✅ |
| $/cancelRequest | ✅ | ✅ | | ✅ | ✅ |
| window/showMessage | ✅ | | | | |
| window/showMessageRequest | | | | | |
| window/logMessage | ✅ | | | | |
| telemetry/event | | | | | |
| client/registerCapability | ✅ | ✅ | ✅ | ✅ | ✅ |
| client/unregisterCapability | ✅ | ✅ | ✅ | ✅ | ✅ |
| workspace/workspaceFolders | | | | | |
| workspace/didChangeWorkspaceFolders | ✅ | ✅ | ✅ | ✅ | ✅ |
| workspace/didChangeConfiguration | ✅ | ✅ | | ✅ | ✅ |
| workspace/configuration | ✅ | ✅ | | ✅ | ✅ |
| workspace/didChangeWatchedFiles | | | | | | unused, server does own watching |
| workspace/symbol | ✅ | ✅ | | ✅ | ✅ |
| workspace/executeCommand | ✅ | ✅ | | ✅ | ✅ |
| workspace/applyEdit | ✅ | ✅ | | ✅ | ✅ |
| workspace/onWillRenameFiles | ✅ | ✅ | | ✅ | ✅ |
| textDocument/didOpen | ✅ | ✅ | ✅ | ✅ | ✅ |
| textDocument/didChange | ✅ | ✅ | ✅ | ✅ | ✅ |
| textDocument/willSave | | | | | |
| textDocument/willSaveWaitUntil | | | | | |
| textDocument/didClose | ✅ | ✅ | ✅ | ✅ | ✅ |
| textDocument/publishDiagnostics | ✅ | ✅ | ✅ | ✅ | ✅ |
| textDocument/completion | ✅ | ✅ | ✅ | ✅ | ✅ |
| completionItem/resolve | ✅ | ✅ | ✅ | ✅ | ✅ |
| textDocument/hover | ✅ | ✅ | | ✅ | ✅ |
| textDocument/signatureHelp | ✅ | ✅ | | ✅ | ✅ | trigger character handling outstanding
| textDocument/declaration | | | | | |
| textDocument/definition | ✅ | ✅ | ✅ | ✅ | ✅ |
| textDocument/typeDefinition | | | | | |
| textDocument/implementation | ✅ | ✅ | | ✅ | ✅ |
| textDocument/references | ✅ | ✅ | | ✅ | ✅ |
| textDocument/documentHighlight | ✅ | ✅ | | ✅ | ✅ |
| textDocument/documentSymbol | ✅ | ✅ | | ✅ | ✅ |
| textDocument/codeAction (sortMembers) | ✅ | ✅ | | ✅ | ✅ |
| textDocument/codeAction (organiseImports) | ✅ | ✅ | | ✅ | ✅ |
| textDocument/codeAction (refactors) | ✅ | ✅ | | ✅ | ✅ |
| textDocument/codeAction (assists) | ✅ | ✅ | | ✅ | ✅ | Only if the client advertises `codeActionLiteralSupport` with `Refactor`
| textDocument/codeAction (fixes) | ✅ | ✅ | | ✅ | ✅ | Only if the client advertises `codeActionLiteralSupport` with `QuickFix`
| textDocument/codeLens | | | | | |
| codeLens/resolve | | | | | |
| textDocument/documentLink | | | | | |
| documentLink/resolve | | | | | |
| textDocument/documentColor | | | | | |
| textDocument/colorPresentation | | | | | |
| textDocument/formatting | ✅ | ✅ | | ✅ | ✅ |
| textDocument/rangeFormatting | ✅ | ✅ | | ✅ | ✅ |
| textDocument/onTypeFormatting | ✅ | ✅ | | ✅ | ✅ |
| textDocument/rename | ✅ | ✅ | | ✅ | ✅ |
| textDocument/prepareRename | ✅ | ✅ | | ✅ | ✅ |
| textDocument/foldingRange | ✅ | ✅ | ✅ | ✅ | ✅ |
| textDocument/semanticTokens/full | ✅ | ✅ | ✅ | ✅ | ✅ |

## Custom Methods and Notifications

The following custom methods/notifications are also provided by the Dart LSP server:

### dart/diagnosticServer Method

Direction: Client -> Server
Params: None
Returns: `{ port: number }`

Starts the analzyer diagnostics server (if not already running) and returns the port number it's listening on.

### dart/reanalyze Method

Direction: Client -> Server
Params: None
Returns: None

Forces re-reading of all potentially changed files, re-resolving of all referenced URIs, and corresponding re-analysis of everything affected in the current analysis roots. Clients should not usually need to call this method - needing to do so may indicate a bug in the server.

### dart/textDocument/super Method

Direction: Client -> Server
Params: `TextDocumentPositionParams`
Returns: `Location | null`

Returns the location of the super definition of the class or method at the provided position or `null` if there isn't one.

### $/analyzerStatus Notification (Deprecated)

Direction: Server -> Client
Params: `{ isAnalyzing: boolean }`

Notifies the client when analysis starts/completes.

This notification is not sent if the client capabilities include `window.workDoneProgress == true` because analyzing status events will be sent using `$/progress`.

This notification may be removed in a future Dart SDK release and should not be depended on.

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
