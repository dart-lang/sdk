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
import 'package:analyzer/dart/analysis/results.dart' as server;
import 'package:analyzer/error/error.dart' as server;
import 'package:analyzer/source/line_info.dart' as server;
import 'package:analyzer/src/dart/analysis/search.dart' as server
    show DeclarationKind;
import 'package:analyzer/src/generated/source.dart' as server;
import 'package:analyzer/src/services/available_declarations.dart';
import 'package:analyzer/src/services/available_declarations.dart' as dec;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart' as server;

const languageSourceName = 'dart';

lsp.Either2<String, lsp.MarkupContent> asStringOrMarkupContent(
    List<lsp.MarkupKind> preferredFormats, String content) {
  if (content == null) {
    return null;
  }

  return preferredFormats == null
      ? new lsp.Either2<String, lsp.MarkupContent>.t1(content)
      : new lsp.Either2<String, lsp.MarkupContent>.t2(
          _asMarkup(preferredFormats, content));
}

/// Note: This code will fetch the version of each document being modified so
/// it's important to call this immediately after computing edits to ensure
/// the document is not modified before the version number is read.
lsp.WorkspaceEdit createWorkspaceEdit(
    lsp.LspAnalysisServer server, List<server.SourceFileEdit> edits) {
  return toWorkspaceEdit(
      server.clientCapabilities?.workspace,
      edits
          .map((e) => new FileEditInformation(
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
        assert(false, 'Unexpected declaration kind $kind');
        return const [];
    }
  }

  return getKindPreferences().firstWhere(isSupported, orElse: () => null);
}

lsp.CompletionItem declarationToCompletionItem(
  lsp.TextDocumentClientCapabilitiesCompletion completionCapabilities,
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
  // Build display labels and text to insert. insertText may differ from label
  // if the label includes things like (…).
  String label;
  String insertText;
  switch (declaration.kind) {
    case DeclarationKind.ENUM_CONSTANT:
      label = '${declaration.parent.name}.${declaration.name}';
      break;
    case DeclarationKind.CONSTRUCTOR:
      label = declaration.parent.name;
      if (declaration.name.isNotEmpty) {
        label += '.${declaration.name}';
      }
      insertText = label;
      label += declaration.parameterNames?.isNotEmpty ?? false ? '(…)' : '()';
      break;
    case DeclarationKind.FUNCTION:
      label = declaration.name;
      insertText = label;
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
  if (declaration.relevanceTags != null)
    declaration.relevanceTags.forEach(
        (t) => relevanceBoost = max(relevanceBoost, tagBoosts[t] ?? 0));
  final itemRelevance = includedSuggestionSet.relevance + relevanceBoost;

  // Because we potentially send thousands of these items, we should minimise
  // the generated JSON as much as possible - for example using nulls in place
  // of empty lists/false where possible.
  return new lsp.CompletionItem(
    label,
    completionKind,
    getDeclarationCompletionDetail(declaration, completionKind, useDeprecated),
    null, // documentation - will be added during resolve.
    useDeprecated && declaration.isDeprecated ? true : null,
    null, // preselect
    // Relevance is a number, highest being best. LSP does text sort so subtract
    // from a large number so that a text sort will result in the correct order.
    // 555 -> 999455
    //  10 -> 999990
    //   1 -> 999999
    (1000000 - itemRelevance).toString(),
    null, // filterText uses label if not set
    insertText, // insertText uses label if not set
    null, // insertTextFormat (we always use plain text so can ommit this)
    null, // textEdit - added on during resolve
    null, // additionalTextEdits, used for adding imports, etc.
    null, // commitCharacters
    null, // command
    // data, used for completionItem/resolve.
    new lsp.CompletionItemResolutionInfo(
        file,
        offset,
        includedSuggestionSet.id,
        includedSuggestionSet.displayUri ?? library.uri?.toString(),
        replacementOffset,
        replacementLength),
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
        assert(false, 'Unexpected element kind $kind');
        return const [];
    }
  }

  return getKindPreferences().firstWhere(isSupported, orElse: () => null);
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
                    1, suggestion.element.parameters.lastIndexOf(" "))
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
    return prefix +
        (declaration.kind == dec.DeclarationKind.GETTER
            ? declaration.returnType
            // Don't assume setters always have parameters
            // See https://github.com/dart-lang/sdk/issues/27747
            : declaration.parameters != null &&
                    declaration.parameters.isNotEmpty
                // Extract the type part from '(MyType value)`
                ? declaration.parameters
                    .substring(1, declaration.parameters.lastIndexOf(" "))
                : '');
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

  return new lsp.Location(
    Uri.file(targetFilePath).toString(),
    toRange(lineInfo, target.offset, target.length),
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
    return new ErrorOr<String>.error(new ResponseError(
        lsp.ServerErrorCodes.InvalidFilePath,
        'Document URI was not supplied',
        null));
  }
  final isValidFileUri = (uri?.isScheme('file') ?? false);
  if (!isValidFileUri) {
    return new ErrorOr<String>.error(new ResponseError(
        lsp.ServerErrorCodes.InvalidFilePath,
        'URI was not a valid file:// URI',
        uri.toString()));
  }
  try {
    return new ErrorOr<String>.success(uri.toFilePath());
  } catch (e) {
    // Even if tryParse() works and file == scheme, toFilePath() can throw on
    // Windows if there are invalid characters.
    return new ErrorOr<String>.error(new ResponseError(
        lsp.ServerErrorCodes.InvalidFilePath,
        'File URI did not contain a valid file path',
        uri.toString()));
  }
}

lsp.Location searchResultToLocation(
    server.SearchResult result, server.LineInfo lineInfo) {
  final location = result.location;

  if (lineInfo == null) {
    return null;
  }

  return new lsp.Location(
    Uri.file(result.location.file).toString(),
    toRange(lineInfo, location.offset, location.length),
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
        toRange(lineInfo, label.offset, label.length), label.label);

lsp.CompletionItem toCompletionItem(
  lsp.TextDocumentClientCapabilitiesCompletion completionCapabilities,
  HashSet<lsp.CompletionItemKind> supportedCompletionItemKinds,
  server.LineInfo lineInfo,
  server.CompletionSuggestion suggestion,
  int replacementOffset,
  int replacementLength,
) {
  // Build display labels and text to insert. insertText may differ from label
  // if the label includes things like (…). If insertText is left as null then
  // label is used.
  String label;
  String insertText;
  if (suggestion.displayText != null) {
    label = suggestion.displayText;
    insertText = suggestion.completion;
  } else {
    switch (suggestion.element?.kind) {
      case server.ElementKind.CONSTRUCTOR:
      case server.ElementKind.FUNCTION:
      case server.ElementKind.METHOD:
        label = suggestion.completion;
        // Label is the insert text plus the parens to indicate it's callable.
        insertText = label;
        label += suggestion.parameterNames?.isNotEmpty ?? false ? '(…)' : '()';
        break;
      default:
        label = suggestion.completion;
    }
  }

  final useDeprecated =
      completionCapabilities?.completionItem?.deprecatedSupport == true;
  final formats = completionCapabilities?.completionItem?.documentationFormat;

  final completionKind = suggestion.element != null
      ? elementKindToCompletionItemKind(
          supportedCompletionItemKinds, suggestion.element.kind)
      : suggestionKindToCompletionItemKind(
          supportedCompletionItemKinds, suggestion.kind, label);

  // Because we potentially send thousands of these items, we should minimise
  // the generated JSON as much as possible - for example using nulls in place
  // of empty lists/false where possible.
  return new lsp.CompletionItem(
    label,
    completionKind,
    getCompletionDetail(suggestion, completionKind, useDeprecated),
    asStringOrMarkupContent(formats, cleanDartdoc(suggestion.docComplete)),
    useDeprecated && suggestion.isDeprecated ? true : null,
    null, // preselect
    // Relevance is a number, highest being best. LSP does text sort so subtract
    // from a large number so that a text sort will result in the correct order.
    // 555 -> 999455
    //  10 -> 999990
    //   1 -> 999999
    (1000000 - suggestion.relevance).toString(),
    null, // filterText uses label if not set
    insertText != label ? insertText : null, // insertText uses label if not set
    null, // insertTextFormat (we always use plain text so can ommit this)
    new lsp.TextEdit(
      // TODO(dantup): If `clientSupportsSnippets == true` then we should map
      // `selection` in to a snippet (see how Dart Code does this).
      toRange(lineInfo, replacementOffset, replacementLength),
      suggestion.completion,
    ),
    null, // additionalTextEdits, used for adding imports, etc.
    null, // commitCharacters
    null, // command
    null, // data, useful for if using lazy resolve, this comes back to us
  );
}

lsp.Diagnostic toDiagnostic(
    server.LineInfo lineInfo, server.AnalysisError error,
    [server.ErrorSeverity errorSeverity]) {
  server.ErrorCode errorCode = error.errorCode;

  // Default to the error's severity if none is specified.
  errorSeverity ??= errorCode.errorSeverity;

  return new lsp.Diagnostic(
    toRange(lineInfo, error.offset, error.length),
    toDiagnosticSeverity(errorSeverity),
    errorCode.name.toLowerCase(),
    languageSourceName,
    error.message,
    null,
  );
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

lsp.FoldingRange toFoldingRange(
    server.LineInfo lineInfo, server.FoldingRegion region) {
  final range = toRange(lineInfo, region.offset, region.length);
  return new lsp.FoldingRange(range.start.line, range.start.character,
      range.end.line, range.end.character, toFoldingRangeKind(region.kind));
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
      .map((offset) => new lsp.DocumentHighlight(
          toRange(lineInfo, offset, occurrences.length), null))
      .toList();
}

lsp.Location toLocation(server.Location location, server.LineInfo lineInfo) =>
    lsp.Location(
      Uri.file(location.file).toString(),
      toRange(
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
    return new ErrorOr<int>.error(new lsp.ResponseError(
        failureIsCritial
            ? lsp.ServerErrorCodes.ClientServerInconsistentState
            : lsp.ServerErrorCodes.InvalidFileLineCol,
        'Invalid line number',
        pos.line.toString()));
  }
  // TODO(dantup): Is there any way to validate the character? We could ensure
  // it's less than the offset of the next line, but that would only work for
  // all lines except the last one.
  return new ErrorOr<int>.success(
      lineInfo.getOffsetOfLine(pos.line) + pos.character);
}

lsp.Position toPosition(server.CharacterLocation location) {
  // LSP is zero-based, but analysis server is 1-based.
  return new lsp.Position(location.lineNumber - 1, location.columnNumber - 1);
}

lsp.Range toRange(server.LineInfo lineInfo, int offset, int length) {
  server.CharacterLocation start = lineInfo.getLocation(offset);
  server.CharacterLocation end = lineInfo.getLocation(offset + length);

  return new lsp.Range(
    toPosition(start),
    toPosition(end),
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
      params.add(req.map(getParamLabel).join(", "));
    }
    if (opt.isNotEmpty) {
      params.add("[" + opt.map(getParamLabel).join(", ") + "]");
    }
    if (named.isNotEmpty) {
      params.add("{" + named.map(getParamLabel).join(", ") + "}");
    }
    return '${resp.name}(${params.join(", ")})';
  }

  lsp.ParameterInformation toParameterInfo(server.ParameterInfo param) {
    // LSP 3.14.0 supports providing label offsets (to avoid clients having
    // to guess based on substrings). We should check the
    // signatureHelp.signatureInformation.parameterInformation.labelOffsetSupport
    // capability when deciding to send that.
    return new lsp.ParameterInformation(getParamLabel(param), null);
  }

  final cleanDoc = cleanDartdoc(signature.dartdoc);

  return new lsp.SignatureHelp(
    [
      new lsp.SignatureInformation(
        getSignatureLabel(signature),
        asStringOrMarkupContent(preferredFormats, cleanDoc),
        signature.parameters.map(toParameterInfo).toList(),
      ),
    ],
    0, // activeSignature
    // TODO(dantup): The LSP spec says this value will default to 0 if it's
    // not supplied or outside of the value range. However, setting -1 results
    // in no parameters being selected in VS Code, whereas null/0 will select the first.
    // We'd like for none to be selected (since we don't support this yet) so
    // we send -1. I've made a request for LSP to support not selecting a parameter
    // (because you could also be on param 5 of an invalid call to a function
    // taking only 3 arguments) here:
    // https://github.com/Microsoft/language-server-protocol/issues/456#issuecomment-452318297
    -1, // activeParameter
  );
}

lsp.TextDocumentEdit toTextDocumentEdit(FileEditInformation edit) {
  return new lsp.TextDocumentEdit(
    edit.doc,
    edit.edits.map((e) => toTextEdit(edit.lineInfo, e)).toList(),
  );
}

lsp.TextEdit toTextEdit(server.LineInfo lineInfo, server.SourceEdit edit) {
  return new lsp.TextEdit(
    toRange(lineInfo, edit.offset, edit.length),
    edit.replacement,
  );
}

lsp.WorkspaceEdit toWorkspaceEdit(
  lsp.WorkspaceClientCapabilities capabilities,
  List<FileEditInformation> edits,
) {
  final clientSupportsTextDocumentEdits =
      capabilities?.workspaceEdit?.documentChanges == true;
  if (clientSupportsTextDocumentEdits) {
    return new lsp.WorkspaceEdit(
        null,
        Either2<
            List<lsp.TextDocumentEdit>,
            List<
                Either4<lsp.TextDocumentEdit, lsp.CreateFile, lsp.RenameFile,
                    lsp.DeleteFile>>>.t1(
          edits.map(toTextDocumentEdit).toList(),
        ));
  } else {
    return new lsp.WorkspaceEdit(toWorkspaceEditChanges(edits), null);
  }
}

Map<String, List<lsp.TextEdit>> toWorkspaceEditChanges(
    List<FileEditInformation> edits) {
  createEdit(FileEditInformation file) {
    final edits =
        file.edits.map((edit) => toTextEdit(file.lineInfo, edit)).toList();
    return new MapEntry(file.doc.uri, edits);
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

  return new lsp.MarkupContent(format, content);
}
