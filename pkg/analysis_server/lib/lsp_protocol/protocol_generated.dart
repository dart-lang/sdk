// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file has been automatically generated.  Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/lsp_spec/generate_all.dart".

class ApplyWorkspaceEditParams {
  /// The edits to apply.
  WorkspaceEdit edit;

  /// An optional label of the workspace edit. This label is presented in the
  /// user interface for example on an undo stack to undo the workspace edit.
  String label;
}

class ApplyWorkspaceEditResponse {
  /// Indicates whether the edit was applied or not.
  bool applied;
}

class CancelParams {
  /// The request id to cancel.
  Object /*Either<num, String>*/ id;
}

class ClientCapabilities {
  /// Experimental client capabilities.
  Object experimental;

  /// Text document specific client capabilities.
  TextDocumentClientCapabilities textDocument;

  /// Workspace specific client capabilities.
  WorkspaceClientCapabilities workspace;
}

/// A code action represents a change that can be performed in code, e.g. to fix
/// a problem or to refactor code.
///
/// A CodeAction must set either `edit` and/or a `command`. If both are
/// supplied, the `edit` is applied first, then the `command` is executed.
class CodeAction {
  /// A command this code action executes. If a code action provides an edit and
  /// a command, first the edit is executed and then the command.
  Command command;

  /// The diagnostics that this code action resolves.
  List<Diagnostic> diagnostics;

  /// The workspace edit this code action performs.
  WorkspaceEdit edit;

  /// The kind of the code action.
  ///
  /// Used to filter code actions.
  String /*CodeActionKind*/ kind;

  /// A short, human-readable, title for this code action.
  String title;
}

/// Contains additional diagnostic information about the context in which a code
/// action is run.
class CodeActionContext {
  /// An array of diagnostics.
  List<Diagnostic> diagnostics;

  /// Requested kind of actions to return.
  ///
  /// Actions not of this kind are filtered out by the client before being
  /// shown. So servers can omit computing them.
  List<String /*CodeActionKind*/ > only;
}

/// A set of predefined code action kinds
abstract class CodeActionKind {
  /// Base kind for quickfix actions: 'quickfix'
  static const QuickFix = 'quickfix';

  /// Base kind for refactoring actions: 'refactor'
  static const Refactor = 'refactor';

  /// Base kind for refactoring extraction actions: 'refactor.extract'
  ///
  /// Example extract actions:
  ///  - Extract method - Extract function - Extract variable - Extract
  /// interface from class - ...
  static const RefactorExtract = 'refactor.extract';

  /// Base kind for refactoring inline actions: 'refactor.inline'
  ///
  /// Example inline actions:
  ///  - Inline function - Inline variable - Inline constant - ...
  static const RefactorInline = 'refactor.inline';

  /// Base kind for refactoring rewrite actions: 'refactor.rewrite'
  ///
  /// Example rewrite actions:
  ///  - Convert JavaScript function to class - Add or remove parameter -
  /// Encapsulate field - Make method static - Move method to base class - ...
  static const RefactorRewrite = 'refactor.rewrite';

  /// Base kind for source actions: `source`
  ///
  /// Source code actions apply to the entire file.
  static const Source = 'source';

  /// Base kind for an organize imports source action: `source.organizeImports`
  static const SourceOrganizeImports = 'source.organizeImports';
}

/// Code Action options.
class CodeActionOptions {
  /// CodeActionKinds that this server may return.
  ///
  /// The list of kinds may be generic, such as `CodeActionKind.Refactor`, or
  /// the server may list out every specific kind they provide.
  List<String /*CodeActionKind*/ > codeActionKinds;
}

/// Params for the CodeActionRequest
class CodeActionParams {
  /// Context carrying additional information.
  CodeActionContext context;

  /// The range for which the command was invoked.
  Range range;

  /// The document in which the command was invoked.
  TextDocumentIdentifier textDocument;
}

class CodeActionRegistrationOptions {}

/// A code lens represents a command that should be shown along with source
/// text, like the number of references, a way to run tests, etc.
///
/// A code lens is _unresolved_ when no command is associated to it. For
/// performance reasons the creation of a code lens and resolving should be done
/// in two stages.
class CodeLens {
  /// The command this code lens represents.
  Command command;

  /// A data entry field that is preserved on a code lens item between a code
  /// lens and a code lens resolve request.
  Object data;

  /// The range in which this code lens is valid. Should only span a single
  /// line.
  Range range;
}

/// Code Lens options.
class CodeLensOptions {
  /// Code lens has a resolve provider as well.
  bool resolveProvider;
}

class CodeLensParams {
  /// The document to request code lens for.
  TextDocumentIdentifier textDocument;
}

class CodeLensRegistrationOptions {
  /// Code lens has a resolve provider as well.
  bool resolveProvider;
}

/// Represents a color in RGBA space.
class Color {
  num alpha;

  num blue;

  num green;

  num red;
}

class ColorInformation {
  /// The actual color value for this color range.
  Color color;

  /// The range in the document where this color appears.
  Range range;
}

class ColorPresentation {
  /// An optional array of additional [text edits](#TextEdit) that are applied
  /// when selecting this color presentation. Edits must not overlap with the
  /// main [edit](#ColorPresentation.textEdit) nor with themselves.
  List<TextEdit> additionalTextEdits;

  /// The label of this color presentation. It will be shown on the color picker
  /// header. By default this is also the text that is inserted when selecting
  /// this color presentation.
  String label;

  /// An [edit](#TextEdit) which is applied to a document when selecting this
  /// presentation for the color.  When `falsy` the
  /// [label](#ColorPresentation.label) is used.
  TextEdit textEdit;
}

class ColorPresentationParams {
  /// The color information to request presentations for.
  Color color;

  /// The range where the color would be inserted. Serves as a context.
  Range range;

  /// The text document.
  TextDocumentIdentifier textDocument;
}

/// Color provider options.
class ColorProviderOptions {}

class Command {
  /// Arguments that the command handler should be invoked with.
  List<Object> arguments;

  /// The identifier of the actual command handler.
  String command;

  /// Title of the command, like `save`.
  String title;
}

/// Contains additional information about the context in which a completion
/// request is triggered.
class CompletionContext {
  /// The trigger character (a single character) that has trigger code complete.
  /// Is undefined if `triggerKind !== CompletionTriggerKind.TriggerCharacter`
  String triggerCharacter;

  /// How the completion was triggered.
  CompletionTriggerKind triggerKind;
}

class CompletionItem {
  /// An optional array of additional text edits that are applied when selecting
  /// this completion. Edits must not overlap (including the same insert
  /// position) with the main edit nor with themselves.
  ///
  /// Additional text edits should be used to change text unrelated to the
  /// current cursor position (for example adding an import statement at the top
  /// of the file if the completion item will insert an unqualified type).
  List<TextEdit> additionalTextEdits;

  /// An optional command that is executed *after* inserting this completion.
  /// *Note* that additional modifications to the current document should be
  /// described with the additionalTextEdits-property.
  Command command;

  /// An optional set of characters that when pressed while this completion is
  /// active will accept it first and then type that character. *Note* that all
  /// commit characters should have `length=1` and that superfluous characters
  /// will be ignored.
  List<String> commitCharacters;

  /// An data entry field that is preserved on a completion item between a
  /// completion and a completion resolve request.
  Object data;

  /// Indicates if this item is deprecated.
  bool deprecated;

  /// A human-readable string with additional information about this item, like
  /// type or symbol information.
  String detail;

  /// A human-readable string that represents a doc-comment.
  Object /*Either<String, MarkupContent>*/ documentation;

  /// A string that should be used when filtering a set of completion items.
  /// When `falsy` the label is used.
  String filterText;

  /// A string that should be inserted into a document when selecting this
  /// completion. When `falsy` the label is used.
  ///
  /// The `insertText` is subject to interpretation by the client side. Some
  /// tools might not take the string literally. For example VS Code when code
  /// complete is requested in this example `con<cursor position>` and a
  /// completion item with an `insertText` of `console` is provided it will only
  /// insert `sole`. Therefore it is recommended to use `textEdit` instead since
  /// it avoids additional client side interpretation.
  ///  @deprecated Use textEdit instead.
  String insertText;

  /// The format of the insert text. The format applies to both the `insertText`
  /// property and the `newText` property of a provided `textEdit`.
  InsertTextFormat insertTextFormat;

  /// The kind of this completion item. Based of the kind an icon is chosen by
  /// the editor.
  num kind;

  /// The label of this completion item. By default also the text that is
  /// inserted when selecting this completion.
  String label;

  /// Select this item when showing.
  ///  *Note* that only one completion item can be selected and that the tool /
  /// client decides which item that is. The rule is that the *first* item of
  /// those that match best is selected.
  bool preselect;

  /// A string that should be used when comparing this item with other items.
  /// When `falsy` the label is used.
  String sortText;

  /// An edit which is applied to a document when selecting this completion.
  /// When an edit is provided the value of `insertText` is ignored.
  ///  *Note:* The range of the edit must be a single line range and it must
  /// contain the position at which completion has been requested.
  TextEdit textEdit;
}

/// The kind of a completion entry.
abstract class CompletionItemKind {
  static const Class = 7;

  static const Color = 16;

  static const Constant = 21;

  static const Constructor = 4;

  static const Enum = 13;

  static const EnumMember = 20;

  static const Event = 23;

  static const Field = 5;

  static const File = 17;

  static const Folder = 19;

  static const Function = 3;

  static const Interface = 8;

  static const Keyword = 14;

  static const Method = 2;

  static const Module = 9;

  static const Operator = 24;

  static const Property = 10;

  static const Reference = 18;

  static const Snippet = 15;

  static const Struct = 22;

  static const Text = 1;

  static const TypeParameter = 25;

  static const Unit = 11;

  static const Value = 12;

  static const Variable = 6;
}

/// Represents a collection of [completion items](#CompletionItem) to be
/// presented in the editor.
class CompletionList {
  /// This list it not complete. Further typing should result in recomputing
  /// this list.
  bool isIncomplete;

  /// The completion items.
  List<CompletionItem> items;
}

/// Completion options.
class CompletionOptions {
  /// The server provides support to resolve additional information for a
  /// completion item.
  bool resolveProvider;

  /// The characters that trigger completion automatically.
  List<String> triggerCharacters;
}

class CompletionParams {
  /// The completion context. This is only available if the client specifies to
  /// send this using `ClientCapabilities.textDocument.completion.contextSupport
  /// === true`
  CompletionContext context;
}

class CompletionRegistrationOptions {
  /// The server provides support to resolve additional information for a
  /// completion item.
  bool resolveProvider;

  /// Most tools trigger completion request automatically without explicitly
  /// requesting it using a keyboard shortcut (e.g. Ctrl+Space). Typically they
  /// do so when the user starts to type an identifier. For example if the user
  /// types `c` in a JavaScript file code complete will automatically pop up
  /// present `console` besides others as a completion item. Characters that
  /// make up identifiers don't need to be listed here.
  ///
  /// If code complete should automatically be trigger on characters not being
  /// valid inside an identifier (for example `.` in JavaScript) list them in
  /// `triggerCharacters`.
  List<String> triggerCharacters;
}

/// How a completion was triggered
abstract class CompletionTriggerKind {
  /// Completion was triggered by typing an identifier (24x7 code complete),
  /// manual invocation (e.g Ctrl+Space) or via API.
  static const Invoked = 1;

  /// Completion was triggered by a trigger character specified by the
  /// `triggerCharacters` properties of the `CompletionRegistrationOptions`.
  static const TriggerCharacter = 2;

  /// Completion was re-triggered as the current completion list is incomplete.
  static const TriggerForIncompleteCompletions = 3;
}

class ConfigurationItem {
  /// The scope to get the configuration section for.
  String scopeUri;

  /// The configuration section asked for.
  String section;
}

class ConfigurationParams {
  List<ConfigurationItem> items;
}

/// Create file operation
class CreateFile {
  /// Additional options
  CreateFileOptions options;

  /// The resource to create.
  String uri;
}

/// Options to create a file.
class CreateFileOptions {
  /// Ignore if exists.
  bool ignoreIfExists;

  /// Overwrite existing file. Overwrite wins over `ignoreIfExists`
  bool overwrite;
}

/// Delete file operation
class DeleteFile {
  /// Delete options.
  DeleteFileOptions options;

  /// The file to delete.
  String uri;
}

/// Delete file options
class DeleteFileOptions {
  /// Ignore the operation if the file doesn't exist.
  bool ignoreIfNotExists;

  /// Delete the content recursively if a folder is denoted.
  bool recursive;
}

class Diagnostic {
  /// The diagnostic's code, which might appear in the user interface.
  Object /*Either<num, String>*/ code;

  /// The diagnostic's message.
  String message;

  /// The range at which the message applies.
  Range range;

  /// An array of related diagnostic information, e.g. when symbol-names within
  /// a scope collide all definitions can be marked via this property.
  List<DiagnosticRelatedInformation> relatedInformation;

  /// The diagnostic's severity. Can be omitted. If omitted it is up to the
  /// client to interpret diagnostics as error, warning, info or hint.
  num severity;

  /// A human-readable string describing the source of this diagnostic, e.g.
  /// 'typescript' or 'super lint'.
  String source;
}

/// Represents a related message and source code location for a diagnostic. This
/// should be used to point to code locations that cause or related to a
/// diagnostics, e.g when duplicating a symbol in a scope.
class DiagnosticRelatedInformation {
  /// The location of this related diagnostic information.
  Location location;

  /// The message of this related diagnostic information.
  String message;
}

abstract class DiagnosticSeverity {
  /// Reports an error.
  static const Error = 1;

  /// Reports a hint.
  static const Hint = 4;

  /// Reports an information.
  static const Information = 3;

  /// Reports a warning.
  static const Warning = 2;
}

class DidChangeConfigurationParams {
  /// The actual changed settings
  Object settings;
}

class DidChangeTextDocumentParams {
  /// The actual content changes. The content changes describe single state
  /// changes to the document. So if there are two content changes c1 and c2 for
  /// a document in state S then c1 move the document to S' and c2 to S''.
  List<TextDocumentContentChangeEvent> contentChanges;

  /// The document that did change. The version number points to the version
  /// after all provided content changes have been applied.
  VersionedTextDocumentIdentifier textDocument;
}

class DidChangeWatchedFilesParams {
  /// The actual file events.
  List<FileEvent> changes;
}

/// Describe options to be used when registering for text document change
/// events.
class DidChangeWatchedFilesRegistrationOptions {
  /// The watchers to register.
  List<FileSystemWatcher> watchers;
}

class DidChangeWorkspaceFoldersParams {
  /// The actual workspace folder change event.
  WorkspaceFoldersChangeEvent event;
}

class DidCloseTextDocumentParams {
  /// The document that was closed.
  TextDocumentIdentifier textDocument;
}

class DidOpenTextDocumentParams {
  /// The document that was opened.
  TextDocumentItem textDocument;
}

class DidSaveTextDocumentParams {
  /// Optional the content when saved. Depends on the includeText value when the
  /// save notification was requested.
  String text;

  /// The document that was saved.
  TextDocumentIdentifier textDocument;
}

class DocumentFilter {
  /// A language id, like `typescript`.
  String language;

  /// A glob pattern, like `*.{ts,js}`.
  String pattern;

  /// A Uri [scheme](#Uri.scheme), like `file` or `untitled`.
  String scheme;
}

class DocumentFormattingParams {
  /// The format options.
  FormattingOptions options;

  /// The document to format.
  TextDocumentIdentifier textDocument;
}

/// A document highlight is a range inside a text document which deserves
/// special attention. Usually a document highlight is visualized by changing
/// the background color of its range.
class DocumentHighlight {
  /// The highlight kind, default is DocumentHighlightKind.Text.
  num kind;

  /// The range this highlight applies to.
  Range range;
}

/// A document highlight kind.
abstract class DocumentHighlightKind {
  /// Read-access of a symbol, like reading a variable.
  static const Read = 2;

  /// A textual occurrence.
  static const Text = 1;

  /// Write-access of a symbol, like writing to a variable.
  static const Write = 3;
}

/// A document link is a range in a text document that links to an internal or
/// external resource, like another text document or a web site.
class DocumentLink {
  /// A data entry field that is preserved on a document link between a
  /// DocumentLinkRequest and a DocumentLinkResolveRequest.
  Object data;

  /// The range this link applies to.
  Range range;

  /// The uri this link points to. If missing a resolve request is sent later.
  String /*DocumentUri*/ target;
}

/// Document link options.
class DocumentLinkOptions {
  /// Document links have a resolve provider as well.
  bool resolveProvider;
}

class DocumentLinkParams {
  /// The document to provide document links for.
  TextDocumentIdentifier textDocument;
}

class DocumentLinkRegistrationOptions {
  /// Document links have a resolve provider as well.
  bool resolveProvider;
}

/// Format document on type options.
class DocumentOnTypeFormattingOptions {
  /// A character on which formatting should be triggered, like `}`.
  String firstTriggerCharacter;

  /// More trigger characters.
  List<String> moreTriggerCharacter;
}

class DocumentOnTypeFormattingParams {
  /// The character that has been typed.
  String ch;

  /// The format options.
  FormattingOptions options;

  /// The position at which this request was sent.
  Position position;

  /// The document to format.
  TextDocumentIdentifier textDocument;
}

class DocumentOnTypeFormattingRegistrationOptions {
  /// A character on which formatting should be triggered, like `}`.
  String firstTriggerCharacter;

  /// More trigger characters.
  List<String> moreTriggerCharacter;
}

class DocumentRangeFormattingParams {
  /// The format options
  FormattingOptions options;

  /// The range to format
  Range range;

  /// The document to format.
  TextDocumentIdentifier textDocument;
}

class DocumentSymbolParams {
  /// The text document.
  TextDocumentIdentifier textDocument;
}

abstract class ErrorCodes {
  static const InternalError = -32603;

  static const InvalidParams = -32602;

  static const InvalidRequest = -32600;

  static const MethodNotFound = -32601;

  static const ParseError = -32700;

  static const RequestCancelled = -32800;

  static const ServerNotInitialized = -32002;

  static const UnknownErrorCode = -32001;

  static const serverErrorEnd = -32000;

  static const serverErrorStart = -32099;
}

/// Execute command options.
class ExecuteCommandOptions {
  /// The commands to be executed on the server
  List<String> commands;
}

class ExecuteCommandParams {
  /// Arguments that the command should be invoked with.
  List<Object> arguments;

  /// The identifier of the actual command handler.
  String command;
}

/// Execute command registration options.
class ExecuteCommandRegistrationOptions {
  /// The commands to be executed on the server
  List<String> commands;
}

abstract class FailureHandlingKind {
  /// Applying the workspace change is simply aborted if one of the changes
  /// provided fails. All operations executed before the failing operation stay
  /// executed.
  static const Abort = 'abort';

  /// If the workspace edit contains only textual file changes they are executed
  /// transactional. If resource changes (create, rename or delete file) are
  /// part of the change the failure handling startegy is abort.
  static const TextOnlyTransactional = 'textOnlyTransactional';

  /// All operations are executed transactional. That means they either all
  /// succeed or no changes at all are applied to the workspace.
  static const Transactional = 'transactional';

  /// The client tries to undo the operations already executed. But there is no
  /// guaruntee that this is succeeding.
  static const Undo = 'undo';
}

/// The file event type.
abstract class FileChangeType {
  /// The file got changed.
  static const Changed = 2;

  /// The file got created.
  static const Created = 1;

  /// The file got deleted.
  static const Deleted = 3;
}

/// An event describing a file change.
class FileEvent {
  /// The change type.
  num type;

  /// The file's URI.
  String /*DocumentUri*/ uri;
}

class FileSystemWatcher {
  /// The  glob pattern to watch
  String globPattern;

  /// The kind of events of interest. If omitted it defaults to WatchKind.Create
  /// | WatchKind.Change | WatchKind.Delete which is 7.
  num kind;
}

/// Represents a folding range.
class FoldingRange {
  /// The zero-based character offset before the folded range ends. If not
  /// defined, defaults to the length of the end line.
  num endCharacter;

  /// The zero-based line number where the folded range ends.
  num endLine;

  /// Describes the kind of the folding range such as `comment' or 'region'. The
  /// kind is used to categorize folding ranges and used by commands like 'Fold
  /// all comments'. See [FoldingRangeKind](#FoldingRangeKind) for an
  /// enumeration of standardized kinds.
  String kind;

  /// The zero-based character offset from where the folded range starts. If not
  /// defined, defaults to the length of the start line.
  num startCharacter;

  /// The zero-based line number from where the folded range starts.
  num startLine;
}

class FoldingRangeParams {
  /// The text document.
  TextDocumentIdentifier textDocument;
}

/// Folding range provider options.
class FoldingRangeProviderOptions {}

/// Value-object describing what options formatting should use.
class FormattingOptions {
  /// Prefer spaces over tabs.
  bool insertSpaces;

  /// Size of a tab in spaces.
  num tabSize;
}

/// The result of a hover request.
class Hover {
  /// The hover's content
  Object /*Either<MarkedString, List<MarkedString>, MarkupContent>*/ contents;

  /// An optional range is a range inside a text document that is used to
  /// visualize a hover, e.g. by changing the background color.
  Range range;
}

class InitializeError {
  /// Indicates whether the client execute the following retry logic: (1) show
  /// the message provided by the ResponseError to the user (2) user selects
  /// retry or cancel (3) if user selected retry the initialize method is sent
  /// again.
  bool retry;

  /// If the protocol version provided by the client can't be handled by the
  /// server. @deprecated This initialize error got replaced by client
  /// capabilities. There is no version handshake in version 3.0x
  static const unknownProtocolVersion = 1;
}

class InitializeParams {
  /// The capabilities provided by the client (editor or tool)
  ClientCapabilities capabilities;

  /// User provided initialization options.
  Object initializationOptions;

  /// The process Id of the parent process that started the server. Is null if
  /// the process has not been started by another process. If the parent process
  /// is not alive then the server should exit (see exit notification) its
  /// process.
  num processId;

  /// The rootPath of the workspace. Is null if no folder is open.
  ///  @deprecated in favour of rootUri.
  String rootPath;

  /// The rootUri of the workspace. Is null if no folder is open. If both
  /// `rootPath` and `rootUri` are set `rootUri` wins.
  String /*DocumentUri*/ rootUri;

  /// The workspace folders configured in the client when the server starts.
  /// This property is only available if the client supports workspace folders.
  /// It can be `null` if the client supports workspace folders but none are
  /// configured.
  ///
  /// Since 3.6.0
  List<WorkspaceFolder> workspaceFolders;
}

class InitializeResult {
  /// The capabilities the language server provides.
  ServerCapabilities capabilities;
}

class InitializedParams {}

/// Defines whether the insert text in a completion item should be interpreted
/// as plain text or a snippet.
abstract class InsertTextFormat {
  /// The primary text to be inserted is treated as a plain string.
  static const PlainText = 1;

  /// The primary text to be inserted is treated as a snippet.
  ///
  /// A snippet can define tab stops and placeholders with `$1`, `$2` and
  /// `${3:foo}`. `$0` defines the final tab stop, it defaults to the end of the
  /// snippet. Placeholders with equal identifiers are linked, that is typing in
  /// one will update others too.
  static const Snippet = 2;
}

class Location {
  Range range;

  String /*DocumentUri*/ uri;
}

class LogMessageParams {
  /// The actual message
  String message;

  /// The message type. See {@link MessageType}
  num type;
}

/// A `MarkupContent` literal represents a string value which content is
/// interpreted base on its kind flag. Currently the protocol supports
/// `plaintext` and `markdown` as markup kinds.
///
/// If the kind is `markdown` then the value can contain fenced code blocks like
/// in GitHub issues. See
/// https://help.github.com/articles/creating-and-highlighting-code-blocks/#syntax-highlighting
///
/// Here is an example how such a string can be constructed using JavaScript /
/// TypeScript: ```ts let markdown: MarkdownContent = {
///
/// kind: MarkupKind.Markdown,
/// 	value: [
/// 		'# Header',
/// 		'Some text',
/// 		'```typescript',
/// 		'someCode();',
/// 		'```'
/// 	].join('\n') }; ```
///  *Please Note* that clients might sanitize the return markdown. A client
/// could decide to remove HTML from the markdown to avoid script execution.
class MarkupContent {
  /// The type of the Markup
  MarkupKind kind;

  /// The content itself
  String value;
}

/// Describes the content type that a client supports in various result literals
/// like `Hover`, `ParameterInfo` or `CompletionItem`.
///
/// Please note that `MarkupKinds` must not start with a `$`. This kinds are
/// reserved for internal usage.
abstract class MarkupKind {
  /// Markdown is supported as a content format
  static const Markdown = 'markdown';

  /// Plain text is supported as a content format
  static const PlainText = 'plaintext';
}

class Message {
  String jsonrpc;
}

class MessageActionItem {
  /// A short title like 'Retry', 'Open Log' etc.
  String title;
}

abstract class MessageType {
  /// An error message.
  static const Error = 1;

  /// An information message.
  static const Info = 3;

  /// A log message.
  static const Log = 4;

  /// A warning message.
  static const Warning = 2;
}

class NotificationMessage {
  /// The method to be invoked.
  String method;
}

/// Represents a parameter of a callable-signature. A parameter can have a label
/// and a doc-comment.
class ParameterInformation {
  /// The human-readable doc-comment of this parameter. Will be shown in the UI
  /// but can be omitted.
  Object /*Either<String, MarkupContent>*/ documentation;

  /// The label of this parameter. Will be shown in the UI.
  String label;
}

class Position {
  /// Character offset on a line in a document (zero-based). Assuming that the
  /// line is represented as a string, the `character` value represents the gap
  /// between the `character` and `character + 1`.
  ///
  /// If the character value is greater than the line length it defaults back to
  /// the line length.
  num character;

  /// Line position in a document (zero-based).
  num line;
}

class PublishDiagnosticsParams {
  /// An array of diagnostic information items.
  List<Diagnostic> diagnostics;

  /// The URI for which diagnostic information is reported.
  String /*DocumentUri*/ uri;
}

class Range {
  /// The range's end position.
  Position end;

  /// The range's start position.
  Position start;
}

class ReferenceContext {
  /// Include the declaration of the current symbol.
  bool includeDeclaration;
}

class ReferenceParams {
  ReferenceContext context;
}

/// General parameters to register for a capability.
class Registration {
  /// The id used to register the request. The id can be used to deregister the
  /// request again.
  String id;

  /// The method / capability to register for.
  String method;

  /// Options necessary for the registration.
  Object registerOptions;
}

class RegistrationParams {
  List<Registration> registrations;
}

/// Rename file operation
class RenameFile {
  /// The new location.
  String newUri;

  /// The old (existing) location.
  String oldUri;

  /// Rename options.
  RenameFileOptions options;
}

/// Rename file options
class RenameFileOptions {
  /// Ignores if target exists.
  bool ignoreIfExists;

  /// Overwrite target if existing. Overwrite wins over `ignoreIfExists`
  bool overwrite;
}

/// Rename options
class RenameOptions {
  /// Renames should be checked and tested before being executed.
  bool prepareProvider;
}

class RenameParams {
  /// The new name of the symbol. If the given name is not valid the request
  /// must return a [ResponseError](#ResponseError) with an appropriate message
  /// set.
  String newName;

  /// The position at which this request was sent.
  Position position;

  /// The document to rename.
  TextDocumentIdentifier textDocument;
}

class RenameRegistrationOptions {
  /// Renames should be checked and tested for validity before being executed.
  bool prepareProvider;
}

class RequestMessage {
  /// The request id.
  Object /*Either<num, String>*/ id;

  /// The method to be invoked.
  String method;
}

abstract class ResourceOperationKind {
  /// Supports creating new files and folders.
  static const Create = 'create';

  /// Supports deleting existing files and folders.
  static const Delete = 'delete';

  /// Supports renaming existing files and folders.
  static const Rename = 'rename';
}

class ResponseMessage {
  /// The request id.
  Object /*Either<num, String>*/ id;

  /// The result of a request. This can be omitted in the case of an error.
  Object result;
}

/// Save options.
class SaveOptions {
  /// The client is supposed to include the content on save.
  bool includeText;
}

class ServerCapabilities {
  /// Whether the server wants to receive workspace folder change notifications.
  ///
  /// If a strings is provided the string is treated as a ID under which the
  /// notification is registered on the client side. The ID can be used to
  /// unregister for these events using the `client/unregisterCapability`
  /// request.
  Object /*Either<String, bool>*/ changeNotifications;

  /// The server provides code actions. The `CodeActionOptions` return type is
  /// only valid if the client signals code action literal support via the
  /// property `textDocument.codeAction.codeActionLiteralSupport`.
  Object /*Either<bool, CodeActionOptions>*/ codeActionProvider;

  /// The server provides code lens.
  CodeLensOptions codeLensProvider;

  /// The server provides completion support.
  CompletionOptions completionProvider;

  /// The server provides goto definition support.
  bool definitionProvider;

  /// The server provides document formatting.
  bool documentFormattingProvider;

  /// The server provides document highlight support.
  bool documentHighlightProvider;

  /// The server provides document link support.
  DocumentLinkOptions documentLinkProvider;

  /// The server provides document formatting on typing.
  DocumentOnTypeFormattingOptions documentOnTypeFormattingProvider;

  /// The server provides document range formatting.
  bool documentRangeFormattingProvider;

  /// The server provides document symbol support.
  bool documentSymbolProvider;

  /// The server provides execute command support.
  ExecuteCommandOptions executeCommandProvider;

  /// The server provides hover support.
  bool hoverProvider;

  /// The server provides find references support.
  bool referencesProvider;

  /// The server provides rename support. RenameOptions may only be specified if
  /// the client states that it supports `prepareSupport` in its initial
  /// `initialize` request.
  Object /*Either<bool, RenameOptions>*/ renameProvider;

  /// The server provides signature help support.
  SignatureHelpOptions signatureHelpProvider;

  /// The server has support for workspace folders
  bool supported;

  /// Defines how text documents are synced. Is either a detailed structure
  /// defining each notification or for backwards compatibility the
  /// TextDocumentSyncKind number. If omitted it defaults to
  /// `TextDocumentSyncKind.None`.
  Object /*Either<TextDocumentSyncOptions, num>*/ textDocumentSync;

  /// The server provides workspace symbol support.
  bool workspaceSymbolProvider;
}

class ShowMessageParams {
  /// The actual message.
  String message;

  /// The message type. See {@link MessageType}.
  num type;
}

class ShowMessageRequestParams {
  /// The message action items to present.
  List<MessageActionItem> actions;

  /// The actual message
  String message;

  /// The message type. See {@link MessageType}
  num type;
}

/// Signature help represents the signature of something callable. There can be
/// multiple signature but only one active and only one active parameter.
class SignatureHelp {
  /// The active parameter of the active signature. If omitted or the value lies
  /// outside the range of `signatures[activeSignature].parameters` defaults to
  /// 0 if the active signature has parameters. If the active signature has no
  /// parameters it is ignored. In future version of the protocol this property
  /// might become mandatory to better express the active parameter if the
  /// active signature does have any.
  num activeParameter;

  /// The active signature. If omitted or the value lies outside the range of
  /// `signatures` the value defaults to zero or is ignored if
  /// `signatures.length === 0`. Whenever possible implementors should make an
  /// active decision about the active signature and shouldn't rely on a default
  /// value. In future version of the protocol this property might become
  /// mandatory to better express this.
  num activeSignature;

  /// One or more signatures.
  List<SignatureInformation> signatures;
}

/// Signature help options.
class SignatureHelpOptions {
  /// The characters that trigger signature help automatically.
  List<String> triggerCharacters;
}

class SignatureHelpRegistrationOptions {
  /// The characters that trigger signature help automatically.
  List<String> triggerCharacters;
}

/// Represents the signature of something callable. A signature can have a
/// label, like a function-name, a doc-comment, and a set of parameters.
class SignatureInformation {
  /// The human-readable doc-comment of this signature. Will be shown in the UI
  /// but can be omitted.
  Object /*Either<String, MarkupContent>*/ documentation;

  /// The label of this signature. Will be shown in the UI.
  String label;

  /// The parameters of this signature.
  List<ParameterInformation> parameters;
}

/// Static registration options to be returned in the initialize request.
class StaticRegistrationOptions {
  /// The id used to register the request. The id can be used to deregister the
  /// request again. See also Registration#id.
  String id;
}

/// Represents information about programming constructs like variables, classes,
/// interfaces etc.
class SymbolInformation {
  /// The name of the symbol containing this symbol. This information is for
  /// user interface purposes (e.g. to render a qualifier in the user interface
  /// if necessary). It can't be used to re-infer a hierarchy for the document
  /// symbols.
  String containerName;

  /// Indicates if this symbol is deprecated.
  bool deprecated;

  /// The kind of this symbol.
  num kind;

  /// The location of this symbol. The location's range is used by a tool to
  /// reveal the location in the editor. If the symbol is selected in the tool
  /// the range's start information is used to position the cursor. So the range
  /// usually spans more then the actual symbol's name and does normally include
  /// things like visibility modifiers.
  ///
  /// The range doesn't have to denote a node range in the sense of a abstract
  /// syntax tree. It can therefore not be used to re-construct a hierarchy of
  /// the symbols.
  Location location;

  /// The name of this symbol.
  String name;
}

/// A symbol kind.
abstract class SymbolKind {
  static const Array = 18;

  static const Boolean = 17;

  static const Class = 5;

  static const Constant = 14;

  static const Constructor = 9;

  static const Enum = 10;

  static const EnumMember = 22;

  static const Event = 24;

  static const Field = 8;

  static const File = 1;

  static const Function = 12;

  static const Interface = 11;

  static const Key = 20;

  static const Method = 6;

  static const Module = 2;

  static const Namespace = 3;

  static const Null = 21;

  static const Number = 16;

  static const Object = 19;

  static const Operator = 25;

  static const Package = 4;

  static const Property = 7;

  static const String = 15;

  static const Struct = 23;

  static const TypeParameter = 26;

  static const Variable = 13;
}

/// Describe options to be used when registering for text document change
/// events.
class TextDocumentChangeRegistrationOptions {
  /// How documents are synced to the server. See TextDocumentSyncKind.Full and
  /// TextDocumentSyncKind.Incremental.
  num syncKind;
}

/// Text document specific client capabilities.
class TextDocumentClientCapabilities {
  /// The client supports did save notifications.
  bool didSave;

  /// Whether text document synchronization supports dynamic registration.
  bool dynamicRegistration;

  /// The client supports sending will save notifications.
  bool willSave;

  /// The client supports sending a will save request and waits for a response
  /// providing text edits which will be applied to the document before it is
  /// saved.
  bool willSaveWaitUntil;
}

/// An event describing a change to a text document. If range and rangeLength
/// are omitted the new text is considered to be the full content of the
/// document.
class TextDocumentContentChangeEvent {
  /// The range of the document that changed.
  Range range;

  /// The length of the range that got replaced.
  num rangeLength;

  /// The new text of the range/document.
  String text;
}

class TextDocumentEdit {
  /// The edits to be applied.
  List<TextEdit> edits;

  /// The text document to change.
  VersionedTextDocumentIdentifier textDocument;
}

class TextDocumentIdentifier {
  /// The text document's URI.
  String /*DocumentUri*/ uri;
}

class TextDocumentItem {
  /// The text document's language identifier.
  String languageId;

  /// The content of the opened text document.
  String text;

  /// The text document's URI.
  String /*DocumentUri*/ uri;

  /// The version number of this document (it will increase after each change,
  /// including undo/redo).
  num version;
}

class TextDocumentPositionParams {
  /// The position inside the text document.
  Position position;

  /// The text document.
  TextDocumentIdentifier textDocument;
}

class TextDocumentRegistrationOptions {
  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  List<DocumentFilter> /*DocumentSelector*/ documentSelector;
}

/// Represents reasons why a text document is saved.
abstract class TextDocumentSaveReason {
  /// Automatic after a delay.
  static const AfterDelay = 2;

  /// When the editor lost focus.
  static const FocusOut = 3;

  /// Manually triggered, e.g. by the user pressing save, by starting debugging,
  /// or by an API call.
  static const Manual = 1;
}

class TextDocumentSaveRegistrationOptions {
  /// The client is supposed to include the content on save.
  bool includeText;
}

/// Defines how the host (editor) should sync document changes to the language
/// server.
abstract class TextDocumentSyncKind {
  /// Documents are synced by always sending the full content of the document.
  static const Full = 1;

  /// Documents are synced by sending the full content on open. After that only
  /// incremental updates to the document are send.
  static const Incremental = 2;

  /// Documents should not be synced at all.
  static const None = 0;
}

class TextDocumentSyncOptions {
  /// Change notifications are sent to the server. See
  /// TextDocumentSyncKind.None, TextDocumentSyncKind.Full and
  /// TextDocumentSyncKind.Incremental. If omitted it defaults to
  /// TextDocumentSyncKind.None.
  num change;

  /// Open and close notifications are sent to the server.
  bool openClose;

  /// Save notifications are sent to the server.
  SaveOptions save;

  /// Will save notifications are sent to the server.
  bool willSave;

  /// Will save wait until requests are sent to the server.
  bool willSaveWaitUntil;
}

class TextEdit {
  /// The string to be inserted. For delete operations use an empty string.
  String newText;

  /// The range of the text document to be manipulated. To insert text into a
  /// document create a range where start === end.
  Range range;
}

/// General parameters to unregister a capability.
class Unregistration {
  /// The id used to unregister the request or notification. Usually an id
  /// provided during the register request.
  String id;

  /// The method / capability to unregister for.
  String method;
}

class UnregistrationParams {
  List<Unregistration> unregisterations;
}

class VersionedTextDocumentIdentifier {
  /// The version number of this document. If a versioned text document
  /// identifier is sent from the server to the client and the file is not open
  /// in the editor (the server has not received an open notification before)
  /// the server can send `null` to indicate that the version is known and the
  /// content on disk is the truth (as speced with document content ownership).
  ///
  /// The version number of a document will increase after each change,
  /// including undo/redo. The number doesn't need to be consecutive.
  num version;
}

abstract class WatchKind {
  /// Interested in change events
  static const Change = 2;

  /// Interested in create events.
  static const Create = 1;

  /// Interested in delete events
  static const Delete = 4;
}

/// The parameters send in a will save text document notification.
class WillSaveTextDocumentParams {
  /// The 'TextDocumentSaveReason'.
  num reason;

  /// The document that will be saved.
  TextDocumentIdentifier textDocument;
}

/// Workspace specific client capabilities.
class WorkspaceClientCapabilities {
  /// The client supports applying batch edits to the workspace by supporting
  /// the request 'workspace/applyEdit'
  bool applyEdit;

  /// The client supports versioned document changes in `WorkspaceEdit`s
  bool documentChanges;

  /// The failure handling strategy of a client if applying the workspace edit
  /// failes.
  FailureHandlingKind failureHandling;

  /// The resource operations the client supports. Clients should at least
  /// support 'create', 'rename' and 'delete' files and folders.
  List<ResourceOperationKind> resourceOperations;
}

class WorkspaceEdit {}

class WorkspaceFolder {
  /// The name of the workspace folder. Defaults to the uri's basename.
  String name;

  /// The associated URI for this workspace folder.
  String uri;
}

/// The workspace folder change event.
class WorkspaceFoldersChangeEvent {
  /// The array of added workspace folders
  List<WorkspaceFolder> added;

  /// The array of the removed workspace folders
  List<WorkspaceFolder> removed;
}

/// The parameters of a Workspace Symbol Request.
class WorkspaceSymbolParams {
  /// A non-empty query string
  String query;
}
