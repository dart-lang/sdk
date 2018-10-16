// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/lsp_spec/generate_all.dart".

import 'package:analysis_server/lsp_protocol/protocol_special.dart';

class ApplyWorkspaceEditParams {
  ApplyWorkspaceEditParams(this.label, this.edit);

  /// The edits to apply.
  final WorkspaceEdit edit;

  /// An optional label of the workspace edit. This label is presented in the
  /// user interface for example on an undo stack to undo the workspace edit.
  final String label;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (label != null) {
      __result['label'] = label;
    }
    __result['edit'] = edit ?? (throw 'edit is required but was not set');
    return __result;
  }
}

class ApplyWorkspaceEditResponse {
  ApplyWorkspaceEditResponse(this.applied);

  /// Indicates whether the edit was applied or not.
  final bool applied;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['applied'] =
        applied ?? (throw 'applied is required but was not set');
    return __result;
  }
}

class CancelParams {
  CancelParams(this.id);

  /// The request id to cancel.
  final Either2<num, String> id;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['id'] = id ?? (throw 'id is required but was not set');
    return __result;
  }
}

class ClientCapabilities {
  ClientCapabilities(this.workspace, this.textDocument, this.experimental);

  /// Experimental client capabilities.
  final dynamic experimental;

  /// Text document specific client capabilities.
  final TextDocumentClientCapabilities textDocument;

  /// Workspace specific client capabilities.
  final WorkspaceClientCapabilities workspace;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (workspace != null) {
      __result['workspace'] = workspace;
    }
    if (textDocument != null) {
      __result['textDocument'] = textDocument;
    }
    if (experimental != null) {
      __result['experimental'] = experimental;
    }
    return __result;
  }
}

/// A code action represents a change that can be performed in code, e.g. to fix
/// a problem or to refactor code.
///
/// A CodeAction must set either `edit` and/or a `command`. If both are
/// supplied, the `edit` is applied first, then the `command` is executed.
class CodeAction {
  CodeAction(this.title, this.kind, this.diagnostics, this.edit, this.command);

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
  final String kind;

  /// A short, human-readable, title for this code action.
  final String title;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['title'] = title ?? (throw 'title is required but was not set');
    if (kind != null) {
      __result['kind'] = kind;
    }
    if (diagnostics != null) {
      __result['diagnostics'] = diagnostics;
    }
    if (edit != null) {
      __result['edit'] = edit;
    }
    if (command != null) {
      __result['command'] = command;
    }
    return __result;
  }
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
  final List<String> only;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['diagnostics'] =
        diagnostics ?? (throw 'diagnostics is required but was not set');
    if (only != null) {
      __result['only'] = only;
    }
    return __result;
  }
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
  final List<String> codeActionKinds;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (codeActionKinds != null) {
      __result['codeActionKinds'] = codeActionKinds;
    }
    return __result;
  }
}

/// Params for the CodeActionRequest
class CodeActionParams {
  CodeActionParams(this.textDocument, this.range, this.context);

  /// Context carrying additional information.
  final CodeActionContext context;

  /// The range for which the command was invoked.
  final Range range;

  /// The document in which the command was invoked.
  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    __result['range'] = range ?? (throw 'range is required but was not set');
    __result['context'] =
        context ?? (throw 'context is required but was not set');
    return __result;
  }
}

class CodeActionRegistrationOptions
    implements TextDocumentRegistrationOptions, CodeActionOptions {
  CodeActionRegistrationOptions(this.documentSelector, this.codeActionKinds);

  /// CodeActionKinds that this server may return.
  ///
  /// The list of kinds may be generic, such as `CodeActionKind.Refactor`, or
  /// the server may list out every specific kind they provide.
  final List<String> codeActionKinds;

  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  final List<DocumentFilter> documentSelector;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['documentSelector'] = documentSelector;
    if (codeActionKinds != null) {
      __result['codeActionKinds'] = codeActionKinds;
    }
    return __result;
  }
}

/// A code lens represents a command that should be shown along with source
/// text, like the number of references, a way to run tests, etc.
///
/// A code lens is _unresolved_ when no command is associated to it. For
/// performance reasons the creation of a code lens and resolving should be done
/// in two stages.
class CodeLens {
  CodeLens(this.range, this.command, this.data);

  /// The command this code lens represents.
  final Command command;

  /// A data entry field that is preserved on a code lens item between a code
  /// lens and a code lens resolve request.
  final dynamic data;

  /// The range in which this code lens is valid. Should only span a single
  /// line.
  final Range range;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['range'] = range ?? (throw 'range is required but was not set');
    if (command != null) {
      __result['command'] = command;
    }
    if (data != null) {
      __result['data'] = data;
    }
    return __result;
  }
}

/// Code Lens options.
class CodeLensOptions {
  CodeLensOptions(this.resolveProvider);

  /// Code lens has a resolve provider as well.
  final bool resolveProvider;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (resolveProvider != null) {
      __result['resolveProvider'] = resolveProvider;
    }
    return __result;
  }
}

class CodeLensParams {
  CodeLensParams(this.textDocument);

  /// The document to request code lens for.
  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    return __result;
  }
}

class CodeLensRegistrationOptions implements TextDocumentRegistrationOptions {
  CodeLensRegistrationOptions(this.resolveProvider, this.documentSelector);

  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  final List<DocumentFilter> documentSelector;

  /// Code lens has a resolve provider as well.
  final bool resolveProvider;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (resolveProvider != null) {
      __result['resolveProvider'] = resolveProvider;
    }
    __result['documentSelector'] = documentSelector;
    return __result;
  }
}

/// Represents a color in RGBA space.
class Color {
  Color(this.red, this.green, this.blue, this.alpha);

  final num alpha;
  final num blue;
  final num green;
  final num red;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['red'] = red ?? (throw 'red is required but was not set');
    __result['green'] = green ?? (throw 'green is required but was not set');
    __result['blue'] = blue ?? (throw 'blue is required but was not set');
    __result['alpha'] = alpha ?? (throw 'alpha is required but was not set');
    return __result;
  }
}

class ColorInformation {
  ColorInformation(this.range, this.color);

  /// The actual color value for this color range.
  final Color color;

  /// The range in the document where this color appears.
  final Range range;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['range'] = range ?? (throw 'range is required but was not set');
    __result['color'] = color ?? (throw 'color is required but was not set');
    return __result;
  }
}

class ColorPresentation {
  ColorPresentation(this.label, this.textEdit, this.additionalTextEdits);

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

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['label'] = label ?? (throw 'label is required but was not set');
    if (textEdit != null) {
      __result['textEdit'] = textEdit;
    }
    if (additionalTextEdits != null) {
      __result['additionalTextEdits'] = additionalTextEdits;
    }
    return __result;
  }
}

class ColorPresentationParams {
  ColorPresentationParams(this.textDocument, this.color, this.range);

  /// The color information to request presentations for.
  final Color color;

  /// The range where the color would be inserted. Serves as a context.
  final Range range;

  /// The text document.
  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    __result['color'] = color ?? (throw 'color is required but was not set');
    __result['range'] = range ?? (throw 'range is required but was not set');
    return __result;
  }
}

/// Color provider options.
class ColorProviderOptions {
  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    return __result;
  }
}

class Command {
  Command(this.title, this.command, this.arguments);

  /// Arguments that the command handler should be invoked with.
  final List<dynamic> arguments;

  /// The identifier of the actual command handler.
  final String command;

  /// Title of the command, like `save`.
  final String title;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['title'] = title ?? (throw 'title is required but was not set');
    __result['command'] =
        command ?? (throw 'command is required but was not set');
    if (arguments != null) {
      __result['arguments'] = arguments;
    }
    return __result;
  }
}

/// Contains additional information about the context in which a completion
/// request is triggered.
class CompletionContext {
  CompletionContext(this.triggerKind, this.triggerCharacter);

  /// The trigger character (a single character) that has trigger code complete.
  /// Is undefined if `triggerKind !== CompletionTriggerKind.TriggerCharacter`
  final String triggerCharacter;

  /// How the completion was triggered.
  final CompletionTriggerKind triggerKind;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['triggerKind'] =
        triggerKind ?? (throw 'triggerKind is required but was not set');
    if (triggerCharacter != null) {
      __result['triggerCharacter'] = triggerCharacter;
    }
    return __result;
  }
}

class CompletionItem {
  CompletionItem(
      this.label,
      this.kind,
      this.detail,
      this.documentation,
      this.deprecated,
      this.preselect,
      this.sortText,
      this.filterText,
      this.insertText,
      this.insertTextFormat,
      this.textEdit,
      this.additionalTextEdits,
      this.commitCharacters,
      this.command,
      this.data);

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
  final dynamic data;

  /// Indicates if this item is deprecated.
  final bool deprecated;

  /// A human-readable string with additional information about this item, like
  /// type or symbol information.
  final String detail;

  /// A human-readable string that represents a doc-comment.
  final Either2<String, MarkupContent> documentation;

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

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['label'] = label ?? (throw 'label is required but was not set');
    if (kind != null) {
      __result['kind'] = kind;
    }
    if (detail != null) {
      __result['detail'] = detail;
    }
    if (documentation != null) {
      __result['documentation'] = documentation;
    }
    if (deprecated != null) {
      __result['deprecated'] = deprecated;
    }
    if (preselect != null) {
      __result['preselect'] = preselect;
    }
    if (sortText != null) {
      __result['sortText'] = sortText;
    }
    if (filterText != null) {
      __result['filterText'] = filterText;
    }
    if (insertText != null) {
      __result['insertText'] = insertText;
    }
    if (insertTextFormat != null) {
      __result['insertTextFormat'] = insertTextFormat;
    }
    if (textEdit != null) {
      __result['textEdit'] = textEdit;
    }
    if (additionalTextEdits != null) {
      __result['additionalTextEdits'] = additionalTextEdits;
    }
    if (commitCharacters != null) {
      __result['commitCharacters'] = commitCharacters;
    }
    if (command != null) {
      __result['command'] = command;
    }
    if (data != null) {
      __result['data'] = data;
    }
    return __result;
  }
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

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['isIncomplete'] =
        isIncomplete ?? (throw 'isIncomplete is required but was not set');
    __result['items'] = items ?? (throw 'items is required but was not set');
    return __result;
  }
}

/// Completion options.
class CompletionOptions {
  CompletionOptions(this.resolveProvider, this.triggerCharacters);

  /// The server provides support to resolve additional information for a
  /// completion item.
  final bool resolveProvider;

  /// The characters that trigger completion automatically.
  final List<String> triggerCharacters;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (resolveProvider != null) {
      __result['resolveProvider'] = resolveProvider;
    }
    if (triggerCharacters != null) {
      __result['triggerCharacters'] = triggerCharacters;
    }
    return __result;
  }
}

class CompletionParams implements TextDocumentPositionParams {
  CompletionParams(this.context, this.textDocument, this.position);

  /// The completion context. This is only available if the client specifies to
  /// send this using `ClientCapabilities.textDocument.completion.contextSupport
  /// === true`
  final CompletionContext context;

  /// The position inside the text document.
  final Position position;

  /// The text document.
  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (context != null) {
      __result['context'] = context;
    }
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    __result['position'] =
        position ?? (throw 'position is required but was not set');
    return __result;
  }
}

class CompletionRegistrationOptions implements TextDocumentRegistrationOptions {
  CompletionRegistrationOptions(
      this.triggerCharacters, this.resolveProvider, this.documentSelector);

  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  final List<DocumentFilter> documentSelector;

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

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (triggerCharacters != null) {
      __result['triggerCharacters'] = triggerCharacters;
    }
    if (resolveProvider != null) {
      __result['resolveProvider'] = resolveProvider;
    }
    __result['documentSelector'] = documentSelector;
    return __result;
  }
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

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (scopeUri != null) {
      __result['scopeUri'] = scopeUri;
    }
    if (section != null) {
      __result['section'] = section;
    }
    return __result;
  }
}

class ConfigurationParams {
  ConfigurationParams(this.items);

  final List<ConfigurationItem> items;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['items'] = items ?? (throw 'items is required but was not set');
    return __result;
  }
}

/// Create file operation
class CreateFile implements FileOperation {
  CreateFile(this.uri, this.options);

  /// Additional options
  final CreateFileOptions options;

  /// The resource to create.
  final String uri;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['uri'] = uri ?? (throw 'uri is required but was not set');
    if (options != null) {
      __result['options'] = options;
    }
    return __result;
  }
}

/// Options to create a file.
class CreateFileOptions {
  CreateFileOptions(this.overwrite, this.ignoreIfExists);

  /// Ignore if exists.
  final bool ignoreIfExists;

  /// Overwrite existing file. Overwrite wins over `ignoreIfExists`
  final bool overwrite;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (overwrite != null) {
      __result['overwrite'] = overwrite;
    }
    if (ignoreIfExists != null) {
      __result['ignoreIfExists'] = ignoreIfExists;
    }
    return __result;
  }
}

/// Delete file operation
class DeleteFile implements FileOperation {
  DeleteFile(this.uri, this.options);

  /// Delete options.
  final DeleteFileOptions options;

  /// The file to delete.
  final String uri;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['uri'] = uri ?? (throw 'uri is required but was not set');
    if (options != null) {
      __result['options'] = options;
    }
    return __result;
  }
}

/// Delete file options
class DeleteFileOptions {
  DeleteFileOptions(this.recursive, this.ignoreIfNotExists);

  /// Ignore the operation if the file doesn't exist.
  final bool ignoreIfNotExists;

  /// Delete the content recursively if a folder is denoted.
  final bool recursive;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (recursive != null) {
      __result['recursive'] = recursive;
    }
    if (ignoreIfNotExists != null) {
      __result['ignoreIfNotExists'] = ignoreIfNotExists;
    }
    return __result;
  }
}

class Diagnostic {
  Diagnostic(this.range, this.severity, this.code, this.source, this.message,
      this.relatedInformation);

  /// The diagnostic's code, which might appear in the user interface.
  final Either2<num, String> code;

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

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['range'] = range ?? (throw 'range is required but was not set');
    if (severity != null) {
      __result['severity'] = severity;
    }
    if (code != null) {
      __result['code'] = code;
    }
    if (source != null) {
      __result['source'] = source;
    }
    __result['message'] =
        message ?? (throw 'message is required but was not set');
    if (relatedInformation != null) {
      __result['relatedInformation'] = relatedInformation;
    }
    return __result;
  }
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

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['location'] =
        location ?? (throw 'location is required but was not set');
    __result['message'] =
        message ?? (throw 'message is required but was not set');
    return __result;
  }
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
  final dynamic settings;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['settings'] =
        settings ?? (throw 'settings is required but was not set');
    return __result;
  }
}

class DidChangeTextDocumentParams {
  DidChangeTextDocumentParams(this.textDocument, this.contentChanges);

  /// The actual content changes. The content changes describe single state
  /// changes to the document. So if there are two content changes c1 and c2 for
  /// a document in state S then c1 move the document to S' and c2 to S''.
  final List<TextDocumentContentChangeEvent> contentChanges;

  /// The document that did change. The version number points to the version
  /// after all provided content changes have been applied.
  final VersionedTextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    __result['contentChanges'] =
        contentChanges ?? (throw 'contentChanges is required but was not set');
    return __result;
  }
}

class DidChangeWatchedFilesParams {
  DidChangeWatchedFilesParams(this.changes);

  /// The actual file events.
  final List<FileEvent> changes;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['changes'] =
        changes ?? (throw 'changes is required but was not set');
    return __result;
  }
}

/// Describe options to be used when registering for text document change
/// events.
class DidChangeWatchedFilesRegistrationOptions {
  DidChangeWatchedFilesRegistrationOptions(this.watchers);

  /// The watchers to register.
  final List<FileSystemWatcher> watchers;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['watchers'] =
        watchers ?? (throw 'watchers is required but was not set');
    return __result;
  }
}

class DidChangeWorkspaceFoldersParams {
  DidChangeWorkspaceFoldersParams(this.event);

  /// The actual workspace folder change event.
  final WorkspaceFoldersChangeEvent event;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['event'] = event ?? (throw 'event is required but was not set');
    return __result;
  }
}

class DidCloseTextDocumentParams {
  DidCloseTextDocumentParams(this.textDocument);

  /// The document that was closed.
  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    return __result;
  }
}

class DidOpenTextDocumentParams {
  DidOpenTextDocumentParams(this.textDocument);

  /// The document that was opened.
  final TextDocumentItem textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    return __result;
  }
}

class DidSaveTextDocumentParams {
  DidSaveTextDocumentParams(this.textDocument, this.text);

  /// Optional the content when saved. Depends on the includeText value when the
  /// save notification was requested.
  final String text;

  /// The document that was saved.
  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    if (text != null) {
      __result['text'] = text;
    }
    return __result;
  }
}

class DocumentFilter {
  DocumentFilter(this.language, this.scheme, this.pattern);

  /// A language id, like `typescript`.
  final String language;

  /// A glob pattern, like `*.{ts,js}`.
  final String pattern;

  /// A Uri [scheme](#Uri.scheme), like `file` or `untitled`.
  final String scheme;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (language != null) {
      __result['language'] = language;
    }
    if (scheme != null) {
      __result['scheme'] = scheme;
    }
    if (pattern != null) {
      __result['pattern'] = pattern;
    }
    return __result;
  }
}

class DocumentFormattingParams {
  DocumentFormattingParams(this.textDocument, this.options);

  /// The format options.
  final FormattingOptions options;

  /// The document to format.
  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    __result['options'] =
        options ?? (throw 'options is required but was not set');
    return __result;
  }
}

/// A document highlight is a range inside a text document which deserves
/// special attention. Usually a document highlight is visualized by changing
/// the background color of its range.
class DocumentHighlight {
  DocumentHighlight(this.range, this.kind);

  /// The highlight kind, default is DocumentHighlightKind.Text.
  final num kind;

  /// The range this highlight applies to.
  final Range range;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['range'] = range ?? (throw 'range is required but was not set');
    if (kind != null) {
      __result['kind'] = kind;
    }
    return __result;
  }
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
  DocumentLink(this.range, this.target, this.data);

  /// A data entry field that is preserved on a document link between a
  /// DocumentLinkRequest and a DocumentLinkResolveRequest.
  final dynamic data;

  /// The range this link applies to.
  final Range range;

  /// The uri this link points to. If missing a resolve request is sent later.
  final String target;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['range'] = range ?? (throw 'range is required but was not set');
    if (target != null) {
      __result['target'] = target;
    }
    if (data != null) {
      __result['data'] = data;
    }
    return __result;
  }
}

/// Document link options.
class DocumentLinkOptions {
  DocumentLinkOptions(this.resolveProvider);

  /// Document links have a resolve provider as well.
  final bool resolveProvider;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (resolveProvider != null) {
      __result['resolveProvider'] = resolveProvider;
    }
    return __result;
  }
}

class DocumentLinkParams {
  DocumentLinkParams(this.textDocument);

  /// The document to provide document links for.
  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    return __result;
  }
}

class DocumentLinkRegistrationOptions
    implements TextDocumentRegistrationOptions {
  DocumentLinkRegistrationOptions(this.resolveProvider, this.documentSelector);

  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  final List<DocumentFilter> documentSelector;

  /// Document links have a resolve provider as well.
  final bool resolveProvider;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (resolveProvider != null) {
      __result['resolveProvider'] = resolveProvider;
    }
    __result['documentSelector'] = documentSelector;
    return __result;
  }
}

/// Format document on type options.
class DocumentOnTypeFormattingOptions {
  DocumentOnTypeFormattingOptions(
      this.firstTriggerCharacter, this.moreTriggerCharacter);

  /// A character on which formatting should be triggered, like `}`.
  final String firstTriggerCharacter;

  /// More trigger characters.
  final List<String> moreTriggerCharacter;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['firstTriggerCharacter'] = firstTriggerCharacter ??
        (throw 'firstTriggerCharacter is required but was not set');
    if (moreTriggerCharacter != null) {
      __result['moreTriggerCharacter'] = moreTriggerCharacter;
    }
    return __result;
  }
}

class DocumentOnTypeFormattingParams {
  DocumentOnTypeFormattingParams(
      this.textDocument, this.position, this.ch, this.options);

  /// The character that has been typed.
  final String ch;

  /// The format options.
  final FormattingOptions options;

  /// The position at which this request was sent.
  final Position position;

  /// The document to format.
  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    __result['position'] =
        position ?? (throw 'position is required but was not set');
    __result['ch'] = ch ?? (throw 'ch is required but was not set');
    __result['options'] =
        options ?? (throw 'options is required but was not set');
    return __result;
  }
}

class DocumentOnTypeFormattingRegistrationOptions
    implements TextDocumentRegistrationOptions {
  DocumentOnTypeFormattingRegistrationOptions(this.firstTriggerCharacter,
      this.moreTriggerCharacter, this.documentSelector);

  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  final List<DocumentFilter> documentSelector;

  /// A character on which formatting should be triggered, like `}`.
  final String firstTriggerCharacter;

  /// More trigger characters.
  final List<String> moreTriggerCharacter;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['firstTriggerCharacter'] = firstTriggerCharacter ??
        (throw 'firstTriggerCharacter is required but was not set');
    if (moreTriggerCharacter != null) {
      __result['moreTriggerCharacter'] = moreTriggerCharacter;
    }
    __result['documentSelector'] = documentSelector;
    return __result;
  }
}

class DocumentRangeFormattingParams {
  DocumentRangeFormattingParams(this.textDocument, this.range, this.options);

  /// The format options
  final FormattingOptions options;

  /// The range to format
  final Range range;

  /// The document to format.
  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    __result['range'] = range ?? (throw 'range is required but was not set');
    __result['options'] =
        options ?? (throw 'options is required but was not set');
    return __result;
  }
}

/// Represents programming constructs like variables, classes, interfaces etc.
/// that appear in a document. Document symbols can be hierarchical and they
/// have two ranges: one that encloses its definition and one that points to its
/// most interesting range, e.g. the range of an identifier.
class DocumentSymbol {
  DocumentSymbol(this.name, this.detail, this.kind, this.deprecated, this.range,
      this.selectionRange, this.children);

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

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['name'] = name ?? (throw 'name is required but was not set');
    if (detail != null) {
      __result['detail'] = detail;
    }
    __result['kind'] = kind ?? (throw 'kind is required but was not set');
    if (deprecated != null) {
      __result['deprecated'] = deprecated;
    }
    __result['range'] = range ?? (throw 'range is required but was not set');
    __result['selectionRange'] =
        selectionRange ?? (throw 'selectionRange is required but was not set');
    if (children != null) {
      __result['children'] = children;
    }
    return __result;
  }
}

class DocumentSymbolParams {
  DocumentSymbolParams(this.textDocument);

  /// The text document.
  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    return __result;
  }
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

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['commands'] =
        commands ?? (throw 'commands is required but was not set');
    return __result;
  }
}

class ExecuteCommandParams {
  ExecuteCommandParams(this.command, this.arguments);

  /// Arguments that the command should be invoked with.
  final List<dynamic> arguments;

  /// The identifier of the actual command handler.
  final String command;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['command'] =
        command ?? (throw 'command is required but was not set');
    if (arguments != null) {
      __result['arguments'] = arguments;
    }
    return __result;
  }
}

/// Execute command registration options.
class ExecuteCommandRegistrationOptions {
  ExecuteCommandRegistrationOptions(this.commands);

  /// The commands to be executed on the server
  final List<String> commands;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['commands'] =
        commands ?? (throw 'commands is required but was not set');
    return __result;
  }
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
  FileEvent(this.uri, this.type);

  /// The change type.
  final num type;

  /// The file's URI.
  final String uri;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['uri'] = uri ?? (throw 'uri is required but was not set');
    __result['type'] = type ?? (throw 'type is required but was not set');
    return __result;
  }
}

class FileSystemWatcher {
  FileSystemWatcher(this.globPattern, this.kind);

  /// The  glob pattern to watch
  final String globPattern;

  /// The kind of events of interest. If omitted it defaults to WatchKind.Create
  /// | WatchKind.Change | WatchKind.Delete which is 7.
  final num kind;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['globPattern'] =
        globPattern ?? (throw 'globPattern is required but was not set');
    if (kind != null) {
      __result['kind'] = kind;
    }
    return __result;
  }
}

/// Represents a folding range.
class FoldingRange {
  FoldingRange(this.startLine, this.startCharacter, this.endLine,
      this.endCharacter, this.kind);

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

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['startLine'] =
        startLine ?? (throw 'startLine is required but was not set');
    if (startCharacter != null) {
      __result['startCharacter'] = startCharacter;
    }
    __result['endLine'] =
        endLine ?? (throw 'endLine is required but was not set');
    if (endCharacter != null) {
      __result['endCharacter'] = endCharacter;
    }
    if (kind != null) {
      __result['kind'] = kind;
    }
    return __result;
  }
}

class FoldingRangeParams {
  FoldingRangeParams(this.textDocument);

  /// The text document.
  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    return __result;
  }
}

/// Folding range provider options.
class FoldingRangeProviderOptions {
  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    return __result;
  }
}

/// Value-object describing what options formatting should use.
class FormattingOptions {
  FormattingOptions(this.tabSize, this.insertSpaces);

  /// Prefer spaces over tabs.
  final bool insertSpaces;

  /// Size of a tab in spaces.
  final num tabSize;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['tabSize'] =
        tabSize ?? (throw 'tabSize is required but was not set');
    __result['insertSpaces'] =
        insertSpaces ?? (throw 'insertSpaces is required but was not set');
    return __result;
  }
}

/// The result of a hover request.
class Hover {
  Hover(this.contents, this.range);

  /// The hover's content
  final Either3<MarkedString, List<MarkedString>, MarkupContent> contents;

  /// An optional range is a range inside a text document that is used to
  /// visualize a hover, e.g. by changing the background color.
  final Range range;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['contents'] =
        contents ?? (throw 'contents is required but was not set');
    if (range != null) {
      __result['range'] = range;
    }
    return __result;
  }
}

class InitializeParams {
  InitializeParams(this.processId, this.rootPath, this.rootUri,
      this.initializationOptions, this.capabilities, this.workspaceFolders);

  /// The capabilities provided by the client (editor or tool)
  final ClientCapabilities capabilities;

  /// User provided initialization options.
  final dynamic initializationOptions;

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
  final String rootUri;

  /// The workspace folders configured in the client when the server starts.
  /// This property is only available if the client supports workspace folders.
  /// It can be `null` if the client supports workspace folders but none are
  /// configured.
  ///
  /// Since 3.6.0
  final List<WorkspaceFolder> workspaceFolders;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['processId'] = processId;
    if (rootPath != null) {
      __result['rootPath'] = rootPath;
    }
    __result['rootUri'] = rootUri;
    if (initializationOptions != null) {
      __result['initializationOptions'] = initializationOptions;
    }
    __result['capabilities'] =
        capabilities ?? (throw 'capabilities is required but was not set');
    if (workspaceFolders != null) {
      __result['workspaceFolders'] = workspaceFolders;
    }
    return __result;
  }
}

class InitializeResult {
  InitializeResult(this.capabilities);

  /// The capabilities the language server provides.
  final ServerCapabilities capabilities;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['capabilities'] =
        capabilities ?? (throw 'capabilities is required but was not set');
    return __result;
  }
}

class InitializedParams {
  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    return __result;
  }
}

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
  Location(this.uri, this.range);

  final Range range;
  final String uri;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['uri'] = uri ?? (throw 'uri is required but was not set');
    __result['range'] = range ?? (throw 'range is required but was not set');
    return __result;
  }
}

class LogMessageParams {
  LogMessageParams(this.type, this.message);

  /// The actual message
  final String message;

  /// The message type.
  final MessageType type;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['type'] = type ?? (throw 'type is required but was not set');
    __result['message'] =
        message ?? (throw 'message is required but was not set');
    return __result;
  }
}

class MarkedString {
  MarkedString(this.language, this.value);

  final String language;
  final String value;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['language'] =
        language ?? (throw 'language is required but was not set');
    __result['value'] = value ?? (throw 'value is required but was not set');
    return __result;
  }
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

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['kind'] = kind ?? (throw 'kind is required but was not set');
    __result['value'] = value ?? (throw 'value is required but was not set');
    return __result;
  }
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

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['jsonrpc'] =
        jsonrpc ?? (throw 'jsonrpc is required but was not set');
    return __result;
  }
}

class MessageActionItem {
  MessageActionItem(this.title);

  /// A short title like 'Retry', 'Open Log' etc.
  final String title;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['title'] = title ?? (throw 'title is required but was not set');
    return __result;
  }
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

  final String jsonrpc;

  /// The method to be invoked.
  final String method;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['method'] = method ?? (throw 'method is required but was not set');
    __result['jsonrpc'] =
        jsonrpc ?? (throw 'jsonrpc is required but was not set');
    return __result;
  }
}

/// Represents a parameter of a callable-signature. A parameter can have a label
/// and a doc-comment.
class ParameterInformation {
  ParameterInformation(this.label, this.documentation);

  /// The human-readable doc-comment of this parameter. Will be shown in the UI
  /// but can be omitted.
  final Either2<String, MarkupContent> documentation;

  /// The label of this parameter. Will be shown in the UI.
  final String label;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['label'] = label ?? (throw 'label is required but was not set');
    if (documentation != null) {
      __result['documentation'] = documentation;
    }
    return __result;
  }
}

class Position {
  Position(this.line, this.character);

  /// Character offset on a line in a document (zero-based). Assuming that the
  /// line is represented as a string, the `character` value represents the gap
  /// between the `character` and `character + 1`.
  ///
  /// If the character value is greater than the line length it defaults back to
  /// the line length.
  final num character;

  /// Line position in a document (zero-based).
  final num line;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['line'] = line ?? (throw 'line is required but was not set');
    __result['character'] =
        character ?? (throw 'character is required but was not set');
    return __result;
  }
}

class PublishDiagnosticsParams {
  PublishDiagnosticsParams(this.uri, this.diagnostics);

  /// An array of diagnostic information items.
  final List<Diagnostic> diagnostics;

  /// The URI for which diagnostic information is reported.
  final String uri;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['uri'] = uri ?? (throw 'uri is required but was not set');
    __result['diagnostics'] =
        diagnostics ?? (throw 'diagnostics is required but was not set');
    return __result;
  }
}

class Range {
  Range(this.start, this.end);

  /// The range's end position.
  final Position end;

  /// The range's start position.
  final Position start;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['start'] = start ?? (throw 'start is required but was not set');
    __result['end'] = end ?? (throw 'end is required but was not set');
    return __result;
  }
}

class ReferenceContext {
  ReferenceContext(this.includeDeclaration);

  /// Include the declaration of the current symbol.
  final bool includeDeclaration;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['includeDeclaration'] = includeDeclaration ??
        (throw 'includeDeclaration is required but was not set');
    return __result;
  }
}

class ReferenceParams implements TextDocumentPositionParams {
  ReferenceParams(this.context, this.textDocument, this.position);

  final ReferenceContext context;

  /// The position inside the text document.
  final Position position;

  /// The text document.
  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['context'] =
        context ?? (throw 'context is required but was not set');
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    __result['position'] =
        position ?? (throw 'position is required but was not set');
    return __result;
  }
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
  final dynamic registerOptions;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['id'] = id ?? (throw 'id is required but was not set');
    __result['method'] = method ?? (throw 'method is required but was not set');
    if (registerOptions != null) {
      __result['registerOptions'] = registerOptions;
    }
    return __result;
  }
}

class RegistrationParams {
  RegistrationParams(this.registrations);

  final List<Registration> registrations;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['registrations'] =
        registrations ?? (throw 'registrations is required but was not set');
    return __result;
  }
}

/// Rename file operation
class RenameFile implements FileOperation {
  RenameFile(this.oldUri, this.newUri, this.options);

  /// The new location.
  final String newUri;

  /// The old (existing) location.
  final String oldUri;

  /// Rename options.
  final RenameFileOptions options;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['oldUri'] = oldUri ?? (throw 'oldUri is required but was not set');
    __result['newUri'] = newUri ?? (throw 'newUri is required but was not set');
    if (options != null) {
      __result['options'] = options;
    }
    return __result;
  }
}

/// Rename file options
class RenameFileOptions {
  RenameFileOptions(this.overwrite, this.ignoreIfExists);

  /// Ignores if target exists.
  final bool ignoreIfExists;

  /// Overwrite target if existing. Overwrite wins over `ignoreIfExists`
  final bool overwrite;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (overwrite != null) {
      __result['overwrite'] = overwrite;
    }
    if (ignoreIfExists != null) {
      __result['ignoreIfExists'] = ignoreIfExists;
    }
    return __result;
  }
}

/// Rename options
class RenameOptions {
  RenameOptions(this.prepareProvider);

  /// Renames should be checked and tested before being executed.
  final bool prepareProvider;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (prepareProvider != null) {
      __result['prepareProvider'] = prepareProvider;
    }
    return __result;
  }
}

class RenameParams {
  RenameParams(this.textDocument, this.position, this.newName);

  /// The new name of the symbol. If the given name is not valid the request
  /// must return a [ResponseError] with an appropriate message set.
  final String newName;

  /// The position at which this request was sent.
  final Position position;

  /// The document to rename.
  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    __result['position'] =
        position ?? (throw 'position is required but was not set');
    __result['newName'] =
        newName ?? (throw 'newName is required but was not set');
    return __result;
  }
}

class RenameRegistrationOptions implements TextDocumentRegistrationOptions {
  RenameRegistrationOptions(this.prepareProvider, this.documentSelector);

  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  final List<DocumentFilter> documentSelector;

  /// Renames should be checked and tested for validity before being executed.
  final bool prepareProvider;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (prepareProvider != null) {
      __result['prepareProvider'] = prepareProvider;
    }
    __result['documentSelector'] = documentSelector;
    return __result;
  }
}

class RequestMessage implements Message {
  RequestMessage(this.id, this.method, this.jsonrpc);

  /// The request id.
  final Either2<num, String> id;
  final String jsonrpc;

  /// The method to be invoked.
  final String method;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['id'] = id ?? (throw 'id is required but was not set');
    __result['method'] = method ?? (throw 'method is required but was not set');
    __result['jsonrpc'] =
        jsonrpc ?? (throw 'jsonrpc is required but was not set');
    return __result;
  }
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
  final Either2<num, String> id;
  final String jsonrpc;

  /// The result of a request. This can be omitted in the case of an error.
  final dynamic result;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['id'] = id;
    if (result != null) {
      __result['result'] = result;
    }
    __result['jsonrpc'] =
        jsonrpc ?? (throw 'jsonrpc is required but was not set');
    return __result;
  }
}

/// Save options.
class SaveOptions {
  SaveOptions(this.includeText);

  /// The client is supposed to include the content on save.
  final bool includeText;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (includeText != null) {
      __result['includeText'] = includeText;
    }
    return __result;
  }
}

class ServerCapabilities {
  ServerCapabilities(
      this.textDocumentSync,
      this.hoverProvider,
      this.completionProvider,
      this.signatureHelpProvider,
      this.definitionProvider,
      this.referencesProvider,
      this.documentHighlightProvider,
      this.documentSymbolProvider,
      this.workspaceSymbolProvider,
      this.codeActionProvider,
      this.codeLensProvider,
      this.documentFormattingProvider,
      this.documentRangeFormattingProvider,
      this.documentOnTypeFormattingProvider,
      this.renameProvider,
      this.documentLinkProvider,
      this.executeCommandProvider,
      this.supported,
      this.changeNotifications);

  /// Whether the server wants to receive workspace folder change notifications.
  ///
  /// If a strings is provided the string is treated as a ID under which the
  /// notification is registered on the client side. The ID can be used to
  /// unregister for these events using the `client/unregisterCapability`
  /// request.
  final Either2<String, bool> changeNotifications;

  /// The server provides code actions. The `CodeActionOptions` return type is
  /// only valid if the client signals code action literal support via the
  /// property `textDocument.codeAction.codeActionLiteralSupport`.
  final Either2<bool, CodeActionOptions> codeActionProvider;

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
  final Either2<bool, RenameOptions> renameProvider;

  /// The server provides signature help support.
  final SignatureHelpOptions signatureHelpProvider;

  /// The server has support for workspace folders
  final bool supported;

  /// Defines how text documents are synced. Is either a detailed structure
  /// defining each notification or for backwards compatibility the
  /// TextDocumentSyncKind number. If omitted it defaults to
  /// `TextDocumentSyncKind.None`.
  final Either2<TextDocumentSyncOptions, num> textDocumentSync;

  /// The server provides workspace symbol support.
  final bool workspaceSymbolProvider;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (textDocumentSync != null) {
      __result['textDocumentSync'] = textDocumentSync;
    }
    if (hoverProvider != null) {
      __result['hoverProvider'] = hoverProvider;
    }
    if (completionProvider != null) {
      __result['completionProvider'] = completionProvider;
    }
    if (signatureHelpProvider != null) {
      __result['signatureHelpProvider'] = signatureHelpProvider;
    }
    if (definitionProvider != null) {
      __result['definitionProvider'] = definitionProvider;
    }
    if (referencesProvider != null) {
      __result['referencesProvider'] = referencesProvider;
    }
    if (documentHighlightProvider != null) {
      __result['documentHighlightProvider'] = documentHighlightProvider;
    }
    if (documentSymbolProvider != null) {
      __result['documentSymbolProvider'] = documentSymbolProvider;
    }
    if (workspaceSymbolProvider != null) {
      __result['workspaceSymbolProvider'] = workspaceSymbolProvider;
    }
    if (codeActionProvider != null) {
      __result['codeActionProvider'] = codeActionProvider;
    }
    if (codeLensProvider != null) {
      __result['codeLensProvider'] = codeLensProvider;
    }
    if (documentFormattingProvider != null) {
      __result['documentFormattingProvider'] = documentFormattingProvider;
    }
    if (documentRangeFormattingProvider != null) {
      __result['documentRangeFormattingProvider'] =
          documentRangeFormattingProvider;
    }
    if (documentOnTypeFormattingProvider != null) {
      __result['documentOnTypeFormattingProvider'] =
          documentOnTypeFormattingProvider;
    }
    if (renameProvider != null) {
      __result['renameProvider'] = renameProvider;
    }
    if (documentLinkProvider != null) {
      __result['documentLinkProvider'] = documentLinkProvider;
    }
    if (executeCommandProvider != null) {
      __result['executeCommandProvider'] = executeCommandProvider;
    }
    if (supported != null) {
      __result['supported'] = supported;
    }
    if (changeNotifications != null) {
      __result['changeNotifications'] = changeNotifications;
    }
    return __result;
  }
}

class ShowMessageParams {
  ShowMessageParams(this.type, this.message);

  /// The actual message.
  final String message;

  /// The message type.
  final MessageType type;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['type'] = type ?? (throw 'type is required but was not set');
    __result['message'] =
        message ?? (throw 'message is required but was not set');
    return __result;
  }
}

class ShowMessageRequestParams {
  ShowMessageRequestParams(this.type, this.message, this.actions);

  /// The message action items to present.
  final List<MessageActionItem> actions;

  /// The actual message
  final String message;

  /// The message type.
  final MessageType type;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['type'] = type ?? (throw 'type is required but was not set');
    __result['message'] =
        message ?? (throw 'message is required but was not set');
    if (actions != null) {
      __result['actions'] = actions;
    }
    return __result;
  }
}

/// Signature help represents the signature of something callable. There can be
/// multiple signature but only one active and only one active parameter.
class SignatureHelp {
  SignatureHelp(this.signatures, this.activeSignature, this.activeParameter);

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

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['signatures'] =
        signatures ?? (throw 'signatures is required but was not set');
    if (activeSignature != null) {
      __result['activeSignature'] = activeSignature;
    }
    if (activeParameter != null) {
      __result['activeParameter'] = activeParameter;
    }
    return __result;
  }
}

/// Signature help options.
class SignatureHelpOptions {
  SignatureHelpOptions(this.triggerCharacters);

  /// The characters that trigger signature help automatically.
  final List<String> triggerCharacters;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (triggerCharacters != null) {
      __result['triggerCharacters'] = triggerCharacters;
    }
    return __result;
  }
}

class SignatureHelpRegistrationOptions
    implements TextDocumentRegistrationOptions {
  SignatureHelpRegistrationOptions(
      this.triggerCharacters, this.documentSelector);

  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  final List<DocumentFilter> documentSelector;

  /// The characters that trigger signature help automatically.
  final List<String> triggerCharacters;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (triggerCharacters != null) {
      __result['triggerCharacters'] = triggerCharacters;
    }
    __result['documentSelector'] = documentSelector;
    return __result;
  }
}

/// Represents the signature of something callable. A signature can have a
/// label, like a function-name, a doc-comment, and a set of parameters.
class SignatureInformation {
  SignatureInformation(this.label, this.documentation, this.parameters);

  /// The human-readable doc-comment of this signature. Will be shown in the UI
  /// but can be omitted.
  final Either2<String, MarkupContent> documentation;

  /// The label of this signature. Will be shown in the UI.
  final String label;

  /// The parameters of this signature.
  final List<ParameterInformation> parameters;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['label'] = label ?? (throw 'label is required but was not set');
    if (documentation != null) {
      __result['documentation'] = documentation;
    }
    if (parameters != null) {
      __result['parameters'] = parameters;
    }
    return __result;
  }
}

/// Static registration options to be returned in the initialize request.
class StaticRegistrationOptions {
  StaticRegistrationOptions(this.id);

  /// The id used to register the request. The id can be used to deregister the
  /// request again. See also Registration#id.
  final String id;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (id != null) {
      __result['id'] = id;
    }
    return __result;
  }
}

/// Represents information about programming constructs like variables, classes,
/// interfaces etc.
class SymbolInformation {
  SymbolInformation(
      this.name, this.kind, this.deprecated, this.location, this.containerName);

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

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['name'] = name ?? (throw 'name is required but was not set');
    __result['kind'] = kind ?? (throw 'kind is required but was not set');
    if (deprecated != null) {
      __result['deprecated'] = deprecated;
    }
    __result['location'] =
        location ?? (throw 'location is required but was not set');
    if (containerName != null) {
      __result['containerName'] = containerName;
    }
    return __result;
  }
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

  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  final List<DocumentFilter> documentSelector;

  /// How documents are synced to the server. See TextDocumentSyncKind.Full and
  /// TextDocumentSyncKind.Incremental.
  final num syncKind;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['syncKind'] =
        syncKind ?? (throw 'syncKind is required but was not set');
    __result['documentSelector'] = documentSelector;
    return __result;
  }
}

/// Text document specific client capabilities.
class TextDocumentClientCapabilities {
  TextDocumentClientCapabilities(this.dynamicRegistration, this.willSave,
      this.willSaveWaitUntil, this.didSave);

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

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    if (willSave != null) {
      __result['willSave'] = willSave;
    }
    if (willSaveWaitUntil != null) {
      __result['willSaveWaitUntil'] = willSaveWaitUntil;
    }
    if (didSave != null) {
      __result['didSave'] = didSave;
    }
    return __result;
  }
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

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (range != null) {
      __result['range'] = range;
    }
    if (rangeLength != null) {
      __result['rangeLength'] = rangeLength;
    }
    __result['text'] = text ?? (throw 'text is required but was not set');
    return __result;
  }
}

class TextDocumentEdit implements FileOperation {
  TextDocumentEdit(this.textDocument, this.edits);

  /// The edits to be applied.
  final List<TextEdit> edits;

  /// The text document to change.
  final VersionedTextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    __result['edits'] = edits ?? (throw 'edits is required but was not set');
    return __result;
  }
}

class TextDocumentIdentifier {
  TextDocumentIdentifier(this.uri);

  /// The text document's URI.
  final String uri;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['uri'] = uri ?? (throw 'uri is required but was not set');
    return __result;
  }
}

class TextDocumentItem {
  TextDocumentItem(this.uri, this.languageId, this.version, this.text);

  /// The text document's language identifier.
  final String languageId;

  /// The content of the opened text document.
  final String text;

  /// The text document's URI.
  final String uri;

  /// The version number of this document (it will increase after each change,
  /// including undo/redo).
  final num version;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['uri'] = uri ?? (throw 'uri is required but was not set');
    __result['languageId'] =
        languageId ?? (throw 'languageId is required but was not set');
    __result['version'] =
        version ?? (throw 'version is required but was not set');
    __result['text'] = text ?? (throw 'text is required but was not set');
    return __result;
  }
}

class TextDocumentPositionParams {
  TextDocumentPositionParams(this.textDocument, this.position);

  /// The position inside the text document.
  final Position position;

  /// The text document.
  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    __result['position'] =
        position ?? (throw 'position is required but was not set');
    return __result;
  }
}

class TextDocumentRegistrationOptions {
  TextDocumentRegistrationOptions(this.documentSelector);

  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  final List<DocumentFilter> documentSelector;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['documentSelector'] = documentSelector;
    return __result;
  }
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

  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  final List<DocumentFilter> documentSelector;

  /// The client is supposed to include the content on save.
  final bool includeText;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (includeText != null) {
      __result['includeText'] = includeText;
    }
    __result['documentSelector'] = documentSelector;
    return __result;
  }
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
  TextDocumentSyncOptions(this.openClose, this.change, this.willSave,
      this.willSaveWaitUntil, this.save);

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

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (openClose != null) {
      __result['openClose'] = openClose;
    }
    if (change != null) {
      __result['change'] = change;
    }
    if (willSave != null) {
      __result['willSave'] = willSave;
    }
    if (willSaveWaitUntil != null) {
      __result['willSaveWaitUntil'] = willSaveWaitUntil;
    }
    if (save != null) {
      __result['save'] = save;
    }
    return __result;
  }
}

class TextEdit {
  TextEdit(this.range, this.newText);

  /// The string to be inserted. For delete operations use an empty string.
  final String newText;

  /// The range of the text document to be manipulated. To insert text into a
  /// document create a range where start === end.
  final Range range;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['range'] = range ?? (throw 'range is required but was not set');
    __result['newText'] =
        newText ?? (throw 'newText is required but was not set');
    return __result;
  }
}

/// General parameters to unregister a capability.
class Unregistration {
  Unregistration(this.id, this.method);

  /// The id used to unregister the request or notification. Usually an id
  /// provided during the register request.
  final String id;

  /// The method / capability to unregister for.
  final String method;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['id'] = id ?? (throw 'id is required but was not set');
    __result['method'] = method ?? (throw 'method is required but was not set');
    return __result;
  }
}

class UnregistrationParams {
  UnregistrationParams(this.unregisterations);

  final List<Unregistration> unregisterations;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['unregisterations'] = unregisterations ??
        (throw 'unregisterations is required but was not set');
    return __result;
  }
}

class VersionedTextDocumentIdentifier implements TextDocumentIdentifier {
  VersionedTextDocumentIdentifier(this.version, this.uri);

  /// The text document's URI.
  final String uri;

  /// The version number of this document. If a versioned text document
  /// identifier is sent from the server to the client and the file is not open
  /// in the editor (the server has not received an open notification before)
  /// the server can send `null` to indicate that the version is known and the
  /// content on disk is the truth (as speced with document content ownership).
  ///
  /// The version number of a document will increase after each change,
  /// including undo/redo. The number doesn't need to be consecutive.
  final num version;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['version'] = version;
    __result['uri'] = uri ?? (throw 'uri is required but was not set');
    return __result;
  }
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
  WillSaveTextDocumentParams(this.textDocument, this.reason);

  /// The 'TextDocumentSaveReason'.
  final num reason;

  /// The document that will be saved.
  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    __result['reason'] = reason ?? (throw 'reason is required but was not set');
    return __result;
  }
}

/// Workspace specific client capabilities.
class WorkspaceClientCapabilities {
  WorkspaceClientCapabilities(this.applyEdit, this.documentChanges,
      this.resourceOperations, this.failureHandling);

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

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (applyEdit != null) {
      __result['applyEdit'] = applyEdit;
    }
    if (documentChanges != null) {
      __result['documentChanges'] = documentChanges;
    }
    if (resourceOperations != null) {
      __result['resourceOperations'] = resourceOperations;
    }
    if (failureHandling != null) {
      __result['failureHandling'] = failureHandling;
    }
    return __result;
  }
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

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (changes != null) {
      __result['changes'] = changes;
    }
    if (documentChanges != null) {
      __result['documentChanges'] = documentChanges;
    }
    return __result;
  }
}

class WorkspaceFolder {
  WorkspaceFolder(this.uri, this.name);

  /// The name of the workspace folder. Defaults to the uri's basename.
  final String name;

  /// The associated URI for this workspace folder.
  final String uri;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['uri'] = uri ?? (throw 'uri is required but was not set');
    __result['name'] = name ?? (throw 'name is required but was not set');
    return __result;
  }
}

/// The workspace folder change event.
class WorkspaceFoldersChangeEvent {
  WorkspaceFoldersChangeEvent(this.added, this.removed);

  /// The array of added workspace folders
  final List<WorkspaceFolder> added;

  /// The array of the removed workspace folders
  final List<WorkspaceFolder> removed;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['added'] = added ?? (throw 'added is required but was not set');
    __result['removed'] =
        removed ?? (throw 'removed is required but was not set');
    return __result;
  }
}

/// The parameters of a Workspace Symbol Request.
class WorkspaceSymbolParams {
  WorkspaceSymbolParams(this.query);

  /// A non-empty query string
  final String query;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['query'] = query ?? (throw 'query is required but was not set');
    return __result;
  }
}
