// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/lsp_spec/generate_all.dart".

import 'package:analysis_server/lsp_protocol/protocol_special.dart';

class ApplyWorkspaceEditParams {
  ApplyWorkspaceEditParams(this.edit, this.label);

  /// The edits to apply.
  final WorkspaceEdit edit;

  /// An optional label of the workspace edit. This label is presented in the
  /// user interface for example on an undo stack to undo the workspace edit.
  final String label;
}

class ApplyWorkspaceEditResponse {
  ApplyWorkspaceEditResponse(this.applied);

  /// Indicates whether the edit was applied or not.
  final bool applied;
}

class CancelParams {
  CancelParams(this.id);

  /// The request id to cancel.
  ///
  /// Must be num or String.
  final Object id;
}

class ClientCapabilities {
  ClientCapabilities(this.experimental, this.textDocument, this.workspace);

  /// Experimental client capabilities.
  final Object experimental;

  /// Text document specific client capabilities.
  final TextDocumentClientCapabilities textDocument;

  /// Workspace specific client capabilities.
  final WorkspaceClientCapabilities workspace;
}

/// A code action represents a change that can be performed in code, e.g. to fix
/// a problem or to refactor code.
///
/// A CodeAction must set either `edit` and/or a `command`. If both are
/// supplied, the `edit` is applied first, then the `command` is executed.
class CodeAction {
  CodeAction(this.command, this.diagnostics, this.edit, this.kind, this.title);

  /// A command this code action executes. If a code action provides an edit and
  /// a command, first the edit is executed and then the command.
  final Command command;

  /// The diagnostics that this code action resolves.
  final List<Diagnostic> diagnostics;

  /// The workspace edit this code action performs.
  final WorkspaceEdit edit;

  /// The kind of the code action.
  ///
  /// Used to filter code actions.
  final String /*CodeActionKind*/ kind;

  /// A short, human-readable, title for this code action.
  final String title;
}

/// Contains additional diagnostic information about the context in which a code
/// action is run.
class CodeActionContext {
  CodeActionContext(this.diagnostics, this.only);

  /// An array of diagnostics.
  final List<Diagnostic> diagnostics;

  /// Requested kind of actions to return.
  ///
  /// Actions not of this kind are filtered out by the client before being
  /// shown. So servers can omit computing them.
  final List<String /*CodeActionKind*/ > only;
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
  ///
  /// - Extract method
  /// - Extract function
  /// - Extract variable
  /// - Extract interface from class
  /// - ...
  static const RefactorExtract = 'refactor.extract';

  /// Base kind for refactoring inline actions: 'refactor.inline'
  ///
  /// Example inline actions:
  ///
  /// - Inline function
  /// - Inline variable
  /// - Inline constant
  /// - ...
  static const RefactorInline = 'refactor.inline';

  /// Base kind for refactoring rewrite actions: 'refactor.rewrite'
  ///
  /// Example rewrite actions:
  ///
  /// - Convert JavaScript function to class
  /// - Add or remove parameter
  /// - Encapsulate field
  /// - Make method static
  /// - Move method to base class
  /// - ...
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
  CodeActionOptions(this.codeActionKinds);

  /// CodeActionKinds that this server may return.
  ///
  /// The list of kinds may be generic, such as `CodeActionKind.Refactor`, or
  /// the server may list out every specific kind they provide.
  final List<String /*CodeActionKind*/ > codeActionKinds;
}

/// Params for the CodeActionRequest
class CodeActionParams {
  CodeActionParams(this.context, this.range, this.textDocument);

  /// Context carrying additional information.
  final CodeActionContext context;

  /// The range for which the command was invoked.
  final Range range;

  /// The document in which the command was invoked.
  final TextDocumentIdentifier textDocument;
}

class CodeActionRegistrationOptions
    implements TextDocumentRegistrationOptions, CodeActionOptions {
  CodeActionRegistrationOptions(this.documentSelector, this.codeActionKinds);

  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  final List<DocumentFilter> /*DocumentSelector*/ documentSelector;

  /// CodeActionKinds that this server may return.
  ///
  /// The list of kinds may be generic, such as `CodeActionKind.Refactor`, or
  /// the server may list out every specific kind they provide.
  final List<String /*CodeActionKind*/ > codeActionKinds;
}

/// A code lens represents a command that should be shown along with source
/// text, like the number of references, a way to run tests, etc.
///
/// A code lens is _unresolved_ when no command is associated to it. For
/// performance reasons the creation of a code lens and resolving should be done
/// in two stages.
class CodeLens {
  CodeLens(this.command, this.data, this.range);

  /// The command this code lens represents.
  final Command command;

  /// A data entry field that is preserved on a code lens item between a code
  /// lens and a code lens resolve request.
  final Object data;

  /// The range in which this code lens is valid. Should only span a single
  /// line.
  final Range range;
}

/// Code Lens options.
class CodeLensOptions {
  CodeLensOptions(this.resolveProvider);

  /// Code lens has a resolve provider as well.
  final bool resolveProvider;
}

class CodeLensParams {
  CodeLensParams(this.textDocument);

  /// The document to request code lens for.
  final TextDocumentIdentifier textDocument;
}

class CodeLensRegistrationOptions implements TextDocumentRegistrationOptions {
  CodeLensRegistrationOptions(this.resolveProvider, this.documentSelector);

  /// Code lens has a resolve provider as well.
  final bool resolveProvider;

  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  final List<DocumentFilter> /*DocumentSelector*/ documentSelector;
}

/// Represents a color in RGBA space.
class Color {
  Color(this.alpha, this.blue, this.green, this.red);

  final num alpha;
  final num blue;
  final num green;
  final num red;
}

class ColorInformation {
  ColorInformation(this.color, this.range);

  /// The actual color value for this color range.
  final Color color;

  /// The range in the document where this color appears.
  final Range range;
}

class ColorPresentation {
  ColorPresentation(this.additionalTextEdits, this.label, this.textEdit);

  /// An optional array of additional text edits ([TextEdit]) that are applied
  /// when selecting this color presentation. Edits must not overlap with the
  /// main [edit](#ColorPresentation.textEdit) nor with themselves.
  final List<TextEdit> additionalTextEdits;

  /// The label of this color presentation. It will be shown on the color picker
  /// header. By default this is also the text that is inserted when selecting
  /// this color presentation.
  final String label;

  /// An edit ([TextEdit]) which is applied to a document when selecting this
  /// presentation for the color.  When `falsy` the
  /// [label](#ColorPresentation.label) is used.
  final TextEdit textEdit;
}

class ColorPresentationParams {
  ColorPresentationParams(this.color, this.range, this.textDocument);

  /// The color information to request presentations for.
  final Color color;

  /// The range where the color would be inserted. Serves as a context.
  final Range range;

  /// The text document.
  final TextDocumentIdentifier textDocument;
}

/// Color provider options.
class ColorProviderOptions {}

class Command {
  Command(this.arguments, this.command, this.title);

  /// Arguments that the command handler should be invoked with.
  final List<Object> arguments;

  /// The identifier of the actual command handler.
  final String command;

  /// Title of the command, like `save`.
  final String title;
}

/// Contains additional information about the context in which a completion
/// request is triggered.
class CompletionContext {
  CompletionContext(this.triggerCharacter, this.triggerKind);

  /// The trigger character (a single character) that has trigger code complete.
  /// Is undefined if `triggerKind !== CompletionTriggerKind.TriggerCharacter`
  final String triggerCharacter;

  /// How the completion was triggered.
  final CompletionTriggerKind triggerKind;
}

class CompletionItem {
  CompletionItem(
      this.additionalTextEdits,
      this.command,
      this.commitCharacters,
      this.data,
      this.deprecated,
      this.detail,
      this.documentation,
      this.filterText,
      this.insertText,
      this.insertTextFormat,
      this.kind,
      this.label,
      this.preselect,
      this.sortText,
      this.textEdit);

  /// An optional array of additional text edits that are applied when selecting
  /// this completion. Edits must not overlap (including the same insert
  /// position) with the main edit nor with themselves.
  ///
  /// Additional text edits should be used to change text unrelated to the
  /// current cursor position (for example adding an import statement at the top
  /// of the file if the completion item will insert an unqualified type).
  final List<TextEdit> additionalTextEdits;

  /// An optional command that is executed *after* inserting this completion.
  /// *Note* that additional modifications to the current document should be
  /// described with the additionalTextEdits-property.
  final Command command;

  /// An optional set of characters that when pressed while this completion is
  /// active will accept it first and then type that character. *Note* that all
  /// commit characters should have `length=1` and that superfluous characters
  /// will be ignored.
  final List<String> commitCharacters;

  /// An data entry field that is preserved on a completion item between a
  /// completion and a completion resolve request.
  final Object data;

  /// Indicates if this item is deprecated.
  final bool deprecated;

  /// A human-readable string with additional information about this item, like
  /// type or symbol information.
  final String detail;

  /// A human-readable string that represents a doc-comment.
  ///
  /// Must be String or MarkupContent.
  final Object documentation;

  /// A string that should be used when filtering a set of completion items.
  /// When `falsy` the label is used.
  final String filterText;

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
  final String insertText;

  /// The format of the insert text. The format applies to both the `insertText`
  /// property and the `newText` property of a provided `textEdit`.
  final InsertTextFormat insertTextFormat;

  /// The kind of this completion item. Based of the kind an icon is chosen by
  /// the editor.
  final num kind;

  /// The label of this completion item. By default also the text that is
  /// inserted when selecting this completion.
  final String label;

  /// Select this item when showing.
  ///
  /// *Note* that only one completion item can be selected and that the tool /
  /// client decides which item that is. The rule is that the *first* item of
  /// those that match best is selected.
  final bool preselect;

  /// A string that should be used when comparing this item with other items.
  /// When `falsy` the label is used.
  final String sortText;

  /// An edit which is applied to a document when selecting this completion.
  /// When an edit is provided the value of `insertText` is ignored.
  ///
  /// *Note:* The range of the edit must be a single line range and it must
  /// contain the position at which completion has been requested.
  final TextEdit textEdit;
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

/// Represents a collection of completion items ([CompletionItem]) to be
/// presented in the editor.
class CompletionList {
  CompletionList(this.isIncomplete, this.items);

  /// This list it not complete. Further typing should result in recomputing
  /// this list.
  final bool isIncomplete;

  /// The completion items.
  final List<CompletionItem> items;
}

/// Completion options.
class CompletionOptions {
  CompletionOptions(this.resolveProvider, this.triggerCharacters);

  /// The server provides support to resolve additional information for a
  /// completion item.
  final bool resolveProvider;

  /// The characters that trigger completion automatically.
  final List<String> triggerCharacters;
}

class CompletionParams implements TextDocumentPositionParams {
  CompletionParams(this.context, this.position, this.textDocument);

  /// The completion context. This is only available if the client specifies to
  /// send this using `ClientCapabilities.textDocument.completion.contextSupport
  /// === true`
  final CompletionContext context;

  /// The position inside the text document.
  final Position position;

  /// The text document.
  final TextDocumentIdentifier textDocument;
}

class CompletionRegistrationOptions implements TextDocumentRegistrationOptions {
  CompletionRegistrationOptions(
      this.resolveProvider, this.triggerCharacters, this.documentSelector);

  /// The server provides support to resolve additional information for a
  /// completion item.
  final bool resolveProvider;

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
  final List<String> triggerCharacters;

  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  final List<DocumentFilter> /*DocumentSelector*/ documentSelector;
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
  ConfigurationItem(this.scopeUri, this.section);

  /// The scope to get the configuration section for.
  final String scopeUri;

  /// The configuration section asked for.
  final String section;
}

class ConfigurationParams {
  ConfigurationParams(this.items);

  final List<ConfigurationItem> items;
}

/// Create file operation
class CreateFile implements FileOperation {
  CreateFile(this.options, this.uri);

  /// Additional options
  final CreateFileOptions options;

  /// The resource to create.
  final String uri;
}

/// Options to create a file.
class CreateFileOptions {
  CreateFileOptions(this.ignoreIfExists, this.overwrite);

  /// Ignore if exists.
  final bool ignoreIfExists;

  /// Overwrite existing file. Overwrite wins over `ignoreIfExists`
  final bool overwrite;
}

/// Delete file operation
class DeleteFile implements FileOperation {
  DeleteFile(this.options, this.uri);

  /// Delete options.
  final DeleteFileOptions options;

  /// The file to delete.
  final String uri;
}

/// Delete file options
class DeleteFileOptions {
  DeleteFileOptions(this.ignoreIfNotExists, this.recursive);

  /// Ignore the operation if the file doesn't exist.
  final bool ignoreIfNotExists;

  /// Delete the content recursively if a folder is denoted.
  final bool recursive;
}

class Diagnostic {
  Diagnostic(this.code, this.message, this.range, this.relatedInformation,
      this.severity, this.source);

  /// The diagnostic's code, which might appear in the user interface.
  ///
  /// Must be num or String.
  final Object code;

  /// The diagnostic's message.
  final String message;

  /// The range at which the message applies.
  final Range range;

  /// An array of related diagnostic information, e.g. when symbol-names within
  /// a scope collide all definitions can be marked via this property.
  final List<DiagnosticRelatedInformation> relatedInformation;

  /// The diagnostic's severity. Can be omitted. If omitted it is up to the
  /// client to interpret diagnostics as error, warning, info or hint.
  final num severity;

  /// A human-readable string describing the source of this diagnostic, e.g.
  /// 'typescript' or 'super lint'.
  final String source;
}

/// Represents a related message and source code location for a diagnostic. This
/// should be used to point to code locations that cause or related to a
/// diagnostics, e.g when duplicating a symbol in a scope.
class DiagnosticRelatedInformation {
  DiagnosticRelatedInformation(this.location, this.message);

  /// The location of this related diagnostic information.
  final Location location;

  /// The message of this related diagnostic information.
  final String message;
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
  DidChangeConfigurationParams(this.settings);

  /// The actual changed settings
  final Object settings;
}

class DidChangeTextDocumentParams {
  DidChangeTextDocumentParams(this.contentChanges, this.textDocument);

  /// The actual content changes. The content changes describe single state
  /// changes to the document. So if there are two content changes c1 and c2 for
  /// a document in state S then c1 move the document to S' and c2 to S''.
  final List<TextDocumentContentChangeEvent> contentChanges;

  /// The document that did change. The version number points to the version
  /// after all provided content changes have been applied.
  final VersionedTextDocumentIdentifier textDocument;
}

class DidChangeWatchedFilesParams {
  DidChangeWatchedFilesParams(this.changes);

  /// The actual file events.
  final List<FileEvent> changes;
}

/// Describe options to be used when registering for text document change
/// events.
class DidChangeWatchedFilesRegistrationOptions {
  DidChangeWatchedFilesRegistrationOptions(this.watchers);

  /// The watchers to register.
  final List<FileSystemWatcher> watchers;
}

class DidChangeWorkspaceFoldersParams {
  DidChangeWorkspaceFoldersParams(this.event);

  /// The actual workspace folder change event.
  final WorkspaceFoldersChangeEvent event;
}

class DidCloseTextDocumentParams {
  DidCloseTextDocumentParams(this.textDocument);

  /// The document that was closed.
  final TextDocumentIdentifier textDocument;
}

class DidOpenTextDocumentParams {
  DidOpenTextDocumentParams(this.textDocument);

  /// The document that was opened.
  final TextDocumentItem textDocument;
}

class DidSaveTextDocumentParams {
  DidSaveTextDocumentParams(this.text, this.textDocument);

  /// Optional the content when saved. Depends on the includeText value when the
  /// save notification was requested.
  final String text;

  /// The document that was saved.
  final TextDocumentIdentifier textDocument;
}

class DocumentFilter {
  DocumentFilter(this.language, this.pattern, this.scheme);

  /// A language id, like `typescript`.
  final String language;

  /// A glob pattern, like `*.{ts,js}`.
  final String pattern;

  /// A Uri [scheme](#Uri.scheme), like `file` or `untitled`.
  final String scheme;
}

class DocumentFormattingParams {
  DocumentFormattingParams(this.options, this.textDocument);

  /// The format options.
  final FormattingOptions options;

  /// The document to format.
  final TextDocumentIdentifier textDocument;
}

/// A document highlight is a range inside a text document which deserves
/// special attention. Usually a document highlight is visualized by changing
/// the background color of its range.
class DocumentHighlight {
  DocumentHighlight(this.kind, this.range);

  /// The highlight kind, default is DocumentHighlightKind.Text.
  final num kind;

  /// The range this highlight applies to.
  final Range range;
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
  DocumentLink(this.data, this.range, this.target);

  /// A data entry field that is preserved on a document link between a
  /// DocumentLinkRequest and a DocumentLinkResolveRequest.
  final Object data;

  /// The range this link applies to.
  final Range range;

  /// The uri this link points to. If missing a resolve request is sent later.
  final String /*DocumentUri*/ target;
}

/// Document link options.
class DocumentLinkOptions {
  DocumentLinkOptions(this.resolveProvider);

  /// Document links have a resolve provider as well.
  final bool resolveProvider;
}

class DocumentLinkParams {
  DocumentLinkParams(this.textDocument);

  /// The document to provide document links for.
  final TextDocumentIdentifier textDocument;
}

class DocumentLinkRegistrationOptions
    implements TextDocumentRegistrationOptions {
  DocumentLinkRegistrationOptions(this.resolveProvider, this.documentSelector);

  /// Document links have a resolve provider as well.
  final bool resolveProvider;

  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  final List<DocumentFilter> /*DocumentSelector*/ documentSelector;
}

/// Format document on type options.
class DocumentOnTypeFormattingOptions {
  DocumentOnTypeFormattingOptions(
      this.firstTriggerCharacter, this.moreTriggerCharacter);

  /// A character on which formatting should be triggered, like `}`.
  final String firstTriggerCharacter;

  /// More trigger characters.
  final List<String> moreTriggerCharacter;
}

class DocumentOnTypeFormattingParams {
  DocumentOnTypeFormattingParams(
      this.ch, this.options, this.position, this.textDocument);

  /// The character that has been typed.
  final String ch;

  /// The format options.
  final FormattingOptions options;

  /// The position at which this request was sent.
  final Position position;

  /// The document to format.
  final TextDocumentIdentifier textDocument;
}

class DocumentOnTypeFormattingRegistrationOptions
    implements TextDocumentRegistrationOptions {
  DocumentOnTypeFormattingRegistrationOptions(this.firstTriggerCharacter,
      this.moreTriggerCharacter, this.documentSelector);

  /// A character on which formatting should be triggered, like `}`.
  final String firstTriggerCharacter;

  /// More trigger characters.
  final List<String> moreTriggerCharacter;

  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  final List<DocumentFilter> /*DocumentSelector*/ documentSelector;
}

class DocumentRangeFormattingParams {
  DocumentRangeFormattingParams(this.options, this.range, this.textDocument);

  /// The format options
  final FormattingOptions options;

  /// The range to format
  final Range range;

  /// The document to format.
  final TextDocumentIdentifier textDocument;
}

/// Represents programming constructs like variables, classes, interfaces etc.
/// that appear in a document. Document symbols can be hierarchical and they
/// have two ranges: one that encloses its definition and one that points to its
/// most interesting range, e.g. the range of an identifier.
class DocumentSymbol {
  DocumentSymbol(this.children, this.deprecated, this.detail, this.kind,
      this.name, this.range, this.selectionRange);

  /// Children of this symbol, e.g. properties of a class.
  final List<DocumentSymbol> children;

  /// Indicates if this symbol is deprecated.
  final bool deprecated;

  /// More detail for this symbol, e.g the signature of a function.
  final String detail;

  /// The kind of this symbol.
  final SymbolKind kind;

  /// The name of this symbol.
  final String name;

  /// The range enclosing this symbol not including leading/trailing whitespace
  /// but everything else like comments. This information is typically used to
  /// determine if the clients cursor is inside the symbol to reveal in the
  /// symbol in the UI.
  final Range range;

  /// The range that should be selected and revealed when this symbol is being
  /// picked, e.g the name of a function. Must be contained by the `range`.
  final Range selectionRange;
}

class DocumentSymbolParams {
  DocumentSymbolParams(this.textDocument);

  /// The text document.
  final TextDocumentIdentifier textDocument;
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
  ExecuteCommandOptions(this.commands);

  /// The commands to be executed on the server
  final List<String> commands;
}

class ExecuteCommandParams {
  ExecuteCommandParams(this.arguments, this.command);

  /// Arguments that the command should be invoked with.
  final List<Object> arguments;

  /// The identifier of the actual command handler.
  final String command;
}

/// Execute command registration options.
class ExecuteCommandRegistrationOptions {
  ExecuteCommandRegistrationOptions(this.commands);

  /// The commands to be executed on the server
  final List<String> commands;
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
  FileEvent(this.type, this.uri);

  /// The change type.
  final num type;

  /// The file's URI.
  final String /*DocumentUri*/ uri;
}

class FileSystemWatcher {
  FileSystemWatcher(this.globPattern, this.kind);

  /// The  glob pattern to watch
  final String globPattern;

  /// The kind of events of interest. If omitted it defaults to WatchKind.Create
  /// | WatchKind.Change | WatchKind.Delete which is 7.
  final num kind;
}

/// Represents a folding range.
class FoldingRange {
  FoldingRange(this.endCharacter, this.endLine, this.kind, this.startCharacter,
      this.startLine);

  /// The zero-based character offset before the folded range ends. If not
  /// defined, defaults to the length of the end line.
  final num endCharacter;

  /// The zero-based line number where the folded range ends.
  final num endLine;

  /// Describes the kind of the folding range such as `comment' or 'region'. The
  /// kind is used to categorize folding ranges and used by commands like 'Fold
  /// all comments'. See [FoldingRangeKind] for an enumeration of standardized
  /// kinds.
  final String kind;

  /// The zero-based character offset from where the folded range starts. If not
  /// defined, defaults to the length of the start line.
  final num startCharacter;

  /// The zero-based line number from where the folded range starts.
  final num startLine;
}

class FoldingRangeParams {
  FoldingRangeParams(this.textDocument);

  /// The text document.
  final TextDocumentIdentifier textDocument;
}

/// Folding range provider options.
class FoldingRangeProviderOptions {}

/// Value-object describing what options formatting should use.
class FormattingOptions {
  FormattingOptions(this.insertSpaces, this.tabSize);

  /// Prefer spaces over tabs.
  final bool insertSpaces;

  /// Size of a tab in spaces.
  final num tabSize;
}

/// The result of a hover request.
class Hover {
  Hover(this.contents, this.range);

  /// The hover's content
  ///
  /// Must be MarkedString or List<MarkedString> or MarkupContent.
  final Object contents;

  /// An optional range is a range inside a text document that is used to
  /// visualize a hover, e.g. by changing the background color.
  final Range range;
}

class InitializeParams {
  InitializeParams(this.capabilities, this.initializationOptions,
      this.processId, this.rootPath, this.rootUri, this.workspaceFolders);

  /// The capabilities provided by the client (editor or tool)
  final ClientCapabilities capabilities;

  /// User provided initialization options.
  final Object initializationOptions;

  /// The process Id of the parent process that started the server. Is null if
  /// the process has not been started by another process. If the parent process
  /// is not alive then the server should exit (see exit notification) its
  /// process.
  final num processId;

  /// The rootPath of the workspace. Is null if no folder is open.
  ///  @deprecated in favour of rootUri.
  final String rootPath;

  /// The rootUri of the workspace. Is null if no folder is open. If both
  /// `rootPath` and `rootUri` are set `rootUri` wins.
  final String /*DocumentUri*/ rootUri;

  /// The workspace folders configured in the client when the server starts.
  /// This property is only available if the client supports workspace folders.
  /// It can be `null` if the client supports workspace folders but none are
  /// configured.
  ///
  /// Since 3.6.0
  final List<WorkspaceFolder> workspaceFolders;
}

class InitializeResult {
  InitializeResult(this.capabilities);

  /// The capabilities the language server provides.
  final ServerCapabilities capabilities;
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
  Location(this.range, this.uri);

  final Range range;
  final String /*DocumentUri*/ uri;
}

class LogMessageParams {
  LogMessageParams(this.message, this.type);

  /// The actual message
  final String message;

  /// The message type.
  final MessageType type;
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
///
/// *Please Note* that clients might sanitize the return markdown. A client
/// could decide to remove HTML from the markdown to avoid script execution.
class MarkupContent {
  MarkupContent(this.kind, this.value);

  /// The type of the Markup
  final MarkupKind kind;

  /// The content itself
  final String value;
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
  Message(this.jsonrpc);

  final String jsonrpc;
}

class MessageActionItem {
  MessageActionItem(this.title);

  /// A short title like 'Retry', 'Open Log' etc.
  final String title;
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

class NotificationMessage implements Message {
  NotificationMessage(this.method, this.jsonrpc);

  /// The method to be invoked.
  final String method;
  final String jsonrpc;
}

/// Represents a parameter of a callable-signature. A parameter can have a label
/// and a doc-comment.
class ParameterInformation {
  ParameterInformation(this.documentation, this.label);

  /// The human-readable doc-comment of this parameter. Will be shown in the UI
  /// but can be omitted.
  ///
  /// Must be String or MarkupContent.
  final Object documentation;

  /// The label of this parameter. Will be shown in the UI.
  final String label;
}

class Position {
  Position(this.character, this.line);

  /// Character offset on a line in a document (zero-based). Assuming that the
  /// line is represented as a string, the `character` value represents the gap
  /// between the `character` and `character + 1`.
  ///
  /// If the character value is greater than the line length it defaults back to
  /// the line length.
  final num character;

  /// Line position in a document (zero-based).
  final num line;
}

class PublishDiagnosticsParams {
  PublishDiagnosticsParams(this.diagnostics, this.uri);

  /// An array of diagnostic information items.
  final List<Diagnostic> diagnostics;

  /// The URI for which diagnostic information is reported.
  final String /*DocumentUri*/ uri;
}

class Range {
  Range(this.end, this.start);

  /// The range's end position.
  final Position end;

  /// The range's start position.
  final Position start;
}

class ReferenceContext {
  ReferenceContext(this.includeDeclaration);

  /// Include the declaration of the current symbol.
  final bool includeDeclaration;
}

class ReferenceParams implements TextDocumentPositionParams {
  ReferenceParams(this.context, this.position, this.textDocument);

  final ReferenceContext context;

  /// The position inside the text document.
  final Position position;

  /// The text document.
  final TextDocumentIdentifier textDocument;
}

/// General parameters to register for a capability.
class Registration {
  Registration(this.id, this.method, this.registerOptions);

  /// The id used to register the request. The id can be used to deregister the
  /// request again.
  final String id;

  /// The method / capability to register for.
  final String method;

  /// Options necessary for the registration.
  final Object registerOptions;
}

class RegistrationParams {
  RegistrationParams(this.registrations);

  final List<Registration> registrations;
}

/// Rename file operation
class RenameFile implements FileOperation {
  RenameFile(this.newUri, this.oldUri, this.options);

  /// The new location.
  final String newUri;

  /// The old (existing) location.
  final String oldUri;

  /// Rename options.
  final RenameFileOptions options;
}

/// Rename file options
class RenameFileOptions {
  RenameFileOptions(this.ignoreIfExists, this.overwrite);

  /// Ignores if target exists.
  final bool ignoreIfExists;

  /// Overwrite target if existing. Overwrite wins over `ignoreIfExists`
  final bool overwrite;
}

/// Rename options
class RenameOptions {
  RenameOptions(this.prepareProvider);

  /// Renames should be checked and tested before being executed.
  final bool prepareProvider;
}

class RenameParams {
  RenameParams(this.newName, this.position, this.textDocument);

  /// The new name of the symbol. If the given name is not valid the request
  /// must return a [ResponseError] with an appropriate message set.
  final String newName;

  /// The position at which this request was sent.
  final Position position;

  /// The document to rename.
  final TextDocumentIdentifier textDocument;
}

class RenameRegistrationOptions implements TextDocumentRegistrationOptions {
  RenameRegistrationOptions(this.prepareProvider, this.documentSelector);

  /// Renames should be checked and tested for validity before being executed.
  final bool prepareProvider;

  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  final List<DocumentFilter> /*DocumentSelector*/ documentSelector;
}

class RequestMessage implements Message {
  RequestMessage(this.id, this.method, this.jsonrpc);

  /// The request id.
  ///
  /// Must be num or String.
  final Object id;

  /// The method to be invoked.
  final String method;
  final String jsonrpc;
}

abstract class ResourceOperationKind {
  /// Supports creating new files and folders.
  static const Create = 'create';

  /// Supports deleting existing files and folders.
  static const Delete = 'delete';

  /// Supports renaming existing files and folders.
  static const Rename = 'rename';
}

class ResponseMessage implements Message {
  ResponseMessage(this.id, this.result, this.jsonrpc);

  /// The request id.
  ///
  /// Must be num or String.
  final Object id;

  /// The result of a request. This can be omitted in the case of an error.
  final Object result;
  final String jsonrpc;
}

/// Save options.
class SaveOptions {
  SaveOptions(this.includeText);

  /// The client is supposed to include the content on save.
  final bool includeText;
}

class ServerCapabilities {
  ServerCapabilities(
      this.changeNotifications,
      this.codeActionProvider,
      this.codeLensProvider,
      this.completionProvider,
      this.definitionProvider,
      this.documentFormattingProvider,
      this.documentHighlightProvider,
      this.documentLinkProvider,
      this.documentOnTypeFormattingProvider,
      this.documentRangeFormattingProvider,
      this.documentSymbolProvider,
      this.executeCommandProvider,
      this.hoverProvider,
      this.referencesProvider,
      this.renameProvider,
      this.signatureHelpProvider,
      this.supported,
      this.textDocumentSync,
      this.workspaceSymbolProvider);

  /// Whether the server wants to receive workspace folder change notifications.
  ///
  /// If a strings is provided the string is treated as a ID under which the
  /// notification is registered on the client side. The ID can be used to
  /// unregister for these events using the `client/unregisterCapability`
  /// request.
  ///
  /// Must be String or bool.
  final Object changeNotifications;

  /// The server provides code actions. The `CodeActionOptions` return type is
  /// only valid if the client signals code action literal support via the
  /// property `textDocument.codeAction.codeActionLiteralSupport`.
  ///
  /// Must be bool or CodeActionOptions.
  final Object codeActionProvider;

  /// The server provides code lens.
  final CodeLensOptions codeLensProvider;

  /// The server provides completion support.
  final CompletionOptions completionProvider;

  /// The server provides goto definition support.
  final bool definitionProvider;

  /// The server provides document formatting.
  final bool documentFormattingProvider;

  /// The server provides document highlight support.
  final bool documentHighlightProvider;

  /// The server provides document link support.
  final DocumentLinkOptions documentLinkProvider;

  /// The server provides document formatting on typing.
  final DocumentOnTypeFormattingOptions documentOnTypeFormattingProvider;

  /// The server provides document range formatting.
  final bool documentRangeFormattingProvider;

  /// The server provides document symbol support.
  final bool documentSymbolProvider;

  /// The server provides execute command support.
  final ExecuteCommandOptions executeCommandProvider;

  /// The server provides hover support.
  final bool hoverProvider;

  /// The server provides find references support.
  final bool referencesProvider;

  /// The server provides rename support. RenameOptions may only be specified if
  /// the client states that it supports `prepareSupport` in its initial
  /// `initialize` request.
  ///
  /// Must be bool or RenameOptions.
  final Object renameProvider;

  /// The server provides signature help support.
  final SignatureHelpOptions signatureHelpProvider;

  /// The server has support for workspace folders
  final bool supported;

  /// Defines how text documents are synced. Is either a detailed structure
  /// defining each notification or for backwards compatibility the
  /// TextDocumentSyncKind number. If omitted it defaults to
  /// `TextDocumentSyncKind.None`.
  ///
  /// Must be TextDocumentSyncOptions or num.
  final Object textDocumentSync;

  /// The server provides workspace symbol support.
  final bool workspaceSymbolProvider;
}

class ShowMessageParams {
  ShowMessageParams(this.message, this.type);

  /// The actual message.
  final String message;

  /// The message type.
  final MessageType type;
}

class ShowMessageRequestParams {
  ShowMessageRequestParams(this.actions, this.message, this.type);

  /// The message action items to present.
  final List<MessageActionItem> actions;

  /// The actual message
  final String message;

  /// The message type.
  final MessageType type;
}

/// Signature help represents the signature of something callable. There can be
/// multiple signature but only one active and only one active parameter.
class SignatureHelp {
  SignatureHelp(this.activeParameter, this.activeSignature, this.signatures);

  /// The active parameter of the active signature. If omitted or the value lies
  /// outside the range of `signatures[activeSignature].parameters` defaults to
  /// 0 if the active signature has parameters. If the active signature has no
  /// parameters it is ignored. In future version of the protocol this property
  /// might become mandatory to better express the active parameter if the
  /// active signature does have any.
  final num activeParameter;

  /// The active signature. If omitted or the value lies outside the range of
  /// `signatures` the value defaults to zero or is ignored if
  /// `signatures.length === 0`. Whenever possible implementors should make an
  /// active decision about the active signature and shouldn't rely on a default
  /// value. In future version of the protocol this property might become
  /// mandatory to better express this.
  final num activeSignature;

  /// One or more signatures.
  final List<SignatureInformation> signatures;
}

/// Signature help options.
class SignatureHelpOptions {
  SignatureHelpOptions(this.triggerCharacters);

  /// The characters that trigger signature help automatically.
  final List<String> triggerCharacters;
}

class SignatureHelpRegistrationOptions
    implements TextDocumentRegistrationOptions {
  SignatureHelpRegistrationOptions(
      this.triggerCharacters, this.documentSelector);

  /// The characters that trigger signature help automatically.
  final List<String> triggerCharacters;

  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  final List<DocumentFilter> /*DocumentSelector*/ documentSelector;
}

/// Represents the signature of something callable. A signature can have a
/// label, like a function-name, a doc-comment, and a set of parameters.
class SignatureInformation {
  SignatureInformation(this.documentation, this.label, this.parameters);

  /// The human-readable doc-comment of this signature. Will be shown in the UI
  /// but can be omitted.
  ///
  /// Must be String or MarkupContent.
  final Object documentation;

  /// The label of this signature. Will be shown in the UI.
  final String label;

  /// The parameters of this signature.
  final List<ParameterInformation> parameters;
}

/// Static registration options to be returned in the initialize request.
class StaticRegistrationOptions {
  StaticRegistrationOptions(this.id);

  /// The id used to register the request. The id can be used to deregister the
  /// request again. See also Registration#id.
  final String id;
}

/// Represents information about programming constructs like variables, classes,
/// interfaces etc.
class SymbolInformation {
  SymbolInformation(
      this.containerName, this.deprecated, this.kind, this.location, this.name);

  /// The name of the symbol containing this symbol. This information is for
  /// user interface purposes (e.g. to render a qualifier in the user interface
  /// if necessary). It can't be used to re-infer a hierarchy for the document
  /// symbols.
  final String containerName;

  /// Indicates if this symbol is deprecated.
  final bool deprecated;

  /// The kind of this symbol.
  final num kind;

  /// The location of this symbol. The location's range is used by a tool to
  /// reveal the location in the editor. If the symbol is selected in the tool
  /// the range's start information is used to position the cursor. So the range
  /// usually spans more then the actual symbol's name and does normally include
  /// things like visibility modifiers.
  ///
  /// The range doesn't have to denote a node range in the sense of a abstract
  /// syntax tree. It can therefore not be used to re-construct a hierarchy of
  /// the symbols.
  final Location location;

  /// The name of this symbol.
  final String name;
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
class TextDocumentChangeRegistrationOptions
    implements TextDocumentRegistrationOptions {
  TextDocumentChangeRegistrationOptions(this.syncKind, this.documentSelector);

  /// How documents are synced to the server. See TextDocumentSyncKind.Full and
  /// TextDocumentSyncKind.Incremental.
  final num syncKind;

  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  final List<DocumentFilter> /*DocumentSelector*/ documentSelector;
}

/// Text document specific client capabilities.
class TextDocumentClientCapabilities {
  TextDocumentClientCapabilities(this.didSave, this.dynamicRegistration,
      this.willSave, this.willSaveWaitUntil);

  /// The client supports did save notifications.
  final bool didSave;

  /// Whether text document synchronization supports dynamic registration.
  final bool dynamicRegistration;

  /// The client supports sending will save notifications.
  final bool willSave;

  /// The client supports sending a will save request and waits for a response
  /// providing text edits which will be applied to the document before it is
  /// saved.
  final bool willSaveWaitUntil;
}

/// An event describing a change to a text document. If range and rangeLength
/// are omitted the new text is considered to be the full content of the
/// document.
class TextDocumentContentChangeEvent {
  TextDocumentContentChangeEvent(this.range, this.rangeLength, this.text);

  /// The range of the document that changed.
  final Range range;

  /// The length of the range that got replaced.
  final num rangeLength;

  /// The new text of the range/document.
  final String text;
}

class TextDocumentEdit implements FileOperation {
  TextDocumentEdit(this.edits, this.textDocument);

  /// The edits to be applied.
  final List<TextEdit> edits;

  /// The text document to change.
  final VersionedTextDocumentIdentifier textDocument;
}

class TextDocumentIdentifier {
  TextDocumentIdentifier(this.uri);

  /// The text document's URI.
  final String /*DocumentUri*/ uri;
}

class TextDocumentItem {
  TextDocumentItem(this.languageId, this.text, this.uri, this.version);

  /// The text document's language identifier.
  final String languageId;

  /// The content of the opened text document.
  final String text;

  /// The text document's URI.
  final String /*DocumentUri*/ uri;

  /// The version number of this document (it will increase after each change,
  /// including undo/redo).
  final num version;
}

class TextDocumentPositionParams {
  TextDocumentPositionParams(this.position, this.textDocument);

  /// The position inside the text document.
  final Position position;

  /// The text document.
  final TextDocumentIdentifier textDocument;
}

class TextDocumentRegistrationOptions {
  TextDocumentRegistrationOptions(this.documentSelector);

  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  final List<DocumentFilter> /*DocumentSelector*/ documentSelector;
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

class TextDocumentSaveRegistrationOptions
    implements TextDocumentRegistrationOptions {
  TextDocumentSaveRegistrationOptions(this.includeText, this.documentSelector);

  /// The client is supposed to include the content on save.
  final bool includeText;

  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  final List<DocumentFilter> /*DocumentSelector*/ documentSelector;
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
  TextDocumentSyncOptions(this.change, this.openClose, this.save, this.willSave,
      this.willSaveWaitUntil);

  /// Change notifications are sent to the server. See
  /// TextDocumentSyncKind.None, TextDocumentSyncKind.Full and
  /// TextDocumentSyncKind.Incremental. If omitted it defaults to
  /// TextDocumentSyncKind.None.
  final num change;

  /// Open and close notifications are sent to the server.
  final bool openClose;

  /// Save notifications are sent to the server.
  final SaveOptions save;

  /// Will save notifications are sent to the server.
  final bool willSave;

  /// Will save wait until requests are sent to the server.
  final bool willSaveWaitUntil;
}

class TextEdit {
  TextEdit(this.newText, this.range);

  /// The string to be inserted. For delete operations use an empty string.
  final String newText;

  /// The range of the text document to be manipulated. To insert text into a
  /// document create a range where start === end.
  final Range range;
}

/// General parameters to unregister a capability.
class Unregistration {
  Unregistration(this.id, this.method);

  /// The id used to unregister the request or notification. Usually an id
  /// provided during the register request.
  final String id;

  /// The method / capability to unregister for.
  final String method;
}

class UnregistrationParams {
  UnregistrationParams(this.unregisterations);

  final List<Unregistration> unregisterations;
}

class VersionedTextDocumentIdentifier implements TextDocumentIdentifier {
  VersionedTextDocumentIdentifier(this.version, this.uri);

  /// The version number of this document. If a versioned text document
  /// identifier is sent from the server to the client and the file is not open
  /// in the editor (the server has not received an open notification before)
  /// the server can send `null` to indicate that the version is known and the
  /// content on disk is the truth (as speced with document content ownership).
  ///
  /// The version number of a document will increase after each change,
  /// including undo/redo. The number doesn't need to be consecutive.
  final num version;

  /// The text document's URI.
  final String /*DocumentUri*/ uri;
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
  WillSaveTextDocumentParams(this.reason, this.textDocument);

  /// The 'TextDocumentSaveReason'.
  final num reason;

  /// The document that will be saved.
  final TextDocumentIdentifier textDocument;
}

/// Workspace specific client capabilities.
class WorkspaceClientCapabilities {
  WorkspaceClientCapabilities(this.applyEdit, this.documentChanges,
      this.failureHandling, this.resourceOperations);

  /// The client supports applying batch edits to the workspace by supporting
  /// the request 'workspace/applyEdit'
  final bool applyEdit;

  /// The client supports versioned document changes in `WorkspaceEdit`s
  final bool documentChanges;

  /// The failure handling strategy of a client if applying the workspace edit
  /// failes.
  final FailureHandlingKind failureHandling;

  /// The resource operations the client supports. Clients should at least
  /// support 'create', 'rename' and 'delete' files and folders.
  final List<ResourceOperationKind> resourceOperations;
}

class WorkspaceEdit {
  WorkspaceEdit(this.changes, this.documentChanges);

  /// Holds changes to existing resources.
  final Map<String, List<TextEdit>> changes;

  /// Depending on the client capability
  /// `workspace.workspaceEdit.resourceOperations` document changes are either
  /// an array of `TextDocumentEdit`s to express changes to n different text
  /// documents where each text document edit addresses a specific version of a
  /// text document. Or it can contain above `TextDocumentEdit`s mixed with
  /// create, rename and delete file / folder operations.
  ///
  /// Whether a client supports versioned document edits is expressed via
  /// `workspace.workspaceEdit.documentChanges` client capability.
  ///
  /// If a client neither supports `documentChanges` nor
  /// `workspace.workspaceEdit.resourceOperations` then only plain `TextEdit`s
  /// using the `changes` property are supported.
  final List<FileOperation> documentChanges;
}

class WorkspaceFolder {
  WorkspaceFolder(this.name, this.uri);

  /// The name of the workspace folder. Defaults to the uri's basename.
  final String name;

  /// The associated URI for this workspace folder.
  final String uri;
}

/// The workspace folder change event.
class WorkspaceFoldersChangeEvent {
  WorkspaceFoldersChangeEvent(this.added, this.removed);

  /// The array of added workspace folders
  final List<WorkspaceFolder> added;

  /// The array of the removed workspace folders
  final List<WorkspaceFolder> removed;
}

/// The parameters of a Workspace Symbol Request.
class WorkspaceSymbolParams {
  WorkspaceSymbolParams(this.query);

  /// A non-empty query string
  final String query;
}
