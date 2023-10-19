// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp;
import 'package:analysis_server/lsp_protocol/protocol.dart' hide Declaration;
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/computer/computer_hover.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/constants.dart' as lsp;
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/dartdoc.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart' as lsp;
import 'package:analysis_server/src/lsp/snippets.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analysis_server/src/protocol_server.dart' as server
    hide AnalysisError;
import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analysis_server/src/services/snippets/snippet.dart';
import 'package:analysis_server/src/utilities/extensions/string.dart';
import 'package:analyzer/dart/analysis/results.dart' as server;
import 'package:analyzer/error/error.dart' as server;
import 'package:analyzer/source/line_info.dart' as server;
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source_range.dart' as server;
import 'package:analyzer/src/dart/analysis/search.dart' as server
    show DeclarationKind;
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;

const languageSourceName = 'dart';

final diagnosticTagsForErrorCode = <String, List<lsp.DiagnosticTag>>{
  _errorCode(WarningCode.DEAD_CODE): [lsp.DiagnosticTag.Unnecessary],
  _errorCode(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE): [
    lsp.DiagnosticTag.Deprecated
  ],
  _errorCode(HintCode.DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE): [
    lsp.DiagnosticTag.Deprecated
  ],
  _errorCode(HintCode.DEPRECATED_MEMBER_USE): [lsp.DiagnosticTag.Deprecated],
  'deprecated_member_use_from_same_package': [lsp.DiagnosticTag.Deprecated],
  'deprecated_member_use_from_same_package_with_message': [
    lsp.DiagnosticTag.Deprecated
  ],
  _errorCode(HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE): [
    lsp.DiagnosticTag.Deprecated
  ],
};

/// The value to subtract relevance from to get the correct sortText for a
/// completion item.
final sortTextMaxValue = int.parse('9' * maximumRelevance.toString().length);

/// A regex used for splitting the display text in a completion so that
/// filterText only includes the symbol name and not any additional text (such
/// as parens, ` => `).
final _completionFilterTextSplitPattern = RegExp(r'[ \(]');

/// A regex to extract the type name from the parameter string of a setter
/// completion item.
final _completionSetterTypePattern = RegExp(r'^\((\S+)\s+\S+\)$');

/// Pattern for docComplete text on completion items that can be upgraded to
/// the "detail" field so that it can be shown more prominently by clients.
///
/// This is typically used for labels like _latest compatible_ and _latest_ in
/// the pubspec version items. These go into docComplete so that they appear
/// reasonably for non-LSP clients where there is no equivalent of the detail
/// field.
final _upgradableDocCompletePattern = RegExp(r'^_([\w ]{0,20})_$');

lsp.Either2<lsp.MarkupContent, String> asMarkupContentOrString(
    Set<lsp.MarkupKind>? preferredFormats, String content) {
  return preferredFormats != null
      ? lsp.Either2<lsp.MarkupContent, String>.t1(
          _asMarkup(preferredFormats, content))
      : lsp.Either2<lsp.MarkupContent, String>.t2(content);
}

/// Creates a [lsp.WorkspaceEdit] from simple [server.SourceFileEdit]s.
///
/// Note: This code will fetch the version of each document being modified so
/// it's important to call this immediately after computing edits to ensure
/// the document is not modified before the version number is read.
lsp.WorkspaceEdit createPlainWorkspaceEdit(
    AnalysisServer server, List<server.SourceFileEdit> edits) {
  return toWorkspaceEdit(
      // Client capabilities are always available after initialization.
      server.lspClientCapabilities!,
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
WorkspaceEdit createRenameEdit(
    path.Context pathContext, String oldPath, String newPath) {
  final changes =
      <Either4<CreateFile, DeleteFile, RenameFile, TextDocumentEdit>>[];

  final rename = RenameFile(
    oldUri: pathContext.toUri(oldPath),
    newUri: pathContext.toUri(newPath),
  );

  final renameUnion =
      Either4<CreateFile, DeleteFile, RenameFile, TextDocumentEdit>.t3(rename);

  changes.add(renameUnion);

  final edit = WorkspaceEdit(documentChanges: changes);
  return edit;
}

/// Creates a [lsp.WorkspaceEdit] from a [server.SourceChange].
///
/// Can return experimental [server.SnippetTextEdit]s if the following are true:
/// - the client has indicated support for in the experimental section of their
///   client capabilities, and
/// - [allowSnippets] is true, and
/// - [change] contains only a single edit to the single file [filePath]
/// - [lineInfo] is provided (which should be for the single edited file)
///
/// Note: This code will fetch the version of each document being modified so
/// it's important to call this immediately after computing edits to ensure
/// the document is not modified before the version number is read.
lsp.WorkspaceEdit createWorkspaceEdit(
  AnalysisServer server,
  server.SourceChange change, {
  // The caller must specify whether snippets are valid here for where they're
  // sending this edit. Right now, support is limited to CodeActions.
  bool allowSnippets = false,
  String? filePath,
  LineInfo? lineInfo,
}) {
  // In order to return snippets, we must ensure we are only modifying a single
  // existing file with a single edit and that there is either a selection or a
  // linked edit group (otherwise there's no value in snippets).
  if (!allowSnippets ||
      !server.lspClientCapabilities!.experimentalSnippetTextEdit ||
      !server.lspClientCapabilities!.documentChanges ||
      filePath == null ||
      lineInfo == null ||
      change.edits.length != 1 ||
      change.edits.single.fileStamp == -1 || // new file
      change.edits.single.file != filePath ||
      change.edits.single.edits.length != 1 ||
      (change.selection == null && change.linkedEditGroups.isEmpty)) {
    return createPlainWorkspaceEdit(server, change.edits);
  }

  final fileEdit = change.edits.single;
  final snippetEdits = toSnippetTextEdits(
    fileEdit.file,
    fileEdit,
    change.linkedEditGroups,
    lineInfo,
    selectionOffset: change.selection?.offset,
    selectionLength: change.selectionLength,
  );

  // Compile the edits into a TextDocumentEdit for this file.
  final textDocumentEdit = lsp.TextDocumentEdit(
    textDocument: server.getVersionedDocumentIdentifier(fileEdit.file),
    edits: snippetEdits
        .map((e) => Either3<lsp.AnnotatedTextEdit, lsp.SnippetTextEdit,
            lsp.TextEdit>.t2(e))
        .toList(),
  );

  // Convert to the union that documentChanges require.
  final textDocumentEditsAsUnion = Either4<lsp.CreateFile, lsp.DeleteFile,
      lsp.RenameFile, lsp.TextDocumentEdit>.t4(textDocumentEdit);

  /// Add the textDocumentEdit to a WorkspaceEdit.
  return lsp.WorkspaceEdit(documentChanges: [textDocumentEditsAsUnion]);
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
      case server.DeclarationKind.EXTENSION_TYPE:
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
        return const [
          lsp.CompletionItemKind.File,
          lsp.CompletionItemKind.Module,
        ];
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
        return const [lsp.SymbolKind.File];
      case server.ElementKind.CONSTRUCTOR:
      case server.ElementKind.CONSTRUCTOR_INVOCATION:
        return const [lsp.SymbolKind.Constructor];
      case server.ElementKind.ENUM:
        return const [lsp.SymbolKind.Enum];
      case server.ElementKind.ENUM_CONSTANT:
        return const [lsp.SymbolKind.EnumMember, lsp.SymbolKind.Enum];
      case server.ElementKind.EXTENSION:
        return const [lsp.SymbolKind.Namespace];
      case server.ElementKind.EXTENSION_TYPE:
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

/// Returns additional details to be shown against a completion.
CompletionDetail getCompletionDetail(
  server.CompletionSuggestion suggestion, {
  required bool supportsDeprecated,
}) {
  final element = suggestion.element;
  var parameters = element?.parameters;
  var returnType = element?.returnType;

  // Extract the type from setters to be shown in the place a return type
  // would usually be shown.
  if (returnType == null &&
      element?.kind == server.ElementKind.SETTER &&
      parameters != null) {
    returnType = _completionSetterTypePattern.firstMatch(parameters)?.group(1);
    parameters = null;
  }

  final truncatedParameters = switch (parameters) {
    null || '' => '',
    '()' => '()',
    _ => '(…)',
  };
  final fullSignature = switch ((parameters, returnType)) {
    (null, _) => returnType ?? '',
    (final parameters?, null) => parameters,
    (final parameters?, '') => parameters,
    (final parameters?, _) => '$parameters → $returnType',
  };
  final truncatedSignature = switch ((parameters, returnType)) {
    (null, null) => '',
    // Include a leading space when no parameters so return type isn't right
    // against the completion label.
    (null, final returnType?) => ' $returnType',
    (_, null) || (_, '') => truncatedParameters,
    (_, final returnType?) => '$truncatedParameters → $returnType',
  };

  // Use the full signature in the details popup.
  var detail = fullSignature;
  if (suggestion.isDeprecated && !supportsDeprecated) {
    // If the item is deprecated and we don't support the native deprecated flag
    // then include it in the details.
    detail = '$detail\n\n(Deprecated)'.trim();
  }

  final autoImportUri =
      (suggestion.isNotImported ?? false) ? suggestion.libraryUri : null;

  return (
    detail: detail,
    truncatedParams: truncatedParameters,
    truncatedSignature: truncatedSignature,
    autoImportUri: autoImportUri,
  );
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

bool isDartDocument(lsp.TextDocumentIdentifier doc) => isDartUri(doc.uri);

bool isDartUri(Uri uri) => uri.path.endsWith('.dart');

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
      <Either4<CreateFile, DeleteFile, RenameFile, TextDocumentEdit>>[];

  for (final edit in edits) {
    changes.addAll(edit.documentChanges!);
  }

  return WorkspaceEdit(documentChanges: changes);
}

lsp.Location navigationTargetToLocation(
  Uri targetFileUri,
  server.NavigationTarget target,
  server.LineInfo targetLineInfo,
) {
  return lsp.Location(
    uri: targetFileUri,
    range: toRange(targetLineInfo, target.offset, target.length),
  );
}

lsp.LocationLink? navigationTargetToLocationLink(
  server.NavigationRegion region,
  server.LineInfo regionLineInfo,
  Uri targetFileUri,
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
    targetUri: targetFileUri,
    targetRange: codeRange,
    targetSelectionRange: nameRange,
  );
}

lsp.Diagnostic pluginToDiagnostic(
  path.Context pathContext,
  server.LineInfo? Function(String) getLineInfo,
  plugin.AnalysisError error, {
  required Set<lsp.DiagnosticTag>? supportedTags,
  required bool clientSupportsCodeDescription,
}) {
  List<lsp.DiagnosticRelatedInformation>? relatedInformation;
  final contextMessages = error.contextMessages;
  if (contextMessages != null && contextMessages.isNotEmpty) {
    relatedInformation = contextMessages
        .map((message) => pluginToDiagnosticRelatedInformation(
            pathContext, getLineInfo, message))
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
    // (a minor optimization to avoid unnecessary payload/(de)serialization).
    codeDescription: clientSupportsCodeDescription && documentationUrl != null
        ? CodeDescription(href: Uri.parse(documentationUrl))
        : null,
  );
}

lsp.DiagnosticRelatedInformation? pluginToDiagnosticRelatedInformation(
    path.Context pathContext,
    server.LineInfo? Function(String) getLineInfo,
    plugin.DiagnosticMessage message) {
  final file = message.location.file;
  final uri = pathContext.toUri(file);
  final lineInfo = getLineInfo(file);
  // We shouldn't get context messages for something we can't get a LineInfo for
  // but if we did, it's better to omit the context than fail to send the errors.
  if (lineInfo == null) {
    return null;
  }
  return lsp.DiagnosticRelatedInformation(
      location: lsp.Location(
        uri: uri,
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
  return switch (severity) {
    plugin.AnalysisErrorSeverity.ERROR => lsp.DiagnosticSeverity.Error,
    plugin.AnalysisErrorSeverity.WARNING => lsp.DiagnosticSeverity.Warning,
    plugin.AnalysisErrorSeverity.INFO => lsp.DiagnosticSeverity.Information,
    // Note: LSP also supports "Hint", but they won't render in things like the
    // VS Code errors list as they're apparently intended to communicate
    // non-visible diagnostics back (for example, if you wanted to grey out
    // unreachable code without producing an item in the error list).
    _ => throw 'Unknown AnalysisErrorSeverity: $severity'
  };
}

/// Converts a numeric relevance to a sortable string.
///
/// The servers relevance value is a number with highest being best. LSP uses a
/// a string sort on the `sortText` field. Subtracting the relevance from a
/// large number will produce text that will sort correctly.
///
/// Relevance can be 0, so it's important to subtract from a number like 999
/// and not 1000 or the 0 relevance items will sort at the top instead of the
/// bottom.
///
/// 1000000 -> 9999999 - 1000000 -> 8 999 999
///     555 -> 9999999 -     555 -> 9 999 444
///      10 -> 9999999 -      10 -> 9 999 989
///       1 -> 9999999 -       1 -> 9 999 998
///       0 -> 9999999 -       0 -> 9 999 999
String relevanceToSortText(int relevance) =>
    (sortTextMaxValue - relevance).toString();

/// Creates a SnippetTextEdit for a set of edits using Linked Edit Groups.
///
/// Edit groups offsets are based on the entire content being modified after all
/// edits, so [editOffset] must to take into account both the offset of the edit
/// _and_ any delta from edits prior to this one in the file.
///
/// [selectionOffset] is also absolute and assumes [edit.replacement] will be
/// inserted at [editOffset].
lsp.SnippetTextEdit snippetTextEditFromEditGroups(
  String filePath,
  server.LineInfo lineInfo,
  server.SourceEdit edit, {
  required List<server.LinkedEditGroup> editGroups,
  required int editOffset,
  required int? selectionOffset,
  required int? selectionLength,
}) {
  return lsp.SnippetTextEdit(
    insertTextFormat: lsp.InsertTextFormat.Snippet,
    range: toRange(lineInfo, edit.offset, edit.length),
    newText: buildSnippetStringForEditGroups(
      edit.replacement,
      filePath: filePath,
      editGroups: editGroups,
      editOffset: editOffset,
      selectionOffset: selectionOffset,
      selectionLength: selectionLength,
    ),
  );
}

/// Creates a SnippetTextEdit for an edit with a selection placeholder.
///
/// [selectionOffset] is relative to (and therefore must be within) the edit.
lsp.SnippetTextEdit snippetTextEditWithSelection(
  server.LineInfo lineInfo,
  server.SourceEdit edit, {
  required int selectionOffsetRelative,
  int? selectionLength,
}) {
  return lsp.SnippetTextEdit(
    insertTextFormat: lsp.InsertTextFormat.Snippet,
    range: toRange(lineInfo, edit.offset, edit.length),
    newText: buildSnippetStringWithTabStops(
      edit.replacement,
      [selectionOffsetRelative, selectionLength ?? 0],
    ),
  );
}

lsp.CompletionItem snippetToCompletionItem(
  lsp.LspAnalysisServer server,
  LspClientCapabilities capabilities,
  String file,
  LineInfo lineInfo,
  Position position,
  Snippet snippet,
) {
  assert(capabilities.completionSnippets);

  final formats = capabilities.completionDocumentationFormats;
  final documentation = snippet.documentation;
  final supportsAsIsInsertMode =
      capabilities.completionInsertTextModes.contains(InsertTextMode.asIs);
  final changes = snippet.change;

  // We must only get one change for this file to be able to apply snippets.
  final thisFilesChange = changes.edits.singleWhere((e) => e.file == file);
  final otherFilesChanges = changes.edits.where((e) => e.file != file).toList();

  // If this completion involves editing other files, we'll need to build
  // a command that the client will call to apply those edits later, because
  // LSP Completions can only provide simple edits for the current file.
  Command? command;
  if (otherFilesChanges.isNotEmpty) {
    final workspaceEdit = createPlainWorkspaceEdit(server, otherFilesChanges);
    command = Command(
        title: 'Add import',
        command: Commands.sendWorkspaceEdit,
        arguments: [
          {'edit': workspaceEdit}
        ]);
  }

  /// Convert the changes to TextEdits using snippet tokens for linked edit
  /// groups.
  final mainFileEdits = toSnippetTextEdits(
    file,
    thisFilesChange,
    changes.linkedEditGroups,
    lineInfo,
    selectionOffset:
        changes.selection?.file == file ? changes.selection?.offset : null,
    selectionLength:
        changes.selection?.file == file ? changes.selectionLength : null,
  );

  // For LSP, we need to provide the main edit and other edits separately. The
  // main edit must include the location that completion was invoked. If we find
  // more than one, take the first one since imports are usually added as later
  // edits (so when applied sequentially they will be inserted at the start of
  // the file after the other edits).
  final mainEdit = mainFileEdits
      .firstWhere((edit) => edit.range.start.line == position.line);
  final nonMainEdits = mainFileEdits.where((edit) => edit != mainEdit).toList();

  return lsp.CompletionItem(
    label: snippet.label,
    filterText: snippet.prefix.orNullIfSameAs(snippet.label),
    kind: lsp.CompletionItemKind.Snippet,
    command: command,
    documentation: documentation != null
        ? asMarkupContentOrString(formats, documentation)
        : null,
    // Force snippets to be sorted at the bottom of the list.
    // TODO(dantup): Consider if we can rank these better. Client-side
    //   snippets have always been forced to the bottom partly because they
    //   show up in more places than wanted.
    sortText: 'zzz${snippet.prefix}',
    insertTextFormat: lsp.InsertTextFormat.Snippet,
    insertTextMode: supportsAsIsInsertMode ? InsertTextMode.asIs : null,
    textEdit: Either2<InsertReplaceEdit, TextEdit>.t2(mainEdit),
    additionalTextEdits: nonMainEdits.nullIfEmpty,
  );
}

/// Sorts a list of [server.SourceEdit]s for mapping to LSP types.
///
/// Server works with edits that can be applied sequentially to a [String]. This
/// means inserts at the same offset are in the reverse order. For LSP, all
/// offsets relate to the original document and inserts with the same offset
/// appear in the order they will appear in the final document.
List<server.SourceEdit> sortSourceEditsForLsp(List<server.SourceEdit> edits) {
  // Since for LSP the ordering of items without the same offset do not matter,
  // we can simply reverse the entire list.
  return edits.reversed.toList();
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
      .replaceAll('analysisOptions.fix', lsp.CodeActionKind.QuickFix.toString())
      .replaceAll('pubspec.assist', lsp.CodeActionKind.Refactor.toString())
      .replaceAll('pubspec.fix', lsp.CodeActionKind.QuickFix.toString());

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
  bool hasDefaultEditRange = false,
  bool hasDefaultTextMode = false,
  required Range replacementRange,
  required Range insertionRange,
  required DocumentationPreference includeDocumentation,
  required bool commitCharactersEnabled,
  required bool completeFunctionCalls,
  CompletionItemResolutionInfo? resolutionData,
}) {
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
  if (!isCallable || !isInvocation) {
    completeFunctionCalls = false;
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
  final useLabelDetails = capabilities.completionLabelDetails;

  var label = suggestion.displayText ?? suggestion.completion;
  assert(label.isNotEmpty);

  // Displayed labels may have additional info appended (for example '(...)' on
  // callables and ` => ` on getters) that should not be included in filterText,
  // so strip anything from the first paren/space.
  final filterText = label.split(_completionFilterTextSplitPattern).first;

  // If we're using label details, we also don't want the label to include any
  // additional symbols as noted above, because they will appear in the extra
  // details fields.
  if (useLabelDetails) {
    label = filterText;
  }

  // Trim any trailing comma from the (displayed) label.
  if (label.endsWith(',')) {
    label = label.substring(0, label.length - 1);
  }

  final element = suggestion.element;
  final completionKind = element != null
      ? elementKindToCompletionItemKind(
          capabilities.completionItemKinds, element.kind)
      : suggestionKindToCompletionItemKind(
          capabilities.completionItemKinds, suggestion.kind, label);

  var labelDetails = getCompletionDetail(
    suggestion,
    supportsDeprecated:
        supportsCompletionDeprecatedFlag || supportsDeprecatedTag,
  );

  // For legacy display, include short params on the end of labels as long as
  // the item doesn't have custom display text (which may already include
  // params).
  if (!useLabelDetails && suggestion.displayText == null) {
    label += labelDetails.truncatedParams;
  }

  final insertTextInfo = _buildInsertText(
    supportsSnippets: supportsSnippets,
    commitCharactersEnabled: commitCharactersEnabled,
    completeFunctionCalls: completeFunctionCalls,
    requiredArgumentListString: suggestion.defaultArgumentListString,
    requiredArgumentListTextRanges: suggestion.defaultArgumentListTextRanges,
    hasOptionalParameters: suggestion.parameterNames?.isNotEmpty ?? false,
    completion: suggestion.completion,
    selectionOffset: suggestion.selectionOffset,
    selectionLength: suggestion.selectionLength,
  );
  final insertText = insertTextInfo.text;
  final insertTextFormat = insertTextInfo.format;
  final isMultilineCompletion = insertText.contains('\n');

  final rawDoc = includeDocumentation == DocumentationPreference.full
      ? suggestion.docComplete
      : includeDocumentation == DocumentationPreference.summary
          ? suggestion.docSummary
          : null;
  var cleanedDoc = cleanDartdoc(rawDoc);

  // To improve the display of some items (like pubspec version numbers),
  // short labels in the format `_foo_` in docComplete are "upgraded" to the
  // detail field.
  final labelMatch = cleanedDoc != null
      ? _upgradableDocCompletePattern.firstMatch(cleanedDoc)
      : null;
  if (labelMatch != null) {
    cleanedDoc = null;
    labelDetails = (
      detail: labelMatch.group(1)!,
      truncatedParams: labelDetails.truncatedParams,
      truncatedSignature: labelDetails.truncatedSignature,
      autoImportUri: labelDetails.autoImportUri,
    );
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
    data: resolutionData,
    detail: labelDetails.detail.nullIfEmpty,
    labelDetails: useLabelDetails
        ? CompletionItemLabelDetails(
            detail: labelDetails.truncatedSignature.nullIfEmpty,
            description: labelDetails.autoImportUri,
          ).nullIfEmpty
        : null,
    documentation: cleanedDoc != null
        ? asMarkupContentOrString(formats, cleanedDoc)
        : null,
    deprecated: supportsCompletionDeprecatedFlag && suggestion.isDeprecated
        ? true
        : null,
    sortText: relevanceToSortText(suggestion.relevance),
    filterText:
        filterText.orNullIfSameAs(label), // filterText uses label if not set
    insertTextFormat: insertTextFormat != lsp.InsertTextFormat.PlainText
        ? insertTextFormat
        : null, // Defaults to PlainText if not supplied
    insertTextMode:
        !hasDefaultTextMode && supportsAsIsInsertMode && isMultilineCompletion
            ? InsertTextMode.asIs
            : null,
    // When using defaults for edit range, don't use textEdit.
    textEdit: hasDefaultEditRange
        ? null
        : supportsInsertReplace && insertionRange != replacementRange
            ? Either2<InsertReplaceEdit, TextEdit>.t1(
                InsertReplaceEdit(
                  insert: insertionRange,
                  replace: replacementRange,
                  newText: insertText,
                ),
              )
            : Either2<InsertReplaceEdit, TextEdit>.t2(
                TextEdit(
                  range: replacementRange,
                  newText: insertText,
                ),
              ),
    // When using defaults for edit range, use textEditText.
    textEditText: hasDefaultEditRange ? insertText.orNullIfSameAs(label) : null,
  );
}

lsp.Diagnostic toDiagnostic(
  path.Context pathContext,
  server.ResolvedUnitResult result,
  server.AnalysisError error, {
  required Set<lsp.DiagnosticTag> supportedTags,
  required bool clientSupportsCodeDescription,
}) {
  return pluginToDiagnostic(
    pathContext,
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
    attributes: attributes
        ?.map((attribute) => toFlutterOutlineAttribute(lineInfo, attribute))
        .toList(),
    dartElement: dartElement != null ? toElement(lineInfo, dartElement) : null,
    range: toRange(lineInfo, outline.offset, outline.length),
    codeRange: toRange(lineInfo, outline.codeOffset, outline.codeLength),
    children: children?.map((c) => toFlutterOutline(lineInfo, c)).toList(),
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
    server.LineInfo lineInfo, List<server.Occurrences> occurrences) {
  return occurrences
      .map((occurrence) => occurrence.offsets.map((offset) =>
          lsp.DocumentHighlight(
              range: toRange(lineInfo, offset, occurrence.length))))
      .expand((occurrences) => occurrences)
      .toSet()
      .toList();
}

lsp.Location toLocation(path.Context pathContext, server.Location location,
        server.LineInfo lineInfo) =>
    lsp.Location(
      uri: pathContext.toUri(location.file),
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
    children: children?.map((c) => toOutline(lineInfo, c)).toList(),
  );
}

lsp.Position toPosition(server.CharacterLocation location) {
  // LSP is zero-based, but analysis server is 1-based.
  return lsp.Position(
      line: location.lineNumber - 1, character: location.columnNumber - 1);
}

lsp.Range toRange(server.LineInfo lineInfo, int offset, int length) {
  assert(offset >= 0);
  assert(length >= 0);
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
      params.add('[${positionalOptional.map(getParamLabel).join(', ')}]');
    }
    if (named.isNotEmpty) {
      params.add('{${named.map(getParamLabel).join(', ')}}');
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
            ? asMarkupContentOrString(preferredFormats, cleanedDoc)
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

List<lsp.SnippetTextEdit> toSnippetTextEdits(
  String filePath,
  server.SourceFileEdit change,
  List<server.LinkedEditGroup> editGroups,
  LineInfo lineInfo, {
  required int? selectionOffset,
  required int? selectionLength,
}) {
  final snippetEdits = <lsp.SnippetTextEdit>[];

  // Edit groups offsets are based on the document after the edits are applied.
  // This means we must compute an offset delta for each edit that takes into
  // account all edits that might be made before it in the document (which are
  // after it in the edits). To do this, reverse the list when computing the
  // offsets, but reverse them back to the original list order when returning so
  // that we do not apply them incorrectly in tests (where we will apply them
  // in-sequence).

  var offsetDelta = 0;
  for (final edit in change.edits.reversed) {
    snippetEdits.add(snippetTextEditFromEditGroups(
      filePath,
      lineInfo,
      edit,
      editGroups: editGroups,
      editOffset: edit.offset + offsetDelta,
      selectionOffset: selectionOffset,
      selectionLength: selectionLength,
    ));

    offsetDelta += edit.replacement.length - edit.length;
  }

  return snippetEdits.reversed.toList();
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
      edits: sortSourceEditsForLsp(edit.edits)
          .map((e) => toTextDocumentEditEdit(capabilities, edit.lineInfo, e,
              selectionOffsetRelative: edit.selectionOffsetRelative,
              selectionLength: edit.selectionLength))
          .toList());
}

Either3<lsp.AnnotatedTextEdit, lsp.SnippetTextEdit, lsp.TextEdit>
    toTextDocumentEditEdit(
  LspClientCapabilities capabilities,
  server.LineInfo lineInfo,
  server.SourceEdit edit, {
  int? selectionOffsetRelative,
  int? selectionLength,
}) {
  if (!capabilities.experimentalSnippetTextEdit ||
      selectionOffsetRelative == null) {
    return Either3<lsp.AnnotatedTextEdit, lsp.SnippetTextEdit, lsp.TextEdit>.t3(
        toTextEdit(lineInfo, edit));
  }
  return Either3<lsp.AnnotatedTextEdit, lsp.SnippetTextEdit, lsp.TextEdit>.t2(
      snippetTextEditWithSelection(lineInfo, edit,
          selectionOffsetRelative: selectionOffsetRelative,
          selectionLength: selectionLength));
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
    final changes = <Either4<lsp.CreateFile, lsp.DeleteFile, lsp.RenameFile,
        lsp.TextDocumentEdit>>[];

    // Convert each SourceEdit to either a TextDocumentEdit or a
    // CreateFile + a TextDocumentEdit depending on whether it's a new
    // file.
    for (final edit in edits) {
      if (supportsCreate && edit.newFile) {
        final create = lsp.CreateFile(uri: edit.doc.uri);
        final createUnion = Either4<lsp.CreateFile, lsp.DeleteFile,
            lsp.RenameFile, lsp.TextDocumentEdit>.t1(create);
        changes.add(createUnion);
      }

      final textDocEdit = toTextDocumentEdit(capabilities, edit);
      final textDocEditUnion = Either4<lsp.CreateFile, lsp.DeleteFile,
          lsp.RenameFile, lsp.TextDocumentEdit>.t4(textDocEdit);
      changes.add(textDocEditUnion);
    }

    return lsp.WorkspaceEdit(documentChanges: changes);
  } else {
    return lsp.WorkspaceEdit(changes: toWorkspaceEditChanges(edits));
  }
}

Map<Uri, List<lsp.TextEdit>> toWorkspaceEditChanges(
    List<FileEditInformation> edits) {
  MapEntry<Uri, List<lsp.TextEdit>> createEdit(FileEditInformation file) {
    final edits = sortSourceEditsForLsp(file.edits)
        .map((edit) => toTextEdit(file.lineInfo, edit))
        .toList();
    return MapEntry(file.doc.uri, edits);
  }

  return Map<Uri, List<lsp.TextEdit>>.fromEntries(edits.map(createEdit));
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

({String text, lsp.InsertTextFormat format}) _buildInsertText({
  required bool supportsSnippets,
  required bool commitCharactersEnabled,
  required bool completeFunctionCalls,
  required String? requiredArgumentListString,
  required List<int>? requiredArgumentListTextRanges,
  required bool hasOptionalParameters,
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
    if (!commitCharactersEnabled && completeFunctionCalls) {
      insertTextFormat = lsp.InsertTextFormat.Snippet;
      final hasRequiredParameters =
          requiredArgumentListTextRanges?.isNotEmpty ?? false;
      final functionCallSuffix =
          hasRequiredParameters && requiredArgumentListString != null
              ? buildSnippetStringWithTabStops(
                  requiredArgumentListString, requiredArgumentListTextRanges)
              // Optional params still gets a final tab stop in the parens.
              : hasOptionalParameters
                  ? SnippetBuilder.finalTabStop
                  // And no parameters at all we skip the tabstop in the parens.
                  : '';
      insertText =
          '${SnippetBuilder.escapeSnippetPlainText(insertText)}($functionCallSuffix)';
    } else if (selectionOffset != 0 &&
        // We don't need a tab stop if the selection is the end of the string.
        selectionOffset != completion.length) {
      insertTextFormat = lsp.InsertTextFormat.Snippet;
      insertText = buildSnippetStringWithTabStops(
          completion, [selectionOffset, selectionLength]);
    }
  }

  return (text: insertText, format: insertTextFormat);
}

String _errorCode(server.ErrorCode code) => code.name.toLowerCase();

/// Additional details about a completion that may be formatted differently
/// depending on the client capabilities.
typedef CompletionDetail = ({
  /// Additional details to go in the details popup.
  ///
  /// This is usually a full signature (with full parameters) and may also
  /// include whether the item is deprecated if the client did not support the
  /// native deprecated tag.
  String detail,

  /// Truncated parameters. Similate to [truncatedSignature] but does not
  /// include return types. Used in clients that cannot format signatures
  /// differently and is appended immediately after the completion label. The
  /// return type is ommitted to reduce noise because this text is not subtle.
  String truncatedParams,

  /// A signature with truncated params. Used for showing immediately after
  /// the completion label when it can be formatted differently.
  ///
  /// () → String
  String truncatedSignature,

  /// The URI that will be auto-imported if this item is selected.
  String? autoImportUri,
});

extension on CompletionItemLabelDetails {
  /// Returns `null` if no fields are set, otherwise `this`.
  CompletionItemLabelDetails? get nullIfEmpty =>
      detail != null || description != null ? this : null;
}

extension on String? {
  /// Returns `null` if this string is the same as [other], otherwise `this`.
  String? orNullIfSameAs(String other) => this == other ? null : this;
}

extension _ListExtensions<T> on List<T> {
  /// Returns `null` if this list is empty, otherwise `this`.
  List<T>? get nullIfEmpty => isEmpty ? null : this;
}
