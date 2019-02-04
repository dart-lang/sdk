// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/lsp_spec/generate_all.dart".

// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: unnecessary_brace_in_string_interps
// ignore_for_file: unused_import

import 'dart:core' hide deprecated;
import 'dart:core' as core show deprecated;
import 'dart:convert' show JsonEncoder;
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart'
    show listEqual, mapEqual;
import 'package:analyzer/src/generated/utilities_general.dart';

const jsonEncoder = const JsonEncoder.withIndent('    ');

class ApplyWorkspaceEditParams implements ToJsonable {
  ApplyWorkspaceEditParams(this.label, this.edit) {
    if (edit == null) {
      throw 'edit is required but was not provided';
    }
  }
  static ApplyWorkspaceEditParams fromJson(Map<String, dynamic> json) {
    final label = json['label'];
    final edit =
        json['edit'] != null ? WorkspaceEdit.fromJson(json['edit']) : null;
    return new ApplyWorkspaceEditParams(label, edit);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('edit') &&
        WorkspaceEdit.canParse(obj['edit']);
  }

  @override
  bool operator ==(other) {
    if (other is ApplyWorkspaceEditParams) {
      return label == other.label && edit == other.edit && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, label.hashCode);
    hash = JenkinsSmiHash.combine(hash, edit.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ApplyWorkspaceEditResponse implements ToJsonable {
  ApplyWorkspaceEditResponse(this.applied) {
    if (applied == null) {
      throw 'applied is required but was not provided';
    }
  }
  static ApplyWorkspaceEditResponse fromJson(Map<String, dynamic> json) {
    final applied = json['applied'];
    return new ApplyWorkspaceEditResponse(applied);
  }

  /// Indicates whether the edit was applied or not.
  final bool applied;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['applied'] =
        applied ?? (throw 'applied is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('applied') &&
        obj['applied'] is bool;
  }

  @override
  bool operator ==(other) {
    if (other is ApplyWorkspaceEditResponse) {
      return applied == other.applied && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, applied.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class CancelParams implements ToJsonable {
  CancelParams(this.id) {
    if (id == null) {
      throw 'id is required but was not provided';
    }
  }
  static CancelParams fromJson(Map<String, dynamic> json) {
    final id = json['id'] is num
        ? new Either2<num, String>.t1(json['id'])
        : (json['id'] is String
            ? new Either2<num, String>.t2(json['id'])
            : (throw '''${json['id']} was not one of (num, String)'''));
    return new CancelParams(id);
  }

  /// The request id to cancel.
  final Either2<num, String> id;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['id'] = id ?? (throw 'id is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('id') &&
        (obj['id'] is num || obj['id'] is String);
  }

  @override
  bool operator ==(other) {
    if (other is CancelParams) {
      return id == other.id && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ClientCapabilities implements ToJsonable {
  ClientCapabilities(this.workspace, this.textDocument, this.experimental);
  static ClientCapabilities fromJson(Map<String, dynamic> json) {
    final workspace = json['workspace'] != null
        ? WorkspaceClientCapabilities.fromJson(json['workspace'])
        : null;
    final textDocument = json['textDocument'] != null
        ? TextDocumentClientCapabilities.fromJson(json['textDocument'])
        : null;
    final experimental = json['experimental'];
    return new ClientCapabilities(workspace, textDocument, experimental);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is ClientCapabilities) {
      return workspace == other.workspace &&
          textDocument == other.textDocument &&
          experimental == other.experimental &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, workspace.hashCode);
    hash = JenkinsSmiHash.combine(hash, textDocument.hashCode);
    hash = JenkinsSmiHash.combine(hash, experimental.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// A code action represents a change that can be performed in code, e.g. to fix
/// a problem or to refactor code.
///
/// A CodeAction must set either `edit` and/or a `command`. If both are
/// supplied, the `edit` is applied first, then the `command` is executed.
class CodeAction implements ToJsonable {
  CodeAction(this.title, this.kind, this.diagnostics, this.edit, this.command) {
    if (title == null) {
      throw 'title is required but was not provided';
    }
  }
  static CodeAction fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    final kind =
        json['kind'] != null ? CodeActionKind.fromJson(json['kind']) : null;
    final diagnostics = json['diagnostics']
        ?.map((item) => item != null ? Diagnostic.fromJson(item) : null)
        ?.cast<Diagnostic>()
        ?.toList();
    final edit =
        json['edit'] != null ? WorkspaceEdit.fromJson(json['edit']) : null;
    final command =
        json['command'] != null ? Command.fromJson(json['command']) : null;
    return new CodeAction(title, kind, diagnostics, edit, command);
  }

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
  final CodeActionKind kind;

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('title') &&
        obj['title'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is CodeAction) {
      return title == other.title &&
          kind == other.kind &&
          listEqual(diagnostics, other.diagnostics,
              (Diagnostic a, Diagnostic b) => a == b) &&
          edit == other.edit &&
          command == other.command &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, title.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, diagnostics.hashCode);
    hash = JenkinsSmiHash.combine(hash, edit.hashCode);
    hash = JenkinsSmiHash.combine(hash, command.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Contains additional diagnostic information about the context in which a code
/// action is run.
class CodeActionContext implements ToJsonable {
  CodeActionContext(this.diagnostics, this.only) {
    if (diagnostics == null) {
      throw 'diagnostics is required but was not provided';
    }
  }
  static CodeActionContext fromJson(Map<String, dynamic> json) {
    final diagnostics = json['diagnostics']
        ?.map((item) => item != null ? Diagnostic.fromJson(item) : null)
        ?.cast<Diagnostic>()
        ?.toList();
    final only = json['only']
        ?.map((item) => item != null ? CodeActionKind.fromJson(item) : null)
        ?.cast<CodeActionKind>()
        ?.toList();
    return new CodeActionContext(diagnostics, only);
  }

  /// An array of diagnostics.
  final List<Diagnostic> diagnostics;

  /// Requested kind of actions to return.
  ///
  /// Actions not of this kind are filtered out by the client before being
  /// shown. So servers can omit computing them.
  final List<CodeActionKind> only;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['diagnostics'] =
        diagnostics ?? (throw 'diagnostics is required but was not set');
    if (only != null) {
      __result['only'] = only;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('diagnostics') &&
        (obj['diagnostics'] is List &&
            (obj['diagnostics'].every((item) => Diagnostic.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is CodeActionContext) {
      return listEqual(diagnostics, other.diagnostics,
              (Diagnostic a, Diagnostic b) => a == b) &&
          listEqual(only, other.only,
              (CodeActionKind a, CodeActionKind b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, diagnostics.hashCode);
    hash = JenkinsSmiHash.combine(hash, only.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// A set of predefined code action kinds
class CodeActionKind {
  const CodeActionKind(this._value);
  const CodeActionKind.fromJson(this._value);

  final String _value;

  static bool canParse(Object obj) {
    return obj is String;
  }

  /// Base kind for quickfix actions: 'quickfix'
  static const QuickFix = const CodeActionKind('quickfix');

  /// Base kind for refactoring actions: 'refactor'
  static const Refactor = const CodeActionKind('refactor');

  /// Base kind for refactoring extraction actions: 'refactor.extract'
  ///
  /// Example extract actions:
  ///
  /// - Extract method
  /// - Extract function
  /// - Extract variable
  /// - Extract interface from class
  /// - ...
  static const RefactorExtract = const CodeActionKind('refactor.extract');

  /// Base kind for refactoring inline actions: 'refactor.inline'
  ///
  /// Example inline actions:
  ///
  /// - Inline function
  /// - Inline variable
  /// - Inline constant
  /// - ...
  static const RefactorInline = const CodeActionKind('refactor.inline');

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
  static const RefactorRewrite = const CodeActionKind('refactor.rewrite');

  /// Base kind for source actions: `source`
  ///
  /// Source code actions apply to the entire file.
  static const Source = const CodeActionKind('source');

  /// Base kind for an organize imports source action: `source.organizeImports`
  static const SourceOrganizeImports =
      const CodeActionKind('source.organizeImports');

  Object toJson() => _value;

  @override
  String toString() => _value.toString();

  @override
  get hashCode => _value.hashCode;

  bool operator ==(o) => o is CodeActionKind && o._value == _value;
}

/// Code Action options.
class CodeActionOptions implements ToJsonable {
  CodeActionOptions(this.codeActionKinds);
  static CodeActionOptions fromJson(Map<String, dynamic> json) {
    if (CodeActionRegistrationOptions.canParse(json)) {
      return CodeActionRegistrationOptions.fromJson(json);
    }
    final codeActionKinds = json['codeActionKinds']
        ?.map((item) => item != null ? CodeActionKind.fromJson(item) : null)
        ?.cast<CodeActionKind>()
        ?.toList();
    return new CodeActionOptions(codeActionKinds);
  }

  /// CodeActionKinds that this server may return.
  ///
  /// The list of kinds may be generic, such as `CodeActionKind.Refactor`, or
  /// the server may list out every specific kind they provide.
  final List<CodeActionKind> codeActionKinds;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (codeActionKinds != null) {
      __result['codeActionKinds'] = codeActionKinds;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is CodeActionOptions) {
      return listEqual(codeActionKinds, other.codeActionKinds,
              (CodeActionKind a, CodeActionKind b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, codeActionKinds.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Params for the CodeActionRequest
class CodeActionParams implements ToJsonable {
  CodeActionParams(this.textDocument, this.range, this.context) {
    if (textDocument == null) {
      throw 'textDocument is required but was not provided';
    }
    if (range == null) {
      throw 'range is required but was not provided';
    }
    if (context == null) {
      throw 'context is required but was not provided';
    }
  }
  static CodeActionParams fromJson(Map<String, dynamic> json) {
    final textDocument = json['textDocument'] != null
        ? TextDocumentIdentifier.fromJson(json['textDocument'])
        : null;
    final range = json['range'] != null ? Range.fromJson(json['range']) : null;
    final context = json['context'] != null
        ? CodeActionContext.fromJson(json['context'])
        : null;
    return new CodeActionParams(textDocument, range, context);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('textDocument') &&
        TextDocumentIdentifier.canParse(obj['textDocument']) &&
        obj.containsKey('range') &&
        Range.canParse(obj['range']) &&
        obj.containsKey('context') &&
        CodeActionContext.canParse(obj['context']);
  }

  @override
  bool operator ==(other) {
    if (other is CodeActionParams) {
      return textDocument == other.textDocument &&
          range == other.range &&
          context == other.context &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, textDocument.hashCode);
    hash = JenkinsSmiHash.combine(hash, range.hashCode);
    hash = JenkinsSmiHash.combine(hash, context.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class CodeActionRegistrationOptions
    implements TextDocumentRegistrationOptions, CodeActionOptions, ToJsonable {
  CodeActionRegistrationOptions(this.documentSelector, this.codeActionKinds);
  static CodeActionRegistrationOptions fromJson(Map<String, dynamic> json) {
    final documentSelector = json['documentSelector']
        ?.map((item) => item != null ? DocumentFilter.fromJson(item) : null)
        ?.cast<DocumentFilter>()
        ?.toList();
    final codeActionKinds = json['codeActionKinds']
        ?.map((item) => item != null ? CodeActionKind.fromJson(item) : null)
        ?.cast<CodeActionKind>()
        ?.toList();
    return new CodeActionRegistrationOptions(documentSelector, codeActionKinds);
  }

  /// CodeActionKinds that this server may return.
  ///
  /// The list of kinds may be generic, such as `CodeActionKind.Refactor`, or
  /// the server may list out every specific kind they provide.
  final List<CodeActionKind> codeActionKinds;

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('documentSelector') &&
        (obj['documentSelector'] is List &&
            (obj['documentSelector']
                .every((item) => DocumentFilter.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is CodeActionRegistrationOptions) {
      return documentSelector == other.documentSelector &&
          listEqual(codeActionKinds, other.codeActionKinds,
              (CodeActionKind a, CodeActionKind b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, documentSelector.hashCode);
    hash = JenkinsSmiHash.combine(hash, codeActionKinds.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// A code lens represents a command that should be shown along with source
/// text, like the number of references, a way to run tests, etc.
///
/// A code lens is _unresolved_ when no command is associated to it. For
/// performance reasons the creation of a code lens and resolving should be done
/// in two stages.
class CodeLens implements ToJsonable {
  CodeLens(this.range, this.command, this.data) {
    if (range == null) {
      throw 'range is required but was not provided';
    }
  }
  static CodeLens fromJson(Map<String, dynamic> json) {
    final range = json['range'] != null ? Range.fromJson(json['range']) : null;
    final command =
        json['command'] != null ? Command.fromJson(json['command']) : null;
    final data = json['data'];
    return new CodeLens(range, command, data);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('range') &&
        Range.canParse(obj['range']);
  }

  @override
  bool operator ==(other) {
    if (other is CodeLens) {
      return range == other.range &&
          command == other.command &&
          data == other.data &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, range.hashCode);
    hash = JenkinsSmiHash.combine(hash, command.hashCode);
    hash = JenkinsSmiHash.combine(hash, data.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Code Lens options.
class CodeLensOptions implements ToJsonable {
  CodeLensOptions(this.resolveProvider);
  static CodeLensOptions fromJson(Map<String, dynamic> json) {
    final resolveProvider = json['resolveProvider'];
    return new CodeLensOptions(resolveProvider);
  }

  /// Code lens has a resolve provider as well.
  final bool resolveProvider;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (resolveProvider != null) {
      __result['resolveProvider'] = resolveProvider;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is CodeLensOptions) {
      return resolveProvider == other.resolveProvider && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, resolveProvider.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class CodeLensParams implements ToJsonable {
  CodeLensParams(this.textDocument) {
    if (textDocument == null) {
      throw 'textDocument is required but was not provided';
    }
  }
  static CodeLensParams fromJson(Map<String, dynamic> json) {
    final textDocument = json['textDocument'] != null
        ? TextDocumentIdentifier.fromJson(json['textDocument'])
        : null;
    return new CodeLensParams(textDocument);
  }

  /// The document to request code lens for.
  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('textDocument') &&
        TextDocumentIdentifier.canParse(obj['textDocument']);
  }

  @override
  bool operator ==(other) {
    if (other is CodeLensParams) {
      return textDocument == other.textDocument && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, textDocument.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class CodeLensRegistrationOptions
    implements TextDocumentRegistrationOptions, ToJsonable {
  CodeLensRegistrationOptions(this.resolveProvider, this.documentSelector);
  static CodeLensRegistrationOptions fromJson(Map<String, dynamic> json) {
    final resolveProvider = json['resolveProvider'];
    final documentSelector = json['documentSelector']
        ?.map((item) => item != null ? DocumentFilter.fromJson(item) : null)
        ?.cast<DocumentFilter>()
        ?.toList();
    return new CodeLensRegistrationOptions(resolveProvider, documentSelector);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('documentSelector') &&
        (obj['documentSelector'] is List &&
            (obj['documentSelector']
                .every((item) => DocumentFilter.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is CodeLensRegistrationOptions) {
      return resolveProvider == other.resolveProvider &&
          documentSelector == other.documentSelector &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, resolveProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, documentSelector.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Represents a color in RGBA space.
class Color implements ToJsonable {
  Color(this.red, this.green, this.blue, this.alpha) {
    if (red == null) {
      throw 'red is required but was not provided';
    }
    if (green == null) {
      throw 'green is required but was not provided';
    }
    if (blue == null) {
      throw 'blue is required but was not provided';
    }
    if (alpha == null) {
      throw 'alpha is required but was not provided';
    }
  }
  static Color fromJson(Map<String, dynamic> json) {
    final red = json['red'];
    final green = json['green'];
    final blue = json['blue'];
    final alpha = json['alpha'];
    return new Color(red, green, blue, alpha);
  }

  /// The alpha component of this color in the range [0-1].
  final num alpha;

  /// The blue component of this color in the range [0-1].
  final num blue;

  /// The green component of this color in the range [0-1].
  final num green;

  /// The red component of this color in the range [0-1].
  final num red;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['red'] = red ?? (throw 'red is required but was not set');
    __result['green'] = green ?? (throw 'green is required but was not set');
    __result['blue'] = blue ?? (throw 'blue is required but was not set');
    __result['alpha'] = alpha ?? (throw 'alpha is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('red') &&
        obj['red'] is num &&
        obj.containsKey('green') &&
        obj['green'] is num &&
        obj.containsKey('blue') &&
        obj['blue'] is num &&
        obj.containsKey('alpha') &&
        obj['alpha'] is num;
  }

  @override
  bool operator ==(other) {
    if (other is Color) {
      return red == other.red &&
          green == other.green &&
          blue == other.blue &&
          alpha == other.alpha &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, red.hashCode);
    hash = JenkinsSmiHash.combine(hash, green.hashCode);
    hash = JenkinsSmiHash.combine(hash, blue.hashCode);
    hash = JenkinsSmiHash.combine(hash, alpha.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ColorInformation implements ToJsonable {
  ColorInformation(this.range, this.color) {
    if (range == null) {
      throw 'range is required but was not provided';
    }
    if (color == null) {
      throw 'color is required but was not provided';
    }
  }
  static ColorInformation fromJson(Map<String, dynamic> json) {
    final range = json['range'] != null ? Range.fromJson(json['range']) : null;
    final color = json['color'] != null ? Color.fromJson(json['color']) : null;
    return new ColorInformation(range, color);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('range') &&
        Range.canParse(obj['range']) &&
        obj.containsKey('color') &&
        Color.canParse(obj['color']);
  }

  @override
  bool operator ==(other) {
    if (other is ColorInformation) {
      return range == other.range && color == other.color && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, range.hashCode);
    hash = JenkinsSmiHash.combine(hash, color.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ColorPresentation implements ToJsonable {
  ColorPresentation(this.label, this.textEdit, this.additionalTextEdits) {
    if (label == null) {
      throw 'label is required but was not provided';
    }
  }
  static ColorPresentation fromJson(Map<String, dynamic> json) {
    final label = json['label'];
    final textEdit =
        json['textEdit'] != null ? TextEdit.fromJson(json['textEdit']) : null;
    final additionalTextEdits = json['additionalTextEdits']
        ?.map((item) => item != null ? TextEdit.fromJson(item) : null)
        ?.cast<TextEdit>()
        ?.toList();
    return new ColorPresentation(label, textEdit, additionalTextEdits);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('label') &&
        obj['label'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is ColorPresentation) {
      return label == other.label &&
          textEdit == other.textEdit &&
          listEqual(additionalTextEdits, other.additionalTextEdits,
              (TextEdit a, TextEdit b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, label.hashCode);
    hash = JenkinsSmiHash.combine(hash, textEdit.hashCode);
    hash = JenkinsSmiHash.combine(hash, additionalTextEdits.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ColorPresentationParams implements ToJsonable {
  ColorPresentationParams(this.textDocument, this.color, this.range) {
    if (textDocument == null) {
      throw 'textDocument is required but was not provided';
    }
    if (color == null) {
      throw 'color is required but was not provided';
    }
    if (range == null) {
      throw 'range is required but was not provided';
    }
  }
  static ColorPresentationParams fromJson(Map<String, dynamic> json) {
    final textDocument = json['textDocument'] != null
        ? TextDocumentIdentifier.fromJson(json['textDocument'])
        : null;
    final color = json['color'] != null ? Color.fromJson(json['color']) : null;
    final range = json['range'] != null ? Range.fromJson(json['range']) : null;
    return new ColorPresentationParams(textDocument, color, range);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('textDocument') &&
        TextDocumentIdentifier.canParse(obj['textDocument']) &&
        obj.containsKey('color') &&
        Color.canParse(obj['color']) &&
        obj.containsKey('range') &&
        Range.canParse(obj['range']);
  }

  @override
  bool operator ==(other) {
    if (other is ColorPresentationParams) {
      return textDocument == other.textDocument &&
          color == other.color &&
          range == other.range &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, textDocument.hashCode);
    hash = JenkinsSmiHash.combine(hash, color.hashCode);
    hash = JenkinsSmiHash.combine(hash, range.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Color provider options.
class ColorProviderOptions implements ToJsonable {
  static ColorProviderOptions fromJson(Map<String, dynamic> json) {
    return new ColorProviderOptions();
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is ColorProviderOptions) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class Command implements ToJsonable {
  Command(this.title, this.command, this.arguments) {
    if (title == null) {
      throw 'title is required but was not provided';
    }
    if (command == null) {
      throw 'command is required but was not provided';
    }
  }
  static Command fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    final command = json['command'];
    final arguments =
        json['arguments']?.map((item) => item)?.cast<dynamic>()?.toList();
    return new Command(title, command, arguments);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('title') &&
        obj['title'] is String &&
        obj.containsKey('command') &&
        obj['command'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is Command) {
      return title == other.title &&
          command == other.command &&
          listEqual(
              arguments, other.arguments, (dynamic a, dynamic b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, title.hashCode);
    hash = JenkinsSmiHash.combine(hash, command.hashCode);
    hash = JenkinsSmiHash.combine(hash, arguments.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Contains additional information about the context in which a completion
/// request is triggered.
class CompletionContext implements ToJsonable {
  CompletionContext(this.triggerKind, this.triggerCharacter) {
    if (triggerKind == null) {
      throw 'triggerKind is required but was not provided';
    }
  }
  static CompletionContext fromJson(Map<String, dynamic> json) {
    final triggerKind = json['triggerKind'] != null
        ? CompletionTriggerKind.fromJson(json['triggerKind'])
        : null;
    final triggerCharacter = json['triggerCharacter'];
    return new CompletionContext(triggerKind, triggerCharacter);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('triggerKind') &&
        obj['triggerKind'] is num;
  }

  @override
  bool operator ==(other) {
    if (other is CompletionContext) {
      return triggerKind == other.triggerKind &&
          triggerCharacter == other.triggerCharacter &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, triggerKind.hashCode);
    hash = JenkinsSmiHash.combine(hash, triggerCharacter.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class CompletionItem implements ToJsonable {
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
      this.data) {
    if (label == null) {
      throw 'label is required but was not provided';
    }
  }
  static CompletionItem fromJson(Map<String, dynamic> json) {
    final label = json['label'];
    final kind =
        json['kind'] != null ? CompletionItemKind.fromJson(json['kind']) : null;
    final detail = json['detail'];
    final documentation = json['documentation'] is String
        ? new Either2<String, MarkupContent>.t1(json['documentation'])
        : (MarkupContent.canParse(json['documentation'])
            ? new Either2<String, MarkupContent>.t2(
                json['documentation'] != null
                    ? MarkupContent.fromJson(json['documentation'])
                    : null)
            : (json['documentation'] == null
                ? null
                : (throw '''${json['documentation']} was not one of (String, MarkupContent)''')));
    final deprecated = json['deprecated'];
    final preselect = json['preselect'];
    final sortText = json['sortText'];
    final filterText = json['filterText'];
    final insertText = json['insertText'];
    final insertTextFormat = json['insertTextFormat'] != null
        ? InsertTextFormat.fromJson(json['insertTextFormat'])
        : null;
    final textEdit =
        json['textEdit'] != null ? TextEdit.fromJson(json['textEdit']) : null;
    final additionalTextEdits = json['additionalTextEdits']
        ?.map((item) => item != null ? TextEdit.fromJson(item) : null)
        ?.cast<TextEdit>()
        ?.toList();
    final commitCharacters =
        json['commitCharacters']?.map((item) => item)?.cast<String>()?.toList();
    final command =
        json['command'] != null ? Command.fromJson(json['command']) : null;
    final data = json['data'];
    return new CompletionItem(
        label,
        kind,
        detail,
        documentation,
        deprecated,
        preselect,
        sortText,
        filterText,
        insertText,
        insertTextFormat,
        textEdit,
        additionalTextEdits,
        commitCharacters,
        command,
        data);
  }

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
  @core.deprecated
  final String insertText;

  /// The format of the insert text. The format applies to both the `insertText`
  /// property and the `newText` property of a provided `textEdit`.
  final InsertTextFormat insertTextFormat;

  /// The kind of this completion item. Based of the kind an icon is chosen by
  /// the editor.
  final CompletionItemKind kind;

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('label') &&
        obj['label'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is CompletionItem) {
      return label == other.label &&
          kind == other.kind &&
          detail == other.detail &&
          documentation == other.documentation &&
          deprecated == other.deprecated &&
          preselect == other.preselect &&
          sortText == other.sortText &&
          filterText == other.filterText &&
          insertText == other.insertText &&
          insertTextFormat == other.insertTextFormat &&
          textEdit == other.textEdit &&
          listEqual(additionalTextEdits, other.additionalTextEdits,
              (TextEdit a, TextEdit b) => a == b) &&
          listEqual(commitCharacters, other.commitCharacters,
              (String a, String b) => a == b) &&
          command == other.command &&
          data == other.data &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, label.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, detail.hashCode);
    hash = JenkinsSmiHash.combine(hash, documentation.hashCode);
    hash = JenkinsSmiHash.combine(hash, deprecated.hashCode);
    hash = JenkinsSmiHash.combine(hash, preselect.hashCode);
    hash = JenkinsSmiHash.combine(hash, sortText.hashCode);
    hash = JenkinsSmiHash.combine(hash, filterText.hashCode);
    hash = JenkinsSmiHash.combine(hash, insertText.hashCode);
    hash = JenkinsSmiHash.combine(hash, insertTextFormat.hashCode);
    hash = JenkinsSmiHash.combine(hash, textEdit.hashCode);
    hash = JenkinsSmiHash.combine(hash, additionalTextEdits.hashCode);
    hash = JenkinsSmiHash.combine(hash, commitCharacters.hashCode);
    hash = JenkinsSmiHash.combine(hash, command.hashCode);
    hash = JenkinsSmiHash.combine(hash, data.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// The kind of a completion entry.
class CompletionItemKind {
  const CompletionItemKind._(this._value);
  const CompletionItemKind.fromJson(this._value);

  final num _value;

  static bool canParse(Object obj) {
    switch (obj) {
      case 1:
      case 2:
      case 3:
      case 4:
      case 5:
      case 6:
      case 7:
      case 8:
      case 9:
      case 10:
      case 11:
      case 12:
      case 13:
      case 14:
      case 15:
      case 16:
      case 17:
      case 18:
      case 19:
      case 20:
      case 21:
      case 22:
      case 23:
      case 24:
      case 25:
        return true;
    }
    return false;
  }

  static const Text = const CompletionItemKind._(1);
  static const Method = const CompletionItemKind._(2);
  static const Function = const CompletionItemKind._(3);
  static const Constructor = const CompletionItemKind._(4);
  static const Field = const CompletionItemKind._(5);
  static const Variable = const CompletionItemKind._(6);
  static const Class = const CompletionItemKind._(7);
  static const Interface = const CompletionItemKind._(8);
  static const Module = const CompletionItemKind._(9);
  static const Property = const CompletionItemKind._(10);
  static const Unit = const CompletionItemKind._(11);
  static const Value = const CompletionItemKind._(12);
  static const Enum = const CompletionItemKind._(13);
  static const Keyword = const CompletionItemKind._(14);
  static const Snippet = const CompletionItemKind._(15);
  static const Color = const CompletionItemKind._(16);
  static const File = const CompletionItemKind._(17);
  static const Reference = const CompletionItemKind._(18);
  static const Folder = const CompletionItemKind._(19);
  static const EnumMember = const CompletionItemKind._(20);
  static const Constant = const CompletionItemKind._(21);
  static const Struct = const CompletionItemKind._(22);
  static const Event = const CompletionItemKind._(23);
  static const Operator = const CompletionItemKind._(24);
  static const TypeParameter = const CompletionItemKind._(25);

  Object toJson() => _value;

  @override
  String toString() => _value.toString();

  @override
  get hashCode => _value.hashCode;

  bool operator ==(o) => o is CompletionItemKind && o._value == _value;
}

/// Represents a collection of completion items ([CompletionItem]) to be
/// presented in the editor.
class CompletionList implements ToJsonable {
  CompletionList(this.isIncomplete, this.items) {
    if (isIncomplete == null) {
      throw 'isIncomplete is required but was not provided';
    }
    if (items == null) {
      throw 'items is required but was not provided';
    }
  }
  static CompletionList fromJson(Map<String, dynamic> json) {
    final isIncomplete = json['isIncomplete'];
    final items = json['items']
        ?.map((item) => item != null ? CompletionItem.fromJson(item) : null)
        ?.cast<CompletionItem>()
        ?.toList();
    return new CompletionList(isIncomplete, items);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('isIncomplete') &&
        obj['isIncomplete'] is bool &&
        obj.containsKey('items') &&
        (obj['items'] is List &&
            (obj['items'].every((item) => CompletionItem.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is CompletionList) {
      return isIncomplete == other.isIncomplete &&
          listEqual(items, other.items,
              (CompletionItem a, CompletionItem b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, isIncomplete.hashCode);
    hash = JenkinsSmiHash.combine(hash, items.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Completion options.
class CompletionOptions implements ToJsonable {
  CompletionOptions(this.resolveProvider, this.triggerCharacters);
  static CompletionOptions fromJson(Map<String, dynamic> json) {
    final resolveProvider = json['resolveProvider'];
    final triggerCharacters = json['triggerCharacters']
        ?.map((item) => item)
        ?.cast<String>()
        ?.toList();
    return new CompletionOptions(resolveProvider, triggerCharacters);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is CompletionOptions) {
      return resolveProvider == other.resolveProvider &&
          listEqual(triggerCharacters, other.triggerCharacters,
              (String a, String b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, resolveProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, triggerCharacters.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class CompletionParams implements TextDocumentPositionParams, ToJsonable {
  CompletionParams(this.context, this.textDocument, this.position) {
    if (textDocument == null) {
      throw 'textDocument is required but was not provided';
    }
    if (position == null) {
      throw 'position is required but was not provided';
    }
  }
  static CompletionParams fromJson(Map<String, dynamic> json) {
    final context = json['context'] != null
        ? CompletionContext.fromJson(json['context'])
        : null;
    final textDocument = json['textDocument'] != null
        ? TextDocumentIdentifier.fromJson(json['textDocument'])
        : null;
    final position =
        json['position'] != null ? Position.fromJson(json['position']) : null;
    return new CompletionParams(context, textDocument, position);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('textDocument') &&
        TextDocumentIdentifier.canParse(obj['textDocument']) &&
        obj.containsKey('position') &&
        Position.canParse(obj['position']);
  }

  @override
  bool operator ==(other) {
    if (other is CompletionParams) {
      return context == other.context &&
          textDocument == other.textDocument &&
          position == other.position &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, context.hashCode);
    hash = JenkinsSmiHash.combine(hash, textDocument.hashCode);
    hash = JenkinsSmiHash.combine(hash, position.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class CompletionRegistrationOptions
    implements TextDocumentRegistrationOptions, ToJsonable {
  CompletionRegistrationOptions(
      this.triggerCharacters, this.resolveProvider, this.documentSelector);
  static CompletionRegistrationOptions fromJson(Map<String, dynamic> json) {
    final triggerCharacters = json['triggerCharacters']
        ?.map((item) => item)
        ?.cast<String>()
        ?.toList();
    final resolveProvider = json['resolveProvider'];
    final documentSelector = json['documentSelector']
        ?.map((item) => item != null ? DocumentFilter.fromJson(item) : null)
        ?.cast<DocumentFilter>()
        ?.toList();
    return new CompletionRegistrationOptions(
        triggerCharacters, resolveProvider, documentSelector);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('documentSelector') &&
        (obj['documentSelector'] is List &&
            (obj['documentSelector']
                .every((item) => DocumentFilter.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is CompletionRegistrationOptions) {
      return listEqual(triggerCharacters, other.triggerCharacters,
              (String a, String b) => a == b) &&
          resolveProvider == other.resolveProvider &&
          documentSelector == other.documentSelector &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, triggerCharacters.hashCode);
    hash = JenkinsSmiHash.combine(hash, resolveProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, documentSelector.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// How a completion was triggered
class CompletionTriggerKind {
  const CompletionTriggerKind._(this._value);
  const CompletionTriggerKind.fromJson(this._value);

  final num _value;

  static bool canParse(Object obj) {
    switch (obj) {
      case 1:
      case 2:
      case 3:
        return true;
    }
    return false;
  }

  /// Completion was triggered by typing an identifier (24x7 code complete),
  /// manual invocation (e.g Ctrl+Space) or via API.
  static const Invoked = const CompletionTriggerKind._(1);

  /// Completion was triggered by a trigger character specified by the
  /// `triggerCharacters` properties of the `CompletionRegistrationOptions`.
  static const TriggerCharacter = const CompletionTriggerKind._(2);

  /// Completion was re-triggered as the current completion list is incomplete.
  static const TriggerForIncompleteCompletions =
      const CompletionTriggerKind._(3);

  Object toJson() => _value;

  @override
  String toString() => _value.toString();

  @override
  get hashCode => _value.hashCode;

  bool operator ==(o) => o is CompletionTriggerKind && o._value == _value;
}

class ConfigurationItem implements ToJsonable {
  ConfigurationItem(this.scopeUri, this.section);
  static ConfigurationItem fromJson(Map<String, dynamic> json) {
    final scopeUri = json['scopeUri'];
    final section = json['section'];
    return new ConfigurationItem(scopeUri, section);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is ConfigurationItem) {
      return scopeUri == other.scopeUri && section == other.section && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, scopeUri.hashCode);
    hash = JenkinsSmiHash.combine(hash, section.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ConfigurationParams implements ToJsonable {
  ConfigurationParams(this.items) {
    if (items == null) {
      throw 'items is required but was not provided';
    }
  }
  static ConfigurationParams fromJson(Map<String, dynamic> json) {
    final items = json['items']
        ?.map((item) => item != null ? ConfigurationItem.fromJson(item) : null)
        ?.cast<ConfigurationItem>()
        ?.toList();
    return new ConfigurationParams(items);
  }

  final List<ConfigurationItem> items;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['items'] = items ?? (throw 'items is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('items') &&
        (obj['items'] is List &&
            (obj['items'].every((item) => ConfigurationItem.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is ConfigurationParams) {
      return listEqual(items, other.items,
              (ConfigurationItem a, ConfigurationItem b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, items.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Create file operation
class CreateFile implements ToJsonable {
  CreateFile(this.kind, this.uri, this.options) {
    if (kind == null) {
      throw 'kind is required but was not provided';
    }
    if (uri == null) {
      throw 'uri is required but was not provided';
    }
  }
  static CreateFile fromJson(Map<String, dynamic> json) {
    final kind = json['kind'];
    final uri = json['uri'];
    final options = json['options'] != null
        ? CreateFileOptions.fromJson(json['options'])
        : null;
    return new CreateFile(kind, uri, options);
  }

  /// A create
  final String kind;

  /// Additional options
  final CreateFileOptions options;

  /// The resource to create.
  final String uri;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['kind'] = kind ?? (throw 'kind is required but was not set');
    __result['uri'] = uri ?? (throw 'uri is required but was not set');
    if (options != null) {
      __result['options'] = options;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('kind') &&
        obj['kind'] is String &&
        obj.containsKey('uri') &&
        obj['uri'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is CreateFile) {
      return kind == other.kind &&
          uri == other.uri &&
          options == other.options &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, uri.hashCode);
    hash = JenkinsSmiHash.combine(hash, options.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Options to create a file.
class CreateFileOptions implements ToJsonable {
  CreateFileOptions(this.overwrite, this.ignoreIfExists);
  static CreateFileOptions fromJson(Map<String, dynamic> json) {
    final overwrite = json['overwrite'];
    final ignoreIfExists = json['ignoreIfExists'];
    return new CreateFileOptions(overwrite, ignoreIfExists);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is CreateFileOptions) {
      return overwrite == other.overwrite &&
          ignoreIfExists == other.ignoreIfExists &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, overwrite.hashCode);
    hash = JenkinsSmiHash.combine(hash, ignoreIfExists.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Delete file operation
class DeleteFile implements ToJsonable {
  DeleteFile(this.kind, this.uri, this.options) {
    if (kind == null) {
      throw 'kind is required but was not provided';
    }
    if (uri == null) {
      throw 'uri is required but was not provided';
    }
  }
  static DeleteFile fromJson(Map<String, dynamic> json) {
    final kind = json['kind'];
    final uri = json['uri'];
    final options = json['options'] != null
        ? DeleteFileOptions.fromJson(json['options'])
        : null;
    return new DeleteFile(kind, uri, options);
  }

  /// A delete
  final String kind;

  /// Delete options.
  final DeleteFileOptions options;

  /// The file to delete.
  final String uri;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['kind'] = kind ?? (throw 'kind is required but was not set');
    __result['uri'] = uri ?? (throw 'uri is required but was not set');
    if (options != null) {
      __result['options'] = options;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('kind') &&
        obj['kind'] is String &&
        obj.containsKey('uri') &&
        obj['uri'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is DeleteFile) {
      return kind == other.kind &&
          uri == other.uri &&
          options == other.options &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, uri.hashCode);
    hash = JenkinsSmiHash.combine(hash, options.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Delete file options
class DeleteFileOptions implements ToJsonable {
  DeleteFileOptions(this.recursive, this.ignoreIfNotExists);
  static DeleteFileOptions fromJson(Map<String, dynamic> json) {
    final recursive = json['recursive'];
    final ignoreIfNotExists = json['ignoreIfNotExists'];
    return new DeleteFileOptions(recursive, ignoreIfNotExists);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is DeleteFileOptions) {
      return recursive == other.recursive &&
          ignoreIfNotExists == other.ignoreIfNotExists &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, recursive.hashCode);
    hash = JenkinsSmiHash.combine(hash, ignoreIfNotExists.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class Diagnostic implements ToJsonable {
  Diagnostic(this.range, this.severity, this.code, this.source, this.message,
      this.relatedInformation) {
    if (range == null) {
      throw 'range is required but was not provided';
    }
    if (message == null) {
      throw 'message is required but was not provided';
    }
  }
  static Diagnostic fromJson(Map<String, dynamic> json) {
    final range = json['range'] != null ? Range.fromJson(json['range']) : null;
    final severity = json['severity'] != null
        ? DiagnosticSeverity.fromJson(json['severity'])
        : null;
    final code = json['code'];
    final source = json['source'];
    final message = json['message'];
    final relatedInformation = json['relatedInformation']
        ?.map((item) =>
            item != null ? DiagnosticRelatedInformation.fromJson(item) : null)
        ?.cast<DiagnosticRelatedInformation>()
        ?.toList();
    return new Diagnostic(
        range, severity, code, source, message, relatedInformation);
  }

  /// The diagnostic's code, which might appear in the user interface.
  final String code;

  /// The diagnostic's message.
  final String message;

  /// The range at which the message applies.
  final Range range;

  /// An array of related diagnostic information, e.g. when symbol-names within
  /// a scope collide all definitions can be marked via this property.
  final List<DiagnosticRelatedInformation> relatedInformation;

  /// The diagnostic's severity. Can be omitted. If omitted it is up to the
  /// client to interpret diagnostics as error, warning, info or hint.
  final DiagnosticSeverity severity;

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('range') &&
        Range.canParse(obj['range']) &&
        obj.containsKey('message') &&
        obj['message'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is Diagnostic) {
      return range == other.range &&
          severity == other.severity &&
          code == other.code &&
          source == other.source &&
          message == other.message &&
          listEqual(
              relatedInformation,
              other.relatedInformation,
              (DiagnosticRelatedInformation a,
                      DiagnosticRelatedInformation b) =>
                  a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, range.hashCode);
    hash = JenkinsSmiHash.combine(hash, severity.hashCode);
    hash = JenkinsSmiHash.combine(hash, code.hashCode);
    hash = JenkinsSmiHash.combine(hash, source.hashCode);
    hash = JenkinsSmiHash.combine(hash, message.hashCode);
    hash = JenkinsSmiHash.combine(hash, relatedInformation.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Represents a related message and source code location for a diagnostic. This
/// should be used to point to code locations that cause or related to a
/// diagnostics, e.g when duplicating a symbol in a scope.
class DiagnosticRelatedInformation implements ToJsonable {
  DiagnosticRelatedInformation(this.location, this.message) {
    if (location == null) {
      throw 'location is required but was not provided';
    }
    if (message == null) {
      throw 'message is required but was not provided';
    }
  }
  static DiagnosticRelatedInformation fromJson(Map<String, dynamic> json) {
    final location =
        json['location'] != null ? Location.fromJson(json['location']) : null;
    final message = json['message'];
    return new DiagnosticRelatedInformation(location, message);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('location') &&
        Location.canParse(obj['location']) &&
        obj.containsKey('message') &&
        obj['message'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is DiagnosticRelatedInformation) {
      return location == other.location && message == other.message && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, location.hashCode);
    hash = JenkinsSmiHash.combine(hash, message.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class DiagnosticSeverity {
  const DiagnosticSeverity._(this._value);
  const DiagnosticSeverity.fromJson(this._value);

  final num _value;

  static bool canParse(Object obj) {
    switch (obj) {
      case 1:
      case 2:
      case 3:
      case 4:
        return true;
    }
    return false;
  }

  /// Reports an error.
  static const Error = const DiagnosticSeverity._(1);

  /// Reports a warning.
  static const Warning = const DiagnosticSeverity._(2);

  /// Reports an information.
  static const Information = const DiagnosticSeverity._(3);

  /// Reports a hint.
  static const Hint = const DiagnosticSeverity._(4);

  Object toJson() => _value;

  @override
  String toString() => _value.toString();

  @override
  get hashCode => _value.hashCode;

  bool operator ==(o) => o is DiagnosticSeverity && o._value == _value;
}

class DidChangeConfigurationParams implements ToJsonable {
  DidChangeConfigurationParams(this.settings);
  static DidChangeConfigurationParams fromJson(Map<String, dynamic> json) {
    final settings = json['settings'];
    return new DidChangeConfigurationParams(settings);
  }

  /// The actual changed settings
  final dynamic settings;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['settings'] = settings;
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> && obj.containsKey('settings') && true;
  }

  @override
  bool operator ==(other) {
    if (other is DidChangeConfigurationParams) {
      return settings == other.settings && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, settings.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class DidChangeTextDocumentParams implements ToJsonable {
  DidChangeTextDocumentParams(this.textDocument, this.contentChanges) {
    if (textDocument == null) {
      throw 'textDocument is required but was not provided';
    }
    if (contentChanges == null) {
      throw 'contentChanges is required but was not provided';
    }
  }
  static DidChangeTextDocumentParams fromJson(Map<String, dynamic> json) {
    final textDocument = json['textDocument'] != null
        ? VersionedTextDocumentIdentifier.fromJson(json['textDocument'])
        : null;
    final contentChanges = json['contentChanges']
        ?.map((item) =>
            item != null ? TextDocumentContentChangeEvent.fromJson(item) : null)
        ?.cast<TextDocumentContentChangeEvent>()
        ?.toList();
    return new DidChangeTextDocumentParams(textDocument, contentChanges);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('textDocument') &&
        VersionedTextDocumentIdentifier.canParse(obj['textDocument']) &&
        obj.containsKey('contentChanges') &&
        (obj['contentChanges'] is List &&
            (obj['contentChanges'].every(
                (item) => TextDocumentContentChangeEvent.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is DidChangeTextDocumentParams) {
      return textDocument == other.textDocument &&
          listEqual(
              contentChanges,
              other.contentChanges,
              (TextDocumentContentChangeEvent a,
                      TextDocumentContentChangeEvent b) =>
                  a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, textDocument.hashCode);
    hash = JenkinsSmiHash.combine(hash, contentChanges.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class DidChangeWatchedFilesParams implements ToJsonable {
  DidChangeWatchedFilesParams(this.changes) {
    if (changes == null) {
      throw 'changes is required but was not provided';
    }
  }
  static DidChangeWatchedFilesParams fromJson(Map<String, dynamic> json) {
    final changes = json['changes']
        ?.map((item) => item != null ? FileEvent.fromJson(item) : null)
        ?.cast<FileEvent>()
        ?.toList();
    return new DidChangeWatchedFilesParams(changes);
  }

  /// The actual file events.
  final List<FileEvent> changes;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['changes'] =
        changes ?? (throw 'changes is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('changes') &&
        (obj['changes'] is List &&
            (obj['changes'].every((item) => FileEvent.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is DidChangeWatchedFilesParams) {
      return listEqual(
              changes, other.changes, (FileEvent a, FileEvent b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, changes.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Describe options to be used when registering for text document change
/// events.
class DidChangeWatchedFilesRegistrationOptions implements ToJsonable {
  DidChangeWatchedFilesRegistrationOptions(this.watchers) {
    if (watchers == null) {
      throw 'watchers is required but was not provided';
    }
  }
  static DidChangeWatchedFilesRegistrationOptions fromJson(
      Map<String, dynamic> json) {
    final watchers = json['watchers']
        ?.map((item) => item != null ? FileSystemWatcher.fromJson(item) : null)
        ?.cast<FileSystemWatcher>()
        ?.toList();
    return new DidChangeWatchedFilesRegistrationOptions(watchers);
  }

  /// The watchers to register.
  final List<FileSystemWatcher> watchers;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['watchers'] =
        watchers ?? (throw 'watchers is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('watchers') &&
        (obj['watchers'] is List &&
            (obj['watchers']
                .every((item) => FileSystemWatcher.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is DidChangeWatchedFilesRegistrationOptions) {
      return listEqual(watchers, other.watchers,
              (FileSystemWatcher a, FileSystemWatcher b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, watchers.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class DidChangeWorkspaceFoldersParams implements ToJsonable {
  DidChangeWorkspaceFoldersParams(this.event) {
    if (event == null) {
      throw 'event is required but was not provided';
    }
  }
  static DidChangeWorkspaceFoldersParams fromJson(Map<String, dynamic> json) {
    final event = json['event'] != null
        ? WorkspaceFoldersChangeEvent.fromJson(json['event'])
        : null;
    return new DidChangeWorkspaceFoldersParams(event);
  }

  /// The actual workspace folder change event.
  final WorkspaceFoldersChangeEvent event;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['event'] = event ?? (throw 'event is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('event') &&
        WorkspaceFoldersChangeEvent.canParse(obj['event']);
  }

  @override
  bool operator ==(other) {
    if (other is DidChangeWorkspaceFoldersParams) {
      return event == other.event && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, event.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class DidCloseTextDocumentParams implements ToJsonable {
  DidCloseTextDocumentParams(this.textDocument) {
    if (textDocument == null) {
      throw 'textDocument is required but was not provided';
    }
  }
  static DidCloseTextDocumentParams fromJson(Map<String, dynamic> json) {
    final textDocument = json['textDocument'] != null
        ? TextDocumentIdentifier.fromJson(json['textDocument'])
        : null;
    return new DidCloseTextDocumentParams(textDocument);
  }

  /// The document that was closed.
  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('textDocument') &&
        TextDocumentIdentifier.canParse(obj['textDocument']);
  }

  @override
  bool operator ==(other) {
    if (other is DidCloseTextDocumentParams) {
      return textDocument == other.textDocument && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, textDocument.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class DidOpenTextDocumentParams implements ToJsonable {
  DidOpenTextDocumentParams(this.textDocument) {
    if (textDocument == null) {
      throw 'textDocument is required but was not provided';
    }
  }
  static DidOpenTextDocumentParams fromJson(Map<String, dynamic> json) {
    final textDocument = json['textDocument'] != null
        ? TextDocumentItem.fromJson(json['textDocument'])
        : null;
    return new DidOpenTextDocumentParams(textDocument);
  }

  /// The document that was opened.
  final TextDocumentItem textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('textDocument') &&
        TextDocumentItem.canParse(obj['textDocument']);
  }

  @override
  bool operator ==(other) {
    if (other is DidOpenTextDocumentParams) {
      return textDocument == other.textDocument && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, textDocument.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class DidSaveTextDocumentParams implements ToJsonable {
  DidSaveTextDocumentParams(this.textDocument, this.text) {
    if (textDocument == null) {
      throw 'textDocument is required but was not provided';
    }
  }
  static DidSaveTextDocumentParams fromJson(Map<String, dynamic> json) {
    final textDocument = json['textDocument'] != null
        ? TextDocumentIdentifier.fromJson(json['textDocument'])
        : null;
    final text = json['text'];
    return new DidSaveTextDocumentParams(textDocument, text);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('textDocument') &&
        TextDocumentIdentifier.canParse(obj['textDocument']);
  }

  @override
  bool operator ==(other) {
    if (other is DidSaveTextDocumentParams) {
      return textDocument == other.textDocument && text == other.text && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, textDocument.hashCode);
    hash = JenkinsSmiHash.combine(hash, text.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class DocumentFilter implements ToJsonable {
  DocumentFilter(this.language, this.scheme, this.pattern);
  static DocumentFilter fromJson(Map<String, dynamic> json) {
    final language = json['language'];
    final scheme = json['scheme'];
    final pattern = json['pattern'];
    return new DocumentFilter(language, scheme, pattern);
  }

  /// A language id, like `typescript`.
  final String language;

  /// A glob pattern, like `*.{ts,js}`.
  ///
  /// Glob patterns can have the following syntax:
  /// - `*` to match one or more characters in a path segment
  /// - `?` to match on one character in a path segment
  /// - `**` to match any number of path segments, including none
  /// - `{}` to group conditions (e.g. `**​/*.{ts,js}` matches all TypeScript
  /// and JavaScript files)
  /// - `[]` to declare a range of characters to match in a path segment (e.g.,
  /// `example.[0-9]` to match on `example.0`, `example.1`, …)
  /// - `[!...]` to negate a range of characters to match in a path segment
  /// (e.g., `example.[!0-9]` to match on `example.a`, `example.b`, but not
  /// `example.0`)
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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is DocumentFilter) {
      return language == other.language &&
          scheme == other.scheme &&
          pattern == other.pattern &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, language.hashCode);
    hash = JenkinsSmiHash.combine(hash, scheme.hashCode);
    hash = JenkinsSmiHash.combine(hash, pattern.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class DocumentFormattingParams implements ToJsonable {
  DocumentFormattingParams(this.textDocument, this.options) {
    if (textDocument == null) {
      throw 'textDocument is required but was not provided';
    }
    if (options == null) {
      throw 'options is required but was not provided';
    }
  }
  static DocumentFormattingParams fromJson(Map<String, dynamic> json) {
    final textDocument = json['textDocument'] != null
        ? TextDocumentIdentifier.fromJson(json['textDocument'])
        : null;
    final options = json['options'] != null
        ? FormattingOptions.fromJson(json['options'])
        : null;
    return new DocumentFormattingParams(textDocument, options);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('textDocument') &&
        TextDocumentIdentifier.canParse(obj['textDocument']) &&
        obj.containsKey('options') &&
        FormattingOptions.canParse(obj['options']);
  }

  @override
  bool operator ==(other) {
    if (other is DocumentFormattingParams) {
      return textDocument == other.textDocument &&
          options == other.options &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, textDocument.hashCode);
    hash = JenkinsSmiHash.combine(hash, options.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// A document highlight is a range inside a text document which deserves
/// special attention. Usually a document highlight is visualized by changing
/// the background color of its range.
class DocumentHighlight implements ToJsonable {
  DocumentHighlight(this.range, this.kind) {
    if (range == null) {
      throw 'range is required but was not provided';
    }
  }
  static DocumentHighlight fromJson(Map<String, dynamic> json) {
    final range = json['range'] != null ? Range.fromJson(json['range']) : null;
    final kind = json['kind'] != null
        ? DocumentHighlightKind.fromJson(json['kind'])
        : null;
    return new DocumentHighlight(range, kind);
  }

  /// The highlight kind, default is DocumentHighlightKind.Text.
  final DocumentHighlightKind kind;

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('range') &&
        Range.canParse(obj['range']);
  }

  @override
  bool operator ==(other) {
    if (other is DocumentHighlight) {
      return range == other.range && kind == other.kind && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, range.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// A document highlight kind.
class DocumentHighlightKind {
  const DocumentHighlightKind._(this._value);
  const DocumentHighlightKind.fromJson(this._value);

  final num _value;

  static bool canParse(Object obj) {
    switch (obj) {
      case 1:
      case 2:
      case 3:
        return true;
    }
    return false;
  }

  /// A textual occurrence.
  static const Text = const DocumentHighlightKind._(1);

  /// Read-access of a symbol, like reading a variable.
  static const Read = const DocumentHighlightKind._(2);

  /// Write-access of a symbol, like writing to a variable.
  static const Write = const DocumentHighlightKind._(3);

  Object toJson() => _value;

  @override
  String toString() => _value.toString();

  @override
  get hashCode => _value.hashCode;

  bool operator ==(o) => o is DocumentHighlightKind && o._value == _value;
}

/// A document link is a range in a text document that links to an internal or
/// external resource, like another text document or a web site.
class DocumentLink implements ToJsonable {
  DocumentLink(this.range, this.target, this.data) {
    if (range == null) {
      throw 'range is required but was not provided';
    }
  }
  static DocumentLink fromJson(Map<String, dynamic> json) {
    final range = json['range'] != null ? Range.fromJson(json['range']) : null;
    final target = json['target'];
    final data = json['data'];
    return new DocumentLink(range, target, data);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('range') &&
        Range.canParse(obj['range']);
  }

  @override
  bool operator ==(other) {
    if (other is DocumentLink) {
      return range == other.range &&
          target == other.target &&
          data == other.data &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, range.hashCode);
    hash = JenkinsSmiHash.combine(hash, target.hashCode);
    hash = JenkinsSmiHash.combine(hash, data.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Document link options.
class DocumentLinkOptions implements ToJsonable {
  DocumentLinkOptions(this.resolveProvider);
  static DocumentLinkOptions fromJson(Map<String, dynamic> json) {
    final resolveProvider = json['resolveProvider'];
    return new DocumentLinkOptions(resolveProvider);
  }

  /// Document links have a resolve provider as well.
  final bool resolveProvider;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (resolveProvider != null) {
      __result['resolveProvider'] = resolveProvider;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is DocumentLinkOptions) {
      return resolveProvider == other.resolveProvider && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, resolveProvider.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class DocumentLinkParams implements ToJsonable {
  DocumentLinkParams(this.textDocument) {
    if (textDocument == null) {
      throw 'textDocument is required but was not provided';
    }
  }
  static DocumentLinkParams fromJson(Map<String, dynamic> json) {
    final textDocument = json['textDocument'] != null
        ? TextDocumentIdentifier.fromJson(json['textDocument'])
        : null;
    return new DocumentLinkParams(textDocument);
  }

  /// The document to provide document links for.
  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('textDocument') &&
        TextDocumentIdentifier.canParse(obj['textDocument']);
  }

  @override
  bool operator ==(other) {
    if (other is DocumentLinkParams) {
      return textDocument == other.textDocument && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, textDocument.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class DocumentLinkRegistrationOptions
    implements TextDocumentRegistrationOptions, ToJsonable {
  DocumentLinkRegistrationOptions(this.resolveProvider, this.documentSelector);
  static DocumentLinkRegistrationOptions fromJson(Map<String, dynamic> json) {
    final resolveProvider = json['resolveProvider'];
    final documentSelector = json['documentSelector']
        ?.map((item) => item != null ? DocumentFilter.fromJson(item) : null)
        ?.cast<DocumentFilter>()
        ?.toList();
    return new DocumentLinkRegistrationOptions(
        resolveProvider, documentSelector);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('documentSelector') &&
        (obj['documentSelector'] is List &&
            (obj['documentSelector']
                .every((item) => DocumentFilter.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is DocumentLinkRegistrationOptions) {
      return resolveProvider == other.resolveProvider &&
          documentSelector == other.documentSelector &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, resolveProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, documentSelector.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Format document on type options.
class DocumentOnTypeFormattingOptions implements ToJsonable {
  DocumentOnTypeFormattingOptions(
      this.firstTriggerCharacter, this.moreTriggerCharacter) {
    if (firstTriggerCharacter == null) {
      throw 'firstTriggerCharacter is required but was not provided';
    }
  }
  static DocumentOnTypeFormattingOptions fromJson(Map<String, dynamic> json) {
    final firstTriggerCharacter = json['firstTriggerCharacter'];
    final moreTriggerCharacter = json['moreTriggerCharacter']
        ?.map((item) => item)
        ?.cast<String>()
        ?.toList();
    return new DocumentOnTypeFormattingOptions(
        firstTriggerCharacter, moreTriggerCharacter);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('firstTriggerCharacter') &&
        obj['firstTriggerCharacter'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is DocumentOnTypeFormattingOptions) {
      return firstTriggerCharacter == other.firstTriggerCharacter &&
          listEqual(moreTriggerCharacter, other.moreTriggerCharacter,
              (String a, String b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, firstTriggerCharacter.hashCode);
    hash = JenkinsSmiHash.combine(hash, moreTriggerCharacter.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class DocumentOnTypeFormattingParams implements ToJsonable {
  DocumentOnTypeFormattingParams(
      this.textDocument, this.position, this.ch, this.options) {
    if (textDocument == null) {
      throw 'textDocument is required but was not provided';
    }
    if (position == null) {
      throw 'position is required but was not provided';
    }
    if (ch == null) {
      throw 'ch is required but was not provided';
    }
    if (options == null) {
      throw 'options is required but was not provided';
    }
  }
  static DocumentOnTypeFormattingParams fromJson(Map<String, dynamic> json) {
    final textDocument = json['textDocument'] != null
        ? TextDocumentIdentifier.fromJson(json['textDocument'])
        : null;
    final position =
        json['position'] != null ? Position.fromJson(json['position']) : null;
    final ch = json['ch'];
    final options = json['options'] != null
        ? FormattingOptions.fromJson(json['options'])
        : null;
    return new DocumentOnTypeFormattingParams(
        textDocument, position, ch, options);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('textDocument') &&
        TextDocumentIdentifier.canParse(obj['textDocument']) &&
        obj.containsKey('position') &&
        Position.canParse(obj['position']) &&
        obj.containsKey('ch') &&
        obj['ch'] is String &&
        obj.containsKey('options') &&
        FormattingOptions.canParse(obj['options']);
  }

  @override
  bool operator ==(other) {
    if (other is DocumentOnTypeFormattingParams) {
      return textDocument == other.textDocument &&
          position == other.position &&
          ch == other.ch &&
          options == other.options &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, textDocument.hashCode);
    hash = JenkinsSmiHash.combine(hash, position.hashCode);
    hash = JenkinsSmiHash.combine(hash, ch.hashCode);
    hash = JenkinsSmiHash.combine(hash, options.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class DocumentOnTypeFormattingRegistrationOptions
    implements TextDocumentRegistrationOptions, ToJsonable {
  DocumentOnTypeFormattingRegistrationOptions(this.firstTriggerCharacter,
      this.moreTriggerCharacter, this.documentSelector) {
    if (firstTriggerCharacter == null) {
      throw 'firstTriggerCharacter is required but was not provided';
    }
  }
  static DocumentOnTypeFormattingRegistrationOptions fromJson(
      Map<String, dynamic> json) {
    final firstTriggerCharacter = json['firstTriggerCharacter'];
    final moreTriggerCharacter = json['moreTriggerCharacter']
        ?.map((item) => item)
        ?.cast<String>()
        ?.toList();
    final documentSelector = json['documentSelector']
        ?.map((item) => item != null ? DocumentFilter.fromJson(item) : null)
        ?.cast<DocumentFilter>()
        ?.toList();
    return new DocumentOnTypeFormattingRegistrationOptions(
        firstTriggerCharacter, moreTriggerCharacter, documentSelector);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('firstTriggerCharacter') &&
        obj['firstTriggerCharacter'] is String &&
        obj.containsKey('documentSelector') &&
        (obj['documentSelector'] is List &&
            (obj['documentSelector']
                .every((item) => DocumentFilter.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is DocumentOnTypeFormattingRegistrationOptions) {
      return firstTriggerCharacter == other.firstTriggerCharacter &&
          listEqual(moreTriggerCharacter, other.moreTriggerCharacter,
              (String a, String b) => a == b) &&
          documentSelector == other.documentSelector &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, firstTriggerCharacter.hashCode);
    hash = JenkinsSmiHash.combine(hash, moreTriggerCharacter.hashCode);
    hash = JenkinsSmiHash.combine(hash, documentSelector.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class DocumentRangeFormattingParams implements ToJsonable {
  DocumentRangeFormattingParams(this.textDocument, this.range, this.options) {
    if (textDocument == null) {
      throw 'textDocument is required but was not provided';
    }
    if (range == null) {
      throw 'range is required but was not provided';
    }
    if (options == null) {
      throw 'options is required but was not provided';
    }
  }
  static DocumentRangeFormattingParams fromJson(Map<String, dynamic> json) {
    final textDocument = json['textDocument'] != null
        ? TextDocumentIdentifier.fromJson(json['textDocument'])
        : null;
    final range = json['range'] != null ? Range.fromJson(json['range']) : null;
    final options = json['options'] != null
        ? FormattingOptions.fromJson(json['options'])
        : null;
    return new DocumentRangeFormattingParams(textDocument, range, options);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('textDocument') &&
        TextDocumentIdentifier.canParse(obj['textDocument']) &&
        obj.containsKey('range') &&
        Range.canParse(obj['range']) &&
        obj.containsKey('options') &&
        FormattingOptions.canParse(obj['options']);
  }

  @override
  bool operator ==(other) {
    if (other is DocumentRangeFormattingParams) {
      return textDocument == other.textDocument &&
          range == other.range &&
          options == other.options &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, textDocument.hashCode);
    hash = JenkinsSmiHash.combine(hash, range.hashCode);
    hash = JenkinsSmiHash.combine(hash, options.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Represents programming constructs like variables, classes, interfaces etc.
/// that appear in a document. Document symbols can be hierarchical and they
/// have two ranges: one that encloses its definition and one that points to its
/// most interesting range, e.g. the range of an identifier.
class DocumentSymbol implements ToJsonable {
  DocumentSymbol(this.name, this.detail, this.kind, this.deprecated, this.range,
      this.selectionRange, this.children) {
    if (name == null) {
      throw 'name is required but was not provided';
    }
    if (kind == null) {
      throw 'kind is required but was not provided';
    }
    if (range == null) {
      throw 'range is required but was not provided';
    }
    if (selectionRange == null) {
      throw 'selectionRange is required but was not provided';
    }
  }
  static DocumentSymbol fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final detail = json['detail'];
    final kind =
        json['kind'] != null ? SymbolKind.fromJson(json['kind']) : null;
    final deprecated = json['deprecated'];
    final range = json['range'] != null ? Range.fromJson(json['range']) : null;
    final selectionRange = json['selectionRange'] != null
        ? Range.fromJson(json['selectionRange'])
        : null;
    final children = json['children']
        ?.map((item) => item != null ? DocumentSymbol.fromJson(item) : null)
        ?.cast<DocumentSymbol>()
        ?.toList();
    return new DocumentSymbol(
        name, detail, kind, deprecated, range, selectionRange, children);
  }

  /// Children of this symbol, e.g. properties of a class.
  final List<DocumentSymbol> children;

  /// Indicates if this symbol is deprecated.
  final bool deprecated;

  /// More detail for this symbol, e.g the signature of a function.
  final String detail;

  /// The kind of this symbol.
  final SymbolKind kind;

  /// The name of this symbol. Will be displayed in the user interface and
  /// therefore must not be an empty string or a string only consisting of white
  /// spaces.
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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('name') &&
        obj['name'] is String &&
        obj.containsKey('kind') &&
        SymbolKind.canParse(obj['kind']) &&
        obj.containsKey('range') &&
        Range.canParse(obj['range']) &&
        obj.containsKey('selectionRange') &&
        Range.canParse(obj['selectionRange']);
  }

  @override
  bool operator ==(other) {
    if (other is DocumentSymbol) {
      return name == other.name &&
          detail == other.detail &&
          kind == other.kind &&
          deprecated == other.deprecated &&
          range == other.range &&
          selectionRange == other.selectionRange &&
          listEqual(children, other.children,
              (DocumentSymbol a, DocumentSymbol b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, detail.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, deprecated.hashCode);
    hash = JenkinsSmiHash.combine(hash, range.hashCode);
    hash = JenkinsSmiHash.combine(hash, selectionRange.hashCode);
    hash = JenkinsSmiHash.combine(hash, children.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class DocumentSymbolParams implements ToJsonable {
  DocumentSymbolParams(this.textDocument) {
    if (textDocument == null) {
      throw 'textDocument is required but was not provided';
    }
  }
  static DocumentSymbolParams fromJson(Map<String, dynamic> json) {
    final textDocument = json['textDocument'] != null
        ? TextDocumentIdentifier.fromJson(json['textDocument'])
        : null;
    return new DocumentSymbolParams(textDocument);
  }

  /// The text document.
  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('textDocument') &&
        TextDocumentIdentifier.canParse(obj['textDocument']);
  }

  @override
  bool operator ==(other) {
    if (other is DocumentSymbolParams) {
      return textDocument == other.textDocument && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, textDocument.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ErrorCodes {
  const ErrorCodes(this._value);
  const ErrorCodes.fromJson(this._value);

  final num _value;

  static bool canParse(Object obj) {
    return obj is num;
  }

  /// Defined by JSON RPC
  static const ParseError = const ErrorCodes(-32700);
  static const InvalidRequest = const ErrorCodes(-32600);
  static const MethodNotFound = const ErrorCodes(-32601);
  static const InvalidParams = const ErrorCodes(-32602);
  static const InternalError = const ErrorCodes(-32603);
  static const serverErrorStart = const ErrorCodes(-32099);
  static const serverErrorEnd = const ErrorCodes(-32000);
  static const ServerNotInitialized = const ErrorCodes(-32002);
  static const UnknownErrorCode = const ErrorCodes(-32001);

  /// Defined by the protocol.
  static const RequestCancelled = const ErrorCodes(-32800);
  static const ContentModified = const ErrorCodes(-32801);

  Object toJson() => _value;

  @override
  String toString() => _value.toString();

  @override
  get hashCode => _value.hashCode;

  bool operator ==(o) => o is ErrorCodes && o._value == _value;
}

/// Execute command options.
class ExecuteCommandOptions implements ToJsonable {
  ExecuteCommandOptions(this.commands) {
    if (commands == null) {
      throw 'commands is required but was not provided';
    }
  }
  static ExecuteCommandOptions fromJson(Map<String, dynamic> json) {
    final commands =
        json['commands']?.map((item) => item)?.cast<String>()?.toList();
    return new ExecuteCommandOptions(commands);
  }

  /// The commands to be executed on the server
  final List<String> commands;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['commands'] =
        commands ?? (throw 'commands is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('commands') &&
        (obj['commands'] is List &&
            (obj['commands'].every((item) => item is String)));
  }

  @override
  bool operator ==(other) {
    if (other is ExecuteCommandOptions) {
      return listEqual(
              commands, other.commands, (String a, String b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, commands.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ExecuteCommandParams implements ToJsonable {
  ExecuteCommandParams(this.command, this.arguments) {
    if (command == null) {
      throw 'command is required but was not provided';
    }
  }
  static ExecuteCommandParams fromJson(Map<String, dynamic> json) {
    final command = json['command'];
    final arguments =
        json['arguments']?.map((item) => item)?.cast<dynamic>()?.toList();
    return new ExecuteCommandParams(command, arguments);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('command') &&
        obj['command'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is ExecuteCommandParams) {
      return command == other.command &&
          listEqual(
              arguments, other.arguments, (dynamic a, dynamic b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, command.hashCode);
    hash = JenkinsSmiHash.combine(hash, arguments.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Execute command registration options.
class ExecuteCommandRegistrationOptions implements ToJsonable {
  ExecuteCommandRegistrationOptions(this.commands) {
    if (commands == null) {
      throw 'commands is required but was not provided';
    }
  }
  static ExecuteCommandRegistrationOptions fromJson(Map<String, dynamic> json) {
    final commands =
        json['commands']?.map((item) => item)?.cast<String>()?.toList();
    return new ExecuteCommandRegistrationOptions(commands);
  }

  /// The commands to be executed on the server
  final List<String> commands;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['commands'] =
        commands ?? (throw 'commands is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('commands') &&
        (obj['commands'] is List &&
            (obj['commands'].every((item) => item is String)));
  }

  @override
  bool operator ==(other) {
    if (other is ExecuteCommandRegistrationOptions) {
      return listEqual(
              commands, other.commands, (String a, String b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, commands.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class FailureHandlingKind {
  const FailureHandlingKind._(this._value);
  const FailureHandlingKind.fromJson(this._value);

  final String _value;

  static bool canParse(Object obj) {
    switch (obj) {
      case 'abort':
      case 'transactional':
      case 'textOnlyTransactional':
      case 'undo':
        return true;
    }
    return false;
  }

  /// Applying the workspace change is simply aborted if one of the changes
  /// provided fails. All operations executed before the failing operation stay
  /// executed.
  static const Abort = const FailureHandlingKind._('abort');

  /// All operations are executed transactional. That means they either all
  /// succeed or no changes at all are applied to the workspace.
  static const Transactional = const FailureHandlingKind._('transactional');

  /// If the workspace edit contains only textual file changes they are executed
  /// transactional. If resource changes (create, rename or delete file) are
  /// part of the change the failure handling strategy is abort.
  static const TextOnlyTransactional =
      const FailureHandlingKind._('textOnlyTransactional');

  /// The client tries to undo the operations already executed. But there is no
  /// guarantee that this is succeeding.
  static const Undo = const FailureHandlingKind._('undo');

  Object toJson() => _value;

  @override
  String toString() => _value.toString();

  @override
  get hashCode => _value.hashCode;

  bool operator ==(o) => o is FailureHandlingKind && o._value == _value;
}

/// The file event type.
class FileChangeType {
  const FileChangeType._(this._value);
  const FileChangeType.fromJson(this._value);

  final num _value;

  static bool canParse(Object obj) {
    switch (obj) {
      case 1:
      case 2:
      case 3:
        return true;
    }
    return false;
  }

  /// The file got created.
  static const Created = const FileChangeType._(1);

  /// The file got changed.
  static const Changed = const FileChangeType._(2);

  /// The file got deleted.
  static const Deleted = const FileChangeType._(3);

  Object toJson() => _value;

  @override
  String toString() => _value.toString();

  @override
  get hashCode => _value.hashCode;

  bool operator ==(o) => o is FileChangeType && o._value == _value;
}

/// An event describing a file change.
class FileEvent implements ToJsonable {
  FileEvent(this.uri, this.type) {
    if (uri == null) {
      throw 'uri is required but was not provided';
    }
    if (type == null) {
      throw 'type is required but was not provided';
    }
  }
  static FileEvent fromJson(Map<String, dynamic> json) {
    final uri = json['uri'];
    final type = json['type'];
    return new FileEvent(uri, type);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('uri') &&
        obj['uri'] is String &&
        obj.containsKey('type') &&
        obj['type'] is num;
  }

  @override
  bool operator ==(other) {
    if (other is FileEvent) {
      return uri == other.uri && type == other.type && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, uri.hashCode);
    hash = JenkinsSmiHash.combine(hash, type.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class FileSystemWatcher implements ToJsonable {
  FileSystemWatcher(this.globPattern, this.kind) {
    if (globPattern == null) {
      throw 'globPattern is required but was not provided';
    }
  }
  static FileSystemWatcher fromJson(Map<String, dynamic> json) {
    final globPattern = json['globPattern'];
    final kind = json['kind'] != null ? WatchKind.fromJson(json['kind']) : null;
    return new FileSystemWatcher(globPattern, kind);
  }

  /// The  glob pattern to watch.
  ///
  /// Glob patterns can have the following syntax:
  /// - `*` to match one or more characters in a path segment
  /// - `?` to match on one character in a path segment
  /// - `**` to match any number of path segments, including none
  /// - `{}` to group conditions (e.g. `**​/*.{ts,js}` matches all TypeScript
  /// and JavaScript files)
  /// - `[]` to declare a range of characters to match in a path segment (e.g.,
  /// `example.[0-9]` to match on `example.0`, `example.1`, …)
  /// - `[!...]` to negate a range of characters to match in a path segment
  /// (e.g., `example.[!0-9]` to match on `example.a`, `example.b`, but not
  /// `example.0`)
  final String globPattern;

  /// The kind of events of interest. If omitted it defaults to WatchKind.Create
  /// | WatchKind.Change | WatchKind.Delete which is 7.
  final WatchKind kind;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['globPattern'] =
        globPattern ?? (throw 'globPattern is required but was not set');
    if (kind != null) {
      __result['kind'] = kind;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('globPattern') &&
        obj['globPattern'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is FileSystemWatcher) {
      return globPattern == other.globPattern && kind == other.kind && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, globPattern.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Represents a folding range.
class FoldingRange implements ToJsonable {
  FoldingRange(this.startLine, this.startCharacter, this.endLine,
      this.endCharacter, this.kind) {
    if (startLine == null) {
      throw 'startLine is required but was not provided';
    }
    if (endLine == null) {
      throw 'endLine is required but was not provided';
    }
  }
  static FoldingRange fromJson(Map<String, dynamic> json) {
    final startLine = json['startLine'];
    final startCharacter = json['startCharacter'];
    final endLine = json['endLine'];
    final endCharacter = json['endCharacter'];
    final kind =
        json['kind'] != null ? FoldingRangeKind.fromJson(json['kind']) : null;
    return new FoldingRange(
        startLine, startCharacter, endLine, endCharacter, kind);
  }

  /// The zero-based character offset before the folded range ends. If not
  /// defined, defaults to the length of the end line.
  final num endCharacter;

  /// The zero-based line number where the folded range ends.
  final num endLine;

  /// Describes the kind of the folding range such as `comment' or 'region'. The
  /// kind is used to categorize folding ranges and used by commands like 'Fold
  /// all comments'. See [FoldingRangeKind] for an enumeration of standardized
  /// kinds.
  final FoldingRangeKind kind;

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('startLine') &&
        obj['startLine'] is num &&
        obj.containsKey('endLine') &&
        obj['endLine'] is num;
  }

  @override
  bool operator ==(other) {
    if (other is FoldingRange) {
      return startLine == other.startLine &&
          startCharacter == other.startCharacter &&
          endLine == other.endLine &&
          endCharacter == other.endCharacter &&
          kind == other.kind &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, startLine.hashCode);
    hash = JenkinsSmiHash.combine(hash, startCharacter.hashCode);
    hash = JenkinsSmiHash.combine(hash, endLine.hashCode);
    hash = JenkinsSmiHash.combine(hash, endCharacter.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Enum of known range kinds
class FoldingRangeKind {
  const FoldingRangeKind._(this._value);
  const FoldingRangeKind.fromJson(this._value);

  final String _value;

  static bool canParse(Object obj) {
    switch (obj) {
      case r'comment':
      case r'imports':
      case r'region':
        return true;
    }
    return false;
  }

  /// Folding range for a comment
  static const Comment = const FoldingRangeKind._(r'comment');

  /// Folding range for a imports or includes
  static const Imports = const FoldingRangeKind._(r'imports');

  /// Folding range for a region (e.g. `#region`)
  static const Region = const FoldingRangeKind._(r'region');

  Object toJson() => _value;

  @override
  String toString() => _value.toString();

  @override
  get hashCode => _value.hashCode;

  bool operator ==(o) => o is FoldingRangeKind && o._value == _value;
}

class FoldingRangeParams implements ToJsonable {
  FoldingRangeParams(this.textDocument) {
    if (textDocument == null) {
      throw 'textDocument is required but was not provided';
    }
  }
  static FoldingRangeParams fromJson(Map<String, dynamic> json) {
    final textDocument = json['textDocument'] != null
        ? TextDocumentIdentifier.fromJson(json['textDocument'])
        : null;
    return new FoldingRangeParams(textDocument);
  }

  /// The text document.
  final TextDocumentIdentifier textDocument;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['textDocument'] =
        textDocument ?? (throw 'textDocument is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('textDocument') &&
        TextDocumentIdentifier.canParse(obj['textDocument']);
  }

  @override
  bool operator ==(other) {
    if (other is FoldingRangeParams) {
      return textDocument == other.textDocument && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, textDocument.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Folding range provider options.
class FoldingRangeProviderOptions implements ToJsonable {
  static FoldingRangeProviderOptions fromJson(Map<String, dynamic> json) {
    return new FoldingRangeProviderOptions();
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is FoldingRangeProviderOptions) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Value-object describing what options formatting should use.
class FormattingOptions implements ToJsonable {
  FormattingOptions(this.tabSize, this.insertSpaces) {
    if (tabSize == null) {
      throw 'tabSize is required but was not provided';
    }
    if (insertSpaces == null) {
      throw 'insertSpaces is required but was not provided';
    }
  }
  static FormattingOptions fromJson(Map<String, dynamic> json) {
    final tabSize = json['tabSize'];
    final insertSpaces = json['insertSpaces'];
    return new FormattingOptions(tabSize, insertSpaces);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('tabSize') &&
        obj['tabSize'] is num &&
        obj.containsKey('insertSpaces') &&
        obj['insertSpaces'] is bool;
  }

  @override
  bool operator ==(other) {
    if (other is FormattingOptions) {
      return tabSize == other.tabSize &&
          insertSpaces == other.insertSpaces &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, tabSize.hashCode);
    hash = JenkinsSmiHash.combine(hash, insertSpaces.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// The result of a hover request.
class Hover implements ToJsonable {
  Hover(this.contents, this.range) {
    if (contents == null) {
      throw 'contents is required but was not provided';
    }
  }
  static Hover fromJson(Map<String, dynamic> json) {
    final contents = json['contents'] is String
        ? new Either2<String, MarkupContent>.t1(json['contents'])
        : (MarkupContent.canParse(json['contents'])
            ? new Either2<String, MarkupContent>.t2(json['contents'] != null
                ? MarkupContent.fromJson(json['contents'])
                : null)
            : (throw '''${json['contents']} was not one of (String, MarkupContent)'''));
    final range = json['range'] != null ? Range.fromJson(json['range']) : null;
    return new Hover(contents, range);
  }

  /// The hover's content
  final Either2<String, MarkupContent> contents;

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('contents') &&
        (obj['contents'] is String || MarkupContent.canParse(obj['contents']));
  }

  @override
  bool operator ==(other) {
    if (other is Hover) {
      return contents == other.contents && range == other.range && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, contents.hashCode);
    hash = JenkinsSmiHash.combine(hash, range.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class InitializeParams implements ToJsonable {
  InitializeParams(
      this.processId,
      this.rootPath,
      this.rootUri,
      this.initializationOptions,
      this.capabilities,
      this.trace,
      this.workspaceFolders) {
    if (capabilities == null) {
      throw 'capabilities is required but was not provided';
    }
  }
  static InitializeParams fromJson(Map<String, dynamic> json) {
    final processId = json['processId'];
    final rootPath = json['rootPath'];
    final rootUri = json['rootUri'];
    final initializationOptions = json['initializationOptions'];
    final capabilities = json['capabilities'] != null
        ? ClientCapabilities.fromJson(json['capabilities'])
        : null;
    final trace = json['trace'];
    final workspaceFolders = json['workspaceFolders']
        ?.map((item) => item != null ? WorkspaceFolder.fromJson(item) : null)
        ?.cast<WorkspaceFolder>()
        ?.toList();
    return new InitializeParams(processId, rootPath, rootUri,
        initializationOptions, capabilities, trace, workspaceFolders);
  }

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
  @core.deprecated
  final String rootPath;

  /// The rootUri of the workspace. Is null if no folder is open. If both
  /// `rootPath` and `rootUri` are set `rootUri` wins.
  final String rootUri;

  /// The initial trace setting. If omitted trace is disabled ('off').
  final String trace;

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
    if (trace != null) {
      __result['trace'] = trace;
    }
    if (workspaceFolders != null) {
      __result['workspaceFolders'] = workspaceFolders;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('processId') &&
        obj['processId'] is num &&
        obj.containsKey('rootUri') &&
        obj['rootUri'] is String &&
        obj.containsKey('capabilities') &&
        ClientCapabilities.canParse(obj['capabilities']);
  }

  @override
  bool operator ==(other) {
    if (other is InitializeParams) {
      return processId == other.processId &&
          rootPath == other.rootPath &&
          rootUri == other.rootUri &&
          initializationOptions == other.initializationOptions &&
          capabilities == other.capabilities &&
          trace == other.trace &&
          listEqual(workspaceFolders, other.workspaceFolders,
              (WorkspaceFolder a, WorkspaceFolder b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, processId.hashCode);
    hash = JenkinsSmiHash.combine(hash, rootPath.hashCode);
    hash = JenkinsSmiHash.combine(hash, rootUri.hashCode);
    hash = JenkinsSmiHash.combine(hash, initializationOptions.hashCode);
    hash = JenkinsSmiHash.combine(hash, capabilities.hashCode);
    hash = JenkinsSmiHash.combine(hash, trace.hashCode);
    hash = JenkinsSmiHash.combine(hash, workspaceFolders.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class InitializeResult implements ToJsonable {
  InitializeResult(this.capabilities) {
    if (capabilities == null) {
      throw 'capabilities is required but was not provided';
    }
  }
  static InitializeResult fromJson(Map<String, dynamic> json) {
    final capabilities = json['capabilities'] != null
        ? ServerCapabilities.fromJson(json['capabilities'])
        : null;
    return new InitializeResult(capabilities);
  }

  /// The capabilities the language server provides.
  final ServerCapabilities capabilities;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['capabilities'] =
        capabilities ?? (throw 'capabilities is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('capabilities') &&
        ServerCapabilities.canParse(obj['capabilities']);
  }

  @override
  bool operator ==(other) {
    if (other is InitializeResult) {
      return capabilities == other.capabilities && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, capabilities.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class InitializedParams implements ToJsonable {
  static InitializedParams fromJson(Map<String, dynamic> json) {
    return new InitializedParams();
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is InitializedParams) {
      return true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Defines whether the insert text in a completion item should be interpreted
/// as plain text or a snippet.
class InsertTextFormat {
  const InsertTextFormat._(this._value);
  const InsertTextFormat.fromJson(this._value);

  final num _value;

  static bool canParse(Object obj) {
    switch (obj) {
      case 1:
      case 2:
        return true;
    }
    return false;
  }

  /// The primary text to be inserted is treated as a plain string.
  static const PlainText = const InsertTextFormat._(1);

  /// The primary text to be inserted is treated as a snippet.
  ///
  /// A snippet can define tab stops and placeholders with `$1`, `$2` and
  /// `${3:foo}`. `$0` defines the final tab stop, it defaults to the end of the
  /// snippet. Placeholders with equal identifiers are linked, that is typing in
  /// one will update others too.
  static const Snippet = const InsertTextFormat._(2);

  Object toJson() => _value;

  @override
  String toString() => _value.toString();

  @override
  get hashCode => _value.hashCode;

  bool operator ==(o) => o is InsertTextFormat && o._value == _value;
}

class Location implements ToJsonable {
  Location(this.uri, this.range) {
    if (uri == null) {
      throw 'uri is required but was not provided';
    }
    if (range == null) {
      throw 'range is required but was not provided';
    }
  }
  static Location fromJson(Map<String, dynamic> json) {
    final uri = json['uri'];
    final range = json['range'] != null ? Range.fromJson(json['range']) : null;
    return new Location(uri, range);
  }

  final Range range;
  final String uri;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['uri'] = uri ?? (throw 'uri is required but was not set');
    __result['range'] = range ?? (throw 'range is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('uri') &&
        obj['uri'] is String &&
        obj.containsKey('range') &&
        Range.canParse(obj['range']);
  }

  @override
  bool operator ==(other) {
    if (other is Location) {
      return uri == other.uri && range == other.range && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, uri.hashCode);
    hash = JenkinsSmiHash.combine(hash, range.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class LocationLink implements ToJsonable {
  LocationLink(this.originSelectionRange, this.targetUri, this.targetRange,
      this.targetSelectionRange) {
    if (targetUri == null) {
      throw 'targetUri is required but was not provided';
    }
    if (targetRange == null) {
      throw 'targetRange is required but was not provided';
    }
    if (targetSelectionRange == null) {
      throw 'targetSelectionRange is required but was not provided';
    }
  }
  static LocationLink fromJson(Map<String, dynamic> json) {
    final originSelectionRange = json['originSelectionRange'] != null
        ? Range.fromJson(json['originSelectionRange'])
        : null;
    final targetUri = json['targetUri'];
    final targetRange = json['targetRange'] != null
        ? Range.fromJson(json['targetRange'])
        : null;
    final targetSelectionRange = json['targetSelectionRange'] != null
        ? Range.fromJson(json['targetSelectionRange'])
        : null;
    return new LocationLink(
        originSelectionRange, targetUri, targetRange, targetSelectionRange);
  }

  /// Span of the origin of this link.
  ///
  /// Used as the underlined span for mouse interaction. Defaults to the word
  /// range at the mouse position.
  final Range originSelectionRange;

  /// The full target range of this link. If the target for example is a symbol
  /// then target range is the range enclosing this symbol not including
  /// leading/trailing whitespace but everything else like comments. This
  /// information is typically used to highlight the range in the editor.
  final Range targetRange;

  /// The range that should be selected and revealed when this link is being
  /// followed, e.g the name of a function. Must be contained by the the
  /// `targetRange`. See also `DocumentSymbol#range`
  final Range targetSelectionRange;

  /// The target resource identifier of this link.
  final String targetUri;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (originSelectionRange != null) {
      __result['originSelectionRange'] = originSelectionRange;
    }
    __result['targetUri'] =
        targetUri ?? (throw 'targetUri is required but was not set');
    __result['targetRange'] =
        targetRange ?? (throw 'targetRange is required but was not set');
    __result['targetSelectionRange'] = targetSelectionRange ??
        (throw 'targetSelectionRange is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('targetUri') &&
        obj['targetUri'] is String &&
        obj.containsKey('targetRange') &&
        Range.canParse(obj['targetRange']) &&
        obj.containsKey('targetSelectionRange') &&
        Range.canParse(obj['targetSelectionRange']);
  }

  @override
  bool operator ==(other) {
    if (other is LocationLink) {
      return originSelectionRange == other.originSelectionRange &&
          targetUri == other.targetUri &&
          targetRange == other.targetRange &&
          targetSelectionRange == other.targetSelectionRange &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, originSelectionRange.hashCode);
    hash = JenkinsSmiHash.combine(hash, targetUri.hashCode);
    hash = JenkinsSmiHash.combine(hash, targetRange.hashCode);
    hash = JenkinsSmiHash.combine(hash, targetSelectionRange.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class LogMessageParams implements ToJsonable {
  LogMessageParams(this.type, this.message) {
    if (type == null) {
      throw 'type is required but was not provided';
    }
    if (message == null) {
      throw 'message is required but was not provided';
    }
  }
  static LogMessageParams fromJson(Map<String, dynamic> json) {
    final type =
        json['type'] != null ? MessageType.fromJson(json['type']) : null;
    final message = json['message'];
    return new LogMessageParams(type, message);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('type') &&
        MessageType.canParse(obj['type']) &&
        obj.containsKey('message') &&
        obj['message'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is LogMessageParams) {
      return type == other.type && message == other.message && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, type.hashCode);
    hash = JenkinsSmiHash.combine(hash, message.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
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
/// TypeScript: ```typescript let markdown: MarkdownContent = {
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
class MarkupContent implements ToJsonable {
  MarkupContent(this.kind, this.value) {
    if (kind == null) {
      throw 'kind is required but was not provided';
    }
    if (value == null) {
      throw 'value is required but was not provided';
    }
  }
  static MarkupContent fromJson(Map<String, dynamic> json) {
    final kind =
        json['kind'] != null ? MarkupKind.fromJson(json['kind']) : null;
    final value = json['value'];
    return new MarkupContent(kind, value);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('kind') &&
        obj['kind'] is String &&
        obj.containsKey('value') &&
        obj['value'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is MarkupContent) {
      return kind == other.kind && value == other.value && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, value.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Describes the content type that a client supports in various result literals
/// like `Hover`, `ParameterInfo` or `CompletionItem`.
///
/// Please note that `MarkupKinds` must not start with a `$`. This kinds are
/// reserved for internal usage.
class MarkupKind {
  const MarkupKind._(this._value);
  const MarkupKind.fromJson(this._value);

  final String _value;

  static bool canParse(Object obj) {
    switch (obj) {
      case r'plaintext':
      case r'markdown':
        return true;
    }
    return false;
  }

  /// Plain text is supported as a content format
  static const PlainText = const MarkupKind._(r'plaintext');

  /// Markdown is supported as a content format
  static const Markdown = const MarkupKind._(r'markdown');

  Object toJson() => _value;

  @override
  String toString() => _value.toString();

  @override
  get hashCode => _value.hashCode;

  bool operator ==(o) => o is MarkupKind && o._value == _value;
}

class Message implements ToJsonable {
  Message(this.jsonrpc) {
    if (jsonrpc == null) {
      throw 'jsonrpc is required but was not provided';
    }
  }
  static Message fromJson(Map<String, dynamic> json) {
    if (RequestMessage.canParse(json)) {
      return RequestMessage.fromJson(json);
    }
    if (ResponseMessage.canParse(json)) {
      return ResponseMessage.fromJson(json);
    }
    if (NotificationMessage.canParse(json)) {
      return NotificationMessage.fromJson(json);
    }
    final jsonrpc = json['jsonrpc'];
    return new Message(jsonrpc);
  }

  final String jsonrpc;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['jsonrpc'] =
        jsonrpc ?? (throw 'jsonrpc is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('jsonrpc') &&
        obj['jsonrpc'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is Message) {
      return jsonrpc == other.jsonrpc && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, jsonrpc.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class MessageActionItem implements ToJsonable {
  MessageActionItem(this.title) {
    if (title == null) {
      throw 'title is required but was not provided';
    }
  }
  static MessageActionItem fromJson(Map<String, dynamic> json) {
    final title = json['title'];
    return new MessageActionItem(title);
  }

  /// A short title like 'Retry', 'Open Log' etc.
  final String title;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['title'] = title ?? (throw 'title is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('title') &&
        obj['title'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is MessageActionItem) {
      return title == other.title && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, title.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class MessageType {
  const MessageType._(this._value);
  const MessageType.fromJson(this._value);

  final num _value;

  static bool canParse(Object obj) {
    switch (obj) {
      case 1:
      case 2:
      case 3:
      case 4:
        return true;
    }
    return false;
  }

  /// An error message.
  static const Error = const MessageType._(1);

  /// A warning message.
  static const Warning = const MessageType._(2);

  /// An information message.
  static const Info = const MessageType._(3);

  /// A log message.
  static const Log = const MessageType._(4);

  Object toJson() => _value;

  @override
  String toString() => _value.toString();

  @override
  get hashCode => _value.hashCode;

  bool operator ==(o) => o is MessageType && o._value == _value;
}

/// Valid LSP methods known at the time of code generation from the spec.
class Method {
  const Method(this._value);
  const Method.fromJson(this._value);

  final String _value;

  static bool canParse(Object obj) {
    return obj is String;
  }

  /// Constant for the '$/cancelRequest' method.
  static const cancelRequest = const Method(r'$/cancelRequest');

  /// Constant for the 'initialize' method.
  static const initialize = const Method(r'initialize');

  /// Constant for the 'initialized' method.
  static const initialized = const Method(r'initialized');

  /// Constant for the 'shutdown' method.
  static const shutdown = const Method(r'shutdown');

  /// Constant for the 'exit' method.
  static const exit = const Method(r'exit');

  /// Constant for the 'window/showMessage' method.
  static const window_showMessage = const Method(r'window/showMessage');

  /// Constant for the 'window/showMessageRequest' method.
  static const window_showMessageRequest =
      const Method(r'window/showMessageRequest');

  /// Constant for the 'window/logMessage' method.
  static const window_logMessage = const Method(r'window/logMessage');

  /// Constant for the 'telemetry/event' method.
  static const telemetry_event = const Method(r'telemetry/event');

  /// Constant for the 'client/registerCapability' method.
  static const client_registerCapability =
      const Method(r'client/registerCapability');

  /// Constant for the 'client/unregisterCapability' method.
  static const client_unregisterCapability =
      const Method(r'client/unregisterCapability');

  /// Constant for the 'workspace/workspaceFolders' method.
  static const workspace_workspaceFolders =
      const Method(r'workspace/workspaceFolders');

  /// Constant for the 'workspace/didChangeWorkspaceFolders' method.
  static const workspace_didChangeWorkspaceFolders =
      const Method(r'workspace/didChangeWorkspaceFolders');

  /// Constant for the 'workspace/configuration' method.
  static const workspace_configuration =
      const Method(r'workspace/configuration');

  /// Constant for the 'workspace/didChangeWatchedFiles' method.
  static const workspace_didChangeWatchedFiles =
      const Method(r'workspace/didChangeWatchedFiles');

  /// Constant for the 'workspace/symbol' method.
  static const workspace_symbol = const Method(r'workspace/symbol');

  /// Constant for the 'workspace/executeCommand' method.
  static const workspace_executeCommand =
      const Method(r'workspace/executeCommand');

  /// Constant for the 'workspace/applyEdit' method.
  static const workspace_applyEdit = const Method(r'workspace/applyEdit');

  /// Constant for the 'textDocument/didOpen' method.
  static const textDocument_didOpen = const Method(r'textDocument/didOpen');

  /// Constant for the 'textDocument/didChange' method.
  static const textDocument_didChange = const Method(r'textDocument/didChange');

  /// Constant for the 'textDocument/willSave' method.
  static const textDocument_willSave = const Method(r'textDocument/willSave');

  /// Constant for the 'textDocument/willSaveWaitUntil' method.
  static const textDocument_willSaveWaitUntil =
      const Method(r'textDocument/willSaveWaitUntil');

  /// Constant for the 'textDocument/didClose' method.
  static const textDocument_didClose = const Method(r'textDocument/didClose');

  /// Constant for the 'textDocument/publishDiagnostics' method.
  static const textDocument_publishDiagnostics =
      const Method(r'textDocument/publishDiagnostics');

  /// Constant for the 'textDocument/completion' method.
  static const textDocument_completion =
      const Method(r'textDocument/completion');

  /// Constant for the 'completionItem/resolve' method.
  static const completionItem_resolve = const Method(r'completionItem/resolve');

  /// Constant for the 'textDocument/hover' method.
  static const textDocument_hover = const Method(r'textDocument/hover');

  /// Constant for the 'textDocument/signatureHelp' method.
  static const textDocument_signatureHelp =
      const Method(r'textDocument/signatureHelp');

  /// Constant for the 'textDocument/declaration' method.
  static const textDocument_declaration =
      const Method(r'textDocument/declaration');

  /// Constant for the 'textDocument/definition' method.
  static const textDocument_definition =
      const Method(r'textDocument/definition');

  /// Constant for the 'textDocument/typeDefinition' method.
  static const textDocument_typeDefinition =
      const Method(r'textDocument/typeDefinition');

  /// Constant for the 'textDocument/implementation' method.
  static const textDocument_implementation =
      const Method(r'textDocument/implementation');

  /// Constant for the 'textDocument/references' method.
  static const textDocument_references =
      const Method(r'textDocument/references');

  /// Constant for the 'textDocument/documentHighlight' method.
  static const textDocument_documentHighlight =
      const Method(r'textDocument/documentHighlight');

  /// Constant for the 'textDocument/documentSymbol' method.
  static const textDocument_documentSymbol =
      const Method(r'textDocument/documentSymbol');

  /// Constant for the 'textDocument/codeAction' method.
  static const textDocument_codeAction =
      const Method(r'textDocument/codeAction');

  /// Constant for the 'textDocument/codeLens' method.
  static const textDocument_codeLens = const Method(r'textDocument/codeLens');

  /// Constant for the 'codeLens/resolve' method.
  static const codeLens_resolve = const Method(r'codeLens/resolve');

  /// Constant for the 'textDocument/documentLink' method.
  static const textDocument_documentLink =
      const Method(r'textDocument/documentLink');

  /// Constant for the 'documentLink/resolve' method.
  static const documentLink_resolve = const Method(r'documentLink/resolve');

  /// Constant for the 'textDocument/documentColor' method.
  static const textDocument_documentColor =
      const Method(r'textDocument/documentColor');

  /// Constant for the 'textDocument/colorPresentation' method.
  static const textDocument_colorPresentation =
      const Method(r'textDocument/colorPresentation');

  /// Constant for the 'textDocument/formatting' method.
  static const textDocument_formatting =
      const Method(r'textDocument/formatting');

  /// Constant for the 'textDocument/onTypeFormatting' method.
  static const textDocument_onTypeFormatting =
      const Method(r'textDocument/onTypeFormatting');

  /// Constant for the 'textDocument/rename' method.
  static const textDocument_rename = const Method(r'textDocument/rename');

  /// Constant for the 'textDocument/prepareRename' method.
  static const textDocument_prepareRename =
      const Method(r'textDocument/prepareRename');

  /// Constant for the 'textDocument/foldingRange' method.
  static const textDocument_foldingRange =
      const Method(r'textDocument/foldingRange');

  Object toJson() => _value;

  @override
  String toString() => _value.toString();

  @override
  get hashCode => _value.hashCode;

  bool operator ==(o) => o is Method && o._value == _value;
}

class NotificationMessage implements Message, IncomingMessage, ToJsonable {
  NotificationMessage(this.method, this.params, this.jsonrpc) {
    if (method == null) {
      throw 'method is required but was not provided';
    }
    if (jsonrpc == null) {
      throw 'jsonrpc is required but was not provided';
    }
  }
  static NotificationMessage fromJson(Map<String, dynamic> json) {
    final method =
        json['method'] != null ? Method.fromJson(json['method']) : null;
    final params = json['params'];
    final jsonrpc = json['jsonrpc'];
    return new NotificationMessage(method, params, jsonrpc);
  }

  final String jsonrpc;

  /// The method to be invoked.
  final Method method;

  /// The notification's params.
  final dynamic params;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['method'] = method ?? (throw 'method is required but was not set');
    if (params != null) {
      __result['params'] = params;
    }
    __result['jsonrpc'] =
        jsonrpc ?? (throw 'jsonrpc is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('method') &&
        Method.canParse(obj['method']) &&
        obj.containsKey('jsonrpc') &&
        obj['jsonrpc'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is NotificationMessage) {
      return method == other.method &&
          params == other.params &&
          jsonrpc == other.jsonrpc &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, method.hashCode);
    hash = JenkinsSmiHash.combine(hash, params.hashCode);
    hash = JenkinsSmiHash.combine(hash, jsonrpc.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Represents a parameter of a callable-signature. A parameter can have a label
/// and a doc-comment.
class ParameterInformation implements ToJsonable {
  ParameterInformation(this.label, this.documentation) {
    if (label == null) {
      throw 'label is required but was not provided';
    }
  }
  static ParameterInformation fromJson(Map<String, dynamic> json) {
    final label = json['label'];
    final documentation = json['documentation'] is String
        ? new Either2<String, MarkupContent>.t1(json['documentation'])
        : (MarkupContent.canParse(json['documentation'])
            ? new Either2<String, MarkupContent>.t2(
                json['documentation'] != null
                    ? MarkupContent.fromJson(json['documentation'])
                    : null)
            : (json['documentation'] == null
                ? null
                : (throw '''${json['documentation']} was not one of (String, MarkupContent)''')));
    return new ParameterInformation(label, documentation);
  }

  /// The human-readable doc-comment of this parameter. Will be shown in the UI
  /// but can be omitted.
  final Either2<String, MarkupContent> documentation;

  /// The label of this parameter information.
  ///
  /// Either a string or an inclusive start and exclusive end offsets within its
  /// containing signature label. (see SignatureInformation.label). The offsets
  /// are based on a UTF-16 string representation as `Position` and `Range`
  /// does.
  ///
  /// *Note*: a label of type string should be a substring of its containing
  /// signature label. Its intended use case is to highlight the parameter label
  /// part in the `SignatureInformation.label`.
  final String label;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['label'] = label ?? (throw 'label is required but was not set');
    if (documentation != null) {
      __result['documentation'] = documentation;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('label') &&
        obj['label'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is ParameterInformation) {
      return label == other.label &&
          documentation == other.documentation &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, label.hashCode);
    hash = JenkinsSmiHash.combine(hash, documentation.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class Position implements ToJsonable {
  Position(this.line, this.character) {
    if (line == null) {
      throw 'line is required but was not provided';
    }
    if (character == null) {
      throw 'character is required but was not provided';
    }
  }
  static Position fromJson(Map<String, dynamic> json) {
    final line = json['line'];
    final character = json['character'];
    return new Position(line, character);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('line') &&
        obj['line'] is num &&
        obj.containsKey('character') &&
        obj['character'] is num;
  }

  @override
  bool operator ==(other) {
    if (other is Position) {
      return line == other.line && character == other.character && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, line.hashCode);
    hash = JenkinsSmiHash.combine(hash, character.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class PublishDiagnosticsParams implements ToJsonable {
  PublishDiagnosticsParams(this.uri, this.diagnostics) {
    if (uri == null) {
      throw 'uri is required but was not provided';
    }
    if (diagnostics == null) {
      throw 'diagnostics is required but was not provided';
    }
  }
  static PublishDiagnosticsParams fromJson(Map<String, dynamic> json) {
    final uri = json['uri'];
    final diagnostics = json['diagnostics']
        ?.map((item) => item != null ? Diagnostic.fromJson(item) : null)
        ?.cast<Diagnostic>()
        ?.toList();
    return new PublishDiagnosticsParams(uri, diagnostics);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('uri') &&
        obj['uri'] is String &&
        obj.containsKey('diagnostics') &&
        (obj['diagnostics'] is List &&
            (obj['diagnostics'].every((item) => Diagnostic.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is PublishDiagnosticsParams) {
      return uri == other.uri &&
          listEqual(diagnostics, other.diagnostics,
              (Diagnostic a, Diagnostic b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, uri.hashCode);
    hash = JenkinsSmiHash.combine(hash, diagnostics.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class Range implements ToJsonable {
  Range(this.start, this.end) {
    if (start == null) {
      throw 'start is required but was not provided';
    }
    if (end == null) {
      throw 'end is required but was not provided';
    }
  }
  static Range fromJson(Map<String, dynamic> json) {
    final start =
        json['start'] != null ? Position.fromJson(json['start']) : null;
    final end = json['end'] != null ? Position.fromJson(json['end']) : null;
    return new Range(start, end);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('start') &&
        Position.canParse(obj['start']) &&
        obj.containsKey('end') &&
        Position.canParse(obj['end']);
  }

  @override
  bool operator ==(other) {
    if (other is Range) {
      return start == other.start && end == other.end && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, start.hashCode);
    hash = JenkinsSmiHash.combine(hash, end.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class RangeAndPlaceholder implements ToJsonable {
  RangeAndPlaceholder(this.range, this.placeholder) {
    if (range == null) {
      throw 'range is required but was not provided';
    }
    if (placeholder == null) {
      throw 'placeholder is required but was not provided';
    }
  }
  static RangeAndPlaceholder fromJson(Map<String, dynamic> json) {
    final range = json['range'] != null ? Range.fromJson(json['range']) : null;
    final placeholder = json['placeholder'];
    return new RangeAndPlaceholder(range, placeholder);
  }

  final String placeholder;
  final Range range;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['range'] = range ?? (throw 'range is required but was not set');
    __result['placeholder'] =
        placeholder ?? (throw 'placeholder is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('range') &&
        Range.canParse(obj['range']) &&
        obj.containsKey('placeholder') &&
        obj['placeholder'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is RangeAndPlaceholder) {
      return range == other.range && placeholder == other.placeholder && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, range.hashCode);
    hash = JenkinsSmiHash.combine(hash, placeholder.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ReferenceContext implements ToJsonable {
  ReferenceContext(this.includeDeclaration) {
    if (includeDeclaration == null) {
      throw 'includeDeclaration is required but was not provided';
    }
  }
  static ReferenceContext fromJson(Map<String, dynamic> json) {
    final includeDeclaration = json['includeDeclaration'];
    return new ReferenceContext(includeDeclaration);
  }

  /// Include the declaration of the current symbol.
  final bool includeDeclaration;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['includeDeclaration'] = includeDeclaration ??
        (throw 'includeDeclaration is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('includeDeclaration') &&
        obj['includeDeclaration'] is bool;
  }

  @override
  bool operator ==(other) {
    if (other is ReferenceContext) {
      return includeDeclaration == other.includeDeclaration && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, includeDeclaration.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ReferenceParams implements TextDocumentPositionParams, ToJsonable {
  ReferenceParams(this.context, this.textDocument, this.position) {
    if (context == null) {
      throw 'context is required but was not provided';
    }
    if (textDocument == null) {
      throw 'textDocument is required but was not provided';
    }
    if (position == null) {
      throw 'position is required but was not provided';
    }
  }
  static ReferenceParams fromJson(Map<String, dynamic> json) {
    final context = json['context'] != null
        ? ReferenceContext.fromJson(json['context'])
        : null;
    final textDocument = json['textDocument'] != null
        ? TextDocumentIdentifier.fromJson(json['textDocument'])
        : null;
    final position =
        json['position'] != null ? Position.fromJson(json['position']) : null;
    return new ReferenceParams(context, textDocument, position);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('context') &&
        ReferenceContext.canParse(obj['context']) &&
        obj.containsKey('textDocument') &&
        TextDocumentIdentifier.canParse(obj['textDocument']) &&
        obj.containsKey('position') &&
        Position.canParse(obj['position']);
  }

  @override
  bool operator ==(other) {
    if (other is ReferenceParams) {
      return context == other.context &&
          textDocument == other.textDocument &&
          position == other.position &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, context.hashCode);
    hash = JenkinsSmiHash.combine(hash, textDocument.hashCode);
    hash = JenkinsSmiHash.combine(hash, position.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// General parameters to register for a capability.
class Registration implements ToJsonable {
  Registration(this.id, this.method, this.registerOptions) {
    if (id == null) {
      throw 'id is required but was not provided';
    }
    if (method == null) {
      throw 'method is required but was not provided';
    }
  }
  static Registration fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final method = json['method'];
    final registerOptions = json['registerOptions'];
    return new Registration(id, method, registerOptions);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('id') &&
        obj['id'] is String &&
        obj.containsKey('method') &&
        obj['method'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is Registration) {
      return id == other.id &&
          method == other.method &&
          registerOptions == other.registerOptions &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    hash = JenkinsSmiHash.combine(hash, method.hashCode);
    hash = JenkinsSmiHash.combine(hash, registerOptions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class RegistrationParams implements ToJsonable {
  RegistrationParams(this.registrations) {
    if (registrations == null) {
      throw 'registrations is required but was not provided';
    }
  }
  static RegistrationParams fromJson(Map<String, dynamic> json) {
    final registrations = json['registrations']
        ?.map((item) => item != null ? Registration.fromJson(item) : null)
        ?.cast<Registration>()
        ?.toList();
    return new RegistrationParams(registrations);
  }

  final List<Registration> registrations;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['registrations'] =
        registrations ?? (throw 'registrations is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('registrations') &&
        (obj['registrations'] is List &&
            (obj['registrations']
                .every((item) => Registration.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is RegistrationParams) {
      return listEqual(registrations, other.registrations,
              (Registration a, Registration b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, registrations.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Rename file operation
class RenameFile implements ToJsonable {
  RenameFile(this.kind, this.oldUri, this.newUri, this.options) {
    if (kind == null) {
      throw 'kind is required but was not provided';
    }
    if (oldUri == null) {
      throw 'oldUri is required but was not provided';
    }
    if (newUri == null) {
      throw 'newUri is required but was not provided';
    }
  }
  static RenameFile fromJson(Map<String, dynamic> json) {
    final kind = json['kind'];
    final oldUri = json['oldUri'];
    final newUri = json['newUri'];
    final options = json['options'] != null
        ? RenameFileOptions.fromJson(json['options'])
        : null;
    return new RenameFile(kind, oldUri, newUri, options);
  }

  /// A rename
  final String kind;

  /// The new location.
  final String newUri;

  /// The old (existing) location.
  final String oldUri;

  /// Rename options.
  final RenameFileOptions options;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['kind'] = kind ?? (throw 'kind is required but was not set');
    __result['oldUri'] = oldUri ?? (throw 'oldUri is required but was not set');
    __result['newUri'] = newUri ?? (throw 'newUri is required but was not set');
    if (options != null) {
      __result['options'] = options;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('kind') &&
        obj['kind'] is String &&
        obj.containsKey('oldUri') &&
        obj['oldUri'] is String &&
        obj.containsKey('newUri') &&
        obj['newUri'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is RenameFile) {
      return kind == other.kind &&
          oldUri == other.oldUri &&
          newUri == other.newUri &&
          options == other.options &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, oldUri.hashCode);
    hash = JenkinsSmiHash.combine(hash, newUri.hashCode);
    hash = JenkinsSmiHash.combine(hash, options.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Rename file options
class RenameFileOptions implements ToJsonable {
  RenameFileOptions(this.overwrite, this.ignoreIfExists);
  static RenameFileOptions fromJson(Map<String, dynamic> json) {
    final overwrite = json['overwrite'];
    final ignoreIfExists = json['ignoreIfExists'];
    return new RenameFileOptions(overwrite, ignoreIfExists);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is RenameFileOptions) {
      return overwrite == other.overwrite &&
          ignoreIfExists == other.ignoreIfExists &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, overwrite.hashCode);
    hash = JenkinsSmiHash.combine(hash, ignoreIfExists.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Rename options
class RenameOptions implements ToJsonable {
  RenameOptions(this.prepareProvider);
  static RenameOptions fromJson(Map<String, dynamic> json) {
    final prepareProvider = json['prepareProvider'];
    return new RenameOptions(prepareProvider);
  }

  /// Renames should be checked and tested before being executed.
  final bool prepareProvider;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (prepareProvider != null) {
      __result['prepareProvider'] = prepareProvider;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is RenameOptions) {
      return prepareProvider == other.prepareProvider && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, prepareProvider.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class RenameParams implements ToJsonable {
  RenameParams(this.textDocument, this.position, this.newName) {
    if (textDocument == null) {
      throw 'textDocument is required but was not provided';
    }
    if (position == null) {
      throw 'position is required but was not provided';
    }
    if (newName == null) {
      throw 'newName is required but was not provided';
    }
  }
  static RenameParams fromJson(Map<String, dynamic> json) {
    final textDocument = json['textDocument'] != null
        ? TextDocumentIdentifier.fromJson(json['textDocument'])
        : null;
    final position =
        json['position'] != null ? Position.fromJson(json['position']) : null;
    final newName = json['newName'];
    return new RenameParams(textDocument, position, newName);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('textDocument') &&
        TextDocumentIdentifier.canParse(obj['textDocument']) &&
        obj.containsKey('position') &&
        Position.canParse(obj['position']) &&
        obj.containsKey('newName') &&
        obj['newName'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is RenameParams) {
      return textDocument == other.textDocument &&
          position == other.position &&
          newName == other.newName &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, textDocument.hashCode);
    hash = JenkinsSmiHash.combine(hash, position.hashCode);
    hash = JenkinsSmiHash.combine(hash, newName.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class RenameRegistrationOptions
    implements TextDocumentRegistrationOptions, ToJsonable {
  RenameRegistrationOptions(this.prepareProvider, this.documentSelector);
  static RenameRegistrationOptions fromJson(Map<String, dynamic> json) {
    final prepareProvider = json['prepareProvider'];
    final documentSelector = json['documentSelector']
        ?.map((item) => item != null ? DocumentFilter.fromJson(item) : null)
        ?.cast<DocumentFilter>()
        ?.toList();
    return new RenameRegistrationOptions(prepareProvider, documentSelector);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('documentSelector') &&
        (obj['documentSelector'] is List &&
            (obj['documentSelector']
                .every((item) => DocumentFilter.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is RenameRegistrationOptions) {
      return prepareProvider == other.prepareProvider &&
          documentSelector == other.documentSelector &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, prepareProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, documentSelector.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class RequestMessage implements Message, IncomingMessage, ToJsonable {
  RequestMessage(this.id, this.method, this.params, this.jsonrpc) {
    if (id == null) {
      throw 'id is required but was not provided';
    }
    if (method == null) {
      throw 'method is required but was not provided';
    }
    if (jsonrpc == null) {
      throw 'jsonrpc is required but was not provided';
    }
  }
  static RequestMessage fromJson(Map<String, dynamic> json) {
    final id = json['id'] is num
        ? new Either2<num, String>.t1(json['id'])
        : (json['id'] is String
            ? new Either2<num, String>.t2(json['id'])
            : (throw '''${json['id']} was not one of (num, String)'''));
    final method =
        json['method'] != null ? Method.fromJson(json['method']) : null;
    final params = json['params'];
    final jsonrpc = json['jsonrpc'];
    return new RequestMessage(id, method, params, jsonrpc);
  }

  /// The request id.
  final Either2<num, String> id;
  final String jsonrpc;

  /// The method to be invoked.
  final Method method;

  /// The method's params.
  final dynamic params;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['id'] = id ?? (throw 'id is required but was not set');
    __result['method'] = method ?? (throw 'method is required but was not set');
    if (params != null) {
      __result['params'] = params;
    }
    __result['jsonrpc'] =
        jsonrpc ?? (throw 'jsonrpc is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('id') &&
        (obj['id'] is num || obj['id'] is String) &&
        obj.containsKey('method') &&
        Method.canParse(obj['method']) &&
        obj.containsKey('jsonrpc') &&
        obj['jsonrpc'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is RequestMessage) {
      return id == other.id &&
          method == other.method &&
          params == other.params &&
          jsonrpc == other.jsonrpc &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    hash = JenkinsSmiHash.combine(hash, method.hashCode);
    hash = JenkinsSmiHash.combine(hash, params.hashCode);
    hash = JenkinsSmiHash.combine(hash, jsonrpc.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ResourceOperationKind {
  const ResourceOperationKind._(this._value);
  const ResourceOperationKind.fromJson(this._value);

  final String _value;

  static bool canParse(Object obj) {
    switch (obj) {
      case 'create':
      case 'rename':
      case 'delete':
        return true;
    }
    return false;
  }

  /// Supports creating new files and folders.
  static const Create = const ResourceOperationKind._('create');

  /// Supports renaming existing files and folders.
  static const Rename = const ResourceOperationKind._('rename');

  /// Supports deleting existing files and folders.
  static const Delete = const ResourceOperationKind._('delete');

  Object toJson() => _value;

  @override
  String toString() => _value.toString();

  @override
  get hashCode => _value.hashCode;

  bool operator ==(o) => o is ResourceOperationKind && o._value == _value;
}

class ResponseError<D> implements ToJsonable {
  ResponseError(this.code, this.message, this.data) {
    if (code == null) {
      throw 'code is required but was not provided';
    }
    if (message == null) {
      throw 'message is required but was not provided';
    }
  }
  static ResponseError<D> fromJson<D>(Map<String, dynamic> json) {
    final code =
        json['code'] != null ? ErrorCodes.fromJson(json['code']) : null;
    final message = json['message'];
    final data = json['data'];
    return new ResponseError<D>(code, message, data);
  }

  /// A number indicating the error type that occurred.
  final ErrorCodes code;

  /// A string that contains additional information about the error. Can be
  /// omitted.
  final String data;

  /// A string providing a short description of the error.
  final String message;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['code'] = code ?? (throw 'code is required but was not set');
    __result['message'] =
        message ?? (throw 'message is required but was not set');
    if (data != null) {
      __result['data'] = data;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('code') &&
        ErrorCodes.canParse(obj['code']) &&
        obj.containsKey('message') &&
        obj['message'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is ResponseError) {
      return code == other.code &&
          message == other.message &&
          data == other.data &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, code.hashCode);
    hash = JenkinsSmiHash.combine(hash, message.hashCode);
    hash = JenkinsSmiHash.combine(hash, data.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ResponseMessage implements Message, ToJsonable {
  ResponseMessage(this.id, this.result, this.error, this.jsonrpc) {
    if (jsonrpc == null) {
      throw 'jsonrpc is required but was not provided';
    }
  }
  static ResponseMessage fromJson(Map<String, dynamic> json) {
    final id = json['id'] is num
        ? new Either2<num, String>.t1(json['id'])
        : (json['id'] is String
            ? new Either2<num, String>.t2(json['id'])
            : (json['id'] == null
                ? null
                : (throw '''${json['id']} was not one of (num, String)''')));
    final result = json['result'];
    final error = json['error'] != null
        ? ResponseError.fromJson<dynamic>(json['error'])
        : null;
    final jsonrpc = json['jsonrpc'];
    return new ResponseMessage(id, result, error, jsonrpc);
  }

  /// The error object in case a request fails.
  final ResponseError<dynamic> error;

  /// The request id.
  final Either2<num, String> id;
  final String jsonrpc;

  /// The result of a request. This can be omitted in the case of an error.
  final dynamic result;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['id'] = id;
    __result['jsonrpc'] =
        jsonrpc ?? (throw 'jsonrpc is required but was not set');
    if (error != null && result != null) {
      throw 'result and error cannot both be set';
    } else if (error != null) {
      __result['error'] = error;
    } else {
      __result['result'] = result;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('id') &&
        (obj['id'] is num || obj['id'] is String) &&
        obj.containsKey('jsonrpc') &&
        obj['jsonrpc'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is ResponseMessage) {
      return id == other.id &&
          result == other.result &&
          error == other.error &&
          jsonrpc == other.jsonrpc &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    hash = JenkinsSmiHash.combine(hash, result.hashCode);
    hash = JenkinsSmiHash.combine(hash, error.hashCode);
    hash = JenkinsSmiHash.combine(hash, jsonrpc.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Save options.
class SaveOptions implements ToJsonable {
  SaveOptions(this.includeText);
  static SaveOptions fromJson(Map<String, dynamic> json) {
    final includeText = json['includeText'];
    return new SaveOptions(includeText);
  }

  /// The client is supposed to include the content on save.
  final bool includeText;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (includeText != null) {
      __result['includeText'] = includeText;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is SaveOptions) {
      return includeText == other.includeText && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, includeText.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ServerCapabilities implements ToJsonable {
  ServerCapabilities(
      this.textDocumentSync,
      this.hoverProvider,
      this.completionProvider,
      this.signatureHelpProvider,
      this.definitionProvider,
      this.typeDefinitionProvider,
      this.implementationProvider,
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
      this.colorProvider,
      this.foldingRangeProvider,
      this.executeCommandProvider,
      this.workspace,
      this.experimental);
  static ServerCapabilities fromJson(Map<String, dynamic> json) {
    final textDocumentSync = TextDocumentSyncOptions.canParse(
            json['textDocumentSync'])
        ? new Either2<TextDocumentSyncOptions, num>.t1(
            json['textDocumentSync'] != null
                ? TextDocumentSyncOptions.fromJson(json['textDocumentSync'])
                : null)
        : (json['textDocumentSync'] is num
            ? new Either2<TextDocumentSyncOptions, num>.t2(
                json['textDocumentSync'])
            : (json['textDocumentSync'] == null
                ? null
                : (throw '''${json['textDocumentSync']} was not one of (TextDocumentSyncOptions, num)''')));
    final hoverProvider = json['hoverProvider'];
    final completionProvider = json['completionProvider'] != null
        ? CompletionOptions.fromJson(json['completionProvider'])
        : null;
    final signatureHelpProvider = json['signatureHelpProvider'] != null
        ? SignatureHelpOptions.fromJson(json['signatureHelpProvider'])
        : null;
    final definitionProvider = json['definitionProvider'];
    final typeDefinitionProvider = json['typeDefinitionProvider'] is bool
        ? new Either2<bool, dynamic>.t1(json['typeDefinitionProvider'])
        : (new Either2<bool, dynamic>.t2(json['typeDefinitionProvider']));
    final implementationProvider = json['implementationProvider'] is bool
        ? new Either2<bool, dynamic>.t1(json['implementationProvider'])
        : (new Either2<bool, dynamic>.t2(json['implementationProvider']));
    final referencesProvider = json['referencesProvider'];
    final documentHighlightProvider = json['documentHighlightProvider'];
    final documentSymbolProvider = json['documentSymbolProvider'];
    final workspaceSymbolProvider = json['workspaceSymbolProvider'];
    final codeActionProvider = json['codeActionProvider'] is bool
        ? new Either2<bool, CodeActionOptions>.t1(json['codeActionProvider'])
        : (CodeActionOptions.canParse(json['codeActionProvider'])
            ? new Either2<bool, CodeActionOptions>.t2(
                json['codeActionProvider'] != null
                    ? CodeActionOptions.fromJson(json['codeActionProvider'])
                    : null)
            : (json['codeActionProvider'] == null
                ? null
                : (throw '''${json['codeActionProvider']} was not one of (bool, CodeActionOptions)''')));
    final codeLensProvider = json['codeLensProvider'] != null
        ? CodeLensOptions.fromJson(json['codeLensProvider'])
        : null;
    final documentFormattingProvider = json['documentFormattingProvider'];
    final documentRangeFormattingProvider =
        json['documentRangeFormattingProvider'];
    final documentOnTypeFormattingProvider =
        json['documentOnTypeFormattingProvider'] != null
            ? DocumentOnTypeFormattingOptions.fromJson(
                json['documentOnTypeFormattingProvider'])
            : null;
    final renameProvider = json['renameProvider'] is bool
        ? new Either2<bool, RenameOptions>.t1(json['renameProvider'])
        : (RenameOptions.canParse(json['renameProvider'])
            ? new Either2<bool, RenameOptions>.t2(json['renameProvider'] != null
                ? RenameOptions.fromJson(json['renameProvider'])
                : null)
            : (json['renameProvider'] == null
                ? null
                : (throw '''${json['renameProvider']} was not one of (bool, RenameOptions)''')));
    final documentLinkProvider = json['documentLinkProvider'] != null
        ? DocumentLinkOptions.fromJson(json['documentLinkProvider'])
        : null;
    final colorProvider = json['colorProvider'] is bool
        ? new Either3<bool, ColorProviderOptions, dynamic>.t1(
            json['colorProvider'])
        : (ColorProviderOptions.canParse(json['colorProvider'])
            ? new Either3<bool, ColorProviderOptions, dynamic>.t2(
                json['colorProvider'] != null
                    ? ColorProviderOptions.fromJson(json['colorProvider'])
                    : null)
            : (new Either3<bool, ColorProviderOptions, dynamic>.t3(
                json['colorProvider'])));
    final foldingRangeProvider = json['foldingRangeProvider'] is bool
        ? new Either3<bool, FoldingRangeProviderOptions, dynamic>.t1(
            json['foldingRangeProvider'])
        : (FoldingRangeProviderOptions.canParse(json['foldingRangeProvider'])
            ? new Either3<bool, FoldingRangeProviderOptions, dynamic>.t2(
                json['foldingRangeProvider'] != null
                    ? FoldingRangeProviderOptions.fromJson(
                        json['foldingRangeProvider'])
                    : null)
            : (new Either3<bool, FoldingRangeProviderOptions, dynamic>.t3(
                json['foldingRangeProvider'])));
    final executeCommandProvider = json['executeCommandProvider'] != null
        ? ExecuteCommandOptions.fromJson(json['executeCommandProvider'])
        : null;
    final workspace = json['workspace'] != null
        ? ServerCapabilitiesWorkspace.fromJson(json['workspace'])
        : null;
    final experimental = json['experimental'];
    return new ServerCapabilities(
        textDocumentSync,
        hoverProvider,
        completionProvider,
        signatureHelpProvider,
        definitionProvider,
        typeDefinitionProvider,
        implementationProvider,
        referencesProvider,
        documentHighlightProvider,
        documentSymbolProvider,
        workspaceSymbolProvider,
        codeActionProvider,
        codeLensProvider,
        documentFormattingProvider,
        documentRangeFormattingProvider,
        documentOnTypeFormattingProvider,
        renameProvider,
        documentLinkProvider,
        colorProvider,
        foldingRangeProvider,
        executeCommandProvider,
        workspace,
        experimental);
  }

  /// The server provides code actions. The `CodeActionOptions` return type is
  /// only valid if the client signals code action literal support via the
  /// property `textDocument.codeAction.codeActionLiteralSupport`.
  final Either2<bool, CodeActionOptions> codeActionProvider;

  /// The server provides code lens.
  final CodeLensOptions codeLensProvider;

  /// The server provides color provider support.
  ///
  /// Since 3.6.0
  final Either3<bool, ColorProviderOptions, dynamic> colorProvider;

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

  /// Experimental server capabilities.
  final dynamic experimental;

  /// The server provides folding provider support.
  ///
  /// Since 3.10.0
  final Either3<bool, FoldingRangeProviderOptions, dynamic>
      foldingRangeProvider;

  /// The server provides hover support.
  final bool hoverProvider;

  /// The server provides Goto Implementation support.
  ///
  /// Since 3.6.0
  final Either2<bool, dynamic> implementationProvider;

  /// The server provides find references support.
  final bool referencesProvider;

  /// The server provides rename support. RenameOptions may only be specified if
  /// the client states that it supports `prepareSupport` in its initial
  /// `initialize` request.
  final Either2<bool, RenameOptions> renameProvider;

  /// The server provides signature help support.
  final SignatureHelpOptions signatureHelpProvider;

  /// Defines how text documents are synced. Is either a detailed structure
  /// defining each notification or for backwards compatibility the
  /// TextDocumentSyncKind number. If omitted it defaults to
  /// `TextDocumentSyncKind.None`.
  final Either2<TextDocumentSyncOptions, num> textDocumentSync;

  /// The server provides Goto Type Definition support.
  ///
  /// Since 3.6.0
  final Either2<bool, dynamic> typeDefinitionProvider;

  /// Workspace specific server capabilities
  final ServerCapabilitiesWorkspace workspace;

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
    if (typeDefinitionProvider != null) {
      __result['typeDefinitionProvider'] = typeDefinitionProvider;
    }
    if (implementationProvider != null) {
      __result['implementationProvider'] = implementationProvider;
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
    if (colorProvider != null) {
      __result['colorProvider'] = colorProvider;
    }
    if (foldingRangeProvider != null) {
      __result['foldingRangeProvider'] = foldingRangeProvider;
    }
    if (executeCommandProvider != null) {
      __result['executeCommandProvider'] = executeCommandProvider;
    }
    if (workspace != null) {
      __result['workspace'] = workspace;
    }
    if (experimental != null) {
      __result['experimental'] = experimental;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is ServerCapabilities) {
      return textDocumentSync == other.textDocumentSync &&
          hoverProvider == other.hoverProvider &&
          completionProvider == other.completionProvider &&
          signatureHelpProvider == other.signatureHelpProvider &&
          definitionProvider == other.definitionProvider &&
          typeDefinitionProvider == other.typeDefinitionProvider &&
          implementationProvider == other.implementationProvider &&
          referencesProvider == other.referencesProvider &&
          documentHighlightProvider == other.documentHighlightProvider &&
          documentSymbolProvider == other.documentSymbolProvider &&
          workspaceSymbolProvider == other.workspaceSymbolProvider &&
          codeActionProvider == other.codeActionProvider &&
          codeLensProvider == other.codeLensProvider &&
          documentFormattingProvider == other.documentFormattingProvider &&
          documentRangeFormattingProvider ==
              other.documentRangeFormattingProvider &&
          documentOnTypeFormattingProvider ==
              other.documentOnTypeFormattingProvider &&
          renameProvider == other.renameProvider &&
          documentLinkProvider == other.documentLinkProvider &&
          colorProvider == other.colorProvider &&
          foldingRangeProvider == other.foldingRangeProvider &&
          executeCommandProvider == other.executeCommandProvider &&
          workspace == other.workspace &&
          experimental == other.experimental &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, textDocumentSync.hashCode);
    hash = JenkinsSmiHash.combine(hash, hoverProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, completionProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, signatureHelpProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, definitionProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, typeDefinitionProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, implementationProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, referencesProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, documentHighlightProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, documentSymbolProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, workspaceSymbolProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, codeActionProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, codeLensProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, documentFormattingProvider.hashCode);
    hash =
        JenkinsSmiHash.combine(hash, documentRangeFormattingProvider.hashCode);
    hash =
        JenkinsSmiHash.combine(hash, documentOnTypeFormattingProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, renameProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, documentLinkProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, colorProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, foldingRangeProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, executeCommandProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, workspace.hashCode);
    hash = JenkinsSmiHash.combine(hash, experimental.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ServerCapabilitiesWorkspace implements ToJsonable {
  ServerCapabilitiesWorkspace(this.workspaceFolders);
  static ServerCapabilitiesWorkspace fromJson(Map<String, dynamic> json) {
    final workspaceFolders = json['workspaceFolders'] != null
        ? ServerCapabilitiesWorkspaceFolders.fromJson(json['workspaceFolders'])
        : null;
    return new ServerCapabilitiesWorkspace(workspaceFolders);
  }

  /// The server supports workspace folder.
  ///
  /// Since 3.6.0
  final ServerCapabilitiesWorkspaceFolders workspaceFolders;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (workspaceFolders != null) {
      __result['workspaceFolders'] = workspaceFolders;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is ServerCapabilitiesWorkspace) {
      return workspaceFolders == other.workspaceFolders && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, workspaceFolders.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ServerCapabilitiesWorkspaceFolders implements ToJsonable {
  ServerCapabilitiesWorkspaceFolders(this.supported, this.changeNotifications);
  static ServerCapabilitiesWorkspaceFolders fromJson(
      Map<String, dynamic> json) {
    final supported = json['supported'];
    final changeNotifications = json['changeNotifications'];
    return new ServerCapabilitiesWorkspaceFolders(
        supported, changeNotifications);
  }

  /// Whether the server wants to receive workspace folder change notifications.
  ///
  /// If a strings is provided the string is treated as a ID under which the
  /// notification is registered on the client side. The ID can be used to
  /// unregister for these events using the `client/unregisterCapability`
  /// request.
  final bool changeNotifications;

  /// The server has support for workspace folders
  final bool supported;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (supported != null) {
      __result['supported'] = supported;
    }
    if (changeNotifications != null) {
      __result['changeNotifications'] = changeNotifications;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is ServerCapabilitiesWorkspaceFolders) {
      return supported == other.supported &&
          changeNotifications == other.changeNotifications &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, supported.hashCode);
    hash = JenkinsSmiHash.combine(hash, changeNotifications.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ShowMessageParams implements ToJsonable {
  ShowMessageParams(this.type, this.message) {
    if (type == null) {
      throw 'type is required but was not provided';
    }
    if (message == null) {
      throw 'message is required but was not provided';
    }
  }
  static ShowMessageParams fromJson(Map<String, dynamic> json) {
    final type =
        json['type'] != null ? MessageType.fromJson(json['type']) : null;
    final message = json['message'];
    return new ShowMessageParams(type, message);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('type') &&
        MessageType.canParse(obj['type']) &&
        obj.containsKey('message') &&
        obj['message'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is ShowMessageParams) {
      return type == other.type && message == other.message && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, type.hashCode);
    hash = JenkinsSmiHash.combine(hash, message.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class ShowMessageRequestParams implements ToJsonable {
  ShowMessageRequestParams(this.type, this.message, this.actions) {
    if (type == null) {
      throw 'type is required but was not provided';
    }
    if (message == null) {
      throw 'message is required but was not provided';
    }
  }
  static ShowMessageRequestParams fromJson(Map<String, dynamic> json) {
    final type =
        json['type'] != null ? MessageType.fromJson(json['type']) : null;
    final message = json['message'];
    final actions = json['actions']
        ?.map((item) => item != null ? MessageActionItem.fromJson(item) : null)
        ?.cast<MessageActionItem>()
        ?.toList();
    return new ShowMessageRequestParams(type, message, actions);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('type') &&
        MessageType.canParse(obj['type']) &&
        obj.containsKey('message') &&
        obj['message'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is ShowMessageRequestParams) {
      return type == other.type &&
          message == other.message &&
          listEqual(actions, other.actions,
              (MessageActionItem a, MessageActionItem b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, type.hashCode);
    hash = JenkinsSmiHash.combine(hash, message.hashCode);
    hash = JenkinsSmiHash.combine(hash, actions.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Signature help represents the signature of something callable. There can be
/// multiple signature but only one active and only one active parameter.
class SignatureHelp implements ToJsonable {
  SignatureHelp(this.signatures, this.activeSignature, this.activeParameter) {
    if (signatures == null) {
      throw 'signatures is required but was not provided';
    }
  }
  static SignatureHelp fromJson(Map<String, dynamic> json) {
    final signatures = json['signatures']
        ?.map(
            (item) => item != null ? SignatureInformation.fromJson(item) : null)
        ?.cast<SignatureInformation>()
        ?.toList();
    final activeSignature = json['activeSignature'];
    final activeParameter = json['activeParameter'];
    return new SignatureHelp(signatures, activeSignature, activeParameter);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('signatures') &&
        (obj['signatures'] is List &&
            (obj['signatures']
                .every((item) => SignatureInformation.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is SignatureHelp) {
      return listEqual(signatures, other.signatures,
              (SignatureInformation a, SignatureInformation b) => a == b) &&
          activeSignature == other.activeSignature &&
          activeParameter == other.activeParameter &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, signatures.hashCode);
    hash = JenkinsSmiHash.combine(hash, activeSignature.hashCode);
    hash = JenkinsSmiHash.combine(hash, activeParameter.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Signature help options.
class SignatureHelpOptions implements ToJsonable {
  SignatureHelpOptions(this.triggerCharacters);
  static SignatureHelpOptions fromJson(Map<String, dynamic> json) {
    final triggerCharacters = json['triggerCharacters']
        ?.map((item) => item)
        ?.cast<String>()
        ?.toList();
    return new SignatureHelpOptions(triggerCharacters);
  }

  /// The characters that trigger signature help automatically.
  final List<String> triggerCharacters;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (triggerCharacters != null) {
      __result['triggerCharacters'] = triggerCharacters;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is SignatureHelpOptions) {
      return listEqual(triggerCharacters, other.triggerCharacters,
              (String a, String b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, triggerCharacters.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class SignatureHelpRegistrationOptions
    implements TextDocumentRegistrationOptions, ToJsonable {
  SignatureHelpRegistrationOptions(
      this.triggerCharacters, this.documentSelector);
  static SignatureHelpRegistrationOptions fromJson(Map<String, dynamic> json) {
    final triggerCharacters = json['triggerCharacters']
        ?.map((item) => item)
        ?.cast<String>()
        ?.toList();
    final documentSelector = json['documentSelector']
        ?.map((item) => item != null ? DocumentFilter.fromJson(item) : null)
        ?.cast<DocumentFilter>()
        ?.toList();
    return new SignatureHelpRegistrationOptions(
        triggerCharacters, documentSelector);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('documentSelector') &&
        (obj['documentSelector'] is List &&
            (obj['documentSelector']
                .every((item) => DocumentFilter.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is SignatureHelpRegistrationOptions) {
      return listEqual(triggerCharacters, other.triggerCharacters,
              (String a, String b) => a == b) &&
          documentSelector == other.documentSelector &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, triggerCharacters.hashCode);
    hash = JenkinsSmiHash.combine(hash, documentSelector.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Represents the signature of something callable. A signature can have a
/// label, like a function-name, a doc-comment, and a set of parameters.
class SignatureInformation implements ToJsonable {
  SignatureInformation(this.label, this.documentation, this.parameters) {
    if (label == null) {
      throw 'label is required but was not provided';
    }
  }
  static SignatureInformation fromJson(Map<String, dynamic> json) {
    final label = json['label'];
    final documentation = json['documentation'] is String
        ? new Either2<String, MarkupContent>.t1(json['documentation'])
        : (MarkupContent.canParse(json['documentation'])
            ? new Either2<String, MarkupContent>.t2(
                json['documentation'] != null
                    ? MarkupContent.fromJson(json['documentation'])
                    : null)
            : (json['documentation'] == null
                ? null
                : (throw '''${json['documentation']} was not one of (String, MarkupContent)''')));
    final parameters = json['parameters']
        ?.map(
            (item) => item != null ? ParameterInformation.fromJson(item) : null)
        ?.cast<ParameterInformation>()
        ?.toList();
    return new SignatureInformation(label, documentation, parameters);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('label') &&
        obj['label'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is SignatureInformation) {
      return label == other.label &&
          documentation == other.documentation &&
          listEqual(parameters, other.parameters,
              (ParameterInformation a, ParameterInformation b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, label.hashCode);
    hash = JenkinsSmiHash.combine(hash, documentation.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameters.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Static registration options to be returned in the initialize request.
class StaticRegistrationOptions implements ToJsonable {
  StaticRegistrationOptions(this.id);
  static StaticRegistrationOptions fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return new StaticRegistrationOptions(id);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is StaticRegistrationOptions) {
      return id == other.id && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Represents information about programming constructs like variables, classes,
/// interfaces etc.
class SymbolInformation implements ToJsonable {
  SymbolInformation(this.name, this.kind, this.deprecated, this.location,
      this.containerName) {
    if (name == null) {
      throw 'name is required but was not provided';
    }
    if (kind == null) {
      throw 'kind is required but was not provided';
    }
    if (location == null) {
      throw 'location is required but was not provided';
    }
  }
  static SymbolInformation fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final kind =
        json['kind'] != null ? SymbolKind.fromJson(json['kind']) : null;
    final deprecated = json['deprecated'];
    final location =
        json['location'] != null ? Location.fromJson(json['location']) : null;
    final containerName = json['containerName'];
    return new SymbolInformation(
        name, kind, deprecated, location, containerName);
  }

  /// The name of the symbol containing this symbol. This information is for
  /// user interface purposes (e.g. to render a qualifier in the user interface
  /// if necessary). It can't be used to re-infer a hierarchy for the document
  /// symbols.
  final String containerName;

  /// Indicates if this symbol is deprecated.
  final bool deprecated;

  /// The kind of this symbol.
  final SymbolKind kind;

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('name') &&
        obj['name'] is String &&
        obj.containsKey('kind') &&
        SymbolKind.canParse(obj['kind']) &&
        obj.containsKey('location') &&
        Location.canParse(obj['location']);
  }

  @override
  bool operator ==(other) {
    if (other is SymbolInformation) {
      return name == other.name &&
          kind == other.kind &&
          deprecated == other.deprecated &&
          location == other.location &&
          containerName == other.containerName &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    hash = JenkinsSmiHash.combine(hash, kind.hashCode);
    hash = JenkinsSmiHash.combine(hash, deprecated.hashCode);
    hash = JenkinsSmiHash.combine(hash, location.hashCode);
    hash = JenkinsSmiHash.combine(hash, containerName.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// A symbol kind.
class SymbolKind {
  const SymbolKind._(this._value);
  const SymbolKind.fromJson(this._value);

  final num _value;

  static bool canParse(Object obj) {
    switch (obj) {
      case 1:
      case 2:
      case 3:
      case 4:
      case 5:
      case 6:
      case 7:
      case 8:
      case 9:
      case 10:
      case 11:
      case 12:
      case 13:
      case 14:
      case 15:
      case 16:
      case 17:
      case 18:
      case 19:
      case 20:
      case 21:
      case 22:
      case 23:
      case 24:
      case 25:
      case 26:
        return true;
    }
    return false;
  }

  static const File = const SymbolKind._(1);
  static const Module = const SymbolKind._(2);
  static const Namespace = const SymbolKind._(3);
  static const Package = const SymbolKind._(4);
  static const Class = const SymbolKind._(5);
  static const Method = const SymbolKind._(6);
  static const Property = const SymbolKind._(7);
  static const Field = const SymbolKind._(8);
  static const Constructor = const SymbolKind._(9);
  static const Enum = const SymbolKind._(10);
  static const Interface = const SymbolKind._(11);
  static const Function = const SymbolKind._(12);
  static const Variable = const SymbolKind._(13);
  static const Constant = const SymbolKind._(14);
  static const Str = const SymbolKind._(15);
  static const Number = const SymbolKind._(16);
  static const Boolean = const SymbolKind._(17);
  static const Array = const SymbolKind._(18);
  static const Obj = const SymbolKind._(19);
  static const Key = const SymbolKind._(20);
  static const Null = const SymbolKind._(21);
  static const EnumMember = const SymbolKind._(22);
  static const Struct = const SymbolKind._(23);
  static const Event = const SymbolKind._(24);
  static const Operator = const SymbolKind._(25);
  static const TypeParameter = const SymbolKind._(26);

  Object toJson() => _value;

  @override
  String toString() => _value.toString();

  @override
  get hashCode => _value.hashCode;

  bool operator ==(o) => o is SymbolKind && o._value == _value;
}

/// Describe options to be used when registering for text document change
/// events.
class TextDocumentChangeRegistrationOptions
    implements TextDocumentRegistrationOptions, ToJsonable {
  TextDocumentChangeRegistrationOptions(this.syncKind, this.documentSelector) {
    if (syncKind == null) {
      throw 'syncKind is required but was not provided';
    }
  }
  static TextDocumentChangeRegistrationOptions fromJson(
      Map<String, dynamic> json) {
    final syncKind = json['syncKind'];
    final documentSelector = json['documentSelector']
        ?.map((item) => item != null ? DocumentFilter.fromJson(item) : null)
        ?.cast<DocumentFilter>()
        ?.toList();
    return new TextDocumentChangeRegistrationOptions(
        syncKind, documentSelector);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('syncKind') &&
        obj['syncKind'] is num &&
        obj.containsKey('documentSelector') &&
        (obj['documentSelector'] is List &&
            (obj['documentSelector']
                .every((item) => DocumentFilter.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentChangeRegistrationOptions) {
      return syncKind == other.syncKind &&
          documentSelector == other.documentSelector &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, syncKind.hashCode);
    hash = JenkinsSmiHash.combine(hash, documentSelector.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Text document specific client capabilities.
class TextDocumentClientCapabilities implements ToJsonable {
  TextDocumentClientCapabilities(
      this.synchronization,
      this.completion,
      this.hover,
      this.signatureHelp,
      this.references,
      this.documentHighlight,
      this.documentSymbol,
      this.formatting,
      this.rangeFormatting,
      this.onTypeFormatting,
      this.declaration,
      this.definition,
      this.typeDefinition,
      this.implementation,
      this.codeAction,
      this.codeLens,
      this.documentLink,
      this.colorProvider,
      this.rename,
      this.publishDiagnostics,
      this.foldingRange);
  static TextDocumentClientCapabilities fromJson(Map<String, dynamic> json) {
    final synchronization = json['synchronization'] != null
        ? TextDocumentClientCapabilitiesSynchronization.fromJson(
            json['synchronization'])
        : null;
    final completion = json['completion'] != null
        ? TextDocumentClientCapabilitiesCompletion.fromJson(json['completion'])
        : null;
    final hover = json['hover'] != null
        ? TextDocumentClientCapabilitiesHover.fromJson(json['hover'])
        : null;
    final signatureHelp = json['signatureHelp'] != null
        ? TextDocumentClientCapabilitiesSignatureHelp.fromJson(
            json['signatureHelp'])
        : null;
    final references = json['references'] != null
        ? TextDocumentClientCapabilitiesReferences.fromJson(json['references'])
        : null;
    final documentHighlight = json['documentHighlight'] != null
        ? TextDocumentClientCapabilitiesDocumentHighlight.fromJson(
            json['documentHighlight'])
        : null;
    final documentSymbol = json['documentSymbol'] != null
        ? TextDocumentClientCapabilitiesDocumentSymbol.fromJson(
            json['documentSymbol'])
        : null;
    final formatting = json['formatting'] != null
        ? TextDocumentClientCapabilitiesFormatting.fromJson(json['formatting'])
        : null;
    final rangeFormatting = json['rangeFormatting'] != null
        ? TextDocumentClientCapabilitiesRangeFormatting.fromJson(
            json['rangeFormatting'])
        : null;
    final onTypeFormatting = json['onTypeFormatting'] != null
        ? TextDocumentClientCapabilitiesOnTypeFormatting.fromJson(
            json['onTypeFormatting'])
        : null;
    final declaration = json['declaration'] != null
        ? TextDocumentClientCapabilitiesDeclaration.fromJson(
            json['declaration'])
        : null;
    final definition = json['definition'] != null
        ? TextDocumentClientCapabilitiesDefinition.fromJson(json['definition'])
        : null;
    final typeDefinition = json['typeDefinition'] != null
        ? TextDocumentClientCapabilitiesTypeDefinition.fromJson(
            json['typeDefinition'])
        : null;
    final implementation = json['implementation'] != null
        ? TextDocumentClientCapabilitiesImplementation.fromJson(
            json['implementation'])
        : null;
    final codeAction = json['codeAction'] != null
        ? TextDocumentClientCapabilitiesCodeAction.fromJson(json['codeAction'])
        : null;
    final codeLens = json['codeLens'] != null
        ? TextDocumentClientCapabilitiesCodeLens.fromJson(json['codeLens'])
        : null;
    final documentLink = json['documentLink'] != null
        ? TextDocumentClientCapabilitiesDocumentLink.fromJson(
            json['documentLink'])
        : null;
    final colorProvider = json['colorProvider'] != null
        ? TextDocumentClientCapabilitiesColorProvider.fromJson(
            json['colorProvider'])
        : null;
    final rename = json['rename'] != null
        ? TextDocumentClientCapabilitiesRename.fromJson(json['rename'])
        : null;
    final publishDiagnostics = json['publishDiagnostics'] != null
        ? TextDocumentClientCapabilitiesPublishDiagnostics.fromJson(
            json['publishDiagnostics'])
        : null;
    final foldingRange = json['foldingRange'] != null
        ? TextDocumentClientCapabilitiesFoldingRange.fromJson(
            json['foldingRange'])
        : null;
    return new TextDocumentClientCapabilities(
        synchronization,
        completion,
        hover,
        signatureHelp,
        references,
        documentHighlight,
        documentSymbol,
        formatting,
        rangeFormatting,
        onTypeFormatting,
        declaration,
        definition,
        typeDefinition,
        implementation,
        codeAction,
        codeLens,
        documentLink,
        colorProvider,
        rename,
        publishDiagnostics,
        foldingRange);
  }

  /// Capabilities specific to the `textDocument/codeAction`
  final TextDocumentClientCapabilitiesCodeAction codeAction;

  /// Capabilities specific to the `textDocument/codeLens`
  final TextDocumentClientCapabilitiesCodeLens codeLens;

  /// Capabilities specific to the `textDocument/documentColor` and the
  /// `textDocument/colorPresentation` request.
  ///
  /// Since 3.6.0
  final TextDocumentClientCapabilitiesColorProvider colorProvider;

  /// Capabilities specific to the `textDocument/completion`
  final TextDocumentClientCapabilitiesCompletion completion;

  /// Capabilities specific to the `textDocument/declaration`
  final TextDocumentClientCapabilitiesDeclaration declaration;

  /// Capabilities specific to the `textDocument/definition`.
  ///
  /// Since 3.14.0
  final TextDocumentClientCapabilitiesDefinition definition;

  /// Capabilities specific to the `textDocument/documentHighlight`
  final TextDocumentClientCapabilitiesDocumentHighlight documentHighlight;

  /// Capabilities specific to the `textDocument/documentLink`
  final TextDocumentClientCapabilitiesDocumentLink documentLink;

  /// Capabilities specific to the `textDocument/documentSymbol`
  final TextDocumentClientCapabilitiesDocumentSymbol documentSymbol;

  /// Capabilities specific to `textDocument/foldingRange` requests.
  ///
  /// Since 3.10.0
  final TextDocumentClientCapabilitiesFoldingRange foldingRange;

  /// Capabilities specific to the `textDocument/formatting`
  final TextDocumentClientCapabilitiesFormatting formatting;

  /// Capabilities specific to the `textDocument/hover`
  final TextDocumentClientCapabilitiesHover hover;

  /// Capabilities specific to the `textDocument/implementation`.
  ///
  /// Since 3.6.0
  final TextDocumentClientCapabilitiesImplementation implementation;

  /// Capabilities specific to the `textDocument/onTypeFormatting`
  final TextDocumentClientCapabilitiesOnTypeFormatting onTypeFormatting;

  /// Capabilities specific to `textDocument/publishDiagnostics`.
  final TextDocumentClientCapabilitiesPublishDiagnostics publishDiagnostics;

  /// Capabilities specific to the `textDocument/rangeFormatting`
  final TextDocumentClientCapabilitiesRangeFormatting rangeFormatting;

  /// Capabilities specific to the `textDocument/references`
  final TextDocumentClientCapabilitiesReferences references;

  /// Capabilities specific to the `textDocument/rename`
  final TextDocumentClientCapabilitiesRename rename;

  /// Capabilities specific to the `textDocument/signatureHelp`
  final TextDocumentClientCapabilitiesSignatureHelp signatureHelp;
  final TextDocumentClientCapabilitiesSynchronization synchronization;

  /// Capabilities specific to the `textDocument/typeDefinition`
  ///
  /// Since 3.6.0
  final TextDocumentClientCapabilitiesTypeDefinition typeDefinition;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (synchronization != null) {
      __result['synchronization'] = synchronization;
    }
    if (completion != null) {
      __result['completion'] = completion;
    }
    if (hover != null) {
      __result['hover'] = hover;
    }
    if (signatureHelp != null) {
      __result['signatureHelp'] = signatureHelp;
    }
    if (references != null) {
      __result['references'] = references;
    }
    if (documentHighlight != null) {
      __result['documentHighlight'] = documentHighlight;
    }
    if (documentSymbol != null) {
      __result['documentSymbol'] = documentSymbol;
    }
    if (formatting != null) {
      __result['formatting'] = formatting;
    }
    if (rangeFormatting != null) {
      __result['rangeFormatting'] = rangeFormatting;
    }
    if (onTypeFormatting != null) {
      __result['onTypeFormatting'] = onTypeFormatting;
    }
    if (declaration != null) {
      __result['declaration'] = declaration;
    }
    if (definition != null) {
      __result['definition'] = definition;
    }
    if (typeDefinition != null) {
      __result['typeDefinition'] = typeDefinition;
    }
    if (implementation != null) {
      __result['implementation'] = implementation;
    }
    if (codeAction != null) {
      __result['codeAction'] = codeAction;
    }
    if (codeLens != null) {
      __result['codeLens'] = codeLens;
    }
    if (documentLink != null) {
      __result['documentLink'] = documentLink;
    }
    if (colorProvider != null) {
      __result['colorProvider'] = colorProvider;
    }
    if (rename != null) {
      __result['rename'] = rename;
    }
    if (publishDiagnostics != null) {
      __result['publishDiagnostics'] = publishDiagnostics;
    }
    if (foldingRange != null) {
      __result['foldingRange'] = foldingRange;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilities) {
      return synchronization == other.synchronization &&
          completion == other.completion &&
          hover == other.hover &&
          signatureHelp == other.signatureHelp &&
          references == other.references &&
          documentHighlight == other.documentHighlight &&
          documentSymbol == other.documentSymbol &&
          formatting == other.formatting &&
          rangeFormatting == other.rangeFormatting &&
          onTypeFormatting == other.onTypeFormatting &&
          declaration == other.declaration &&
          definition == other.definition &&
          typeDefinition == other.typeDefinition &&
          implementation == other.implementation &&
          codeAction == other.codeAction &&
          codeLens == other.codeLens &&
          documentLink == other.documentLink &&
          colorProvider == other.colorProvider &&
          rename == other.rename &&
          publishDiagnostics == other.publishDiagnostics &&
          foldingRange == other.foldingRange &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, synchronization.hashCode);
    hash = JenkinsSmiHash.combine(hash, completion.hashCode);
    hash = JenkinsSmiHash.combine(hash, hover.hashCode);
    hash = JenkinsSmiHash.combine(hash, signatureHelp.hashCode);
    hash = JenkinsSmiHash.combine(hash, references.hashCode);
    hash = JenkinsSmiHash.combine(hash, documentHighlight.hashCode);
    hash = JenkinsSmiHash.combine(hash, documentSymbol.hashCode);
    hash = JenkinsSmiHash.combine(hash, formatting.hashCode);
    hash = JenkinsSmiHash.combine(hash, rangeFormatting.hashCode);
    hash = JenkinsSmiHash.combine(hash, onTypeFormatting.hashCode);
    hash = JenkinsSmiHash.combine(hash, declaration.hashCode);
    hash = JenkinsSmiHash.combine(hash, definition.hashCode);
    hash = JenkinsSmiHash.combine(hash, typeDefinition.hashCode);
    hash = JenkinsSmiHash.combine(hash, implementation.hashCode);
    hash = JenkinsSmiHash.combine(hash, codeAction.hashCode);
    hash = JenkinsSmiHash.combine(hash, codeLens.hashCode);
    hash = JenkinsSmiHash.combine(hash, documentLink.hashCode);
    hash = JenkinsSmiHash.combine(hash, colorProvider.hashCode);
    hash = JenkinsSmiHash.combine(hash, rename.hashCode);
    hash = JenkinsSmiHash.combine(hash, publishDiagnostics.hashCode);
    hash = JenkinsSmiHash.combine(hash, foldingRange.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesCodeAction implements ToJsonable {
  TextDocumentClientCapabilitiesCodeAction(
      this.dynamicRegistration, this.codeActionLiteralSupport);
  static TextDocumentClientCapabilitiesCodeAction fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    final codeActionLiteralSupport = json['codeActionLiteralSupport'] != null
        ? TextDocumentClientCapabilitiesCodeActionLiteralSupport.fromJson(
            json['codeActionLiteralSupport'])
        : null;
    return new TextDocumentClientCapabilitiesCodeAction(
        dynamicRegistration, codeActionLiteralSupport);
  }

  /// The client support code action literals as a valid response of the
  /// `textDocument/codeAction` request.
  ///
  /// Since 3.8.0
  final TextDocumentClientCapabilitiesCodeActionLiteralSupport
      codeActionLiteralSupport;

  /// Whether code action supports dynamic registration.
  final bool dynamicRegistration;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    if (codeActionLiteralSupport != null) {
      __result['codeActionLiteralSupport'] = codeActionLiteralSupport;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesCodeAction) {
      return dynamicRegistration == other.dynamicRegistration &&
          codeActionLiteralSupport == other.codeActionLiteralSupport &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    hash = JenkinsSmiHash.combine(hash, codeActionLiteralSupport.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesCodeActionKind implements ToJsonable {
  TextDocumentClientCapabilitiesCodeActionKind(this.valueSet) {
    if (valueSet == null) {
      throw 'valueSet is required but was not provided';
    }
  }
  static TextDocumentClientCapabilitiesCodeActionKind fromJson(
      Map<String, dynamic> json) {
    final valueSet = json['valueSet']
        ?.map((item) => item != null ? CodeActionKind.fromJson(item) : null)
        ?.cast<CodeActionKind>()
        ?.toList();
    return new TextDocumentClientCapabilitiesCodeActionKind(valueSet);
  }

  /// The code action kind values the client supports. When this property exists
  /// the client also guarantees that it will handle values outside its set
  /// gracefully and falls back to a default value when unknown.
  final List<CodeActionKind> valueSet;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['valueSet'] =
        valueSet ?? (throw 'valueSet is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('valueSet') &&
        (obj['valueSet'] is List &&
            (obj['valueSet'].every((item) => item is String)));
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesCodeActionKind) {
      return listEqual(valueSet, other.valueSet,
              (CodeActionKind a, CodeActionKind b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, valueSet.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesCodeActionLiteralSupport
    implements ToJsonable {
  TextDocumentClientCapabilitiesCodeActionLiteralSupport(this.codeActionKind) {
    if (codeActionKind == null) {
      throw 'codeActionKind is required but was not provided';
    }
  }
  static TextDocumentClientCapabilitiesCodeActionLiteralSupport fromJson(
      Map<String, dynamic> json) {
    final codeActionKind = json['codeActionKind'] != null
        ? TextDocumentClientCapabilitiesCodeActionKind.fromJson(
            json['codeActionKind'])
        : null;
    return new TextDocumentClientCapabilitiesCodeActionLiteralSupport(
        codeActionKind);
  }

  /// The code action kind is support with the following value set.
  final TextDocumentClientCapabilitiesCodeActionKind codeActionKind;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['codeActionKind'] =
        codeActionKind ?? (throw 'codeActionKind is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('codeActionKind') &&
        TextDocumentClientCapabilitiesCodeActionKind.canParse(
            obj['codeActionKind']);
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesCodeActionLiteralSupport) {
      return codeActionKind == other.codeActionKind && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, codeActionKind.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesCodeLens implements ToJsonable {
  TextDocumentClientCapabilitiesCodeLens(this.dynamicRegistration);
  static TextDocumentClientCapabilitiesCodeLens fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    return new TextDocumentClientCapabilitiesCodeLens(dynamicRegistration);
  }

  /// Whether code lens supports dynamic registration.
  final bool dynamicRegistration;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesCodeLens) {
      return dynamicRegistration == other.dynamicRegistration && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesColorProvider implements ToJsonable {
  TextDocumentClientCapabilitiesColorProvider(this.dynamicRegistration);
  static TextDocumentClientCapabilitiesColorProvider fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    return new TextDocumentClientCapabilitiesColorProvider(dynamicRegistration);
  }

  /// Whether colorProvider supports dynamic registration. If this is set to
  /// `true` the client supports the new `(ColorProviderOptions &
  /// TextDocumentRegistrationOptions & StaticRegistrationOptions)` return value
  /// for the corresponding server capability as well.
  final bool dynamicRegistration;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesColorProvider) {
      return dynamicRegistration == other.dynamicRegistration && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesCompletion implements ToJsonable {
  TextDocumentClientCapabilitiesCompletion(this.dynamicRegistration,
      this.completionItem, this.completionItemKind, this.contextSupport);
  static TextDocumentClientCapabilitiesCompletion fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    final completionItem = json['completionItem'] != null
        ? TextDocumentClientCapabilitiesCompletionItem.fromJson(
            json['completionItem'])
        : null;
    final completionItemKind = json['completionItemKind'] != null
        ? TextDocumentClientCapabilitiesCompletionItemKind.fromJson(
            json['completionItemKind'])
        : null;
    final contextSupport = json['contextSupport'];
    return new TextDocumentClientCapabilitiesCompletion(dynamicRegistration,
        completionItem, completionItemKind, contextSupport);
  }

  /// The client supports the following `CompletionItem` specific capabilities.
  final TextDocumentClientCapabilitiesCompletionItem completionItem;
  final TextDocumentClientCapabilitiesCompletionItemKind completionItemKind;

  /// The client supports to send additional context information for a
  /// `textDocument/completion` request.
  final bool contextSupport;

  /// Whether completion supports dynamic registration.
  final bool dynamicRegistration;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    if (completionItem != null) {
      __result['completionItem'] = completionItem;
    }
    if (completionItemKind != null) {
      __result['completionItemKind'] = completionItemKind;
    }
    if (contextSupport != null) {
      __result['contextSupport'] = contextSupport;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesCompletion) {
      return dynamicRegistration == other.dynamicRegistration &&
          completionItem == other.completionItem &&
          completionItemKind == other.completionItemKind &&
          contextSupport == other.contextSupport &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    hash = JenkinsSmiHash.combine(hash, completionItem.hashCode);
    hash = JenkinsSmiHash.combine(hash, completionItemKind.hashCode);
    hash = JenkinsSmiHash.combine(hash, contextSupport.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesCompletionItem implements ToJsonable {
  TextDocumentClientCapabilitiesCompletionItem(
      this.snippetSupport,
      this.commitCharactersSupport,
      this.documentationFormat,
      this.deprecatedSupport,
      this.preselectSupport);
  static TextDocumentClientCapabilitiesCompletionItem fromJson(
      Map<String, dynamic> json) {
    final snippetSupport = json['snippetSupport'];
    final commitCharactersSupport = json['commitCharactersSupport'];
    final documentationFormat = json['documentationFormat']
        ?.map((item) => item != null ? MarkupKind.fromJson(item) : null)
        ?.cast<MarkupKind>()
        ?.toList();
    final deprecatedSupport = json['deprecatedSupport'];
    final preselectSupport = json['preselectSupport'];
    return new TextDocumentClientCapabilitiesCompletionItem(
        snippetSupport,
        commitCharactersSupport,
        documentationFormat,
        deprecatedSupport,
        preselectSupport);
  }

  /// The client supports commit characters on a completion item.
  final bool commitCharactersSupport;

  /// The client supports the deprecated property on a completion item.
  final bool deprecatedSupport;

  /// The client supports the following content formats for the documentation
  /// property. The order describes the preferred format of the client.
  final List<MarkupKind> documentationFormat;

  /// The client supports the preselect property on a completion item.
  final bool preselectSupport;

  /// The client supports snippets as insert text.
  ///
  /// A snippet can define tab stops and placeholders with `$1`, `$2` and
  /// `${3:foo}`. `$0` defines the final tab stop, it defaults to the end of the
  /// snippet. Placeholders with equal identifiers are linked, that is typing in
  /// one will update others too.
  final bool snippetSupport;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (snippetSupport != null) {
      __result['snippetSupport'] = snippetSupport;
    }
    if (commitCharactersSupport != null) {
      __result['commitCharactersSupport'] = commitCharactersSupport;
    }
    if (documentationFormat != null) {
      __result['documentationFormat'] = documentationFormat;
    }
    if (deprecatedSupport != null) {
      __result['deprecatedSupport'] = deprecatedSupport;
    }
    if (preselectSupport != null) {
      __result['preselectSupport'] = preselectSupport;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesCompletionItem) {
      return snippetSupport == other.snippetSupport &&
          commitCharactersSupport == other.commitCharactersSupport &&
          listEqual(documentationFormat, other.documentationFormat,
              (MarkupKind a, MarkupKind b) => a == b) &&
          deprecatedSupport == other.deprecatedSupport &&
          preselectSupport == other.preselectSupport &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, snippetSupport.hashCode);
    hash = JenkinsSmiHash.combine(hash, commitCharactersSupport.hashCode);
    hash = JenkinsSmiHash.combine(hash, documentationFormat.hashCode);
    hash = JenkinsSmiHash.combine(hash, deprecatedSupport.hashCode);
    hash = JenkinsSmiHash.combine(hash, preselectSupport.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesCompletionItemKind implements ToJsonable {
  TextDocumentClientCapabilitiesCompletionItemKind(this.valueSet);
  static TextDocumentClientCapabilitiesCompletionItemKind fromJson(
      Map<String, dynamic> json) {
    final valueSet = json['valueSet']
        ?.map((item) => item != null ? CompletionItemKind.fromJson(item) : null)
        ?.cast<CompletionItemKind>()
        ?.toList();
    return new TextDocumentClientCapabilitiesCompletionItemKind(valueSet);
  }

  /// The completion item kind values the client supports. When this property
  /// exists the client also guarantees that it will handle values outside its
  /// set gracefully and falls back to a default value when unknown.
  ///
  /// If this property is not present the client only supports the completion
  /// items kinds from `Text` to `Reference` as defined in the initial version
  /// of the protocol.
  final List<CompletionItemKind> valueSet;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (valueSet != null) {
      __result['valueSet'] = valueSet;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesCompletionItemKind) {
      return listEqual(valueSet, other.valueSet,
              (CompletionItemKind a, CompletionItemKind b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, valueSet.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesDeclaration implements ToJsonable {
  TextDocumentClientCapabilitiesDeclaration(
      this.dynamicRegistration, this.linkSupport);
  static TextDocumentClientCapabilitiesDeclaration fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    final linkSupport = json['linkSupport'];
    return new TextDocumentClientCapabilitiesDeclaration(
        dynamicRegistration, linkSupport);
  }

  /// Whether declaration supports dynamic registration. If this is set to
  /// `true` the client supports the new `(TextDocumentRegistrationOptions &
  /// StaticRegistrationOptions)` return value for the corresponding server
  /// capability as well.
  final bool dynamicRegistration;

  /// The client supports additional metadata in the form of declaration links.
  ///
  /// Since 3.14.0
  final bool linkSupport;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    if (linkSupport != null) {
      __result['linkSupport'] = linkSupport;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesDeclaration) {
      return dynamicRegistration == other.dynamicRegistration &&
          linkSupport == other.linkSupport &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    hash = JenkinsSmiHash.combine(hash, linkSupport.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesDefinition implements ToJsonable {
  TextDocumentClientCapabilitiesDefinition(
      this.dynamicRegistration, this.linkSupport);
  static TextDocumentClientCapabilitiesDefinition fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    final linkSupport = json['linkSupport'];
    return new TextDocumentClientCapabilitiesDefinition(
        dynamicRegistration, linkSupport);
  }

  /// Whether definition supports dynamic registration.
  final bool dynamicRegistration;

  /// The client supports additional metadata in the form of definition links.
  final bool linkSupport;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    if (linkSupport != null) {
      __result['linkSupport'] = linkSupport;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesDefinition) {
      return dynamicRegistration == other.dynamicRegistration &&
          linkSupport == other.linkSupport &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    hash = JenkinsSmiHash.combine(hash, linkSupport.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesDocumentHighlight implements ToJsonable {
  TextDocumentClientCapabilitiesDocumentHighlight(this.dynamicRegistration);
  static TextDocumentClientCapabilitiesDocumentHighlight fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    return new TextDocumentClientCapabilitiesDocumentHighlight(
        dynamicRegistration);
  }

  /// Whether document highlight supports dynamic registration.
  final bool dynamicRegistration;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesDocumentHighlight) {
      return dynamicRegistration == other.dynamicRegistration && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesDocumentLink implements ToJsonable {
  TextDocumentClientCapabilitiesDocumentLink(this.dynamicRegistration);
  static TextDocumentClientCapabilitiesDocumentLink fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    return new TextDocumentClientCapabilitiesDocumentLink(dynamicRegistration);
  }

  /// Whether document link supports dynamic registration.
  final bool dynamicRegistration;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesDocumentLink) {
      return dynamicRegistration == other.dynamicRegistration && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesDocumentSymbol implements ToJsonable {
  TextDocumentClientCapabilitiesDocumentSymbol(this.dynamicRegistration,
      this.symbolKind, this.hierarchicalDocumentSymbolSupport);
  static TextDocumentClientCapabilitiesDocumentSymbol fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    final symbolKind = json['symbolKind'] != null
        ? TextDocumentClientCapabilitiesSymbolKind.fromJson(json['symbolKind'])
        : null;
    final hierarchicalDocumentSymbolSupport =
        json['hierarchicalDocumentSymbolSupport'];
    return new TextDocumentClientCapabilitiesDocumentSymbol(
        dynamicRegistration, symbolKind, hierarchicalDocumentSymbolSupport);
  }

  /// Whether document symbol supports dynamic registration.
  final bool dynamicRegistration;

  /// The client supports hierarchical document symbols.
  final bool hierarchicalDocumentSymbolSupport;

  /// Specific capabilities for the `SymbolKind`.
  final TextDocumentClientCapabilitiesSymbolKind symbolKind;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    if (symbolKind != null) {
      __result['symbolKind'] = symbolKind;
    }
    if (hierarchicalDocumentSymbolSupport != null) {
      __result['hierarchicalDocumentSymbolSupport'] =
          hierarchicalDocumentSymbolSupport;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesDocumentSymbol) {
      return dynamicRegistration == other.dynamicRegistration &&
          symbolKind == other.symbolKind &&
          hierarchicalDocumentSymbolSupport ==
              other.hierarchicalDocumentSymbolSupport &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    hash = JenkinsSmiHash.combine(hash, symbolKind.hashCode);
    hash = JenkinsSmiHash.combine(
        hash, hierarchicalDocumentSymbolSupport.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesFoldingRange implements ToJsonable {
  TextDocumentClientCapabilitiesFoldingRange(
      this.dynamicRegistration, this.rangeLimit, this.lineFoldingOnly);
  static TextDocumentClientCapabilitiesFoldingRange fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    final rangeLimit = json['rangeLimit'];
    final lineFoldingOnly = json['lineFoldingOnly'];
    return new TextDocumentClientCapabilitiesFoldingRange(
        dynamicRegistration, rangeLimit, lineFoldingOnly);
  }

  /// Whether implementation supports dynamic registration for folding range
  /// providers. If this is set to `true` the client supports the new
  /// `(FoldingRangeProviderOptions & TextDocumentRegistrationOptions &
  /// StaticRegistrationOptions)` return value for the corresponding server
  /// capability as well.
  final bool dynamicRegistration;

  /// If set, the client signals that it only supports folding complete lines.
  /// If set, client will ignore specified `startCharacter` and `endCharacter`
  /// properties in a FoldingRange.
  final bool lineFoldingOnly;

  /// The maximum number of folding ranges that the client prefers to receive
  /// per document. The value serves as a hint, servers are free to follow the
  /// limit.
  final num rangeLimit;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    if (rangeLimit != null) {
      __result['rangeLimit'] = rangeLimit;
    }
    if (lineFoldingOnly != null) {
      __result['lineFoldingOnly'] = lineFoldingOnly;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesFoldingRange) {
      return dynamicRegistration == other.dynamicRegistration &&
          rangeLimit == other.rangeLimit &&
          lineFoldingOnly == other.lineFoldingOnly &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    hash = JenkinsSmiHash.combine(hash, rangeLimit.hashCode);
    hash = JenkinsSmiHash.combine(hash, lineFoldingOnly.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesFormatting implements ToJsonable {
  TextDocumentClientCapabilitiesFormatting(this.dynamicRegistration);
  static TextDocumentClientCapabilitiesFormatting fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    return new TextDocumentClientCapabilitiesFormatting(dynamicRegistration);
  }

  /// Whether formatting supports dynamic registration.
  final bool dynamicRegistration;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesFormatting) {
      return dynamicRegistration == other.dynamicRegistration && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesHover implements ToJsonable {
  TextDocumentClientCapabilitiesHover(
      this.dynamicRegistration, this.contentFormat);
  static TextDocumentClientCapabilitiesHover fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    final contentFormat = json['contentFormat']
        ?.map((item) => item != null ? MarkupKind.fromJson(item) : null)
        ?.cast<MarkupKind>()
        ?.toList();
    return new TextDocumentClientCapabilitiesHover(
        dynamicRegistration, contentFormat);
  }

  /// The client supports the follow content formats for the content property.
  /// The order describes the preferred format of the client.
  final List<MarkupKind> contentFormat;

  /// Whether hover supports dynamic registration.
  final bool dynamicRegistration;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    if (contentFormat != null) {
      __result['contentFormat'] = contentFormat;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesHover) {
      return dynamicRegistration == other.dynamicRegistration &&
          listEqual(contentFormat, other.contentFormat,
              (MarkupKind a, MarkupKind b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    hash = JenkinsSmiHash.combine(hash, contentFormat.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesImplementation implements ToJsonable {
  TextDocumentClientCapabilitiesImplementation(
      this.dynamicRegistration, this.linkSupport);
  static TextDocumentClientCapabilitiesImplementation fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    final linkSupport = json['linkSupport'];
    return new TextDocumentClientCapabilitiesImplementation(
        dynamicRegistration, linkSupport);
  }

  /// Whether implementation supports dynamic registration. If this is set to
  /// `true` the client supports the new `(TextDocumentRegistrationOptions &
  /// StaticRegistrationOptions)` return value for the corresponding server
  /// capability as well.
  final bool dynamicRegistration;

  /// The client supports additional metadata in the form of definition links.
  ///
  /// Since 3.14.0
  final bool linkSupport;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    if (linkSupport != null) {
      __result['linkSupport'] = linkSupport;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesImplementation) {
      return dynamicRegistration == other.dynamicRegistration &&
          linkSupport == other.linkSupport &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    hash = JenkinsSmiHash.combine(hash, linkSupport.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesOnTypeFormatting implements ToJsonable {
  TextDocumentClientCapabilitiesOnTypeFormatting(this.dynamicRegistration);
  static TextDocumentClientCapabilitiesOnTypeFormatting fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    return new TextDocumentClientCapabilitiesOnTypeFormatting(
        dynamicRegistration);
  }

  /// Whether on type formatting supports dynamic registration.
  final bool dynamicRegistration;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesOnTypeFormatting) {
      return dynamicRegistration == other.dynamicRegistration && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesParameterInformation implements ToJsonable {
  TextDocumentClientCapabilitiesParameterInformation(this.labelOffsetSupport);
  static TextDocumentClientCapabilitiesParameterInformation fromJson(
      Map<String, dynamic> json) {
    final labelOffsetSupport = json['labelOffsetSupport'];
    return new TextDocumentClientCapabilitiesParameterInformation(
        labelOffsetSupport);
  }

  /// The client supports processing label offsets instead of a simple label
  /// string.
  ///
  /// Since 3.14.0
  final bool labelOffsetSupport;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (labelOffsetSupport != null) {
      __result['labelOffsetSupport'] = labelOffsetSupport;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesParameterInformation) {
      return labelOffsetSupport == other.labelOffsetSupport && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, labelOffsetSupport.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesPublishDiagnostics implements ToJsonable {
  TextDocumentClientCapabilitiesPublishDiagnostics(this.relatedInformation);
  static TextDocumentClientCapabilitiesPublishDiagnostics fromJson(
      Map<String, dynamic> json) {
    final relatedInformation = json['relatedInformation'];
    return new TextDocumentClientCapabilitiesPublishDiagnostics(
        relatedInformation);
  }

  /// Whether the clients accepts diagnostics with related information.
  final bool relatedInformation;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (relatedInformation != null) {
      __result['relatedInformation'] = relatedInformation;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesPublishDiagnostics) {
      return relatedInformation == other.relatedInformation && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, relatedInformation.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesRangeFormatting implements ToJsonable {
  TextDocumentClientCapabilitiesRangeFormatting(this.dynamicRegistration);
  static TextDocumentClientCapabilitiesRangeFormatting fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    return new TextDocumentClientCapabilitiesRangeFormatting(
        dynamicRegistration);
  }

  /// Whether range formatting supports dynamic registration.
  final bool dynamicRegistration;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesRangeFormatting) {
      return dynamicRegistration == other.dynamicRegistration && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesReferences implements ToJsonable {
  TextDocumentClientCapabilitiesReferences(this.dynamicRegistration);
  static TextDocumentClientCapabilitiesReferences fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    return new TextDocumentClientCapabilitiesReferences(dynamicRegistration);
  }

  /// Whether references supports dynamic registration.
  final bool dynamicRegistration;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesReferences) {
      return dynamicRegistration == other.dynamicRegistration && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesRename implements ToJsonable {
  TextDocumentClientCapabilitiesRename(
      this.dynamicRegistration, this.prepareSupport);
  static TextDocumentClientCapabilitiesRename fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    final prepareSupport = json['prepareSupport'];
    return new TextDocumentClientCapabilitiesRename(
        dynamicRegistration, prepareSupport);
  }

  /// Whether rename supports dynamic registration.
  final bool dynamicRegistration;

  /// The client supports testing for validity of rename operations before
  /// execution.
  final bool prepareSupport;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    if (prepareSupport != null) {
      __result['prepareSupport'] = prepareSupport;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesRename) {
      return dynamicRegistration == other.dynamicRegistration &&
          prepareSupport == other.prepareSupport &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    hash = JenkinsSmiHash.combine(hash, prepareSupport.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesSignatureHelp implements ToJsonable {
  TextDocumentClientCapabilitiesSignatureHelp(
      this.dynamicRegistration, this.signatureInformation);
  static TextDocumentClientCapabilitiesSignatureHelp fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    final signatureInformation = json['signatureInformation'] != null
        ? TextDocumentClientCapabilitiesSignatureInformation.fromJson(
            json['signatureInformation'])
        : null;
    return new TextDocumentClientCapabilitiesSignatureHelp(
        dynamicRegistration, signatureInformation);
  }

  /// Whether signature help supports dynamic registration.
  final bool dynamicRegistration;

  /// The client supports the following `SignatureInformation` specific
  /// properties.
  final TextDocumentClientCapabilitiesSignatureInformation signatureInformation;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    if (signatureInformation != null) {
      __result['signatureInformation'] = signatureInformation;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesSignatureHelp) {
      return dynamicRegistration == other.dynamicRegistration &&
          signatureInformation == other.signatureInformation &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    hash = JenkinsSmiHash.combine(hash, signatureInformation.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesSignatureInformation implements ToJsonable {
  TextDocumentClientCapabilitiesSignatureInformation(
      this.documentationFormat, this.parameterInformation);
  static TextDocumentClientCapabilitiesSignatureInformation fromJson(
      Map<String, dynamic> json) {
    final documentationFormat = json['documentationFormat']
        ?.map((item) => item != null ? MarkupKind.fromJson(item) : null)
        ?.cast<MarkupKind>()
        ?.toList();
    final parameterInformation = json['parameterInformation'] != null
        ? TextDocumentClientCapabilitiesParameterInformation.fromJson(
            json['parameterInformation'])
        : null;
    return new TextDocumentClientCapabilitiesSignatureInformation(
        documentationFormat, parameterInformation);
  }

  /// The client supports the follow content formats for the documentation
  /// property. The order describes the preferred format of the client.
  final List<MarkupKind> documentationFormat;

  /// Client capabilities specific to parameter information.
  final TextDocumentClientCapabilitiesParameterInformation parameterInformation;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (documentationFormat != null) {
      __result['documentationFormat'] = documentationFormat;
    }
    if (parameterInformation != null) {
      __result['parameterInformation'] = parameterInformation;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesSignatureInformation) {
      return listEqual(documentationFormat, other.documentationFormat,
              (MarkupKind a, MarkupKind b) => a == b) &&
          parameterInformation == other.parameterInformation &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, documentationFormat.hashCode);
    hash = JenkinsSmiHash.combine(hash, parameterInformation.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesSymbolKind implements ToJsonable {
  TextDocumentClientCapabilitiesSymbolKind(this.valueSet);
  static TextDocumentClientCapabilitiesSymbolKind fromJson(
      Map<String, dynamic> json) {
    final valueSet = json['valueSet']
        ?.map((item) => item != null ? SymbolKind.fromJson(item) : null)
        ?.cast<SymbolKind>()
        ?.toList();
    return new TextDocumentClientCapabilitiesSymbolKind(valueSet);
  }

  /// The symbol kind values the client supports. When this property exists the
  /// client also guarantees that it will handle values outside its set
  /// gracefully and falls back to a default value when unknown.
  ///
  /// If this property is not present the client only supports the symbol kinds
  /// from `File` to `Array` as defined in the initial version of the protocol.
  final List<SymbolKind> valueSet;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (valueSet != null) {
      __result['valueSet'] = valueSet;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesSymbolKind) {
      return listEqual(valueSet, other.valueSet,
              (SymbolKind a, SymbolKind b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, valueSet.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesSynchronization implements ToJsonable {
  TextDocumentClientCapabilitiesSynchronization(this.dynamicRegistration,
      this.willSave, this.willSaveWaitUntil, this.didSave);
  static TextDocumentClientCapabilitiesSynchronization fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    final willSave = json['willSave'];
    final willSaveWaitUntil = json['willSaveWaitUntil'];
    final didSave = json['didSave'];
    return new TextDocumentClientCapabilitiesSynchronization(
        dynamicRegistration, willSave, willSaveWaitUntil, didSave);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesSynchronization) {
      return dynamicRegistration == other.dynamicRegistration &&
          willSave == other.willSave &&
          willSaveWaitUntil == other.willSaveWaitUntil &&
          didSave == other.didSave &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    hash = JenkinsSmiHash.combine(hash, willSave.hashCode);
    hash = JenkinsSmiHash.combine(hash, willSaveWaitUntil.hashCode);
    hash = JenkinsSmiHash.combine(hash, didSave.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentClientCapabilitiesTypeDefinition implements ToJsonable {
  TextDocumentClientCapabilitiesTypeDefinition(
      this.dynamicRegistration, this.linkSupport);
  static TextDocumentClientCapabilitiesTypeDefinition fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    final linkSupport = json['linkSupport'];
    return new TextDocumentClientCapabilitiesTypeDefinition(
        dynamicRegistration, linkSupport);
  }

  /// Whether typeDefinition supports dynamic registration. If this is set to
  /// `true` the client supports the new `(TextDocumentRegistrationOptions &
  /// StaticRegistrationOptions)` return value for the corresponding server
  /// capability as well.
  final bool dynamicRegistration;

  /// The client supports additional metadata in the form of definition links.
  ///
  /// Since 3.14.0
  final bool linkSupport;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    if (linkSupport != null) {
      __result['linkSupport'] = linkSupport;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentClientCapabilitiesTypeDefinition) {
      return dynamicRegistration == other.dynamicRegistration &&
          linkSupport == other.linkSupport &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    hash = JenkinsSmiHash.combine(hash, linkSupport.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// An event describing a change to a text document. If range and rangeLength
/// are omitted the new text is considered to be the full content of the
/// document.
class TextDocumentContentChangeEvent implements ToJsonable {
  TextDocumentContentChangeEvent(this.range, this.rangeLength, this.text) {
    if (text == null) {
      throw 'text is required but was not provided';
    }
  }
  static TextDocumentContentChangeEvent fromJson(Map<String, dynamic> json) {
    final range = json['range'] != null ? Range.fromJson(json['range']) : null;
    final rangeLength = json['rangeLength'];
    final text = json['text'];
    return new TextDocumentContentChangeEvent(range, rangeLength, text);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('text') &&
        obj['text'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentContentChangeEvent) {
      return range == other.range &&
          rangeLength == other.rangeLength &&
          text == other.text &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, range.hashCode);
    hash = JenkinsSmiHash.combine(hash, rangeLength.hashCode);
    hash = JenkinsSmiHash.combine(hash, text.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentEdit implements ToJsonable {
  TextDocumentEdit(this.textDocument, this.edits) {
    if (textDocument == null) {
      throw 'textDocument is required but was not provided';
    }
    if (edits == null) {
      throw 'edits is required but was not provided';
    }
  }
  static TextDocumentEdit fromJson(Map<String, dynamic> json) {
    final textDocument = json['textDocument'] != null
        ? VersionedTextDocumentIdentifier.fromJson(json['textDocument'])
        : null;
    final edits = json['edits']
        ?.map((item) => item != null ? TextEdit.fromJson(item) : null)
        ?.cast<TextEdit>()
        ?.toList();
    return new TextDocumentEdit(textDocument, edits);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('textDocument') &&
        VersionedTextDocumentIdentifier.canParse(obj['textDocument']) &&
        obj.containsKey('edits') &&
        (obj['edits'] is List &&
            (obj['edits'].every((item) => TextEdit.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentEdit) {
      return textDocument == other.textDocument &&
          listEqual(edits, other.edits, (TextEdit a, TextEdit b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, textDocument.hashCode);
    hash = JenkinsSmiHash.combine(hash, edits.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentIdentifier implements ToJsonable {
  TextDocumentIdentifier(this.uri) {
    if (uri == null) {
      throw 'uri is required but was not provided';
    }
  }
  static TextDocumentIdentifier fromJson(Map<String, dynamic> json) {
    if (VersionedTextDocumentIdentifier.canParse(json)) {
      return VersionedTextDocumentIdentifier.fromJson(json);
    }
    final uri = json['uri'];
    return new TextDocumentIdentifier(uri);
  }

  /// The text document's URI.
  final String uri;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['uri'] = uri ?? (throw 'uri is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('uri') &&
        obj['uri'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentIdentifier) {
      return uri == other.uri && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, uri.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentItem implements ToJsonable {
  TextDocumentItem(this.uri, this.languageId, this.version, this.text) {
    if (uri == null) {
      throw 'uri is required but was not provided';
    }
    if (languageId == null) {
      throw 'languageId is required but was not provided';
    }
    if (version == null) {
      throw 'version is required but was not provided';
    }
    if (text == null) {
      throw 'text is required but was not provided';
    }
  }
  static TextDocumentItem fromJson(Map<String, dynamic> json) {
    final uri = json['uri'];
    final languageId = json['languageId'];
    final version = json['version'];
    final text = json['text'];
    return new TextDocumentItem(uri, languageId, version, text);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('uri') &&
        obj['uri'] is String &&
        obj.containsKey('languageId') &&
        obj['languageId'] is String &&
        obj.containsKey('version') &&
        obj['version'] is num &&
        obj.containsKey('text') &&
        obj['text'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentItem) {
      return uri == other.uri &&
          languageId == other.languageId &&
          version == other.version &&
          text == other.text &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, uri.hashCode);
    hash = JenkinsSmiHash.combine(hash, languageId.hashCode);
    hash = JenkinsSmiHash.combine(hash, version.hashCode);
    hash = JenkinsSmiHash.combine(hash, text.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentPositionParams implements ToJsonable {
  TextDocumentPositionParams(this.textDocument, this.position) {
    if (textDocument == null) {
      throw 'textDocument is required but was not provided';
    }
    if (position == null) {
      throw 'position is required but was not provided';
    }
  }
  static TextDocumentPositionParams fromJson(Map<String, dynamic> json) {
    if (CompletionParams.canParse(json)) {
      return CompletionParams.fromJson(json);
    }
    if (ReferenceParams.canParse(json)) {
      return ReferenceParams.fromJson(json);
    }
    final textDocument = json['textDocument'] != null
        ? TextDocumentIdentifier.fromJson(json['textDocument'])
        : null;
    final position =
        json['position'] != null ? Position.fromJson(json['position']) : null;
    return new TextDocumentPositionParams(textDocument, position);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('textDocument') &&
        TextDocumentIdentifier.canParse(obj['textDocument']) &&
        obj.containsKey('position') &&
        Position.canParse(obj['position']);
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentPositionParams) {
      return textDocument == other.textDocument &&
          position == other.position &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, textDocument.hashCode);
    hash = JenkinsSmiHash.combine(hash, position.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextDocumentRegistrationOptions implements ToJsonable {
  TextDocumentRegistrationOptions(this.documentSelector);
  static TextDocumentRegistrationOptions fromJson(Map<String, dynamic> json) {
    if (TextDocumentChangeRegistrationOptions.canParse(json)) {
      return TextDocumentChangeRegistrationOptions.fromJson(json);
    }
    if (TextDocumentSaveRegistrationOptions.canParse(json)) {
      return TextDocumentSaveRegistrationOptions.fromJson(json);
    }
    if (CompletionRegistrationOptions.canParse(json)) {
      return CompletionRegistrationOptions.fromJson(json);
    }
    if (SignatureHelpRegistrationOptions.canParse(json)) {
      return SignatureHelpRegistrationOptions.fromJson(json);
    }
    if (CodeActionRegistrationOptions.canParse(json)) {
      return CodeActionRegistrationOptions.fromJson(json);
    }
    if (CodeLensRegistrationOptions.canParse(json)) {
      return CodeLensRegistrationOptions.fromJson(json);
    }
    if (DocumentLinkRegistrationOptions.canParse(json)) {
      return DocumentLinkRegistrationOptions.fromJson(json);
    }
    if (DocumentOnTypeFormattingRegistrationOptions.canParse(json)) {
      return DocumentOnTypeFormattingRegistrationOptions.fromJson(json);
    }
    if (RenameRegistrationOptions.canParse(json)) {
      return RenameRegistrationOptions.fromJson(json);
    }
    final documentSelector = json['documentSelector']
        ?.map((item) => item != null ? DocumentFilter.fromJson(item) : null)
        ?.cast<DocumentFilter>()
        ?.toList();
    return new TextDocumentRegistrationOptions(documentSelector);
  }

  /// A document selector to identify the scope of the registration. If set to
  /// null the document selector provided on the client side will be used.
  final List<DocumentFilter> documentSelector;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['documentSelector'] = documentSelector;
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('documentSelector') &&
        (obj['documentSelector'] is List &&
            (obj['documentSelector']
                .every((item) => DocumentFilter.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentRegistrationOptions) {
      return documentSelector == other.documentSelector && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, documentSelector.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Represents reasons why a text document is saved.
class TextDocumentSaveReason {
  const TextDocumentSaveReason._(this._value);
  const TextDocumentSaveReason.fromJson(this._value);

  final num _value;

  static bool canParse(Object obj) {
    switch (obj) {
      case 1:
      case 2:
      case 3:
        return true;
    }
    return false;
  }

  /// Manually triggered, e.g. by the user pressing save, by starting debugging,
  /// or by an API call.
  static const Manual = const TextDocumentSaveReason._(1);

  /// Automatic after a delay.
  static const AfterDelay = const TextDocumentSaveReason._(2);

  /// When the editor lost focus.
  static const FocusOut = const TextDocumentSaveReason._(3);

  Object toJson() => _value;

  @override
  String toString() => _value.toString();

  @override
  get hashCode => _value.hashCode;

  bool operator ==(o) => o is TextDocumentSaveReason && o._value == _value;
}

class TextDocumentSaveRegistrationOptions
    implements TextDocumentRegistrationOptions, ToJsonable {
  TextDocumentSaveRegistrationOptions(this.includeText, this.documentSelector);
  static TextDocumentSaveRegistrationOptions fromJson(
      Map<String, dynamic> json) {
    final includeText = json['includeText'];
    final documentSelector = json['documentSelector']
        ?.map((item) => item != null ? DocumentFilter.fromJson(item) : null)
        ?.cast<DocumentFilter>()
        ?.toList();
    return new TextDocumentSaveRegistrationOptions(
        includeText, documentSelector);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('documentSelector') &&
        (obj['documentSelector'] is List &&
            (obj['documentSelector']
                .every((item) => DocumentFilter.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentSaveRegistrationOptions) {
      return includeText == other.includeText &&
          documentSelector == other.documentSelector &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, includeText.hashCode);
    hash = JenkinsSmiHash.combine(hash, documentSelector.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Defines how the host (editor) should sync document changes to the language
/// server.
class TextDocumentSyncKind {
  const TextDocumentSyncKind._(this._value);
  const TextDocumentSyncKind.fromJson(this._value);

  final num _value;

  static bool canParse(Object obj) {
    switch (obj) {
      case 0:
      case 1:
      case 2:
        return true;
    }
    return false;
  }

  /// Documents should not be synced at all.
  static const None = const TextDocumentSyncKind._(0);

  /// Documents are synced by always sending the full content of the document.
  static const Full = const TextDocumentSyncKind._(1);

  /// Documents are synced by sending the full content on open. After that only
  /// incremental updates to the document are send.
  static const Incremental = const TextDocumentSyncKind._(2);

  Object toJson() => _value;

  @override
  String toString() => _value.toString();

  @override
  get hashCode => _value.hashCode;

  bool operator ==(o) => o is TextDocumentSyncKind && o._value == _value;
}

class TextDocumentSyncOptions implements ToJsonable {
  TextDocumentSyncOptions(this.openClose, this.change, this.willSave,
      this.willSaveWaitUntil, this.save);
  static TextDocumentSyncOptions fromJson(Map<String, dynamic> json) {
    final openClose = json['openClose'];
    final change = json['change'] != null
        ? TextDocumentSyncKind.fromJson(json['change'])
        : null;
    final willSave = json['willSave'];
    final willSaveWaitUntil = json['willSaveWaitUntil'];
    final save =
        json['save'] != null ? SaveOptions.fromJson(json['save']) : null;
    return new TextDocumentSyncOptions(
        openClose, change, willSave, willSaveWaitUntil, save);
  }

  /// Change notifications are sent to the server. See
  /// TextDocumentSyncKind.None, TextDocumentSyncKind.Full and
  /// TextDocumentSyncKind.Incremental. If omitted it defaults to
  /// TextDocumentSyncKind.None.
  final TextDocumentSyncKind change;

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is TextDocumentSyncOptions) {
      return openClose == other.openClose &&
          change == other.change &&
          willSave == other.willSave &&
          willSaveWaitUntil == other.willSaveWaitUntil &&
          save == other.save &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, openClose.hashCode);
    hash = JenkinsSmiHash.combine(hash, change.hashCode);
    hash = JenkinsSmiHash.combine(hash, willSave.hashCode);
    hash = JenkinsSmiHash.combine(hash, willSaveWaitUntil.hashCode);
    hash = JenkinsSmiHash.combine(hash, save.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class TextEdit implements ToJsonable {
  TextEdit(this.range, this.newText) {
    if (range == null) {
      throw 'range is required but was not provided';
    }
    if (newText == null) {
      throw 'newText is required but was not provided';
    }
  }
  static TextEdit fromJson(Map<String, dynamic> json) {
    final range = json['range'] != null ? Range.fromJson(json['range']) : null;
    final newText = json['newText'];
    return new TextEdit(range, newText);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('range') &&
        Range.canParse(obj['range']) &&
        obj.containsKey('newText') &&
        obj['newText'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is TextEdit) {
      return range == other.range && newText == other.newText && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, range.hashCode);
    hash = JenkinsSmiHash.combine(hash, newText.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// General parameters to unregister a capability.
class Unregistration implements ToJsonable {
  Unregistration(this.id, this.method) {
    if (id == null) {
      throw 'id is required but was not provided';
    }
    if (method == null) {
      throw 'method is required but was not provided';
    }
  }
  static Unregistration fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final method = json['method'];
    return new Unregistration(id, method);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('id') &&
        obj['id'] is String &&
        obj.containsKey('method') &&
        obj['method'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is Unregistration) {
      return id == other.id && method == other.method && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, id.hashCode);
    hash = JenkinsSmiHash.combine(hash, method.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class UnregistrationParams implements ToJsonable {
  UnregistrationParams(this.unregisterations) {
    if (unregisterations == null) {
      throw 'unregisterations is required but was not provided';
    }
  }
  static UnregistrationParams fromJson(Map<String, dynamic> json) {
    final unregisterations = json['unregisterations']
        ?.map((item) => item != null ? Unregistration.fromJson(item) : null)
        ?.cast<Unregistration>()
        ?.toList();
    return new UnregistrationParams(unregisterations);
  }

  final List<Unregistration> unregisterations;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['unregisterations'] = unregisterations ??
        (throw 'unregisterations is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('unregisterations') &&
        (obj['unregisterations'] is List &&
            (obj['unregisterations']
                .every((item) => Unregistration.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is UnregistrationParams) {
      return listEqual(unregisterations, other.unregisterations,
              (Unregistration a, Unregistration b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, unregisterations.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class VersionedTextDocumentIdentifier
    implements TextDocumentIdentifier, ToJsonable {
  VersionedTextDocumentIdentifier(this.version, this.uri) {
    if (uri == null) {
      throw 'uri is required but was not provided';
    }
  }
  static VersionedTextDocumentIdentifier fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    final uri = json['uri'];
    return new VersionedTextDocumentIdentifier(version, uri);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('version') &&
        obj['version'] is num &&
        obj.containsKey('uri') &&
        obj['uri'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is VersionedTextDocumentIdentifier) {
      return version == other.version && uri == other.uri && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, version.hashCode);
    hash = JenkinsSmiHash.combine(hash, uri.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class WatchKind {
  const WatchKind._(this._value);
  const WatchKind.fromJson(this._value);

  final num _value;

  static bool canParse(Object obj) {
    switch (obj) {
      case 1:
      case 2:
      case 4:
        return true;
    }
    return false;
  }

  /// Interested in create events.
  static const Create = const WatchKind._(1);

  /// Interested in change events
  static const Change = const WatchKind._(2);

  /// Interested in delete events
  static const Delete = const WatchKind._(4);

  Object toJson() => _value;

  @override
  String toString() => _value.toString();

  @override
  get hashCode => _value.hashCode;

  bool operator ==(o) => o is WatchKind && o._value == _value;
}

/// The parameters send in a will save text document notification.
class WillSaveTextDocumentParams implements ToJsonable {
  WillSaveTextDocumentParams(this.textDocument, this.reason) {
    if (textDocument == null) {
      throw 'textDocument is required but was not provided';
    }
    if (reason == null) {
      throw 'reason is required but was not provided';
    }
  }
  static WillSaveTextDocumentParams fromJson(Map<String, dynamic> json) {
    final textDocument = json['textDocument'] != null
        ? TextDocumentIdentifier.fromJson(json['textDocument'])
        : null;
    final reason = json['reason'];
    return new WillSaveTextDocumentParams(textDocument, reason);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('textDocument') &&
        TextDocumentIdentifier.canParse(obj['textDocument']) &&
        obj.containsKey('reason') &&
        obj['reason'] is num;
  }

  @override
  bool operator ==(other) {
    if (other is WillSaveTextDocumentParams) {
      return textDocument == other.textDocument &&
          reason == other.reason &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, textDocument.hashCode);
    hash = JenkinsSmiHash.combine(hash, reason.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// Workspace specific client capabilities.
class WorkspaceClientCapabilities implements ToJsonable {
  WorkspaceClientCapabilities(
      this.applyEdit,
      this.workspaceEdit,
      this.didChangeConfiguration,
      this.didChangeWatchedFiles,
      this.symbol,
      this.executeCommand,
      this.workspaceFolders,
      this.configuration);
  static WorkspaceClientCapabilities fromJson(Map<String, dynamic> json) {
    final applyEdit = json['applyEdit'];
    final workspaceEdit = json['workspaceEdit'] != null
        ? WorkspaceClientCapabilitiesWorkspaceEdit.fromJson(
            json['workspaceEdit'])
        : null;
    final didChangeConfiguration = json['didChangeConfiguration'] != null
        ? WorkspaceClientCapabilitiesDidChangeConfiguration.fromJson(
            json['didChangeConfiguration'])
        : null;
    final didChangeWatchedFiles = json['didChangeWatchedFiles'] != null
        ? WorkspaceClientCapabilitiesDidChangeWatchedFiles.fromJson(
            json['didChangeWatchedFiles'])
        : null;
    final symbol = json['symbol'] != null
        ? WorkspaceClientCapabilitiesSymbol.fromJson(json['symbol'])
        : null;
    final executeCommand = json['executeCommand'] != null
        ? WorkspaceClientCapabilitiesExecuteCommand.fromJson(
            json['executeCommand'])
        : null;
    final workspaceFolders = json['workspaceFolders'];
    final configuration = json['configuration'];
    return new WorkspaceClientCapabilities(
        applyEdit,
        workspaceEdit,
        didChangeConfiguration,
        didChangeWatchedFiles,
        symbol,
        executeCommand,
        workspaceFolders,
        configuration);
  }

  /// The client supports applying batch edits to the workspace by supporting
  /// the request 'workspace/applyEdit'
  final bool applyEdit;

  /// The client supports `workspace/configuration` requests.
  ///
  /// Since 3.6.0
  final bool configuration;

  /// Capabilities specific to the `workspace/didChangeConfiguration`
  /// notification.
  final WorkspaceClientCapabilitiesDidChangeConfiguration
      didChangeConfiguration;

  /// Capabilities specific to the `workspace/didChangeWatchedFiles`
  /// notification.
  final WorkspaceClientCapabilitiesDidChangeWatchedFiles didChangeWatchedFiles;

  /// Capabilities specific to the `workspace/executeCommand` request.
  final WorkspaceClientCapabilitiesExecuteCommand executeCommand;

  /// Capabilities specific to the `workspace/symbol` request.
  final WorkspaceClientCapabilitiesSymbol symbol;

  /// Capabilities specific to `WorkspaceEdit`s
  final WorkspaceClientCapabilitiesWorkspaceEdit workspaceEdit;

  /// The client has support for workspace folders.
  ///
  /// Since 3.6.0
  final bool workspaceFolders;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (applyEdit != null) {
      __result['applyEdit'] = applyEdit;
    }
    if (workspaceEdit != null) {
      __result['workspaceEdit'] = workspaceEdit;
    }
    if (didChangeConfiguration != null) {
      __result['didChangeConfiguration'] = didChangeConfiguration;
    }
    if (didChangeWatchedFiles != null) {
      __result['didChangeWatchedFiles'] = didChangeWatchedFiles;
    }
    if (symbol != null) {
      __result['symbol'] = symbol;
    }
    if (executeCommand != null) {
      __result['executeCommand'] = executeCommand;
    }
    if (workspaceFolders != null) {
      __result['workspaceFolders'] = workspaceFolders;
    }
    if (configuration != null) {
      __result['configuration'] = configuration;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is WorkspaceClientCapabilities) {
      return applyEdit == other.applyEdit &&
          workspaceEdit == other.workspaceEdit &&
          didChangeConfiguration == other.didChangeConfiguration &&
          didChangeWatchedFiles == other.didChangeWatchedFiles &&
          symbol == other.symbol &&
          executeCommand == other.executeCommand &&
          workspaceFolders == other.workspaceFolders &&
          configuration == other.configuration &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, applyEdit.hashCode);
    hash = JenkinsSmiHash.combine(hash, workspaceEdit.hashCode);
    hash = JenkinsSmiHash.combine(hash, didChangeConfiguration.hashCode);
    hash = JenkinsSmiHash.combine(hash, didChangeWatchedFiles.hashCode);
    hash = JenkinsSmiHash.combine(hash, symbol.hashCode);
    hash = JenkinsSmiHash.combine(hash, executeCommand.hashCode);
    hash = JenkinsSmiHash.combine(hash, workspaceFolders.hashCode);
    hash = JenkinsSmiHash.combine(hash, configuration.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class WorkspaceClientCapabilitiesDidChangeConfiguration implements ToJsonable {
  WorkspaceClientCapabilitiesDidChangeConfiguration(this.dynamicRegistration);
  static WorkspaceClientCapabilitiesDidChangeConfiguration fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    return new WorkspaceClientCapabilitiesDidChangeConfiguration(
        dynamicRegistration);
  }

  /// Did change configuration notification supports dynamic registration.
  final bool dynamicRegistration;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is WorkspaceClientCapabilitiesDidChangeConfiguration) {
      return dynamicRegistration == other.dynamicRegistration && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class WorkspaceClientCapabilitiesDidChangeWatchedFiles implements ToJsonable {
  WorkspaceClientCapabilitiesDidChangeWatchedFiles(this.dynamicRegistration);
  static WorkspaceClientCapabilitiesDidChangeWatchedFiles fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    return new WorkspaceClientCapabilitiesDidChangeWatchedFiles(
        dynamicRegistration);
  }

  /// Did change watched files notification supports dynamic registration.
  /// Please note that the current protocol doesn't support static configuration
  /// for file changes from the server side.
  final bool dynamicRegistration;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is WorkspaceClientCapabilitiesDidChangeWatchedFiles) {
      return dynamicRegistration == other.dynamicRegistration && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class WorkspaceClientCapabilitiesExecuteCommand implements ToJsonable {
  WorkspaceClientCapabilitiesExecuteCommand(this.dynamicRegistration);
  static WorkspaceClientCapabilitiesExecuteCommand fromJson(
      Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    return new WorkspaceClientCapabilitiesExecuteCommand(dynamicRegistration);
  }

  /// Execute command supports dynamic registration.
  final bool dynamicRegistration;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is WorkspaceClientCapabilitiesExecuteCommand) {
      return dynamicRegistration == other.dynamicRegistration && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class WorkspaceClientCapabilitiesSymbol implements ToJsonable {
  WorkspaceClientCapabilitiesSymbol(this.dynamicRegistration, this.symbolKind);
  static WorkspaceClientCapabilitiesSymbol fromJson(Map<String, dynamic> json) {
    final dynamicRegistration = json['dynamicRegistration'];
    final symbolKind = json['symbolKind'] != null
        ? WorkspaceClientCapabilitiesSymbolKind.fromJson(json['symbolKind'])
        : null;
    return new WorkspaceClientCapabilitiesSymbol(
        dynamicRegistration, symbolKind);
  }

  /// Symbol request supports dynamic registration.
  final bool dynamicRegistration;

  /// Specific capabilities for the `SymbolKind` in the `workspace/symbol`
  /// request.
  final WorkspaceClientCapabilitiesSymbolKind symbolKind;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (dynamicRegistration != null) {
      __result['dynamicRegistration'] = dynamicRegistration;
    }
    if (symbolKind != null) {
      __result['symbolKind'] = symbolKind;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is WorkspaceClientCapabilitiesSymbol) {
      return dynamicRegistration == other.dynamicRegistration &&
          symbolKind == other.symbolKind &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, dynamicRegistration.hashCode);
    hash = JenkinsSmiHash.combine(hash, symbolKind.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class WorkspaceClientCapabilitiesSymbolKind implements ToJsonable {
  WorkspaceClientCapabilitiesSymbolKind(this.valueSet);
  static WorkspaceClientCapabilitiesSymbolKind fromJson(
      Map<String, dynamic> json) {
    final valueSet = json['valueSet']
        ?.map((item) => item != null ? SymbolKind.fromJson(item) : null)
        ?.cast<SymbolKind>()
        ?.toList();
    return new WorkspaceClientCapabilitiesSymbolKind(valueSet);
  }

  /// The symbol kind values the client supports. When this property exists the
  /// client also guarantees that it will handle values outside its set
  /// gracefully and falls back to a default value when unknown.
  ///
  /// If this property is not present the client only supports the symbol kinds
  /// from `File` to `Array` as defined in the initial version of the protocol.
  final List<SymbolKind> valueSet;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    if (valueSet != null) {
      __result['valueSet'] = valueSet;
    }
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is WorkspaceClientCapabilitiesSymbolKind) {
      return listEqual(valueSet, other.valueSet,
              (SymbolKind a, SymbolKind b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, valueSet.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class WorkspaceClientCapabilitiesWorkspaceEdit implements ToJsonable {
  WorkspaceClientCapabilitiesWorkspaceEdit(
      this.documentChanges, this.resourceOperations, this.failureHandling);
  static WorkspaceClientCapabilitiesWorkspaceEdit fromJson(
      Map<String, dynamic> json) {
    final documentChanges = json['documentChanges'];
    final resourceOperations = json['resourceOperations']
        ?.map((item) =>
            item != null ? ResourceOperationKind.fromJson(item) : null)
        ?.cast<ResourceOperationKind>()
        ?.toList();
    final failureHandling = json['failureHandling'] != null
        ? FailureHandlingKind.fromJson(json['failureHandling'])
        : null;
    return new WorkspaceClientCapabilitiesWorkspaceEdit(
        documentChanges, resourceOperations, failureHandling);
  }

  /// The client supports versioned document changes in `WorkspaceEdit`s
  final bool documentChanges;

  /// The failure handling strategy of a client if applying the workspace edit
  /// fails.
  final FailureHandlingKind failureHandling;

  /// The resource operations the client supports. Clients should at least
  /// support 'create', 'rename' and 'delete' files and folders.
  final List<ResourceOperationKind> resourceOperations;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is WorkspaceClientCapabilitiesWorkspaceEdit) {
      return documentChanges == other.documentChanges &&
          listEqual(resourceOperations, other.resourceOperations,
              (ResourceOperationKind a, ResourceOperationKind b) => a == b) &&
          failureHandling == other.failureHandling &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, documentChanges.hashCode);
    hash = JenkinsSmiHash.combine(hash, resourceOperations.hashCode);
    hash = JenkinsSmiHash.combine(hash, failureHandling.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class WorkspaceEdit implements ToJsonable {
  WorkspaceEdit(this.changes, this.documentChanges);
  static WorkspaceEdit fromJson(Map<String, dynamic> json) {
    final changes = json['changes']
        ?.map((key, value) => new MapEntry(
            key,
            value
                ?.map((item) => item != null ? TextEdit.fromJson(item) : null)
                ?.cast<TextEdit>()
                ?.toList()))
        ?.cast<String, List<TextEdit>>();
    final documentChanges = (json['documentChanges'] is List && (json['documentChanges'].every((item) => TextDocumentEdit.canParse(item))))
        ? new Either2<List<TextDocumentEdit>, List<Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>>>.t1(
            json['documentChanges']
                ?.map((item) =>
                    item != null ? TextDocumentEdit.fromJson(item) : null)
                ?.cast<TextDocumentEdit>()
                ?.toList())
        : ((json['documentChanges'] is List && (json['documentChanges'].every((item) => (TextDocumentEdit.canParse(item) || CreateFile.canParse(item) || RenameFile.canParse(item) || DeleteFile.canParse(item)))))
            ? new Either2<List<TextDocumentEdit>, List<Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>>>.t2(json['documentChanges']
                ?.map((item) => TextDocumentEdit.canParse(item)
                    ? new Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>.t1(
                        item != null ? TextDocumentEdit.fromJson(item) : null)
                    : (CreateFile.canParse(item)
                        ? new Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>.t2(item != null ? CreateFile.fromJson(item) : null)
                        : (RenameFile.canParse(item) ? new Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>.t3(item != null ? RenameFile.fromJson(item) : null) : (DeleteFile.canParse(item) ? new Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>.t4(item != null ? DeleteFile.fromJson(item) : null) : (item == null ? null : (throw '''${item} was not one of (TextDocumentEdit, CreateFile, RenameFile, DeleteFile)'''))))))
                ?.cast<Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>>()
                ?.toList())
            : (json['documentChanges'] == null ? null : (throw '''${json['documentChanges']} was not one of (List<TextDocumentEdit>, List<Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>>)''')));
    return new WorkspaceEdit(changes, documentChanges);
  }

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
  final Either2<List<TextDocumentEdit>,
          List<Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>>>
      documentChanges;

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic>;
  }

  @override
  bool operator ==(other) {
    if (other is WorkspaceEdit) {
      return mapEqual(changes, other.changes,
              (List<TextEdit> a, List<TextEdit> b) => a == b) &&
          documentChanges == other.documentChanges &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, changes.hashCode);
    hash = JenkinsSmiHash.combine(hash, documentChanges.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

class WorkspaceFolder implements ToJsonable {
  WorkspaceFolder(this.uri, this.name) {
    if (uri == null) {
      throw 'uri is required but was not provided';
    }
    if (name == null) {
      throw 'name is required but was not provided';
    }
  }
  static WorkspaceFolder fromJson(Map<String, dynamic> json) {
    final uri = json['uri'];
    final name = json['name'];
    return new WorkspaceFolder(uri, name);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('uri') &&
        obj['uri'] is String &&
        obj.containsKey('name') &&
        obj['name'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is WorkspaceFolder) {
      return uri == other.uri && name == other.name && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, uri.hashCode);
    hash = JenkinsSmiHash.combine(hash, name.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// The workspace folder change event.
class WorkspaceFoldersChangeEvent implements ToJsonable {
  WorkspaceFoldersChangeEvent(this.added, this.removed) {
    if (added == null) {
      throw 'added is required but was not provided';
    }
    if (removed == null) {
      throw 'removed is required but was not provided';
    }
  }
  static WorkspaceFoldersChangeEvent fromJson(Map<String, dynamic> json) {
    final added = json['added']
        ?.map((item) => item != null ? WorkspaceFolder.fromJson(item) : null)
        ?.cast<WorkspaceFolder>()
        ?.toList();
    final removed = json['removed']
        ?.map((item) => item != null ? WorkspaceFolder.fromJson(item) : null)
        ?.cast<WorkspaceFolder>()
        ?.toList();
    return new WorkspaceFoldersChangeEvent(added, removed);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('added') &&
        (obj['added'] is List &&
            (obj['added'].every((item) => WorkspaceFolder.canParse(item)))) &&
        obj.containsKey('removed') &&
        (obj['removed'] is List &&
            (obj['removed'].every((item) => WorkspaceFolder.canParse(item))));
  }

  @override
  bool operator ==(other) {
    if (other is WorkspaceFoldersChangeEvent) {
      return listEqual(added, other.added,
              (WorkspaceFolder a, WorkspaceFolder b) => a == b) &&
          listEqual(removed, other.removed,
              (WorkspaceFolder a, WorkspaceFolder b) => a == b) &&
          true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, added.hashCode);
    hash = JenkinsSmiHash.combine(hash, removed.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}

/// The parameters of a Workspace Symbol Request.
class WorkspaceSymbolParams implements ToJsonable {
  WorkspaceSymbolParams(this.query) {
    if (query == null) {
      throw 'query is required but was not provided';
    }
  }
  static WorkspaceSymbolParams fromJson(Map<String, dynamic> json) {
    final query = json['query'];
    return new WorkspaceSymbolParams(query);
  }

  /// A non-empty query string
  final String query;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['query'] = query ?? (throw 'query is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('query') &&
        obj['query'] is String;
  }

  @override
  bool operator ==(other) {
    if (other is WorkspaceSymbolParams) {
      return query == other.query && true;
    }
    return false;
  }

  @override
  int get hashCode {
    int hash = 0;
    hash = JenkinsSmiHash.combine(hash, query.hashCode);
    return JenkinsSmiHash.finish(hash);
  }

  @override
  String toString() => jsonEncoder.convert(toJson());
}
