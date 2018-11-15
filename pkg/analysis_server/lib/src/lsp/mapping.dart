import 'dart:collection';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart' as lsp;
import 'package:analysis_server/lsp_protocol/protocol_special.dart' as lsp;
import 'package:analysis_server/src/lsp/dartdoc.dart';
import 'package:analysis_server/src/protocol_server.dart' as server
    hide AnalysisError;
import 'package:analyzer/error/error.dart' as server;
import 'package:analyzer/source/line_info.dart' as server;
import 'package:analyzer/src/generated/source.dart' as server;

const languageSourceName = 'dart';

lsp.MarkupContent asMarkdown(String content) => content == null
    ? null
    : new lsp.MarkupContent(lsp.MarkupKind.Markdown, content);

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
      case server.ElementKind.FUNCTION_TYPE_ALIAS:
        return const [lsp.CompletionItemKind.Function];
      case server.ElementKind.GETTER:
        return const [lsp.CompletionItemKind.Property];
      case server.ElementKind.LABEL:
      case server.ElementKind.LIBRARY:
        return const [lsp.CompletionItemKind.Module];
      case server.ElementKind.LOCAL_VARIABLE:
        return const [lsp.CompletionItemKind.Variable];
      case server.ElementKind.METHOD:
        return const [lsp.CompletionItemKind.Method];
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
        return const [lsp.CompletionItemKind.Module];
      case server.ElementKind.UNIT_TEST_TEST:
        return const [lsp.CompletionItemKind.Method];
      default:
        return null;
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
    return prefix;
  }
}

/// Returns the file system path for a TextDocumentIdentifier.
String pathOf(lsp.TextDocumentIdentifier doc) =>
    Uri.parse(doc.uri).toFilePath();

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
        return null;
    }
  }

  return getKindPreferences().firstWhere(isSupported, orElse: () => null);
}

lsp.CompletionItem toCompletionItem(
  lsp.TextDocumentClientCapabilitiesCompletion completionCapabilities,
  HashSet<lsp.CompletionItemKind> supportedCompletionItemKinds,
  server.LineInfo lineInfo,
  server.CompletionSuggestion suggestion,
  int replacementOffset,
  int replacementLength,
) {
  final label = suggestion.displayText != null
      ? suggestion.displayText
      : suggestion.completion;

  final clientSupportsSnippets = completionCapabilities != null &&
      completionCapabilities.completionItem != null &&
      completionCapabilities.completionItem.snippetSupport == true;

  final clientSupportsDeprecated = completionCapabilities != null &&
      completionCapabilities.completionItem != null &&
      completionCapabilities.completionItem.deprecatedSupport == true;

  final completionKind = suggestion.element != null
      ? elementKindToCompletionItemKind(
          supportedCompletionItemKinds, suggestion.element.kind)
      : suggestionKindToCompletionItemKind(
          supportedCompletionItemKinds, suggestion.kind, label);

  return new lsp.CompletionItem(
    label,
    completionKind,
    getCompletionDetail(suggestion, completionKind, clientSupportsDeprecated),
    // TODO(dantup): completionItem.documentationFormat from ClientCapabilities
    lsp.Either2<String, lsp.MarkupContent>.t2(
        asMarkdown(cleanDartdoc(suggestion.docComplete))),
    clientSupportsDeprecated ? suggestion.isDeprecated : null,
    false, // preselect
    // Relevance is a number, highest being best. LSP does text sort so subtract
    // from a large number so that a text sort will result in the correct order.
    // 555 -> 999455
    //  10 -> 999990
    //   1 -> 999999
    (1000000 - suggestion.relevance).toString(),
    null, // filterText uses label if not set
    null, // insertText is deprecated, but also uses label if not set
    clientSupportsSnippets
        ? lsp.InsertTextFormat.Snippet
        : lsp.InsertTextFormat.PlainText,
    new lsp.TextEdit(
      // TODO(dantup): If `clientSupportsSnippets == true` then we should map
      // `selection` in to a snippet (see how Dart Code does this).
      toRange(lineInfo, replacementOffset, replacementLength),
      suggestion.completion,
    ),
    [], // additionalTextEdits, used for adding imports, etc.
    [], // commitCharacters
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
    // TODO(dantup): We should strip these union types in places where we know
    // we'll only generate one set from the server to simplify this code. We only
    // need to keep unions where the value may be either (eg. originates
    // from the client).
    lsp.Either2<num, String>.t2(errorCode.name.toLowerCase()),
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
