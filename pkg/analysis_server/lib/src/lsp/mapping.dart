// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math';

import 'package:analysis_server/lsp_protocol/protocol_custom_generated.dart'
    as lsp;
import 'package:analysis_server/lsp_protocol/protocol_generated.dart' as lsp;
import 'package:analysis_server/lsp_protocol/protocol_generated.dart'
    show ResponseError;
import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart' as lsp;
import 'package:analysis_server/lsp_protocol/protocol_special.dart'
    show ErrorOr, Either2, Either4;
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/constants.dart' as lsp;
import 'package:analysis_server/src/lsp/dartdoc.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart' as lsp;
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analysis_server/src/protocol_server.dart' as server
    hide AnalysisError;
import 'package:analysis_server/src/search/workspace_symbols.dart' as server
    show DeclarationKind;
import 'package:analyzer/dart/analysis/results.dart' as server;
import 'package:analyzer/diagnostic/diagnostic.dart' as analyzer;
import 'package:analyzer/error/error.dart' as server;
import 'package:analyzer/source/line_info.dart' as server;
import 'package:analyzer/src/generated/source.dart' as server;
import 'package:analyzer/src/services/available_declarations.dart';
import 'package:analyzer/src/services/available_declarations.dart' as dec;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart' as server;

const languageSourceName = 'dart';

lsp.Either2<String, lsp.MarkupContent> asStringOrMarkupContent(
    List<lsp.MarkupKind> preferredFormats, String content) {
  if (content == null) {
    return null;
  }

  return preferredFormats == null
      ? lsp.Either2<String, lsp.MarkupContent>.t1(content)
      : lsp.Either2<String, lsp.MarkupContent>.t2(
          _asMarkup(preferredFormats, content));
}

/// Builds an LSP snippet string that uses a $1 tabstop to set the selected text
/// after insertion.
String buildSnippetStringWithSelection(
  String text,
  int selectionOffset,
  int selectionLength,
) {
  String escape(String input) => input.replaceAllMapped(
        RegExp(r'[$}\\]'), // Replace any of $ } \
        (c) => '\\${c[0]}', // Prefix with a backslash
      );
  // Snippets syntax is documented in the LSP spec:
  // https://microsoft.github.io/language-server-protocol/specifications/specification-3-14/#snippet-syntax
  //
  // $1, $2, etc. are used for tab stops and ${1:foo} inserts a placeholder of foo.
  // Since we only need to support a single tab stop, our string is constructed of three parts:
  // - Anything before the selection
  // - The selection (which may or may not include text, depending on selectionLength)
  // - Anything after the selection
  final prefix = escape(text.substring(0, selectionOffset));
  final selectionText = escape(
      text.substring(selectionOffset, selectionOffset + selectionLength));
  final selection = '\${1:$selectionText}';
  final suffix = escape(text.substring(selectionOffset + selectionLength));

  return '$prefix$selection$suffix';
}

/// Note: This code will fetch the version of each document being modified so
/// it's important to call this immediately after computing edits to ensure
/// the document is not modified before the version number is read.
lsp.WorkspaceEdit createWorkspaceEdit(
    lsp.LspAnalysisServer server, List<server.SourceFileEdit> edits) {
  return toWorkspaceEdit(
      server.clientCapabilities?.workspace,
      edits
          .map((e) => FileEditInformation(
              server.getVersionedDocumentIdentifier(e.file),
              server.getLineInfo(e.file),
              e.edits))
          .toList());
}

lsp.CompletionItemKind declarationKindToCompletionItemKind(
  HashSet<lsp.CompletionItemKind> clientSupportedCompletionKinds,
  dec.DeclarationKind kind,
) {
  bool isSupported(lsp.CompletionItemKind kind) =>
      clientSupportedCompletionKinds.contains(kind);

  List<lsp.CompletionItemKind> getKindPreferences() {
    switch (kind) {
      case dec.DeclarationKind.CLASS:
      case dec.DeclarationKind.CLASS_TYPE_ALIAS:
      case dec.DeclarationKind.MIXIN:
        return const [lsp.CompletionItemKind.Class];
      case dec.DeclarationKind.CONSTRUCTOR:
        return const [lsp.CompletionItemKind.Constructor];
      case dec.DeclarationKind.ENUM:
      case dec.DeclarationKind.ENUM_CONSTANT:
        return const [lsp.CompletionItemKind.Enum];
      case dec.DeclarationKind.FUNCTION:
        return const [lsp.CompletionItemKind.Function];
      case dec.DeclarationKind.FUNCTION_TYPE_ALIAS:
        return const [lsp.CompletionItemKind.Class];
      case dec.DeclarationKind.GETTER:
        return const [lsp.CompletionItemKind.Property];
      case dec.DeclarationKind.SETTER:
        return const [lsp.CompletionItemKind.Property];
      case dec.DeclarationKind.VARIABLE:
        return const [lsp.CompletionItemKind.Variable];
      default:
        return const [];
    }
  }

  return getKindPreferences().firstWhere(isSupported, orElse: () => null);
}

lsp.SymbolKind declarationKindToSymbolKind(
  HashSet<lsp.SymbolKind> clientSupportedSymbolKinds,
  server.DeclarationKind kind,
) {
  bool isSupported(lsp.SymbolKind kind) =>
      clientSupportedSymbolKinds.contains(kind);

  List<lsp.SymbolKind> getKindPreferences() {
    switch (kind) {
      case server.DeclarationKind.CLASS:
      case server.DeclarationKind.CLASS_TYPE_ALIAS:
        return const [lsp.SymbolKind.Class];
      case server.DeclarationKind.CONSTRUCTOR:
        return const [lsp.SymbolKind.Constructor];
      case server.DeclarationKind.ENUM:
      case server.DeclarationKind.ENUM_CONSTANT:
        return const [lsp.SymbolKind.Enum];
      case server.DeclarationKind.FIELD:
        return const [lsp.SymbolKind.Field];
      case server.DeclarationKind.FUNCTION:
        return const [lsp.SymbolKind.Function];
      case server.DeclarationKind.FUNCTION_TYPE_ALIAS:
        return const [lsp.SymbolKind.Class];
      case server.DeclarationKind.GETTER:
        return const [lsp.SymbolKind.Property];
      case server.DeclarationKind.METHOD:
        return const [lsp.SymbolKind.Method];
      case server.DeclarationKind.MIXIN:
        return const [lsp.SymbolKind.Class];
      case server.DeclarationKind.SETTER:
        return const [lsp.SymbolKind.Property];
      case server.DeclarationKind.VARIABLE:
        return const [lsp.SymbolKind.Variable];
      default:
        // Assert that we only get here if kind=null. If it's anything else
        // then we're missing a mapping from above.
        assert(kind == null, 'Unexpected declaration kind $kind');
        return const [];
    }
  }

  // LSP requires we specify *some* kind, so in the case where the above code doesn't
  // match we'll just have to send a value to avoid a crash.
  return getKindPreferences()
      .firstWhere(isSupported, orElse: () => lsp.SymbolKind.Obj);
}

lsp.CompletionItem declarationToCompletionItem(
  lsp.CompletionClientCapabilities completionCapabilities,
  HashSet<lsp.CompletionItemKind> supportedCompletionItemKinds,
  String file,
  int offset,
  IncludedSuggestionSet includedSuggestionSet,
  Library library,
  Map<String, int> tagBoosts,
  server.LineInfo lineInfo,
  dec.Declaration declaration,
  int replacementOffset,
  int replacementLength,
) {
  // Build display labels and text to insert. insertText and filterText may
  // differ from label (for ex. if the label includes things like (…)). If
  // either are missing then label will be used by the client.
  String label;
  String insertText;
  String filterText;
  switch (declaration.kind) {
    case DeclarationKind.ENUM_CONSTANT:
      label = '${declaration.parent.name}.${declaration.name}';
      break;
    case DeclarationKind.GETTER:
    case DeclarationKind.FIELD:
      label = declaration.parent != null &&
              declaration.parent.name != null &&
              declaration.parent.name.isNotEmpty
          ? '${declaration.parent.name}.${declaration.name}'
          : declaration.name;
      break;
    case DeclarationKind.CONSTRUCTOR:
      label = declaration.parent.name;
      if (declaration.name.isNotEmpty) {
        label += '.${declaration.name}';
      }
      insertText = label;
      filterText = label;
      label += declaration.parameterNames?.isNotEmpty ?? false ? '(…)' : '()';
      break;
    case DeclarationKind.FUNCTION:
      label = declaration.name;
      insertText = label;
      filterText = label;
      label += declaration.parameterNames?.isNotEmpty ?? false ? '(…)' : '()';
      break;
    default:
      label = declaration.name;
  }

  final useDeprecated =
      completionCapabilities?.completionItem?.deprecatedSupport == true;

  final completionKind = declarationKindToCompletionItemKind(
      supportedCompletionItemKinds, declaration.kind);

  var relevanceBoost = 0;
  if (declaration.relevanceTags != null) {
    declaration.relevanceTags.forEach(
        (t) => relevanceBoost = max(relevanceBoost, tagBoosts[t] ?? 0));
  }
  final itemRelevance = includedSuggestionSet.relevance + relevanceBoost;

  // Because we potentially send thousands of these items, we should minimise
  // the generated JSON as much as possible - for example using nulls in place
  // of empty lists/false where possible.
  return lsp.CompletionItem(
    label: label,
    kind: completionKind,
    tags: null, // TODO(dantup): CompletionItemTags
    detail: getDeclarationCompletionDetail(
        declaration, completionKind, useDeprecated),
    deprecated: useDeprecated && declaration.isDeprecated ? true : null,
    // Relevance is a number, highest being best. LSP does text sort so subtract
    // from a large number so that a text sort will result in the correct order.
    // 555 -> 999455
    //  10 -> 999990
    //   1 -> 999999
    sortText: (1000000 - itemRelevance).toString(),
    filterText: filterText != label
        ? filterText
        : null, // filterText uses label if not set
    insertText: insertText != label
        ? insertText
        : null, // insertText uses label if not set
    // data, used for completionItem/resolve.
    data: lsp.CompletionItemResolutionInfo(
        file: file,
        offset: offset,
        libId: includedSuggestionSet.id,
        displayUri: includedSuggestionSet.displayUri ?? library.uri?.toString(),
        rOffset: replacementOffset,
        rLength: replacementLength),
  );
}

lsp.CompletionItemKind elementKindToCompletionItemKind(
  HashSet<lsp.CompletionItemKind> clientSupportedCompletionKinds,
  server.ElementKind kind,
) {
  bool isSupported(lsp.CompletionItemKind kind) =>
      clientSupportedCompletionKinds.contains(kind);

  List<lsp.CompletionItemKind> getKindPreferences() {
    switch (kind) {
      case server.ElementKind.CLASS:
      case server.ElementKind.CLASS_TYPE_ALIAS:
        return const [lsp.CompletionItemKind.Class];
      case server.ElementKind.COMPILATION_UNIT:
        return const [lsp.CompletionItemKind.Module];
      case server.ElementKind.CONSTRUCTOR:
      case server.ElementKind.CONSTRUCTOR_INVOCATION:
        return const [lsp.CompletionItemKind.Constructor];
      case server.ElementKind.ENUM:
      case server.ElementKind.ENUM_CONSTANT:
        return const [lsp.CompletionItemKind.Enum];
      case server.ElementKind.FIELD:
        return const [lsp.CompletionItemKind.Field];
      case server.ElementKind.FILE:
        return const [lsp.CompletionItemKind.File];
      case server.ElementKind.FUNCTION:
        return const [lsp.CompletionItemKind.Function];
      case server.ElementKind.FUNCTION_TYPE_ALIAS:
        return const [lsp.CompletionItemKind.Class];
      case server.ElementKind.GETTER:
        return const [lsp.CompletionItemKind.Property];
      case server.ElementKind.LABEL:
        // There isn't really a good CompletionItemKind for labels so we'll
        // just use the Text option.
        return const [lsp.CompletionItemKind.Text];
      case server.ElementKind.LIBRARY:
        return const [lsp.CompletionItemKind.Module];
      case server.ElementKind.LOCAL_VARIABLE:
        return const [lsp.CompletionItemKind.Variable];
      case server.ElementKind.METHOD:
        return const [lsp.CompletionItemKind.Method];
      case server.ElementKind.MIXIN:
        return const [lsp.CompletionItemKind.Class];
      case server.ElementKind.PARAMETER:
      case server.ElementKind.PREFIX:
        return const [lsp.CompletionItemKind.Variable];
      case server.ElementKind.SETTER:
        return const [lsp.CompletionItemKind.Property];
      case server.ElementKind.TOP_LEVEL_VARIABLE:
        return const [lsp.CompletionItemKind.Variable];
      case server.ElementKind.TYPE_PARAMETER:
        return const [
          lsp.CompletionItemKind.TypeParameter,
          lsp.CompletionItemKind.Variable,
        ];
      case server.ElementKind.UNIT_TEST_GROUP:
      case server.ElementKind.UNIT_TEST_TEST:
        return const [lsp.CompletionItemKind.Method];
      default:
        return const [];
    }
  }

  return getKindPreferences().firstWhere(isSupported, orElse: () => null);
}

lsp.SymbolKind elementKindToSymbolKind(
  HashSet<lsp.SymbolKind> clientSupportedSymbolKinds,
  server.ElementKind kind,
) {
  bool isSupported(lsp.SymbolKind kind) =>
      clientSupportedSymbolKinds.contains(kind);

  List<lsp.SymbolKind> getKindPreferences() {
    switch (kind) {
      case server.ElementKind.CLASS:
      case server.ElementKind.CLASS_TYPE_ALIAS:
        return const [lsp.SymbolKind.Class];
      case server.ElementKind.COMPILATION_UNIT:
        return const [lsp.SymbolKind.Module];
      case server.ElementKind.CONSTRUCTOR:
      case server.ElementKind.CONSTRUCTOR_INVOCATION:
        return const [lsp.SymbolKind.Constructor];
      case server.ElementKind.ENUM:
      case server.ElementKind.ENUM_CONSTANT:
        return const [lsp.SymbolKind.Enum];
      case server.ElementKind.EXTENSION:
        return const [lsp.SymbolKind.Namespace];
      case server.ElementKind.FIELD:
        return const [lsp.SymbolKind.Field];
      case server.ElementKind.FILE:
        return const [lsp.SymbolKind.File];
      case server.ElementKind.FUNCTION:
      case server.ElementKind.FUNCTION_INVOCATION:
        return const [lsp.SymbolKind.Function];
      case server.ElementKind.FUNCTION_TYPE_ALIAS:
        return const [lsp.SymbolKind.Class];
      case server.ElementKind.GETTER:
        return const [lsp.SymbolKind.Property];
      case server.ElementKind.LABEL:
        // There isn't really a good SymbolKind for labels so we'll
        // just use the Null option.
        return const [lsp.SymbolKind.Null];
      case server.ElementKind.LIBRARY:
        return const [lsp.SymbolKind.Namespace];
      case server.ElementKind.LOCAL_VARIABLE:
        return const [lsp.SymbolKind.Variable];
      case server.ElementKind.METHOD:
        return const [lsp.SymbolKind.Method];
      case server.ElementKind.MIXIN:
        return const [lsp.SymbolKind.Class];
      case server.ElementKind.PARAMETER:
      case server.ElementKind.PREFIX:
        return const [lsp.SymbolKind.Variable];
      case server.ElementKind.SETTER:
        return const [lsp.SymbolKind.Property];
      case server.ElementKind.TOP_LEVEL_VARIABLE:
        return const [lsp.SymbolKind.Variable];
      case server.ElementKind.TYPE_PARAMETER:
        return const [
          lsp.SymbolKind.TypeParameter,
          lsp.SymbolKind.Variable,
        ];
      case server.ElementKind.UNIT_TEST_GROUP:
      case server.ElementKind.UNIT_TEST_TEST:
        return const [lsp.SymbolKind.Method];
      default:
        // Assert that we only get here if kind=null. If it's anything else
        // then we're missing a mapping from above.
        assert(kind == null, 'Unexpected element kind $kind');
        return const [];
    }
  }

  // LSP requires we specify *some* kind, so in the case where the above code doesn't
  // match we'll just have to send a value to avoid a crash.
  return getKindPreferences()
      .firstWhere(isSupported, orElse: () => lsp.SymbolKind.Obj);
}

String getCompletionDetail(
  server.CompletionSuggestion suggestion,
  lsp.CompletionItemKind completionKind,
  bool clientSupportsDeprecated,
) {
  final hasElement = suggestion.element != null;
  final hasParameters = hasElement &&
      suggestion.element.parameters != null &&
      suggestion.element.parameters.isNotEmpty;
  final hasReturnType = hasElement &&
      suggestion.element.returnType != null &&
      suggestion.element.returnType.isNotEmpty;
  final hasParameterType =
      suggestion.parameterType != null && suggestion.parameterType.isNotEmpty;

  final prefix = clientSupportsDeprecated || !suggestion.isDeprecated
      ? ''
      : '(Deprecated) ';

  if (completionKind == lsp.CompletionItemKind.Property) {
    // Setters appear as methods with one arg but they also cause getters to not
    // appear in the completion list, so displaying them as setters is misleading.
    // To avoid this, always show only the return type, whether it's a getter
    // or a setter.
    return prefix +
        (suggestion.element.kind == server.ElementKind.GETTER
            ? suggestion.element.returnType
            // Don't assume setters always have parameters
            // See https://github.com/dart-lang/sdk/issues/27747
            : suggestion.element.parameters != null &&
                    suggestion.element.parameters.isNotEmpty
                // Extract the type part from '(MyType value)`
                ? suggestion.element.parameters.substring(
                    1, suggestion.element.parameters.lastIndexOf(' '))
                : '');
  } else if (hasParameters && hasReturnType) {
    return '$prefix${suggestion.element.parameters} → ${suggestion.element.returnType}';
  } else if (hasReturnType) {
    return '$prefix${suggestion.element.returnType}';
  } else if (hasParameterType) {
    return '$prefix${suggestion.parameterType}';
  } else {
    return prefix.isNotEmpty ? prefix : null;
  }
}

String getDeclarationCompletionDetail(
  dec.Declaration declaration,
  lsp.CompletionItemKind completionKind,
  bool clientSupportsDeprecated,
) {
  final hasParameters =
      declaration.parameters != null && declaration.parameters.isNotEmpty;
  final hasReturnType =
      declaration.returnType != null && declaration.returnType.isNotEmpty;

  final prefix = clientSupportsDeprecated || !declaration.isDeprecated
      ? ''
      : '(Deprecated) ';

  if (completionKind == lsp.CompletionItemKind.Property) {
    // Setters appear as methods with one arg but they also cause getters to not
    // appear in the completion list, so displaying them as setters is misleading.
    // To avoid this, always show only the return type, whether it's a getter
    // or a setter.
    var suffix = '';
    if (declaration.kind == dec.DeclarationKind.GETTER) {
      suffix = declaration.returnType;
    } else {
      // Don't assume setters always have parameters
      // See https://github.com/dart-lang/sdk/issues/27747
      if (declaration.parameters != null && declaration.parameters.isNotEmpty) {
        // Extract the type part from `(MyType value)`, if there is a type.
        var spaceIndex = declaration.parameters.lastIndexOf(' ');
        if (spaceIndex > 0) {
          suffix = declaration.parameters.substring(1, spaceIndex);
        }
      }
    }
    return prefix + suffix;
  } else if (hasParameters && hasReturnType) {
    return '$prefix${declaration.parameters} → ${declaration.returnType}';
  } else if (hasReturnType) {
    return '$prefix${declaration.returnType}';
  } else {
    return prefix.isNotEmpty ? prefix : null;
  }
}

bool isDartDocument(lsp.TextDocumentIdentifier doc) =>
    doc?.uri?.endsWith('.dart');

lsp.Location navigationTargetToLocation(String targetFilePath,
    server.NavigationTarget target, server.LineInfo lineInfo) {
  if (lineInfo == null) {
    return null;
  }

  return lsp.Location(
    uri: Uri.file(targetFilePath).toString(),
    range: toRange(lineInfo, target.offset, target.length),
  );
}

/// Returns the file system path for a TextDocumentIdentifier.
ErrorOr<String> pathOfDoc(lsp.TextDocumentIdentifier doc) =>
    pathOfUri(Uri.tryParse(doc?.uri));

/// Returns the file system path for a TextDocumentItem.
ErrorOr<String> pathOfDocItem(lsp.TextDocumentItem doc) =>
    pathOfUri(Uri.tryParse(doc?.uri));

/// Returns the file system path for a file URI.
ErrorOr<String> pathOfUri(Uri uri) {
  if (uri == null) {
    return ErrorOr<String>.error(ResponseError(
      code: lsp.ServerErrorCodes.InvalidFilePath,
      message: 'Document URI was not supplied',
    ));
  }
  final isValidFileUri = (uri?.isScheme('file') ?? false);
  if (!isValidFileUri) {
    return ErrorOr<String>.error(ResponseError(
      code: lsp.ServerErrorCodes.InvalidFilePath,
      message: 'URI was not a valid file:// URI',
      data: uri.toString(),
    ));
  }
  try {
    return ErrorOr<String>.success(uri.toFilePath());
  } catch (e) {
    // Even if tryParse() works and file == scheme, toFilePath() can throw on
    // Windows if there are invalid characters.
    return ErrorOr<String>.error(ResponseError(
        code: lsp.ServerErrorCodes.InvalidFilePath,
        message: 'File URI did not contain a valid file path',
        data: uri.toString()));
  }
}

lsp.Diagnostic pluginToDiagnostic(
  server.LineInfo Function(String) getLineInfo,
  plugin.AnalysisError error,
) {
  List<DiagnosticRelatedInformation> relatedInformation;
  if (error.contextMessages != null && error.contextMessages.isNotEmpty) {
    relatedInformation = error.contextMessages
        .map((message) =>
            pluginToDiagnosticRelatedInformation(getLineInfo, message))
        .toList();
  }

  var message = error.message;
  if (error.correction != null) {
    message = '$message\n${error.correction}';
  }

  var lineInfo = getLineInfo(error.location.file);
  return lsp.Diagnostic(
    range: toRange(lineInfo, error.location.offset, error.location.length),
    severity: pluginToDiagnosticSeverity(error.severity),
    code: error.code,
    source: languageSourceName,
    message: message,
    tags: null, // TODO(dantup): DiagnosticTags
    relatedInformation: relatedInformation,
  );
}

lsp.DiagnosticRelatedInformation pluginToDiagnosticRelatedInformation(
    server.LineInfo Function(String) getLineInfo,
    plugin.DiagnosticMessage message) {
  var file = message.location.file;
  var lineInfo = getLineInfo(file);
  return lsp.DiagnosticRelatedInformation(
      location: lsp.Location(
        uri: Uri.file(file).toString(),
        range: toRange(
          lineInfo,
          message.location.offset,
          message.location.length,
        ),
      ),
      message: message.message);
}

lsp.DiagnosticSeverity pluginToDiagnosticSeverity(
    plugin.AnalysisErrorSeverity severity) {
  switch (severity) {
    case plugin.AnalysisErrorSeverity.ERROR:
      return lsp.DiagnosticSeverity.Error;
    case plugin.AnalysisErrorSeverity.WARNING:
      return lsp.DiagnosticSeverity.Warning;
    case plugin.AnalysisErrorSeverity.INFO:
      return lsp.DiagnosticSeverity.Information;
    // Note: LSP also supports "Hint", but they won't render in things like the
    // VS Code errors list as they're apparently intended to communicate
    // non-visible diagnostics back (for example, if you wanted to grey out
    // unreachable code without producing an item in the error list).
    default:
      throw 'Unknown AnalysisErrorSeverity: $severity';
  }
}

lsp.Location searchResultToLocation(
    server.SearchResult result, server.LineInfo lineInfo) {
  final location = result.location;

  if (lineInfo == null) {
    return null;
  }

  return lsp.Location(
    uri: Uri.file(result.location.file).toString(),
    range: toRange(lineInfo, location.offset, location.length),
  );
}

lsp.CompletionItemKind suggestionKindToCompletionItemKind(
  HashSet<lsp.CompletionItemKind> clientSupportedCompletionKinds,
  server.CompletionSuggestionKind kind,
  String label,
) {
  bool isSupported(lsp.CompletionItemKind kind) =>
      clientSupportedCompletionKinds.contains(kind);

  List<lsp.CompletionItemKind> getKindPreferences() {
    switch (kind) {
      case server.CompletionSuggestionKind.ARGUMENT_LIST:
        return const [lsp.CompletionItemKind.Variable];
      case server.CompletionSuggestionKind.IMPORT:
        // For package/relative URIs, we can send File/Folder kinds for better icons.
        if (!label.startsWith('dart:')) {
          return label.endsWith('.dart')
              ? const [
                  lsp.CompletionItemKind.File,
                  lsp.CompletionItemKind.Module,
                ]
              : const [
                  lsp.CompletionItemKind.Folder,
                  lsp.CompletionItemKind.Module,
                ];
        }
        return const [lsp.CompletionItemKind.Module];
      case server.CompletionSuggestionKind.IDENTIFIER:
        return const [lsp.CompletionItemKind.Variable];
      case server.CompletionSuggestionKind.INVOCATION:
        return const [lsp.CompletionItemKind.Method];
      case server.CompletionSuggestionKind.KEYWORD:
        return const [lsp.CompletionItemKind.Keyword];
      case server.CompletionSuggestionKind.NAMED_ARGUMENT:
        return const [lsp.CompletionItemKind.Variable];
      case server.CompletionSuggestionKind.OPTIONAL_ARGUMENT:
        return const [lsp.CompletionItemKind.Variable];
      case server.CompletionSuggestionKind.PARAMETER:
        return const [lsp.CompletionItemKind.Value];
      default:
        return const [];
    }
  }

  return getKindPreferences().firstWhere(isSupported, orElse: () => null);
}

lsp.ClosingLabel toClosingLabel(
        server.LineInfo lineInfo, server.ClosingLabel label) =>
    lsp.ClosingLabel(
        range: toRange(lineInfo, label.offset, label.length),
        label: label.label);

CodeActionKind toCodeActionKind(String id, lsp.CodeActionKind fallback) {
  if (id == null) {
    return fallback;
  }
  // Dart fixes and assists start with "dart.assist." and "dart.fix." but in LSP
  // we want to use the predefined prefixes for CodeActions.
  final newId = id
      .replaceAll('dart.assist', CodeActionKind.Refactor.toString())
      .replaceAll('dart.fix', CodeActionKind.QuickFix.toString())
      .replaceAll('analysisOptions.assist', CodeActionKind.Refactor.toString())
      .replaceAll('analysisOptions.fix', CodeActionKind.QuickFix.toString());
  return CodeActionKind(newId);
}

lsp.CompletionItem toCompletionItem(
  lsp.CompletionClientCapabilities completionCapabilities,
  HashSet<lsp.CompletionItemKind> supportedCompletionItemKinds,
  server.LineInfo lineInfo,
  server.CompletionSuggestion suggestion,
  int replacementOffset,
  int replacementLength,
) {
  // Build display labels and text to insert. insertText and filterText may
  // differ from label (for ex. if the label includes things like (…)). If
  // either are missing then label will be used by the client.
  var label = suggestion.displayText ?? suggestion.completion;
  var insertText = suggestion.completion;
  var filterText = suggestion.completion;

  // Trim any trailing comma from the (displayed) label.
  if (label.endsWith(',')) {
    label = label.substring(0, label.length - 1);
  }

  if (suggestion.displayText == null) {
    switch (suggestion.element?.kind) {
      case server.ElementKind.CONSTRUCTOR:
      case server.ElementKind.FUNCTION:
      case server.ElementKind.METHOD:
        label += suggestion.parameterNames?.isNotEmpty ?? false ? '(…)' : '()';
        break;
    }
  }

  final useDeprecated =
      completionCapabilities?.completionItem?.deprecatedSupport == true;
  final formats = completionCapabilities?.completionItem?.documentationFormat;
  final supportsSnippets =
      completionCapabilities?.completionItem?.snippetSupport == true;

  final completionKind = suggestion.element != null
      ? elementKindToCompletionItemKind(
          supportedCompletionItemKinds, suggestion.element.kind)
      : suggestionKindToCompletionItemKind(
          supportedCompletionItemKinds, suggestion.kind, label);

  var insertTextFormat = lsp.InsertTextFormat.PlainText;
  if (supportsSnippets && suggestion.selectionOffset != 0) {
    insertTextFormat = lsp.InsertTextFormat.Snippet;
    insertText = buildSnippetStringWithSelection(
      suggestion.completion,
      suggestion.selectionOffset,
      suggestion.selectionLength,
    );
  }

  // Because we potentially send thousands of these items, we should minimise
  // the generated JSON as much as possible - for example using nulls in place
  // of empty lists/false where possible.
  return lsp.CompletionItem(
    label: label,
    kind: completionKind,
    tags: null, // TODO(dantup): CompletionItemTags
    detail: getCompletionDetail(suggestion, completionKind, useDeprecated),
    documentation:
        asStringOrMarkupContent(formats, cleanDartdoc(suggestion.docComplete)),
    deprecated: useDeprecated && suggestion.isDeprecated ? true : null,
    // Relevance is a number, highest being best. LSP does text sort so subtract
    // from a large number so that a text sort will result in the correct order.
    // 555 -> 999455
    //  10 -> 999990
    //   1 -> 999999
    sortText: (1000000 - suggestion.relevance).toString(),
    filterText: filterText != label
        ? filterText
        : null, // filterText uses label if not set
    insertText: insertText != label
        ? insertText
        : null, // insertText uses label if not set
    insertTextFormat: insertTextFormat != lsp.InsertTextFormat.PlainText
        ? insertTextFormat
        : null, // Defaults to PlainText if not supplied
    textEdit: lsp.TextEdit(
      range: toRange(lineInfo, replacementOffset, replacementLength),
      newText: insertText,
    ),
  );
}

lsp.Diagnostic toDiagnostic(
    server.ResolvedUnitResult result, server.AnalysisError error,
    [server.ErrorSeverity errorSeverity]) {
  var errorCode = error.errorCode;

  // Default to the error's severity if none is specified.
  errorSeverity ??= errorCode.errorSeverity;

  List<DiagnosticRelatedInformation> relatedInformation;
  if (error.contextMessages.isNotEmpty) {
    relatedInformation = error.contextMessages
        .map((message) => toDiagnosticRelatedInformation(result, message))
        .toList();
  }

  var message = error.message;
  if (error.correctionMessage != null) {
    message = '$message\n${error.correctionMessage}';
  }

  return lsp.Diagnostic(
    range: toRange(result.lineInfo, error.offset, error.length),
    severity: toDiagnosticSeverity(errorSeverity),
    code: errorCode.name.toLowerCase(),
    source: languageSourceName,
    message: message,
    tags: null, // TODO(dantup): DiagnosticTags
    relatedInformation: relatedInformation,
  );
}

lsp.DiagnosticRelatedInformation toDiagnosticRelatedInformation(
    server.ResolvedUnitResult result, analyzer.DiagnosticMessage message) {
  var file = message.filePath;
  var lineInfo = result.session.getFile(file).lineInfo;
  return lsp.DiagnosticRelatedInformation(
      location: lsp.Location(
        uri: Uri.file(file).toString(),
        range: toRange(
          lineInfo,
          message.offset,
          message.length,
        ),
      ),
      message: message.message);
}

lsp.DiagnosticSeverity toDiagnosticSeverity(server.ErrorSeverity severity) {
  switch (severity) {
    case server.ErrorSeverity.ERROR:
      return lsp.DiagnosticSeverity.Error;
    case server.ErrorSeverity.WARNING:
      return lsp.DiagnosticSeverity.Warning;
    case server.ErrorSeverity.INFO:
      return lsp.DiagnosticSeverity.Information;
    // Note: LSP also supports "Hint", but they won't render in things like the
    // VS Code errors list as they're apparently intended to communicate
    // non-visible diagnostics back (for example, if you wanted to grey out
    // unreachable code without producing an item in the error list).
    default:
      throw 'Unknown AnalysisErrorSeverity: $severity';
  }
}

lsp.Element toElement(server.LineInfo lineInfo, server.Element element) =>
    lsp.Element(
      range: element.location != null
          ? toRange(lineInfo, element.location.offset, element.location.length)
          : null,
      name: toElementName(element),
      kind: element.kind.name,
      parameters: element.parameters,
      typeParameters: element.typeParameters,
      returnType: element.returnType,
    );

String toElementName(server.Element element) {
  return element.name != null && element.name != ''
      ? element.name
      : (element.kind == server.ElementKind.EXTENSION
          ? '<unnamed extension>'
          : '<unnamed>');
}

lsp.FlutterOutline toFlutterOutline(
        server.LineInfo lineInfo, server.FlutterOutline outline) =>
    lsp.FlutterOutline(
      kind: outline.kind.name,
      label: outline.label,
      className: outline.className,
      variableName: outline.variableName,
      attributes: outline.attributes != null
          ? outline.attributes
              .map(
                  (attribute) => toFlutterOutlineAttribute(lineInfo, attribute))
              .toList()
          : null,
      dartElement: outline.dartElement != null
          ? toElement(lineInfo, outline.dartElement)
          : null,
      range: toRange(lineInfo, outline.offset, outline.length),
      codeRange: toRange(lineInfo, outline.codeOffset, outline.codeLength),
      children: outline.children != null
          ? outline.children.map((c) => toFlutterOutline(lineInfo, c)).toList()
          : null,
    );

lsp.FlutterOutlineAttribute toFlutterOutlineAttribute(
        server.LineInfo lineInfo, server.FlutterOutlineAttribute attribute) =>
    lsp.FlutterOutlineAttribute(
        name: attribute.name,
        label: attribute.label,
        valueRange: attribute.valueLocation != null
            ? toRange(lineInfo, attribute.valueLocation.offset,
                attribute.valueLocation.length)
            : null);

lsp.FoldingRange toFoldingRange(
    server.LineInfo lineInfo, server.FoldingRegion region) {
  final range = toRange(lineInfo, region.offset, region.length);
  return lsp.FoldingRange(
      startLine: range.start.line,
      startCharacter: range.start.character,
      endLine: range.end.line,
      endCharacter: range.end.character,
      kind: toFoldingRangeKind(region.kind));
}

lsp.FoldingRangeKind toFoldingRangeKind(server.FoldingKind kind) {
  switch (kind) {
    case server.FoldingKind.DOCUMENTATION_COMMENT:
    case server.FoldingKind.FILE_HEADER:
      return lsp.FoldingRangeKind.Comment;
    case server.FoldingKind.DIRECTIVES:
      return lsp.FoldingRangeKind.Imports;
    default:
      // null (actually undefined in LSP, the toJson() takes care of that) is
      // valid, and actually the value used for the majority of folds
      // (class/functions/etc.).
      return null;
  }
}

List<lsp.DocumentHighlight> toHighlights(
    server.LineInfo lineInfo, server.Occurrences occurrences) {
  return occurrences.offsets
      .map((offset) => lsp.DocumentHighlight(
          range: toRange(lineInfo, offset, occurrences.length)))
      .toList();
}

lsp.Location toLocation(server.Location location, server.LineInfo lineInfo) =>
    lsp.Location(
      uri: Uri.file(location.file).toString(),
      range: toRange(
        lineInfo,
        location.offset,
        location.length,
      ),
    );

ErrorOr<int> toOffset(
  server.LineInfo lineInfo,
  lsp.Position pos, {
  failureIsCritial = false,
}) {
  if (pos.line > lineInfo.lineCount) {
    return ErrorOr<int>.error(lsp.ResponseError(
        code: failureIsCritial
            ? lsp.ServerErrorCodes.ClientServerInconsistentState
            : lsp.ServerErrorCodes.InvalidFileLineCol,
        message: 'Invalid line number',
        data: pos.line.toString()));
  }
  // TODO(dantup): Is there any way to validate the character? We could ensure
  // it's less than the offset of the next line, but that would only work for
  // all lines except the last one.
  return ErrorOr<int>.success(
      lineInfo.getOffsetOfLine(pos.line) + pos.character);
}

lsp.Outline toOutline(server.LineInfo lineInfo, server.Outline outline) =>
    lsp.Outline(
      element: toElement(lineInfo, outline.element),
      range: toRange(lineInfo, outline.offset, outline.length),
      codeRange: toRange(lineInfo, outline.codeOffset, outline.codeLength),
      children: outline.children != null
          ? outline.children.map((c) => toOutline(lineInfo, c)).toList()
          : null,
    );

lsp.Position toPosition(server.CharacterLocation location) {
  // LSP is zero-based, but analysis server is 1-based.
  return lsp.Position(
      line: location.lineNumber - 1, character: location.columnNumber - 1);
}

lsp.Range toRange(server.LineInfo lineInfo, int offset, int length) {
  server.CharacterLocation start = lineInfo.getLocation(offset);
  server.CharacterLocation end = lineInfo.getLocation(offset + length);

  return lsp.Range(
    start: toPosition(start),
    end: toPosition(end),
  );
}

lsp.SignatureHelp toSignatureHelp(List<lsp.MarkupKind> preferredFormats,
    server.AnalysisGetSignatureResult signature) {
  // For now, we only support returning one (though we may wish to use named
  // args. etc. to provide one for each possible "next" option when the cursor
  // is at the end ready to provide another argument).

  /// Gets the label for an individual parameter in the form
  ///     String s = 'foo'
  String getParamLabel(server.ParameterInfo p) {
    final def = p.defaultValue != null ? ' = ${p.defaultValue}' : '';
    return '${p.type} ${p.name}$def';
  }

  /// Gets the full signature label in the form
  ///     foo(String s, int i, bool a = true)
  String getSignatureLabel(server.AnalysisGetSignatureResult resp) {
    final req = signature.parameters
        .where((p) => p.kind == server.ParameterKind.REQUIRED)
        .toList();
    final opt = signature.parameters
        .where((p) => p.kind == server.ParameterKind.OPTIONAL)
        .toList();
    final named = signature.parameters
        .where((p) => p.kind == server.ParameterKind.NAMED)
        .toList();
    final params = [];
    if (req.isNotEmpty) {
      params.add(req.map(getParamLabel).join(', '));
    }
    if (opt.isNotEmpty) {
      params.add('[' + opt.map(getParamLabel).join(', ') + ']');
    }
    if (named.isNotEmpty) {
      params.add('{' + named.map(getParamLabel).join(', ') + '}');
    }
    return '${resp.name}(${params.join(", ")})';
  }

  lsp.ParameterInformation toParameterInfo(server.ParameterInfo param) {
    // LSP 3.14.0 supports providing label offsets (to avoid clients having
    // to guess based on substrings). We should check the
    // signatureHelp.signatureInformation.parameterInformation.labelOffsetSupport
    // capability when deciding to send that.
    return lsp.ParameterInformation(label: getParamLabel(param));
  }

  final cleanDoc = cleanDartdoc(signature.dartdoc);

  return lsp.SignatureHelp(
    signatures: [
      lsp.SignatureInformation(
        label: getSignatureLabel(signature),
        documentation: asStringOrMarkupContent(preferredFormats, cleanDoc),
        parameters: signature.parameters.map(toParameterInfo).toList(),
      ),
    ],
    activeSignature: 0, // activeSignature
    // TODO(dantup): The LSP spec says this value will default to 0 if it's
    // not supplied or outside of the value range. However, setting -1 results
    // in no parameters being selected in VS Code, whereas null/0 will select the first.
    // We'd like for none to be selected (since we don't support this yet) so
    // we send -1. I've made a request for LSP to support not selecting a parameter
    // (because you could also be on param 5 of an invalid call to a function
    // taking only 3 arguments) here:
    // https://github.com/Microsoft/language-server-protocol/issues/456#issuecomment-452318297
    activeParameter: -1, // activeParameter
  );
}

lsp.TextDocumentEdit toTextDocumentEdit(FileEditInformation edit) {
  return lsp.TextDocumentEdit(
    textDocument: edit.doc,
    edits: edit.edits.map((e) => toTextEdit(edit.lineInfo, e)).toList(),
  );
}

lsp.TextEdit toTextEdit(server.LineInfo lineInfo, server.SourceEdit edit) {
  return lsp.TextEdit(
    range: toRange(lineInfo, edit.offset, edit.length),
    newText: edit.replacement,
  );
}

lsp.WorkspaceEdit toWorkspaceEdit(
  lsp.ClientCapabilitiesWorkspace capabilities,
  List<FileEditInformation> edits,
) {
  final clientSupportsTextDocumentEdits =
      capabilities?.workspaceEdit?.documentChanges == true;
  if (clientSupportsTextDocumentEdits) {
    return lsp.WorkspaceEdit(
        documentChanges: Either2<
            List<lsp.TextDocumentEdit>,
            List<
                Either4<lsp.TextDocumentEdit, lsp.CreateFile, lsp.RenameFile,
                    lsp.DeleteFile>>>.t1(
      edits.map(toTextDocumentEdit).toList(),
    ));
  } else {
    return lsp.WorkspaceEdit(changes: toWorkspaceEditChanges(edits));
  }
}

Map<String, List<lsp.TextEdit>> toWorkspaceEditChanges(
    List<FileEditInformation> edits) {
  MapEntry<String, List<lsp.TextEdit>> createEdit(FileEditInformation file) {
    final edits =
        file.edits.map((edit) => toTextEdit(file.lineInfo, edit)).toList();
    return MapEntry(file.doc.uri, edits);
  }

  return Map<String, List<lsp.TextEdit>>.fromEntries(edits.map(createEdit));
}

lsp.MarkupContent _asMarkup(
    List<lsp.MarkupKind> preferredFormats, String content) {
  // It's not valid to call this function with a null format, as null formats
  // do not support MarkupContent. [asStringOrMarkupContent] is probably the
  // better choice.
  assert(preferredFormats != null);

  if (content == null) {
    return null;
  }

  if (preferredFormats.isEmpty) {
    preferredFormats.add(lsp.MarkupKind.Markdown);
  }

  final supportsMarkdown = preferredFormats.contains(lsp.MarkupKind.Markdown);
  final supportsPlain = preferredFormats.contains(lsp.MarkupKind.PlainText);
  // Since our PlainText version is actually just Markdown, only advertise it
  // as PlainText if the client explicitly supports PlainText and not Markdown.
  final format = supportsPlain && !supportsMarkdown
      ? lsp.MarkupKind.PlainText
      : lsp.MarkupKind.Markdown;

  return lsp.MarkupContent(kind: format, value: content);
}
