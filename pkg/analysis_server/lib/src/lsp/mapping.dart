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
import 'package:analysis_server/src/lsp/constants.dart';
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
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart' as server;
import 'package:analyzer/src/services/available_declarations.dart';
import 'package:analyzer/src/services/available_declarations.dart' as dec;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/utilities/pair.dart';
import 'package:meta/meta.dart';

const diagnosticTagsForErrorCode = <server.ErrorCode, List<lsp.DiagnosticTag>>{
  HintCode.DEAD_CODE: [lsp.DiagnosticTag.Unnecessary],
  HintCode.DEPRECATED_MEMBER_USE: [lsp.DiagnosticTag.Deprecated],
  HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE: [
    lsp.DiagnosticTag.Deprecated
  ],
  HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE: [
    lsp.DiagnosticTag.Deprecated
  ],
  HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE: [lsp.DiagnosticTag.Deprecated],
};

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

/// Builds an LSP snippet string with supplied ranges as tabstops.
String buildSnippetStringWithTabStops(
  String text,
  List<int> offsetLengthPairs,
) {
  text ??= '';
  offsetLengthPairs ??= const [];

  String escape(String input) => input.replaceAllMapped(
        RegExp(r'[$}\\]'), // Replace any of $ } \
        (c) => '\\${c[0]}', // Prefix with a backslash
      );

  // Snippets syntax is documented in the LSP spec:
  // https://microsoft.github.io/language-server-protocol/specifications/specification-current/#snippet_syntax
  //
  // $1, $2, etc. are used for tab stops and ${1:foo} inserts a placeholder of foo.

  final output = [];
  var offset = 0;

  // When there's only a single tabstop, it should be ${0} as this is treated
  // specially as the final cursor position (if we use 1, the editor will insert
  // a 0 at the end of the string which is not what we expect).
  // When there are multiple, start with ${1} since these are placeholders the
  // user can tab through and the editor-inserted ${0} at the end is expected.
  var tabStopNumber = offsetLengthPairs.length <= 2 ? 0 : 1;

  for (var i = 0; i < offsetLengthPairs.length; i += 2) {
    final pairOffset = offsetLengthPairs[i];
    final pairLength = offsetLengthPairs[i + 1];

    // Add any text that came before this tabstop to the result.
    output.add(escape(text.substring(offset, pairOffset)));

    // Add this tabstop
    final tabStopText =
        escape(text.substring(pairOffset, pairOffset + pairLength));
    output.add('\${${tabStopNumber++}:$tabStopText}');

    offset = pairOffset + pairLength;
  }

  // Add any remaining text that was after the last tabstop.
  output.add(escape(text.substring(offset)));

  return output.join('');
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
        return const [lsp.SymbolKind.Enum];
      case server.DeclarationKind.ENUM_CONSTANT:
        return const [lsp.SymbolKind.EnumMember, lsp.SymbolKind.Enum];
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
  int replacementLength, {
  @required bool includeCommitCharacters,
  @required bool completeFunctionCalls,
}) {
  final supportsSnippets =
      completionCapabilities?.completionItem?.snippetSupport == true;

  String completion;
  switch (declaration.kind) {
    case DeclarationKind.ENUM_CONSTANT:
      completion = '${declaration.parent.name}.${declaration.name}';
      break;
    case DeclarationKind.GETTER:
    case DeclarationKind.FIELD:
      completion = declaration.parent != null &&
              declaration.parent.name != null &&
              declaration.parent.name.isNotEmpty
          ? '${declaration.parent.name}.${declaration.name}'
          : declaration.name;
      break;
    case DeclarationKind.CONSTRUCTOR:
      completion = declaration.parent.name;
      if (declaration.name.isNotEmpty) {
        completion += '.${declaration.name}';
      }
      break;
    default:
      completion = declaration.name;
      break;
  }
  // By default, label is the same as the completion text, but may be added to
  // later (parens/snippets).
  var label = completion;

  // isCallable is used to suffix the label with parens so it's clear the item
  // is callable.
  final declarationKind = declaration.kind;
  final isCallable = declarationKind == DeclarationKind.CONSTRUCTOR ||
      declarationKind == DeclarationKind.FUNCTION ||
      declarationKind == DeclarationKind.METHOD;

  if (isCallable) {
    label += declaration.parameterNames?.isNotEmpty ?? false ? '(…)' : '()';
  }

  final insertTextInfo = _buildInsertText(
    supportsSnippets: supportsSnippets,
    includeCommitCharacters: includeCommitCharacters,
    completeFunctionCalls: completeFunctionCalls,
    isCallable: isCallable,
    // For SuggestionSets, we don't have a CompletionKind to check if it's
    // an invocation, but since they do not show in show/hide combinators
    // we can assume if an item is callable it's probably being used in a context
    // that can invoke it.
    isInvocation: isCallable,
    defaultArgumentListString: declaration.defaultArgumentListString,
    defaultArgumentListTextRanges: declaration.defaultArgumentListTextRanges,
    completion: completion,
    selectionOffset: 0,
    selectionLength: 0,
  );
  final insertText = insertTextInfo.first;
  final insertTextFormat = insertTextInfo.last;

  final supportsDeprecatedFlag =
      completionCapabilities?.completionItem?.deprecatedSupport == true;
  final supportedTags =
      completionCapabilities?.completionItem?.tagSupport?.valueSet ?? const [];
  final supportsDeprecatedTag =
      supportedTags.contains(lsp.CompletionItemTag.Deprecated);

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
    tags: supportedTags.isNotEmpty
        ? [
            if (supportsDeprecatedTag && declaration.isDeprecated)
              lsp.CompletionItemTag.Deprecated
          ]
        : null,
    commitCharacters:
        includeCommitCharacters ? lsp.dartCompletionCommitCharacters : null,
    detail: getDeclarationCompletionDetail(declaration, completionKind,
        supportsDeprecatedFlag || supportsDeprecatedTag),
    deprecated:
        supportsDeprecatedFlag && declaration.isDeprecated ? true : null,
    // Relevance is a number, highest being best. LSP does text sort so subtract
    // from a large number so that a text sort will result in the correct order.
    // 555 -> 999455
    //  10 -> 999990
    //   1 -> 999999
    sortText: (1000000 - itemRelevance).toString(),
    filterText: completion != label
        ? completion
        : null, // filterText uses label if not set
    insertText: insertText != label
        ? insertText
        : null, // insertText uses label if not set
    insertTextFormat: insertTextFormat != lsp.InsertTextFormat.PlainText
        ? insertTextFormat
        : null, // Defaults to PlainText if not supplied
    // data, used for completionItem/resolve.
    data: lsp.DartCompletionItemResolutionInfo(
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
        return const [lsp.SymbolKind.Enum];
      case server.ElementKind.ENUM_CONSTANT:
        return const [lsp.SymbolKind.EnumMember, lsp.SymbolKind.Enum];
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

List<lsp.DiagnosticTag> getDiagnosticTags(
    HashSet<lsp.DiagnosticTag> supportedTags, server.AnalysisError error) {
  if (supportedTags == null) {
    return null;
  }

  final tags = diagnosticTagsForErrorCode[error.errorCode]
      ?.where(supportedTags.contains)
      ?.toList();

  return tags != null && tags.isNotEmpty ? tags : null;
}

bool isDartDocument(lsp.TextDocumentIdentifier doc) =>
    doc?.uri?.endsWith('.dart');

lsp.Location navigationTargetToLocation(
  String targetFilePath,
  server.NavigationTarget target,
  server.LineInfo targetLineInfo,
) {
  if (targetLineInfo == null) {
    return null;
  }

  return lsp.Location(
    uri: Uri.file(targetFilePath).toString(),
    range: toRange(targetLineInfo, target.offset, target.length),
  );
}

lsp.LocationLink navigationTargetToLocationLink(
  server.NavigationRegion region,
  server.LineInfo regionLineInfo,
  String targetFilePath,
  server.NavigationTarget target,
  server.LineInfo targetLineInfo,
) {
  if (regionLineInfo == null || targetLineInfo == null) {
    return null;
  }

  final nameRange = toRange(targetLineInfo, target.offset, target.length);
  final codeRange = target.codeOffset != null && target.codeLength != null
      ? toRange(targetLineInfo, target.codeOffset, target.codeLength)
      : nameRange;

  return lsp.LocationLink(
    originSelectionRange: toRange(regionLineInfo, region.offset, region.length),
    targetUri: Uri.file(targetFilePath).toString(),
    targetRange: codeRange,
    targetSelectionRange: nameRange,
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
  int replacementLength, {
  @required bool includeCommitCharacters,
  @required bool completeFunctionCalls,
  Object resolutionData,
}) {
  // Build display labels and text to insert. insertText and filterText may
  // differ from label (for ex. if the label includes things like (…)). If
  // either are missing then label will be used by the client.
  var label = suggestion.displayText ?? suggestion.completion;

  // Trim any trailing comma from the (displayed) label.
  if (label.endsWith(',')) {
    label = label.substring(0, label.length - 1);
  }

  // isCallable is used to suffix the label with parens so it's clear the item
  // is callable.
  //
  // isInvocation means the location at which it's used is an invocation (and
  // therefore it is appropriate to include the parens/parameters in the
  // inserted text).
  //
  // In the case of show combinators, the parens will still be shown to indicate
  // functions but they should not be included in the completions.
  final elementKind = suggestion.element?.kind;
  final isCallable = elementKind == server.ElementKind.CONSTRUCTOR ||
      elementKind == server.ElementKind.FUNCTION ||
      elementKind == server.ElementKind.METHOD;
  final isInvocation =
      suggestion.kind == server.CompletionSuggestionKind.INVOCATION;

  if (suggestion.displayText == null && isCallable) {
    label += suggestion.parameterNames?.isNotEmpty ?? false ? '(…)' : '()';
  }

  final supportsDeprecatedFlag =
      completionCapabilities?.completionItem?.deprecatedSupport == true;
  final supportedTags =
      completionCapabilities?.completionItem?.tagSupport?.valueSet ?? const [];
  final supportsDeprecatedTag =
      supportedTags.contains(lsp.CompletionItemTag.Deprecated);
  final formats = completionCapabilities?.completionItem?.documentationFormat;
  final supportsSnippets =
      completionCapabilities?.completionItem?.snippetSupport == true;

  final completionKind = suggestion.element != null
      ? elementKindToCompletionItemKind(
          supportedCompletionItemKinds, suggestion.element.kind)
      : suggestionKindToCompletionItemKind(
          supportedCompletionItemKinds, suggestion.kind, label);

  final insertTextInfo = _buildInsertText(
    supportsSnippets: supportsSnippets,
    includeCommitCharacters: includeCommitCharacters,
    completeFunctionCalls: completeFunctionCalls,
    isCallable: isCallable,
    isInvocation: isInvocation,
    defaultArgumentListString: suggestion.defaultArgumentListString,
    defaultArgumentListTextRanges: suggestion.defaultArgumentListTextRanges,
    completion: suggestion.completion,
    selectionOffset: suggestion.selectionOffset,
    selectionLength: suggestion.selectionLength,
  );
  final insertText = insertTextInfo.first;
  final insertTextFormat = insertTextInfo.last;

  // Because we potentially send thousands of these items, we should minimise
  // the generated JSON as much as possible - for example using nulls in place
  // of empty lists/false where possible.
  return lsp.CompletionItem(
    label: label,
    kind: completionKind,
    tags: supportedTags.isNotEmpty
        ? [
            if (supportsDeprecatedTag && suggestion.isDeprecated)
              lsp.CompletionItemTag.Deprecated
          ]
        : null,
    commitCharacters:
        includeCommitCharacters ? dartCompletionCommitCharacters : null,
    data: resolutionData,
    detail: getCompletionDetail(suggestion, completionKind,
        supportsDeprecatedFlag || supportsDeprecatedTag),
    documentation:
        asStringOrMarkupContent(formats, cleanDartdoc(suggestion.docComplete)),
    deprecated: supportsDeprecatedFlag && suggestion.isDeprecated ? true : null,
    // Relevance is a number, highest being best. LSP does text sort so subtract
    // from a large number so that a text sort will result in the correct order.
    // 555 -> 999455
    //  10 -> 999990
    //   1 -> 999999
    sortText: (1000000 - suggestion.relevance).toString(),
    filterText: suggestion.completion != label
        ? suggestion.completion
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
  server.ResolvedUnitResult result,
  server.AnalysisError error, {
  @required HashSet<lsp.DiagnosticTag> supportedTags,
  server.ErrorSeverity errorSeverity,
}) {
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
    tags: getDiagnosticTags(supportedTags, error),
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
  // line is zero-based so cannot equal lineCount
  if (pos.line >= lineInfo.lineCount) {
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
    final prefix =
        p.kind == server.ParameterKind.REQUIRED_NAMED ? 'required ' : '';
    return '$prefix${p.type} ${p.name}$def';
  }

  /// Gets the full signature label in the form
  ///     foo(String s, int i, bool a = true)
  String getSignatureLabel(server.AnalysisGetSignatureResult resp) {
    final positionalRequired = signature.parameters
        .where((p) => p.kind == server.ParameterKind.REQUIRED_POSITIONAL)
        .toList();
    final positionalOptional = signature.parameters
        .where((p) => p.kind == server.ParameterKind.OPTIONAL_POSITIONAL)
        .toList();
    final named = signature.parameters
        .where((p) =>
            p.kind == server.ParameterKind.OPTIONAL_NAMED ||
            p.kind == server.ParameterKind.REQUIRED_NAMED)
        .toList();
    final params = [];
    if (positionalRequired.isNotEmpty) {
      params.add(positionalRequired.map(getParamLabel).join(', '));
    }
    if (positionalOptional.isNotEmpty) {
      params.add('[' + positionalOptional.map(getParamLabel).join(', ') + ']');
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
    edits: edit.edits
        .map((e) => Either2<TextEdit, AnnotatedTextEdit>.t1(
            toTextEdit(edit.lineInfo, e)))
        .toList(),
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

Pair<String, lsp.InsertTextFormat> _buildInsertText({
  @required bool supportsSnippets,
  @required bool includeCommitCharacters,
  @required bool completeFunctionCalls,
  @required bool isCallable,
  @required bool isInvocation,
  @required String defaultArgumentListString,
  @required List<int> defaultArgumentListTextRanges,
  @required String completion,
  @required int selectionOffset,
  @required int selectionLength,
}) {
  var insertText = completion;
  var insertTextFormat = lsp.InsertTextFormat.PlainText;

  // SuggestionBuilder already does the equiv of completeFunctionCalls for
  // some methods (for example Flutter's setState). If the completion already
  // includes any `(` then disable our own insertion as the special-cased code
  // will likely provide better code.
  if (completion.contains('(')) {
    completeFunctionCalls = false;
  }

  // If the client supports snippets, we can support completeFunctionCalls or
  // setting a selection.
  if (supportsSnippets) {
    // completeFunctionCalls should only work if commit characters are disabled
    // otherwise the editor may insert parens that we're also inserting.
    if (!includeCommitCharacters &&
        completeFunctionCalls &&
        isCallable &&
        isInvocation) {
      insertTextFormat = lsp.InsertTextFormat.Snippet;
      final hasRequiredParameters =
          (defaultArgumentListTextRanges?.length ?? 0) > 0;
      final functionCallSuffix = hasRequiredParameters
          ? buildSnippetStringWithTabStops(
              defaultArgumentListString,
              defaultArgumentListTextRanges,
            )
          : '\${0:}'; // No required params still gets a tabstop in the parens.
      insertText += '($functionCallSuffix)';
    } else if (selectionOffset != 0 &&
        // We don't need a tabstop if the selection is the end of the string.
        selectionOffset != completion.length) {
      insertTextFormat = lsp.InsertTextFormat.Snippet;
      insertText = buildSnippetStringWithTabStops(
        completion,
        [selectionOffset, selectionLength],
      );
    }
  }

  return Pair(insertText, insertTextFormat);
}
