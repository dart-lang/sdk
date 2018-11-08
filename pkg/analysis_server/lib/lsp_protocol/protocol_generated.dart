// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/lsp_spec/generate_all.dart".

// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:core' hide deprecated;
import 'dart:core' as core show deprecated;
import 'package:analysis_server/lsp_protocol/protocol_special.dart';

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
            (obj['diagnostics'].length == 0 ||
                obj['diagnostics'].every((item) => Diagnostic.canParse(item))));
  }
}

/// A set of predefined code action kinds
class CodeActionKind {
  const CodeActionKind(this._value);
  const CodeActionKind.fromJson(this._value);

  final Object _value;

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
            (obj['documentSelector'].length == 0 ||
                obj['documentSelector']
                    .every((item) => DocumentFilter.canParse(item))));
  }
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
            (obj['documentSelector'].length == 0 ||
                obj['documentSelector']
                    .every((item) => DocumentFilter.canParse(item))));
  }
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
        true;
  }
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
            : (throw '''${json['documentation']} was not one of (String, MarkupContent)'''));
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
    // ignore: deprecated_member_use
    if (insertText != null) {
      // ignore: deprecated_member_use
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
}

/// The kind of a completion entry.
class CompletionItemKind {
  const CompletionItemKind._(this._value);
  const CompletionItemKind.fromJson(this._value);

  final Object _value;

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
            (obj['items'].length == 0 ||
                obj['items'].every((item) => CompletionItem.canParse(item))));
  }
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
            (obj['documentSelector'].length == 0 ||
                obj['documentSelector']
                    .every((item) => DocumentFilter.canParse(item))));
  }
}

/// How a completion was triggered
class CompletionTriggerKind {
  const CompletionTriggerKind._(this._value);
  const CompletionTriggerKind.fromJson(this._value);

  final Object _value;

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
            (obj['items'].length == 0 ||
                obj['items']
                    .every((item) => ConfigurationItem.canParse(item))));
  }
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
  final dynamic kind;

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
        true &&
        obj.containsKey('uri') &&
        obj['uri'] is String;
  }
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
  final dynamic kind;

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
        true &&
        obj.containsKey('uri') &&
        obj['uri'] is String;
  }
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
    final code = json['code'] is num
        ? new Either2<num, String>.t1(json['code'])
        : (json['code'] is String
            ? new Either2<num, String>.t2(json['code'])
            : (throw '''${json['code']} was not one of (num, String)'''));
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
}

class DiagnosticSeverity {
  const DiagnosticSeverity._(this._value);
  const DiagnosticSeverity.fromJson(this._value);

  final Object _value;

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
  DidChangeConfigurationParams(this.settings) {
    if (settings == null) {
      throw 'settings is required but was not provided';
    }
  }
  static DidChangeConfigurationParams fromJson(Map<String, dynamic> json) {
    final settings = json['settings'];
    return new DidChangeConfigurationParams(settings);
  }

  /// The actual changed settings
  final dynamic settings;

  Map<String, dynamic> toJson() {
    Map<String, dynamic> __result = {};
    __result['settings'] =
        settings ?? (throw 'settings is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> && obj.containsKey('settings') && true;
  }
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
            (obj['contentChanges'].length == 0 ||
                obj['contentChanges'].every(
                    (item) => TextDocumentContentChangeEvent.canParse(item))));
  }
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
            (obj['changes'].length == 0 ||
                obj['changes'].every((item) => FileEvent.canParse(item))));
  }
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
            (obj['watchers'].length == 0 ||
                obj['watchers']
                    .every((item) => FileSystemWatcher.canParse(item))));
  }
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
}

/// A document highlight kind.
class DocumentHighlightKind {
  const DocumentHighlightKind._(this._value);
  const DocumentHighlightKind.fromJson(this._value);

  final Object _value;

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
            (obj['documentSelector'].length == 0 ||
                obj['documentSelector']
                    .every((item) => DocumentFilter.canParse(item))));
  }
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
            (obj['documentSelector'].length == 0 ||
                obj['documentSelector']
                    .every((item) => DocumentFilter.canParse(item))));
  }
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
}

class ErrorCodes {
  const ErrorCodes(this._value);
  const ErrorCodes.fromJson(this._value);

  final Object _value;

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
            (obj['commands'].length == 0 ||
                obj['commands'].every((item) => item is String)));
  }
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
            (obj['commands'].length == 0 ||
                obj['commands'].every((item) => item is String)));
  }
}

class FailureHandlingKind {
  const FailureHandlingKind._(this._value);
  const FailureHandlingKind.fromJson(this._value);

  final Object _value;

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
  /// part of the change the failure handling startegy is abort.
  static const TextOnlyTransactional =
      const FailureHandlingKind._('textOnlyTransactional');

  /// The client tries to undo the operations already executed. But there is no
  /// guaruntee that this is succeeding.
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

  final Object _value;

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

  /// The  glob pattern to watch
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
}

/// Enum of known range kinds
class FoldingRangeKind {
  const FoldingRangeKind._(this._value);
  const FoldingRangeKind.fromJson(this._value);

  final Object _value;

  static bool canParse(Object obj) {
    switch (obj) {
      case 'comment':
      case 'imports':
      case 'region':
        return true;
    }
    return false;
  }

  /// Folding range for a comment
  static const Comment = const FoldingRangeKind._('comment');

  /// Folding range for a imports or includes
  static const Imports = const FoldingRangeKind._('imports');

  /// Folding range for a region (e.g. `#region`)
  static const Region = const FoldingRangeKind._('region');

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
}

/// The result of a hover request.
class Hover implements ToJsonable {
  Hover(this.contents, this.range) {
    if (contents == null) {
      throw 'contents is required but was not provided';
    }
  }
  static Hover fromJson(Map<String, dynamic> json) {
    final contents = json['contents'] != null
        ? MarkupContent.fromJson(json['contents'])
        : null;
    final range = json['range'] != null ? Range.fromJson(json['range']) : null;
    return new Hover(contents, range);
  }

  /// The hover's content
  final MarkupContent contents;

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
        MarkupContent.canParse(obj['contents']);
  }
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
  final dynamic trace;

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
    // ignore: deprecated_member_use
    if (rootPath != null) {
      // ignore: deprecated_member_use
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
}

/// Defines whether the insert text in a completion item should be interpreted
/// as plain text or a snippet.
class InsertTextFormat {
  const InsertTextFormat._(this._value);
  const InsertTextFormat.fromJson(this._value);

  final Object _value;

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
        true &&
        obj.containsKey('value') &&
        obj['value'] is String;
  }
}

/// Describes the content type that a client supports in various result literals
/// like `Hover`, `ParameterInfo` or `CompletionItem`.
///
/// Please note that `MarkupKinds` must not start with a `$`. This kinds are
/// reserved for internal usage.
class MarkupKind {
  const MarkupKind._(this._value);
  const MarkupKind.fromJson(this._value);

  final Object _value;

  static bool canParse(Object obj) {
    switch (obj) {
      case 'plaintext':
      case 'markdown':
        return true;
    }
    return false;
  }

  /// Plain text is supported as a content format
  static const PlainText = const MarkupKind._('plaintext');

  /// Markdown is supported as a content format
  static const Markdown = const MarkupKind._('markdown');

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
}

class MessageType {
  const MessageType._(this._value);
  const MessageType.fromJson(this._value);

  final Object _value;

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
    final method = json['method'];
    final params = (json['params'] is List &&
            (json['params'].length == 0 ||
                json['params'].every((item) => true)))
        ? new Either2<List<dynamic>, dynamic>.t1(
            json['params']?.map((item) => item)?.cast<dynamic>()?.toList())
        : (new Either2<List<dynamic>, dynamic>.t2(json['params']));
    final jsonrpc = json['jsonrpc'];
    return new NotificationMessage(method, params, jsonrpc);
  }

  final String jsonrpc;

  /// The method to be invoked.
  final String method;

  /// The notification's params.
  final Either2<List<dynamic>, dynamic> params;

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
        obj['method'] is String &&
        obj.containsKey('jsonrpc') &&
        obj['jsonrpc'] is String;
  }
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
            : (throw '''${json['documentation']} was not one of (String, MarkupContent)'''));
    return new ParameterInformation(label, documentation);
  }

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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('label') &&
        obj['label'] is String;
  }
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
            (obj['diagnostics'].length == 0 ||
                obj['diagnostics'].every((item) => Diagnostic.canParse(item))));
  }
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
            (obj['registrations'].length == 0 ||
                obj['registrations']
                    .every((item) => Registration.canParse(item))));
  }
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
  final dynamic kind;

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
        true &&
        obj.containsKey('oldUri') &&
        obj['oldUri'] is String &&
        obj.containsKey('newUri') &&
        obj['newUri'] is String;
  }
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
            (obj['documentSelector'].length == 0 ||
                obj['documentSelector']
                    .every((item) => DocumentFilter.canParse(item))));
  }
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
    final method = json['method'];
    final params = (json['params'] is List &&
            (json['params'].length == 0 ||
                json['params'].every((item) => true)))
        ? new Either2<List<dynamic>, dynamic>.t1(
            json['params']?.map((item) => item)?.cast<dynamic>()?.toList())
        : (new Either2<List<dynamic>, dynamic>.t2(json['params']));
    final jsonrpc = json['jsonrpc'];
    return new RequestMessage(id, method, params, jsonrpc);
  }

  /// The request id.
  final Either2<num, String> id;
  final String jsonrpc;

  /// The method to be invoked.
  final String method;

  /// The method's params.
  final Either2<List<dynamic>, dynamic> params;

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
        obj['method'] is String &&
        obj.containsKey('jsonrpc') &&
        obj['jsonrpc'] is String;
  }
}

class ResourceOperationKind {
  const ResourceOperationKind._(this._value);
  const ResourceOperationKind.fromJson(this._value);

  final Object _value;

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

  /// A Primitive or Structured value that contains additional information about
  /// the error. Can be omitted.
  final D data;

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
            : (throw '''${json['id']} was not one of (num, String)'''));
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
    if (result != null) {
      __result['result'] = result;
    }
    if (error != null) {
      __result['error'] = error;
    }
    __result['jsonrpc'] =
        jsonrpc ?? (throw 'jsonrpc is required but was not set');
    return __result;
  }

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('id') &&
        (obj['id'] is num || obj['id'] is String) &&
        obj.containsKey('jsonrpc') &&
        obj['jsonrpc'] is String;
  }
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
            : (throw '''${json['textDocumentSync']} was not one of (TextDocumentSyncOptions, num)'''));
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
            : (throw '''${json['codeActionProvider']} was not one of (bool, CodeActionOptions)'''));
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
            : (throw '''${json['renameProvider']} was not one of (bool, RenameOptions)'''));
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
    final workspace = json['workspace'];
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
  final dynamic workspace;

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
            (obj['signatures'].length == 0 ||
                obj['signatures']
                    .every((item) => SignatureInformation.canParse(item))));
  }
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
            (obj['documentSelector'].length == 0 ||
                obj['documentSelector']
                    .every((item) => DocumentFilter.canParse(item))));
  }
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
            : (throw '''${json['documentation']} was not one of (String, MarkupContent)'''));
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
    final kind = json['kind'];
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

  static bool canParse(Object obj) {
    return obj is Map<String, dynamic> &&
        obj.containsKey('name') &&
        obj['name'] is String &&
        obj.containsKey('kind') &&
        obj['kind'] is num &&
        obj.containsKey('location') &&
        Location.canParse(obj['location']);
  }
}

/// A symbol kind.
class SymbolKind {
  const SymbolKind._(this._value);
  const SymbolKind.fromJson(this._value);

  final Object _value;

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
            (obj['documentSelector'].length == 0 ||
                obj['documentSelector']
                    .every((item) => DocumentFilter.canParse(item))));
  }
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
    final synchronization = json['synchronization'];
    final completion = json['completion'];
    final hover = json['hover'];
    final signatureHelp = json['signatureHelp'];
    final references = json['references'];
    final documentHighlight = json['documentHighlight'];
    final documentSymbol = json['documentSymbol'];
    final formatting = json['formatting'];
    final rangeFormatting = json['rangeFormatting'];
    final onTypeFormatting = json['onTypeFormatting'];
    final definition = json['definition'];
    final typeDefinition = json['typeDefinition'];
    final implementation = json['implementation'];
    final codeAction = json['codeAction'];
    final codeLens = json['codeLens'];
    final documentLink = json['documentLink'];
    final colorProvider = json['colorProvider'];
    final rename = json['rename'];
    final publishDiagnostics = json['publishDiagnostics'];
    final foldingRange = json['foldingRange'];
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
  final dynamic codeAction;

  /// Capabilities specific to the `textDocument/codeLens`
  final dynamic codeLens;

  /// Capabilities specific to the `textDocument/documentColor` and the
  /// `textDocument/colorPresentation` request.
  ///
  /// Since 3.6.0
  final dynamic colorProvider;

  /// Capabilities specific to the `textDocument/completion`
  final dynamic completion;

  /// Capabilities specific to the `textDocument/definition`
  final dynamic definition;

  /// Capabilities specific to the `textDocument/documentHighlight`
  final dynamic documentHighlight;

  /// Capabilities specific to the `textDocument/documentLink`
  final dynamic documentLink;

  /// Capabilities specific to the `textDocument/documentSymbol`
  final dynamic documentSymbol;

  /// Capabilities specific to `textDocument/foldingRange` requests.
  ///
  /// Since 3.10.0
  final dynamic foldingRange;

  /// Capabilities specific to the `textDocument/formatting`
  final dynamic formatting;

  /// Capabilities specific to the `textDocument/hover`
  final dynamic hover;

  /// Capabilities specific to the `textDocument/implementation`.
  ///
  /// Since 3.6.0
  final dynamic implementation;

  /// Capabilities specific to the `textDocument/onTypeFormatting`
  final dynamic onTypeFormatting;

  /// Capabilities specific to `textDocument/publishDiagnostics`.
  final dynamic publishDiagnostics;

  /// Capabilities specific to the `textDocument/rangeFormatting`
  final dynamic rangeFormatting;

  /// Capabilities specific to the `textDocument/references`
  final dynamic references;

  /// Capabilities specific to the `textDocument/rename`
  final dynamic rename;

  /// Capabilities specific to the `textDocument/signatureHelp`
  final dynamic signatureHelp;
  final dynamic synchronization;

  /// Capabilities specific to the `textDocument/typeDefinition`
  ///
  /// Since 3.6.0
  final dynamic typeDefinition;

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
            (obj['edits'].length == 0 ||
                obj['edits'].every((item) => TextEdit.canParse(item))));
  }
}

class TextDocumentIdentifier implements ToJsonable {
  TextDocumentIdentifier(this.uri) {
    if (uri == null) {
      throw 'uri is required but was not provided';
    }
  }
  static TextDocumentIdentifier fromJson(Map<String, dynamic> json) {
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
}

class TextDocumentRegistrationOptions implements ToJsonable {
  TextDocumentRegistrationOptions(this.documentSelector);
  static TextDocumentRegistrationOptions fromJson(Map<String, dynamic> json) {
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
            (obj['documentSelector'].length == 0 ||
                obj['documentSelector']
                    .every((item) => DocumentFilter.canParse(item))));
  }
}

/// Represents reasons why a text document is saved.
class TextDocumentSaveReason {
  const TextDocumentSaveReason._(this._value);
  const TextDocumentSaveReason.fromJson(this._value);

  final Object _value;

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
            (obj['documentSelector'].length == 0 ||
                obj['documentSelector']
                    .every((item) => DocumentFilter.canParse(item))));
  }
}

/// Defines how the host (editor) should sync document changes to the language
/// server.
class TextDocumentSyncKind {
  const TextDocumentSyncKind._(this._value);
  const TextDocumentSyncKind.fromJson(this._value);

  final Object _value;

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
            (obj['unregisterations'].length == 0 ||
                obj['unregisterations']
                    .every((item) => Unregistration.canParse(item))));
  }
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
}

class WatchKind {
  const WatchKind._(this._value);
  const WatchKind.fromJson(this._value);

  final Object _value;

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
    final workspaceEdit = json['workspaceEdit'];
    final didChangeConfiguration = json['didChangeConfiguration'];
    final didChangeWatchedFiles = json['didChangeWatchedFiles'];
    final symbol = json['symbol'];
    final executeCommand = json['executeCommand'];
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
  final dynamic didChangeConfiguration;

  /// Capabilities specific to the `workspace/didChangeWatchedFiles`
  /// notification.
  final dynamic didChangeWatchedFiles;

  /// Capabilities specific to the `workspace/executeCommand` request.
  final dynamic executeCommand;

  /// Capabilities specific to the `workspace/symbol` request.
  final dynamic symbol;

  /// Capabilities specific to `WorkspaceEdit`s
  final dynamic workspaceEdit;

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
}

class WorkspaceEdit implements ToJsonable {
  WorkspaceEdit(this.changes, this.documentChanges);
  static WorkspaceEdit fromJson(Map<String, dynamic> json) {
    final changes = json['changes'];
    final documentChanges = (json['documentChanges'] is List && (json['documentChanges'].length == 0 || json['documentChanges'].every((item) => TextDocumentEdit.canParse(item))))
        ? new Either2<List<TextDocumentEdit>, List<Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>>>.t1(json['documentChanges']
            ?.map(
                (item) => item != null ? TextDocumentEdit.fromJson(item) : null)
            ?.cast<TextDocumentEdit>()
            ?.toList())
        : ((json['documentChanges'] is List && (json['documentChanges'].length == 0 || json['documentChanges'].every((item) => (TextDocumentEdit.canParse(item) || CreateFile.canParse(item) || RenameFile.canParse(item) || DeleteFile.canParse(item)))))
            ? new Either2<List<TextDocumentEdit>, List<Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>>>.t2(json['documentChanges']
                ?.map((item) => TextDocumentEdit.canParse(item)
                    ? new Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>.t1(
                        item != null ? TextDocumentEdit.fromJson(item) : null)
                    : (CreateFile.canParse(item)
                        ? new Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>.t2(
                            item != null ? CreateFile.fromJson(item) : null)
                        : (RenameFile.canParse(item) ? new Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>.t3(item != null ? RenameFile.fromJson(item) : null) : (DeleteFile.canParse(item) ? new Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>.t4(item != null ? DeleteFile.fromJson(item) : null) : (throw '''${item} was not one of (TextDocumentEdit, CreateFile, RenameFile, DeleteFile)''')))))
                ?.cast<Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>>()
                ?.toList())
            : (throw '''${json['documentChanges']} was not one of (List<TextDocumentEdit>, List<Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>>)'''));
    return new WorkspaceEdit(changes, documentChanges);
  }

  /// Holds changes to existing resources.
  final dynamic changes;

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
            (obj['added'].length == 0 ||
                obj['added']
                    .every((item) => WorkspaceFolder.canParse(item)))) &&
        obj.containsKey('removed') &&
        (obj['removed'] is List &&
            (obj['removed'].length == 0 ||
                obj['removed']
                    .every((item) => WorkspaceFolder.canParse(item))));
  }
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
}
