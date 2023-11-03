# Language Server Protocol

[Language Server Protocol](https://microsoft.github.io/language-server-protocol/) (LSP) support is available in the Dart analysis server from version 2.2.0 of the SDK (which was included in version 1.2.1 of Flutter). The supported messages are detailed below (for the version of the SDK that matches this README).

## Using the Dart LSP server in editors

- [Using LSP with Dart-Vim](https://github.com/dart-lang/dart-vim-plugin/blob/master/README.md#how-do-i-configure-an-lsp-plugin-to-start-the-analysis-server)
- [Using LSP with Emacs](https://emacs-lsp.github.io/lsp-dart)

## Running the Server

Start the language server using the `dart language-server` command. Pass the `--client-id` and `--client-version` flags to identify your editor/plugin and version:

```
dart language-server --client-id my-editor.my-plugin --client-version 1.2
```

Note: In LSP the client makes the first request so there is no obvious confirmation that the server is working correctly until the client sends an `initialize` request. Unlike standard JSON RPC, [LSP requires that headers are sent](https://microsoft.github.io/language-server-protocol/specification).

## Handling of "Loose" Files

When there are no open workspace folders (or if the initialization option `onlyAnalyzeProjectsWithOpenFiles` is set to `true`), analysis will be performed based on project folders located by the open files. For each open file, the project root will be located, and that whole project analyzed. If the file does not have a project (eg. there is no pubspec.yaml in its ancestor folders) then the file will be analyzed in isolation.

## Initialization Options

- `onlyAnalyzeProjectsWithOpenFiles` (`bool?`): When set to `true`, workspace folders will be ignored and analysis will be performed based on the open files, as if no workspace was open at all. This allows opening large folders without causing them to be completely analyzed. Defaults to `false`.
- `suggestFromUnimportedLibraries` (`bool?`): When set to `false`, completion will not include symbols that are not already imported into the current file. Defaults to `true`, though the client must additionally support `workspace/applyEdit` for these completions to be included.
- `closingLabels` (`bool?`): When set to `true`, `dart/textDocument/publishClosingLabels` notifications will be sent with information to render editor closing labels.
- `outline` (`bool?`): When set to `true`, `dart/textDocument/publishOutline` notifications will be sent with outline information for open files.
- `flutterOutline` (`bool?`): When set to `true`, `dart/textDocument/publishFlutterOutline` notifications will be sent with Flutter outline information for open files.
- `allowOpenUri`: When set to `true`, indicates that the client will handle `dart/openUri` notifications by opening a browser for the supplied URI.

## Client Workspace Configuration

Client workspace settings are requested with `workspace/configuration` during initialization and re-requested whenever the client notifies the server with `workspace/didChangeConfiguration`. This allows the settings to take effect without restarting the server.

- `dart.analysisExcludedFolders` (`List<String>?`): An array of paths (absolute or relative to each workspace folder) that should be excluded from analysis.
- `dart.enableSdkFormatter` (`bool?`): When set to `false`, prevents registration (or unregisters) the SDK formatter. When set to `true` or not supplied, will register/reregister the SDK formatter.
- `dart.lineLength` (`int?`): The number of characters the formatter should wrap code at. If unspecified, code will be wrapped at `80` characters.
- `dart.completeFunctionCalls` (`bool?`): When set to true, completes functions/methods with their required parameters.
- `dart.showTodos` (`bool?`): Whether to generate diagnostics for TODO comments. If unspecified, diagnostics will not be generated.
- `dart.renameFilesWithClasses` (`String`): When set to `"always"`, will include edits to rename files when classes are renamed if the filename matches the class name (but in snake_form). When set to `"prompt"`, a prompt will be shown on each class rename asking to confirm the file rename. Otherwise, files will not be renamed. Renames are performed using LSP's ResourceOperation edits - that means the rename is simply included in the resulting `WorkspaceEdit` and must be handled by the client.
- `dart.enableSnippets` (`bool?`): Whether to include code snippets (such as `class`, `stful`, `switch`) in code completion. When unspecified, snippets will be included.
- `dart.updateImportsOnRename` (`bool?`): Whether to update imports and other directives when files are renamed. When unspecified, imports will be updated if the client supports `willRenameFiles` requests.
- `dart.documentation` (`none`, `summary` or `full`): The typekind of dartdocs to include in Hovers, Code Completion, Signature Help and other similar requests. If not set, defaults to `full`.
- `dart.includeDependenciesInWorkspaceSymbols` (`bool?`): Whether to include symbols from dependencies and Dart/Flutter SDKs in Workspace Symbol results. If not set, defaults to `true`.

## Method Status

Below is a list of LSP methods and their implementation status.

- Method: The LSP method name
- Basic Impl: This method has an implementation but may assume some client capabilities
- Capabilities: Only types from the original spec or as advertised in client capabilities are returned
- Plugins: This functionality works with server plugins
- Tests: Has automated tests
- Tested Client: Has been manually tested in at least one LSP client editor

| Method | Server | Plugins | Notes |
| - | - | - | - |
| initialize | ✅ | N/A | trace and other options NYI|
| initialized | ✅ | N/A | |
| shutdown | ✅ | N/A | supported but does nothing|
| exit | ✅ | N/A | |
| $/cancelRequest | ✅ | | |
| $/logTrace | | | |
| $/progress | | | |
| $/setTrace | | | |
| client/registerCapability | ✅ | ✅ | |
| client/unregisterCapability | ✅ | ✅ | |
| notebookDocument/* | | | |
| telemetry/event | | | |
| textDocument/codeAction (assists) | ✅ | ✅ | Only if the client advertises `codeActionLiteralSupport` with `Refactor`|
| textDocument/codeAction (fixAll) | ✅ | | |
| textDocument/codeAction (fixes) | ✅ | ✅ | Only if the client advertises `codeActionLiteralSupport` with `QuickFix`|
| textDocument/codeAction (organiseImports) | ✅ | | |
| textDocument/codeAction (refactors) | ✅ | | |
| textDocument/codeAction (sortMembers) | ✅ | | |
|  codeAction/resolve | | | |
| textDocument/codeLens | | | |
|   codeLens/resolve | | | |
| textDocument/completion | ✅ | ✅ | |
|   completionItem/resolve | ✅ | | |
| textDocument/declaration | | | |
| textDocument/definition | ✅ | ✅ | |
| textDocument/diagnostic | | | |
| textDocument/didChange | ✅ | ✅ | |
| textDocument/didClose | ✅ | ✅ | |
| textDocument/didOpen | ✅ | ✅ | |
| textDocument/didSave | | | |
| textDocument/documentColor | ✅ | | |
|   textDocument/colorPresentation | ✅ | | |
| textDocument/documentHighlight | ✅ | | |
| textDocument/documentLink | ✅ | | |
|   documentLink/resolve | | | |
| textDocument/documentSymbol | ✅ | | |
| textDocument/foldingRange | ✅ | ✅ | |
| textDocument/formatting | ✅ | | |
|   textDocument/onTypeFormatting | ✅ | | |
|   textDocument/rangeFormatting | ✅ | | |
| textDocument/hover | ✅ | | |
| textDocument/implementation | ✅ | | |
| textDocument/inlayHint | ✅ | | |
|   inlayHint/resolve | | | |
| textDocument/inlineValue | | | |
| textDocument/linkedEditingRange | | | |
| textDocument/moniker | | | |
| textDocument/prepareCallHierarchy | ✅ | | |
|   callHierarchy/incomingCalls | ✅ | | |
|   callHierarchy/outgoingCalls | ✅ | | |
| textDocument/prepareRename | ✅ | | |
|   textDocument/rename | ✅ | | |
| textDocument/prepareTypeHierarchy | ✅ | | |
|   typeHierarchy/subtypes | ✅ | | |
|   typeHierarchy/supertypes | ✅ | | |
| textDocument/publishDiagnostics | ✅ | ✅ | |
| textDocument/references | ✅ | | |
| textDocument/selectionRange | ✅ | | |
| textDocument/semanticTokens/full | ✅ | ✅ | |
| textDocument/semanticTokens/full/delta | | | |
| textDocument/semanticTokens/range | ✅ | ✅ | |
| workspace/semanticTokens/refresh | | | |
| textDocument/signatureHelp | ✅ | | |
| textDocument/typeDefinition | ✅ | | |
| textDocument/willSave | | | |
| textDocument/willSaveWaitUntil | | | |
| window/logMessage | ✅ | | |
| window/showDocument | | | |
| window/showMessage | ✅ | | |
| window/showMessageRequest | | | |
| window/workDoneProgress/cancel | | | |
| window/workDoneProgress/create | ✅ | | |
| workspace/applyEdit | ✅ | | |
| workspace/codeLens/refresh | | | |
| workspace/configuration | ✅ | | |
| workspace/diagnostic | | | |
| workspace/diagnostic/refresh | | | |
| workspace/didChangeConfiguration | ✅ | | |
| workspace/didChangeWatchedFiles | | | unused, server does own watching|
| workspace/didChangeWorkspaceFolders | ✅ | ✅ | |
| workspace/didCreateFiles | | | |
| workspace/didDeleteFiles | | | |
| workspace/didRenameFiles | | | |
| workspace/executeCommand | ✅ | | |
| workspace/inlayHint/refresh | | | |
| workspace/inlineValue/refresh | | | |
| workspace/symbol | ✅ | | |
|   workspaceSymbol/resolve | | | |
| workspace/willCreateFiles | | | |
| workspace/willDeleteFiles | | | |
| workspace/willRenameFiles | | | |
| workspace/willRenameFiles | ✅ | | |
| workspace/workspaceFolders | | | |

## Custom Fields, Methods and Notifications

The following custom fields/methods/notifications are also provided by the Dart LSP server:

### Message.clientRequestTime Field

The server accepts an optional `int?` on all incoming messages named `clientRequestTime` (alongside `id`, `method`, `params`) containing a timestamp (milliseconds since epoch) of when the client made that request. Providing clientRequestTime helps track how responsive analysis server is to client requests and better address any issues that occur.

### dart/diagnosticServer Method

Direction: Client -> Server
Params: None
Returns: `{ port: number }`

Starts the analyzer diagnostics server (if not already running) and returns the port number it's listening on.

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

Nodes contains multiple ranges as described for the `dart/textDocument/publishOutline` notification.

### dart/openUri Notification

Direction: Server -> Client
Params: `{ uri: Uri }`

Notifies the client that the server would like to open a given URI. This event is only sent in response to direct user actions (such as if the user clicks a "Learn More" button in a `window/showMessageRequest`). URIs could be either external web pages (http/https) to be opened in the browser or documents (file:///) to be opened in the editor.

This notification (and functionality that relies on it) will only be sent if the client passes `allowOpenUri: true` in `initializationOptions`.
