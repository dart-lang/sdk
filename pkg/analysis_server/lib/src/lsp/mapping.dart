// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:analysis_server/lsp_protocol/protocol_custom_generated.dart'
    as lsp;
import 'package:analysis_server/lsp_protocol/protocol_custom_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_generated.dart' as lsp;
import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart' as lsp;
import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/constants.dart' as lsp;
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/dartdoc.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart' as lsp;
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analysis_server/src/protocol_server.dart' as server
    hide AnalysisError;
import 'package:analyzer/dart/analysis/results.dart' as server;
import 'package:analyzer/error/error.dart' as server;
import 'package:analyzer/source/line_info.dart' as server;
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source_range.dart' as server;
import 'package:analyzer/src/dart/analysis/search.dart' as server
    show DeclarationKind;
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/services/available_declarations.dart';
import 'package:analyzer/src/services/available_declarations.dart' as dec;
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/utilities/pair.dart';
import 'package:collection/collection.dart';

const languageSourceName = 'dart';

final diagnosticTagsForErrorCode = <String, List<lsp.DiagnosticTag>>{
  _errorCode(HintCode.DEAD_CODE): [lsp.DiagnosticTag.Unnecessary],
  _errorCode(HintCode.DEPRECATED_MEMBER_USE): [lsp.DiagnosticTag.Deprecated],
  _errorCode(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE): [
    lsp.DiagnosticTag.Deprecated
  ],
  _errorCode(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE): [
    lsp.DiagnosticTag.Deprecated
  ],
  _errorCode(HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE): [
    lsp.DiagnosticTag.Deprecated
  ],
};

/// Pattern for docComplete text on completion items that can be upgraded to
/// the "detail" field so that it can be shown more prominently by clients.
///
/// This is typically used for labels like _latest compatible_ and _latest_ in
/// the pubspec version items. These go into docComplete so that they appear
/// reasonably for non-LSP clients where there is no equivalent of the detail
/// field.
final _upgradableDocCompletePattern = RegExp(r'^_([\w ]{0,20})_$');

lsp.Either2<String, lsp.MarkupContent> asStringOrMarkupContent(
    Set<lsp.MarkupKind>? preferredFormats, String content) {
  return preferredFormats == null
      ? lsp.Either2<String, lsp.MarkupContent>.t1(content)
      : lsp.Either2<String, lsp.MarkupContent>.t2(
          _asMarkup(preferredFormats, content));
}

/// Builds an LSP snippet string with supplied ranges as tabstops.
String buildSnippetStringWithTabStops(
  String? text,
  List<int>? offsetLengthPairs,
) {
  text ??= '';
  offsetLengthPairs ??= const [];

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
    output.add(escapeSnippetString(text.substring(offset, pairOffset)));

    // Add this tabstop
    final tabStopText = escapeSnippetString(
        text.substring(pairOffset, pairOffset + pairLength));
    output.add('\${${tabStopNumber++}:$tabStopText}');

    offset = pairOffset + pairLength;
  }

  // Add any remaining text that was after the last tabstop.
  output.add(escapeSnippetString(text.substring(offset)));

  return output.join('');
}

/// Creates a [lsp.WorkspaceEdit] from simple [server.SourceFileEdit]s.
///
/// Note: This code will fetch the version of each document being modified so
/// it's important to call this immediately after computing edits to ensure
/// the document is not modified before the version number is read.
lsp.WorkspaceEdit createPlainWorkspaceEdit(
    lsp.LspAnalysisServer server, List<server.SourceFileEdit> edits) {
  return toWorkspaceEdit(
      // Client capabilities are always available after initialization.
      server.clientCapabilities!,
      edits
          .map((e) => FileEditInformation(
                server.getVersionedDocumentIdentifier(e.file),
                // If we expect to create the file, server.getLineInfo() won't
                // provide a LineInfo so create one from empty contents.
                e.fileStamp == -1
                    ? LineInfo.fromContent('')
                    : server.getLineInfo(e.file)!,
                e.edits,
                // fileStamp == 1 is used by the server to indicate the file needs creating.
                newFile: e.fileStamp == -1,
              ))
          .toList());
}

/// Create a [WorkspaceEdit] that renames [oldPath] to [newPath].
WorkspaceEdit createRenameEdit(String oldPath, String newPath) {
  final changes =
      <Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>>[];

  final rename = RenameFile(
    oldUri: Uri.file(oldPath).toString(),
    newUri: Uri.file(newPath).toString(),
  );

  final renameUnion =
      Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>.t3(rename);

  changes.add(renameUnion);

  final edit = WorkspaceEdit(
      documentChanges: Either2<
          List<TextDocumentEdit>,
          List<
              Either4<TextDocumentEdit, CreateFile, RenameFile,
                  DeleteFile>>>.t2(changes));
  return edit;
}

/// Creates a [lsp.WorkspaceEdit] from a [server.SourceChange] that can include
/// experimental [server.SnippetTextEdit]s if the client has indicated support
/// for these in the experimental section of their client capabilities.
///
/// Note: This code will fetch the version of each document being modified so
/// it's important to call this immediately after computing edits to ensure
/// the document is not modified before the version number is read.
lsp.WorkspaceEdit createWorkspaceEdit(
    lsp.LspAnalysisServer server, server.SourceChange change) {
  // In order to return snippets, we must ensure we are only modifying a single
  // existing file with a single edit and that there is a linked edit group with
  // only one position and no suggestions.
  if (!server.clientCapabilities!.experimentalSnippetTextEdit ||
      change.edits.length != 1 ||
      change.edits.first.fileStamp == -1 || // new file
      change.edits.first.edits.length != 1 ||
      change.linkedEditGroups.isEmpty ||
      change.linkedEditGroups.first.positions.length != 1 ||
      change.linkedEditGroups.first.suggestions.isNotEmpty) {
    return createPlainWorkspaceEdit(server, change.edits);
  }

  // Additionally, the selection must fall within the edit offset.
  final edit = change.edits.first.edits.first;
  final selectionOffset = change.linkedEditGroups.first.positions.first.offset;
  final selectionLength = change.linkedEditGroups.first.length;

  if (selectionOffset < edit.offset ||
      selectionOffset + selectionLength > edit.offset + edit.length) {
    return createPlainWorkspaceEdit(server, change.edits);
  }

  return toWorkspaceEdit(
      server.clientCapabilities!,
      change.edits
          .map((e) => FileEditInformation(
                server.getVersionedDocumentIdentifier(e.file),
                // We should never produce edits for a file with no LineInfo.
                server.getLineInfo(e.file)!,
                e.edits,
                selectionOffsetRelative: selectionOffset - edit.offset,
                selectionLength: selectionLength,
                newFile: e.fileStamp == -1,
              ))
          .toList());
}

lsp.CompletionItemKind? declarationKindToCompletionItemKind(
  Set<lsp.CompletionItemKind> supportedCompletionKinds,
  dec.DeclarationKind kind,
) {
  bool isSupported(lsp.CompletionItemKind kind) =>
      supportedCompletionKinds.contains(kind);

  List<lsp.CompletionItemKind> getKindPreferences() {
    switch (kind) {
      case dec.DeclarationKind.CLASS:
      case dec.DeclarationKind.CLASS_TYPE_ALIAS:
      case dec.DeclarationKind.MIXIN:
        return const [lsp.CompletionItemKind.Class];
      case dec.DeclarationKind.CONSTRUCTOR:
        return const [lsp.CompletionItemKind.Constructor];
      case dec.DeclarationKind.ENUM:
        return const [lsp.CompletionItemKind.Enum];
      case dec.DeclarationKind.ENUM_CONSTANT:
        return const [
          lsp.CompletionItemKind.EnumMember,
          lsp.CompletionItemKind.Enum,
        ];
      case dec.DeclarationKind.FUNCTION:
        return const [lsp.CompletionItemKind.Function];
      case dec.DeclarationKind.FUNCTION_TYPE_ALIAS:
        return const [lsp.CompletionItemKind.Class];
      case dec.DeclarationKind.GETTER:
        return const [lsp.CompletionItemKind.Property];
      case dec.DeclarationKind.SETTER:
        return const [lsp.CompletionItemKind.Property];
      case dec.DeclarationKind.TYPE_ALIAS:
        return const [lsp.CompletionItemKind.Class];
      case dec.DeclarationKind.VARIABLE:
        return const [lsp.CompletionItemKind.Variable];
      default:
        return const [];
    }
  }

  return getKindPreferences().firstWhereOrNull(isSupported);
}

lsp.SymbolKind declarationKindToSymbolKind(
  Set<lsp.SymbolKind> supportedSymbolKinds,
  server.DeclarationKind? kind,
) {
  bool isSupported(lsp.SymbolKind kind) => supportedSymbolKinds.contains(kind);

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
      case server.DeclarationKind.EXTENSION:
        return const [lsp.SymbolKind.Class];
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
      case server.DeclarationKind.TYPE_ALIAS:
        return const [lsp.SymbolKind.Class];
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
  LspClientCapabilities capabilities,
  String file,
  int offset,
  server.IncludedSuggestionSet includedSuggestionSet,
  Library library,
  Map<String, int> tagBoosts,
  server.LineInfo lineInfo,
  dec.Declaration declaration,
  int replacementOffset,
  int insertLength,
  int replacementLength, {
  required bool includeCommitCharacters,
  required bool completeFunctionCalls,
}) {
  final supportsSnippets = capabilities.completionSnippets;
  final parent = declaration.parent;

  String completion;
  switch (declaration.kind) {
    case DeclarationKind.ENUM_CONSTANT:
      completion = '${parent!.name}.${declaration.name}';
      break;
    case DeclarationKind.GETTER:
    case DeclarationKind.FIELD:
      completion = parent != null && parent.name.isNotEmpty
          ? '${parent.name}.${declaration.name}'
          : declaration.name;
      break;
    case DeclarationKind.CONSTRUCTOR:
      completion = parent!.name;
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
  final isMultilineCompletion = insertText.contains('\n');

  final supportsDeprecatedFlag = capabilities.completionDeprecatedFlag;
  final supportsDeprecatedTag = capabilities.completionItemTags
      .contains(lsp.CompletionItemTag.Deprecated);
  final supportsAsIsInsertMode =
      capabilities.completionInsertTextModes.contains(InsertTextMode.asIs);

  final completionKind = declarationKindToCompletionItemKind(
      capabilities.completionItemKinds, declaration.kind);

  var relevanceBoost = 0;
  declaration.relevanceTags
      .forEach((t) => relevanceBoost = max(relevanceBoost, tagBoosts[t] ?? 0));
  final itemRelevance = includedSuggestionSet.relevance + relevanceBoost;

  // Because we potentially send thousands of these items, we should minimise
  // the generated JSON as much as possible - for example using nulls in place
  // of empty lists/false where possible.
  return lsp.CompletionItem(
    label: label,
    kind: completionKind,
    tags: nullIfEmpty([
      if (supportsDeprecatedTag && declaration.isDeprecated)
        lsp.CompletionItemTag.Deprecated
    ]),
    commitCharacters:
        includeCommitCharacters ? lsp.dartCompletionCommitCharacters : null,
    detail: getDeclarationCompletionDetail(declaration, completionKind,
        supportsDeprecatedFlag || supportsDeprecatedTag),
    deprecated:
        supportsDeprecatedFlag && declaration.isDeprecated ? true : null,
    sortText: relevanceToSortText(itemRelevance),
    filterText: completion != label
        ? completion
        : null, // filterText uses label if not set
    insertText: insertText != label
        ? insertText
        : null, // insertText uses label if not set
    insertTextFormat: insertTextFormat != lsp.InsertTextFormat.PlainText
        ? insertTextFormat
        : null, // Defaults to PlainText if not supplied
    insertTextMode: supportsAsIsInsertMode && isMultilineCompletion
        ? InsertTextMode.asIs
        : null,
    // data, used for completionItem/resolve.
    data: lsp.DartSuggestionSetCompletionItemResolutionInfo(
        file: file,
        offset: offset,
        libId: includedSuggestionSet.id,
        displayUri: includedSuggestionSet.displayUri ?? library.uri.toString(),
        rOffset: replacementOffset,
        iLength: insertLength,
        rLength: replacementLength),
  );
}

lsp.CompletionItemKind? elementKindToCompletionItemKind(
  Set<lsp.CompletionItemKind> supportedCompletionKinds,
  server.ElementKind kind,
) {
  bool isSupported(lsp.CompletionItemKind kind) =>
      supportedCompletionKinds.contains(kind);

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
        return const [lsp.CompletionItemKind.Enum];
      case server.ElementKind.ENUM_CONSTANT:
        return const [
          lsp.CompletionItemKind.EnumMember,
          lsp.CompletionItemKind.Enum,
        ];
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

  return getKindPreferences().firstWhereOrNull(isSupported);
}

lsp.SymbolKind elementKindToSymbolKind(
  Set<lsp.SymbolKind> supportedSymbolKinds,
  server.ElementKind? kind,
) {
  bool isSupported(lsp.SymbolKind kind) => supportedSymbolKinds.contains(kind);

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

/// Escapes a string to be used in an LSP edit that uses Snippet mode.
///
/// Snippets can contain special markup like `${a:b}` so some characters need
/// escaping (according to the LSP spec, those are `$`, `}` and `\`).
String escapeSnippetString(String input) => input.replaceAllMapped(
      RegExp(r'[$}\\]'), // Replace any of $ } \
      (c) => '\\${c[0]}', // Prefix with a backslash
    );

String? getCompletionDetail(
  server.CompletionSuggestion suggestion,
  lsp.CompletionItemKind? completionKind,
  bool supportsDeprecated,
) {
  final element = suggestion.element;
  final hasElement = element != null;
  final parameters = element?.parameters;
  final returnType = element?.returnType;
  final parameterType = suggestion.parameterType;
  final hasParameters =
      hasElement && parameters != null && parameters.isNotEmpty;
  final hasReturnType =
      hasElement && returnType != null && returnType.isNotEmpty;
  final hasParameterType = parameterType != null && parameterType.isNotEmpty;

  final prefix =
      supportsDeprecated || !suggestion.isDeprecated ? '' : '(Deprecated) ';

  if (completionKind == lsp.CompletionItemKind.Property) {
    // Setters appear as methods with one arg but they also cause getters to not
    // appear in the completion list, so displaying them as setters is misleading.
    // To avoid this, always show only the return type, whether it's a getter
    // or a setter.
    return prefix +
        (element?.kind == server.ElementKind.GETTER
            ? (returnType ?? '')
            // Don't assume setters always have parameters
            // See https://github.com/dart-lang/sdk/issues/27747
            : parameters != null && parameters.isNotEmpty
                // Extract the type part from '(MyType value)`
                ? parameters.substring(1, parameters.lastIndexOf(' '))
                : '');
  } else if (hasParameters && hasReturnType) {
    return '$prefix$parameters → $returnType';
  } else if (hasReturnType) {
    return '$prefix$returnType';
  } else if (hasParameterType) {
    return '$prefix$parameterType';
  } else {
    return prefix.isNotEmpty ? prefix : null;
  }
}

String? getDeclarationCompletionDetail(
  dec.Declaration declaration,
  lsp.CompletionItemKind? completionKind,
  bool supportsDeprecated,
) {
  final parameters = declaration.parameters;
  final hasParameters = parameters != null && parameters.isNotEmpty;
  final returnType = declaration.returnType;
  final hasReturnType = returnType != null && returnType.isNotEmpty;

  final prefix =
      supportsDeprecated || !declaration.isDeprecated ? '' : '(Deprecated) ';

  if (completionKind == lsp.CompletionItemKind.Property) {
    // Setters appear as methods with one arg but they also cause getters to not
    // appear in the completion list, so displaying them as setters is misleading.
    // To avoid this, always show only the return type, whether it's a getter
    // or a setter.
    var suffix = '';
    if (declaration.kind == dec.DeclarationKind.GETTER) {
      suffix = declaration.returnType ?? '';
    } else {
      // Don't assume setters always have parameters
      // See https://github.com/dart-lang/sdk/issues/27747
      if (parameters != null && parameters.isNotEmpty) {
        // Extract the type part from `(MyType value)`, if there is a type.
        var spaceIndex = parameters.lastIndexOf(' ');
        if (spaceIndex > 0) {
          suffix = parameters.substring(1, spaceIndex);
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

List<lsp.DiagnosticTag>? getDiagnosticTags(
    Set<lsp.DiagnosticTag>? supportedTags, plugin.AnalysisError error) {
  if (supportedTags == null) {
    return null;
  }

  final tags = diagnosticTagsForErrorCode[error.code]
      ?.where(supportedTags.contains)
      .toList();

  return tags != null && tags.isNotEmpty ? tags : null;
}

bool isDartDocument(lsp.TextDocumentIdentifier? doc) =>
    doc?.uri.endsWith('.dart') ?? false;

/// Converts a [server.Location] to an [lsp.Range] by translating the
/// offset/length using a `LineInfo`.
///
/// This function ignores any line/column info on the
/// [server.Location] assuming it is either not available not unreliable.
lsp.Range locationOffsetLenToRange(
        server.LineInfo lineInfo, server.Location location) =>
    toRange(lineInfo, location.offset, location.length);

/// Converts a [server.Location] to an [lsp.Range] if all line and column
/// values are available.
///
/// Returns null if any values are -1 or null.
lsp.Range? locationToRange(server.Location location) {
  final startLine = location.startLine;
  final startColumn = location.startColumn;
  final endLine = location.endLine ?? -1;
  final endColumn = location.endColumn ?? -1;
  if (startLine == -1 ||
      startColumn == -1 ||
      endLine == -1 ||
      endColumn == -1) {
    return null;
  }
  // LSP positions are 0-based but Location is 1-based.
  return Range(
      start: Position(line: startLine - 1, character: startColumn - 1),
      end: Position(line: endLine - 1, character: endColumn - 1));
}

/// Merges two [WorkspaceEdit]s into a single one.
///
/// Will throw if given [WorkspaceEdit]s that do not use documentChanges.
WorkspaceEdit mergeWorkspaceEdits(List<WorkspaceEdit> edits) {
  // TODO(dantup): This method (and much other code here) should be
  // significantly tidied up when nonfunction-type-aliases is available here.
  final changes =
      <Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>>[];

  for (final edit in edits) {
    // Flatten the Either into just the Union side to get a flat list.
    final flatResourceChanges = edit.documentChanges!.map(
      (edits) => edits.map((e) =>
          Either4<TextDocumentEdit, CreateFile, RenameFile, DeleteFile>.t1(e)),
      (resources) => resources,
    );
    changes.addAll(flatResourceChanges);
  }

  return WorkspaceEdit(
      documentChanges: Either2<
          List<TextDocumentEdit>,
          List<
              Either4<TextDocumentEdit, CreateFile, RenameFile,
                  DeleteFile>>>.t2(changes));
}

lsp.Location navigationTargetToLocation(
  String targetFilePath,
  server.NavigationTarget target,
  server.LineInfo targetLineInfo,
) {
  return lsp.Location(
    uri: Uri.file(targetFilePath).toString(),
    range: toRange(targetLineInfo, target.offset, target.length),
  );
}

lsp.LocationLink? navigationTargetToLocationLink(
  server.NavigationRegion region,
  server.LineInfo regionLineInfo,
  String targetFilePath,
  server.NavigationTarget target,
  server.LineInfo targetLineInfo,
) {
  final nameRange = toRange(targetLineInfo, target.offset, target.length);
  final codeOffset = target.codeOffset;
  final codeLength = target.codeLength;
  final codeRange = codeOffset != null && codeLength != null
      ? toRange(targetLineInfo, codeOffset, codeLength)
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
    pathOfUri(Uri.tryParse(doc.uri));

/// Returns the file system path for a TextDocumentItem.
ErrorOr<String> pathOfDocItem(lsp.TextDocumentItem doc) =>
    pathOfUri(Uri.tryParse(doc.uri));

/// Returns the file system path for a file URI.
ErrorOr<String> pathOfUri(Uri? uri) {
  if (uri == null) {
    return ErrorOr<String>.error(ResponseError(
      code: lsp.ServerErrorCodes.InvalidFilePath,
      message: 'Document URI was not supplied',
    ));
  }
  final isValidFileUri = uri.isScheme('file');
  if (!isValidFileUri) {
    return ErrorOr<String>.error(ResponseError(
      code: lsp.ServerErrorCodes.InvalidFilePath,
      message: 'URI was not a valid file:// URI',
      data: uri.toString(),
    ));
  }
  try {
    final filePath = uri.toFilePath();
    // On Windows, paths that start with \ and not a drive letter are not
    // supported but will return `true` from `path.isAbsolute` so check for them
    // specifically.
    if (Platform.isWindows && filePath.startsWith(r'\')) {
      return ErrorOr<String>.error(ResponseError(
        code: lsp.ServerErrorCodes.InvalidFilePath,
        message: 'URI was not an absolute file path (missing drive letter)',
        data: uri.toString(),
      ));
    }
    return ErrorOr<String>.success(filePath);
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
  server.LineInfo? Function(String) getLineInfo,
  plugin.AnalysisError error, {
  required Set<lsp.DiagnosticTag>? supportedTags,
  required bool clientSupportsCodeDescription,
}) {
  List<lsp.DiagnosticRelatedInformation>? relatedInformation;
  final contextMessages = error.contextMessages;
  if (contextMessages != null && contextMessages.isNotEmpty) {
    relatedInformation = contextMessages
        .map((message) =>
            pluginToDiagnosticRelatedInformation(getLineInfo, message))
        .whereNotNull()
        .toList();
  }

  var message = error.message;
  if (error.correction != null) {
    message = '$message\n${error.correction}';
  }

  final range = locationToRange(error.location) ??
      locationOffsetLenToRange(
        // TODO(dantup): This null assertion is not sound and can lead to
        //   errors (for example during a large rename where files may be
        //   removed as diagnostics are being mapped). To remove this,
        //   error.location should be updated to require line/col information
        //   (which involves breaking changes).
        getLineInfo(error.location.file)!,
        error.location,
      );
  var documentationUrl = error.url;
  return lsp.Diagnostic(
    range: range,
    severity: pluginToDiagnosticSeverity(error.severity),
    code: error.code,
    source: languageSourceName,
    message: message,
    tags: getDiagnosticTags(supportedTags, error),
    relatedInformation: relatedInformation,
    // Only include codeDescription if the client explicitly supports it
    // (a minor optimization to avoid unnecessary payload/(de)serialisation).
    codeDescription: clientSupportsCodeDescription && documentationUrl != null
        ? CodeDescription(href: documentationUrl)
        : null,
  );
}

lsp.DiagnosticRelatedInformation? pluginToDiagnosticRelatedInformation(
    server.LineInfo? Function(String) getLineInfo,
    plugin.DiagnosticMessage message) {
  final file = message.location.file;
  final lineInfo = getLineInfo(file);
  // We shouldn't get context messages for something we can't get a LineInfo for
  // but if we did, it's better to omit the context than fail to send the errors.
  if (lineInfo == null) {
    return null;
  }
  return lsp.DiagnosticRelatedInformation(
      location: lsp.Location(
        uri: Uri.file(file).toString(),
        // TODO(dantup): Switch to using line/col information from the context
        // message once confirmed that AnalyzerConverter is not using the wrong
        // LineInfo.
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

/// Converts a numeric relevance to a sortable string.
///
/// The servers relevance value is a number with highest being best. LSP uses a
/// a string sort on the `sortText` field. Subtracting the relevance from a large
/// number will produce text that will sort correctly.
///
/// Relevance can be 0, so it's important to subtract from a number like 999
/// and not 1000 or the 0 relevance items will sort at the top instead of the
/// bottom.
///
/// 555 -> 9999999 - 555 -> 9 999 444
///  10 -> 9999999 -  10 -> 9 999 989
///   1 -> 9999999 -   1 -> 9 999 998
///   0 -> 9999999 -   0 -> 9 999 999
String relevanceToSortText(int relevance) => (9999999 - relevance).toString();

lsp.Location? searchResultToLocation(
    server.SearchResult result, server.LineInfo? lineInfo) {
  final location = result.location;

  if (lineInfo == null) {
    return null;
  }

  return lsp.Location(
    uri: Uri.file(result.location.file).toString(),
    range: toRange(lineInfo, location.offset, location.length),
  );
}

lsp.CompletionItemKind? suggestionKindToCompletionItemKind(
  Set<lsp.CompletionItemKind> supportedCompletionKinds,
  server.CompletionSuggestionKind kind,
  String label,
) {
  bool isSupported(lsp.CompletionItemKind kind) =>
      supportedCompletionKinds.contains(kind);

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
      case server.CompletionSuggestionKind.PACKAGE_NAME:
        return const [lsp.CompletionItemKind.Module];
      default:
        return const [];
    }
  }

  return getKindPreferences().firstWhereOrNull(isSupported);
}

lsp.ClosingLabel toClosingLabel(
        server.LineInfo lineInfo, server.ClosingLabel label) =>
    lsp.ClosingLabel(
        range: toRange(lineInfo, label.offset, label.length),
        label: label.label);

/// Converts [id] to a [CodeActionKind] using [fallbackOrPrefix] as a fallback
/// or a prefix if the ID is not already a fix/refactor.
lsp.CodeActionKind toCodeActionKind(
    String? id, lsp.CodeActionKind fallbackOrPrefix) {
  if (id == null) {
    return fallbackOrPrefix;
  }
  // Dart fixes and assists start with "dart.assist." and "dart.fix." but in LSP
  // we want to use the predefined prefixes for CodeActions.
  var newId = id
      .replaceAll('dart.assist', lsp.CodeActionKind.Refactor.toString())
      .replaceAll('dart.fix', lsp.CodeActionKind.QuickFix.toString())
      .replaceAll(
          'analysisOptions.assist', lsp.CodeActionKind.Refactor.toString())
      .replaceAll(
          'analysisOptions.fix', lsp.CodeActionKind.QuickFix.toString());

  // If the ID does not start with either of the kinds above, prefix it as
  // it will be an unqualified ID from a plugin.
  if (!newId.startsWith(lsp.CodeActionKind.Refactor.toString()) &&
      !newId.startsWith(lsp.CodeActionKind.QuickFix.toString())) {
    newId = '$fallbackOrPrefix.$newId';
  }

  return lsp.CodeActionKind(newId);
}

lsp.CompletionItem toCompletionItem(
  LspClientCapabilities capabilities,
  server.LineInfo lineInfo,
  server.CompletionSuggestion suggestion, {
  Range? replacementRange,
  Range? insertionRange,
  required bool includeCommitCharacters,
  required bool completeFunctionCalls,
  CompletionItemResolutionInfo? resolutionData,
}) {
  // Build separate display and filter labels. Displayed labels may have additional
  // info appended (for example '(...)' on callables) that should not be included
  // in filterText.
  var label = suggestion.displayText ?? suggestion.completion;
  final filterText = label;

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

  final supportsCompletionDeprecatedFlag =
      capabilities.completionDeprecatedFlag;
  final supportsDeprecatedTag = capabilities.completionItemTags
      .contains(lsp.CompletionItemTag.Deprecated);
  final formats = capabilities.completionDocumentationFormats;
  final supportsSnippets = capabilities.completionSnippets;
  final supportsInsertReplace = capabilities.insertReplaceCompletionRanges;
  final supportsAsIsInsertMode =
      capabilities.completionInsertTextModes.contains(InsertTextMode.asIs);

  final element = suggestion.element;
  final completionKind = element != null
      ? elementKindToCompletionItemKind(
          capabilities.completionItemKinds, element.kind)
      : suggestionKindToCompletionItemKind(
          capabilities.completionItemKinds, suggestion.kind, label);

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
  final isMultilineCompletion = insertText.contains('\n');

  var cleanedDoc = cleanDartdoc(suggestion.docComplete);
  var detail = getCompletionDetail(suggestion, completionKind,
      supportsCompletionDeprecatedFlag || supportsDeprecatedTag);

  // To improve the display of some items (like pubspec version numbers),
  // short labels in the format `_foo_` in docComplete are "upgraded" to the
  // detail field.
  final labelMatch = cleanedDoc != null
      ? _upgradableDocCompletePattern.firstMatch(cleanedDoc)
      : null;
  if (labelMatch != null) {
    cleanedDoc = null;
    detail = labelMatch.group(1);
  }

  // Because we potentially send thousands of these items, we should minimise
  // the generated JSON as much as possible - for example using nulls in place
  // of empty lists/false where possible.
  return lsp.CompletionItem(
    label: label,
    kind: completionKind,
    tags: nullIfEmpty([
      if (supportsDeprecatedTag && suggestion.isDeprecated)
        lsp.CompletionItemTag.Deprecated
    ]),
    commitCharacters:
        includeCommitCharacters ? dartCompletionCommitCharacters : null,
    data: resolutionData,
    detail: detail,
    documentation: cleanedDoc != null
        ? asStringOrMarkupContent(formats, cleanedDoc)
        : null,
    deprecated: supportsCompletionDeprecatedFlag && suggestion.isDeprecated
        ? true
        : null,
    sortText: relevanceToSortText(suggestion.relevance),
    filterText: filterText != label
        ? filterText
        : null, // filterText uses label if not set
    insertText: insertText != label
        ? insertText
        : null, // insertText uses label if not set
    insertTextFormat: insertTextFormat != lsp.InsertTextFormat.PlainText
        ? insertTextFormat
        : null, // Defaults to PlainText if not supplied
    insertTextMode: supportsAsIsInsertMode && isMultilineCompletion
        ? InsertTextMode.asIs
        : null,
    textEdit: (insertionRange == null || replacementRange == null)
        ? null
        : supportsInsertReplace && insertionRange != replacementRange
            ? Either2<TextEdit, InsertReplaceEdit>.t2(
                InsertReplaceEdit(
                  insert: insertionRange,
                  replace: replacementRange,
                  newText: insertText,
                ),
              )
            : Either2<TextEdit, InsertReplaceEdit>.t1(
                TextEdit(
                  range: replacementRange,
                  newText: insertText,
                ),
              ),
  );
}

lsp.Diagnostic toDiagnostic(
  server.ResolvedUnitResult result,
  server.AnalysisError error, {
  required Set<lsp.DiagnosticTag> supportedTags,
  required bool clientSupportsCodeDescription,
}) {
  return pluginToDiagnostic(
    (_) => result.lineInfo,
    server.newAnalysisError_fromEngine(result, error),
    supportedTags: supportedTags,
    clientSupportsCodeDescription: clientSupportsCodeDescription,
  );
}

lsp.Element toElement(server.LineInfo lineInfo, server.Element element) {
  final location = element.location;
  return lsp.Element(
    range: location != null
        ? toRange(lineInfo, location.offset, location.length)
        : null,
    name: toElementName(element),
    kind: element.kind.name,
    parameters: element.parameters,
    typeParameters: element.typeParameters,
    returnType: element.returnType,
  );
}

String toElementName(server.Element element) {
  return element.name.isNotEmpty
      ? element.name
      : (element.kind == server.ElementKind.EXTENSION
          ? '<unnamed extension>'
          : '<unnamed>');
}

lsp.FlutterOutline toFlutterOutline(
    server.LineInfo lineInfo, server.FlutterOutline outline) {
  final attributes = outline.attributes;
  final dartElement = outline.dartElement;
  final children = outline.children;

  return lsp.FlutterOutline(
    kind: outline.kind.name,
    label: outline.label,
    className: outline.className,
    variableName: outline.variableName,
    attributes: attributes != null
        ? attributes
            .map((attribute) => toFlutterOutlineAttribute(lineInfo, attribute))
            .toList()
        : null,
    dartElement: dartElement != null ? toElement(lineInfo, dartElement) : null,
    range: toRange(lineInfo, outline.offset, outline.length),
    codeRange: toRange(lineInfo, outline.codeOffset, outline.codeLength),
    children: children != null
        ? children.map((c) => toFlutterOutline(lineInfo, c)).toList()
        : null,
  );
}

lsp.FlutterOutlineAttribute toFlutterOutlineAttribute(
    server.LineInfo lineInfo, server.FlutterOutlineAttribute attribute) {
  final valueLocation = attribute.valueLocation;
  return lsp.FlutterOutlineAttribute(
      name: attribute.name,
      label: attribute.label,
      valueRange: valueLocation != null
          ? toRange(lineInfo, valueLocation.offset, valueLocation.length)
          : null);
}

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

lsp.FoldingRangeKind? toFoldingRangeKind(server.FoldingKind kind) {
  switch (kind) {
    case server.FoldingKind.COMMENT:
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
  bool failureIsCritical = false,
}) {
  // line is zero-based so cannot equal lineCount
  if (pos.line >= lineInfo.lineCount) {
    return ErrorOr<int>.error(lsp.ResponseError(
        code: failureIsCritical
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

lsp.Outline toOutline(server.LineInfo lineInfo, server.Outline outline) {
  final children = outline.children;
  return lsp.Outline(
    element: toElement(lineInfo, outline.element),
    range: toRange(lineInfo, outline.offset, outline.length),
    codeRange: toRange(lineInfo, outline.codeOffset, outline.codeLength),
    children: children != null
        ? children.map((c) => toOutline(lineInfo, c)).toList()
        : null,
  );
}

lsp.Position toPosition(server.CharacterLocation location) {
  // LSP is zero-based, but analysis server is 1-based.
  return lsp.Position(
      line: location.lineNumber - 1, character: location.columnNumber - 1);
}

lsp.Range toRange(server.LineInfo lineInfo, int offset, int length) {
  final start = lineInfo.getLocation(offset);
  final end = lineInfo.getLocation(offset + length);

  return lsp.Range(
    start: toPosition(start),
    end: toPosition(end),
  );
}

lsp.SignatureHelp toSignatureHelp(Set<lsp.MarkupKind>? preferredFormats,
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

  final cleanedDoc = cleanDartdoc(signature.dartdoc);

  return lsp.SignatureHelp(
    signatures: [
      lsp.SignatureInformation(
        label: getSignatureLabel(signature),
        documentation: cleanedDoc != null
            ? asStringOrMarkupContent(preferredFormats, cleanedDoc)
            : null,
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

lsp.SnippetTextEdit toSnippetTextEdit(
    LspClientCapabilities capabilities,
    server.LineInfo lineInfo,
    server.SourceEdit edit,
    int selectionOffsetRelative,
    int? selectionLength) {
  return lsp.SnippetTextEdit(
    insertTextFormat: lsp.InsertTextFormat.Snippet,
    range: toRange(lineInfo, edit.offset, edit.length),
    newText: buildSnippetStringWithTabStops(
        edit.replacement, [selectionOffsetRelative, selectionLength ?? 0]),
  );
}

ErrorOr<server.SourceRange> toSourceRange(
    server.LineInfo lineInfo, Range range) {
  // If there is a range, convert to offsets because that's what
  // the tokens are computed using initially.
  final start = toOffset(lineInfo, range.start);
  final end = toOffset(lineInfo, range.end);
  if (start.isError) {
    return failure(start);
  }
  if (end.isError) {
    return failure(end);
  }

  final startOffset = start.result;
  final endOffset = end.result;

  return success(server.SourceRange(startOffset, endOffset - startOffset));
}

ErrorOr<server.SourceRange?> toSourceRangeNullable(
        server.LineInfo lineInfo, Range? range) =>
    range != null ? toSourceRange(lineInfo, range) : success(null);

lsp.TextDocumentEdit toTextDocumentEdit(
    LspClientCapabilities capabilities, FileEditInformation edit) {
  return lsp.TextDocumentEdit(
      textDocument: edit.doc,
      edits: edit.edits
          .map((e) => toTextDocumentEditEdit(capabilities, edit.lineInfo, e,
              selectionOffsetRelative: edit.selectionOffsetRelative,
              selectionLength: edit.selectionLength))
          .toList());
}

Either3<lsp.SnippetTextEdit, lsp.AnnotatedTextEdit, lsp.TextEdit>
    toTextDocumentEditEdit(
  LspClientCapabilities capabilities,
  server.LineInfo lineInfo,
  server.SourceEdit edit, {
  int? selectionOffsetRelative,
  int? selectionLength,
}) {
  if (!capabilities.experimentalSnippetTextEdit ||
      selectionOffsetRelative == null) {
    return Either3<lsp.SnippetTextEdit, lsp.AnnotatedTextEdit, lsp.TextEdit>.t3(
        toTextEdit(lineInfo, edit));
  }
  return Either3<lsp.SnippetTextEdit, lsp.AnnotatedTextEdit, lsp.TextEdit>.t1(
      toSnippetTextEdit(capabilities, lineInfo, edit, selectionOffsetRelative,
          selectionLength));
}

lsp.TextEdit toTextEdit(server.LineInfo lineInfo, server.SourceEdit edit) {
  return lsp.TextEdit(
    range: toRange(lineInfo, edit.offset, edit.length),
    newText: edit.replacement,
  );
}

lsp.WorkspaceEdit toWorkspaceEdit(
  LspClientCapabilities capabilities,
  List<FileEditInformation> edits,
) {
  final supportsDocumentChanges = capabilities.documentChanges;
  if (supportsDocumentChanges) {
    final supportsCreate = capabilities.createResourceOperations;
    final changes = <
        Either4<lsp.TextDocumentEdit, lsp.CreateFile, lsp.RenameFile,
            lsp.DeleteFile>>[];

    // Convert each SourceEdit to either a TextDocumentEdit or a
    // CreateFile + a TextDocumentEdit depending on whether it's a new
    // file.
    for (final edit in edits) {
      if (supportsCreate && edit.newFile) {
        final create = lsp.CreateFile(uri: edit.doc.uri);
        final createUnion = Either4<lsp.TextDocumentEdit, lsp.CreateFile,
            lsp.RenameFile, lsp.DeleteFile>.t2(create);
        changes.add(createUnion);
      }

      final textDocEdit = toTextDocumentEdit(capabilities, edit);
      final textDocEditUnion = Either4<lsp.TextDocumentEdit, lsp.CreateFile,
          lsp.RenameFile, lsp.DeleteFile>.t1(textDocEdit);
      changes.add(textDocEditUnion);
    }

    return lsp.WorkspaceEdit(
        documentChanges: Either2<
            List<lsp.TextDocumentEdit>,
            List<
                Either4<lsp.TextDocumentEdit, lsp.CreateFile, lsp.RenameFile,
                    lsp.DeleteFile>>>.t2(changes));
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
    Set<lsp.MarkupKind> preferredFormats, String content) {
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
  required bool supportsSnippets,
  required bool includeCommitCharacters,
  required bool completeFunctionCalls,
  required bool isCallable,
  required bool isInvocation,
  required String? defaultArgumentListString,
  required List<int>? defaultArgumentListTextRanges,
  required String completion,
  required int selectionOffset,
  required int selectionLength,
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
      insertText = '${escapeSnippetString(insertText)}($functionCallSuffix)';
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

String _errorCode(server.ErrorCode code) => code.name.toLowerCase();
