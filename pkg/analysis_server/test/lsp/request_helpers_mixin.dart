// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:collection/collection.dart';
import 'package:language_server_protocol/json_parsing.dart';
import 'package:test/test.dart' as test show expect;
import 'package:test/test.dart' hide expect;

import 'change_verifier.dart';

mixin LspEditHelpersMixin {
  String applyTextEdit(String content, TextEdit edit) {
    final startPos = edit.range.start;
    final endPos = edit.range.end;
    final lineInfo = LineInfo.fromContent(content);
    final start = lineInfo.getOffsetOfLine(startPos.line) + startPos.character;
    final end = lineInfo.getOffsetOfLine(endPos.line) + endPos.character;
    return content.replaceRange(start, end, edit.newText);
  }

  String applyTextEdits(String content, List<TextEdit> changes) {
    // Complex text manipulations are described with an array of TextEdit's,
    // representing a single change to the document.
    //
    // All text edits ranges refer to positions in the original document. Text
    // edits ranges must never overlap, that means no part of the original
    // document must be manipulated by more than one edit. It is possible
    // that multiple edits have the same start position (eg. multiple inserts in
    // reverse order), however since that involves complicated tracking and we
    // only apply edits here sequentially, we don't supported them. We do sort
    // edits to ensure we apply the later ones first, so we can assume the locations
    // in the edit are still valid against the new string as each edit is applied.

    /// Ensures changes are simple enough to apply easily without any complicated
    /// logic.
    void validateChangesCanBeApplied() {
      /// Check if a position is before (but not equal) to another position.
      bool isBeforeOrEqual(Position p, Position other) =>
          p.line < other.line ||
          (p.line == other.line && p.character <= other.character);

      /// Check if a position is after (but not equal) to another position.
      bool isAfterOrEqual(Position p, Position other) =>
          p.line > other.line ||
          (p.line == other.line && p.character >= other.character);
      // Check if two ranges intersect.
      bool rangesIntersect(Range r1, Range r2) {
        var endsBefore = isBeforeOrEqual(r1.end, r2.start);
        var startsAfter = isAfterOrEqual(r1.start, r2.end);
        return !(endsBefore || startsAfter);
      }

      for (final change1 in changes) {
        for (final change2 in changes) {
          if (change1 != change2 &&
              rangesIntersect(change1.range, change2.range)) {
            throw 'Test helper applyTextEdits does not support applying multiple edits '
                'where the edits are not in reverse order.';
          }
        }
      }
    }

    validateChangesCanBeApplied();

    final indexedEdits = changes.mapIndexed(TextEditWithIndex.new).toList();
    indexedEdits.sort(TextEditWithIndex.compare);
    return indexedEdits.map((e) => e.edit).fold(content, applyTextEdit);
  }
}

/// Helpers to simplify building LSP requests for use in tests.
///
/// The actual sending of requests must be supplied by the implementing class
/// via [expectSuccessfulResponseTo].
///
/// These helpers can be used by in-process tests and out-of-process integration
/// tests and by both the native LSP server and using LSP over the legacy
/// protocol.
mixin LspRequestHelpersMixin {
  int _id = 0;

  final startOfDocPos = Position(line: 0, character: 0);

  final startOfDocRange = Range(
      start: Position(line: 0, character: 0),
      end: Position(line: 0, character: 0));

  /// Whether to include 'clientRequestTime' fields in outgoing messages.
  bool includeClientRequestTime = false;

  Future<List<CallHierarchyIncomingCall>?> callHierarchyIncoming(
      CallHierarchyItem item) {
    final request = makeRequest(
      Method.callHierarchy_incomingCalls,
      CallHierarchyIncomingCallsParams(item: item),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(CallHierarchyIncomingCall.fromJson));
  }

  Future<List<CallHierarchyOutgoingCall>?> callHierarchyOutgoing(
      CallHierarchyItem item) {
    final request = makeRequest(
      Method.callHierarchy_outgoingCalls,
      CallHierarchyOutgoingCallsParams(item: item),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(CallHierarchyOutgoingCall.fromJson));
  }

  /// Gets the entire range for [code].
  Range entireRange(String code) => Range(
        start: startOfDocPos,
        end: positionFromOffset(code.length, code),
      );

  void expect(Object? actual, Matcher matcher, {String? reason}) =>
      test.expect(actual, matcher, reason: reason);

  Future<T> expectSuccessfulResponseTo<T, R>(
      RequestMessage request, T Function(R) fromJson);

  Future<List<TextEdit>?> formatDocument(Uri fileUri) {
    final request = makeRequest(
      Method.textDocument_formatting,
      DocumentFormattingParams(
        textDocument: TextDocumentIdentifier(uri: fileUri),
        options: FormattingOptions(
            tabSize: 2,
            insertSpaces: true), // These currently don't do anything
      ),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(TextEdit.fromJson));
  }

  Future<List<TextEdit>?> formatOnType(
      Uri fileUri, Position pos, String character) {
    final request = makeRequest(
      Method.textDocument_onTypeFormatting,
      DocumentOnTypeFormattingParams(
        ch: character,
        options: FormattingOptions(
            tabSize: 2,
            insertSpaces: true), // These currently don't do anything
        textDocument: TextDocumentIdentifier(uri: fileUri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(TextEdit.fromJson));
  }

  Future<List<TextEdit>?> formatRange(Uri fileUri, Range range) {
    final request = makeRequest(
      Method.textDocument_rangeFormatting,
      DocumentRangeFormattingParams(
        options: FormattingOptions(
            tabSize: 2,
            insertSpaces: true), // These currently don't do anything
        textDocument: TextDocumentIdentifier(uri: fileUri),
        range: range,
      ),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(TextEdit.fromJson));
  }

  Future<List<Either2<Command, CodeAction>>> getCodeActions(
    Uri fileUri, {
    Range? range,
    Position? position,
    List<CodeActionKind>? kinds,
    CodeActionTriggerKind? triggerKind,
    ProgressToken? workDoneToken,
  }) {
    range ??= position != null
        ? Range(start: position, end: position)
        : throw 'Supply either a Range or Position for CodeActions requests';
    final request = makeRequest(
      Method.textDocument_codeAction,
      CodeActionParams(
        textDocument: TextDocumentIdentifier(uri: fileUri),
        range: range,
        context: CodeActionContext(
          // TODO(dantup): We may need to revise the tests/implementation when
          // it's clear how we're supposed to handle diagnostics:
          // https://github.com/Microsoft/language-server-protocol/issues/583
          diagnostics: [],
          only: kinds,
          triggerKind: triggerKind,
        ),
        workDoneToken: workDoneToken,
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(_generateFromJsonFor(Command.canParse, Command.fromJson,
          CodeAction.canParse, CodeAction.fromJson)),
    );
  }

  Future<List<ColorPresentation>> getColorPresentation(
      Uri fileUri, Range range, Color color) {
    final request = makeRequest(
      Method.textDocument_colorPresentation,
      ColorPresentationParams(
        textDocument: TextDocumentIdentifier(uri: fileUri),
        range: range,
        color: color,
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(ColorPresentation.fromJson),
    );
  }

  Future<List<CompletionItem>> getCompletion(Uri uri, Position pos,
      {CompletionContext? context}) async {
    final response = await getCompletionList(uri, pos, context: context);
    return response.items;
  }

  Future<CompletionList> getCompletionList(Uri uri, Position pos,
      {CompletionContext? context}) {
    final request = makeRequest(
      Method.textDocument_completion,
      CompletionParams(
        context: context,
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(request, CompletionList.fromJson);
  }

  Future<Either2<List<Location>, List<LocationLink>>> getDefinition(
      Uri uri, Position pos) {
    final request = makeRequest(
      Method.textDocument_definition,
      TextDocumentPositionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      _generateFromJsonFor(
          _canParseList(Location.canParse),
          _fromJsonList(Location.fromJson),
          _canParseList(LocationLink.canParse),
          _fromJsonList(LocationLink.fromJson)),
    );
  }

  Future<List<Location>> getDefinitionAsLocation(Uri uri, Position pos) async {
    final results = await getDefinition(uri, pos);
    return results.map(
      (locations) => locations,
      (locationLinks) => throw 'Expected List<Location> got List<LocationLink>',
    );
  }

  Future<List<LocationLink>> getDefinitionAsLocationLinks(
      Uri uri, Position pos) async {
    final results = await getDefinition(uri, pos);
    return results.map(
      (locations) => throw 'Expected List<LocationLink> got List<Location>',
      (locationLinks) => locationLinks,
    );
  }

  Future<DartDiagnosticServer> getDiagnosticServer() {
    final request = makeRequest(
      CustomMethods.diagnosticServer,
      null,
    );
    return expectSuccessfulResponseTo(request, DartDiagnosticServer.fromJson);
  }

  Future<List<ColorInformation>> getDocumentColors(Uri fileUri) {
    final request = makeRequest(
      Method.textDocument_documentColor,
      DocumentColorParams(
        textDocument: TextDocumentIdentifier(uri: fileUri),
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(ColorInformation.fromJson),
    );
  }

  Future<List<DocumentHighlight>?> getDocumentHighlights(
      Uri uri, Position pos) {
    final request = makeRequest(
      Method.textDocument_documentHighlight,
      TextDocumentPositionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(DocumentHighlight.fromJson));
  }

  Future<Either2<List<DocumentSymbol>, List<SymbolInformation>>>
      getDocumentSymbols(Uri uri) {
    final request = makeRequest(
      Method.textDocument_documentSymbol,
      DocumentSymbolParams(
        textDocument: TextDocumentIdentifier(uri: uri),
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      _generateFromJsonFor(
          _canParseList(DocumentSymbol.canParse),
          _fromJsonList(DocumentSymbol.fromJson),
          _canParseList(SymbolInformation.canParse),
          _fromJsonList(SymbolInformation.fromJson)),
    );
  }

  Future<List<FoldingRange>> getFoldingRanges(Uri uri) {
    final request = makeRequest(
      Method.textDocument_foldingRange,
      FoldingRangeParams(
        textDocument: TextDocumentIdentifier(uri: uri),
      ),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(FoldingRange.fromJson));
  }

  Future<Hover?> getHover(Uri uri, Position pos) {
    final request = makeRequest(
      Method.textDocument_hover,
      TextDocumentPositionParams(
          textDocument: TextDocumentIdentifier(uri: uri), position: pos),
    );
    return expectSuccessfulResponseTo(request, Hover.fromJson);
  }

  Future<List<Location>> getImplementations(
    Uri uri,
    Position pos, {
    includeDeclarations = false,
  }) {
    final request = makeRequest(
      Method.textDocument_implementation,
      TextDocumentPositionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(Location.fromJson));
  }

  Future<List<InlayHint>> getInlayHints(Uri uri, Range range) {
    final request = makeRequest(
      Method.textDocument_inlayHint,
      InlayHintParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        range: range,
      ),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(InlayHint.fromJson));
  }

  Future<List<Location>> getReferences(
    Uri uri,
    Position pos, {
    bool includeDeclarations = false,
  }) {
    final request = makeRequest(
      Method.textDocument_references,
      ReferenceParams(
        context: ReferenceContext(includeDeclaration: includeDeclarations),
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(Location.fromJson));
  }

  Future<CompletionItem> getResolvedCompletion(
    Uri uri,
    Position pos,
    String label, {
    CompletionContext? context,
  }) async {
    final completions = await getCompletion(uri, pos, context: context);

    final completion = completions.singleWhere((c) => c.label == label);
    expect(completion, isNotNull);

    return resolveCompletion(completion);
  }

  Future<List<SelectionRange>?> getSelectionRanges(
      Uri uri, List<Position> positions) {
    final request = makeRequest(
      Method.textDocument_selectionRange,
      SelectionRangeParams(
          textDocument: TextDocumentIdentifier(uri: uri), positions: positions),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(SelectionRange.fromJson));
  }

  Future<SemanticTokens> getSemanticTokens(Uri uri) {
    final request = makeRequest(
      Method.textDocument_semanticTokens_full,
      SemanticTokensParams(
        textDocument: TextDocumentIdentifier(uri: uri),
      ),
    );
    return expectSuccessfulResponseTo(request, SemanticTokens.fromJson);
  }

  Future<SemanticTokens> getSemanticTokensRange(Uri uri, Range range) {
    final request = makeRequest(
      Method.textDocument_semanticTokens_range,
      SemanticTokensRangeParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        range: range,
      ),
    );
    return expectSuccessfulResponseTo(request, SemanticTokens.fromJson);
  }

  Future<SignatureHelp?> getSignatureHelp(Uri uri, Position pos,
      [SignatureHelpContext? context]) {
    final request = makeRequest(
      Method.textDocument_signatureHelp,
      SignatureHelpParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
        context: context,
      ),
    );
    return expectSuccessfulResponseTo(request, SignatureHelp.fromJson);
  }

  Future<Location> getSuper(
    Uri uri,
    Position pos,
  ) {
    final request = makeRequest(
      CustomMethods.super_,
      TextDocumentPositionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(request, Location.fromJson);
  }

  Future<TextDocumentTypeDefinitionResult> getTypeDefinition(
      Uri uri, Position pos) {
    final request = makeRequest(
      Method.textDocument_typeDefinition,
      TypeDefinitionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );

    // TextDocumentTypeDefinitionResult is a nested Either, so we need to handle
    // nested fromJson/canParse here.
    // TextDocumentTypeDefinitionResult: Either2<Definition, List<DefinitionLink>>?
    // Definition: Either2<List<Location>, Location>

    // Definition = Either2<List<Location>, Location>
    final definitionCanParse = _generateCanParseFor(
      _canParseList(Location.canParse),
      Location.canParse,
    );
    final definitionFromJson = _generateFromJsonFor(
      _canParseList(Location.canParse),
      _fromJsonList(Location.fromJson),
      Location.canParse,
      Location.fromJson,
    );

    return expectSuccessfulResponseTo(
      request,
      _generateFromJsonFor(
          definitionCanParse,
          definitionFromJson,
          _canParseList(DefinitionLink.canParse),
          _fromJsonList(DefinitionLink.fromJson)),
    );
  }

  Future<List<Location>> getTypeDefinitionAsLocation(
      Uri uri, Position pos) async {
    final results = (await getTypeDefinition(uri, pos))!;
    return results.map(
      (locationOrList) => locationOrList.map(
        (locations) => locations,
        (location) => [location],
      ),
      (locationLinks) => throw 'Expected Locations, got LocationLinks',
    );
  }

  Future<List<LocationLink>> getTypeDefinitionAsLocationLinks(
      Uri uri, Position pos) async {
    final results = (await getTypeDefinition(uri, pos))!;
    return results.map(
      (locationOrList) => throw 'Expected LocationLinks, got Locations',
      (locationLinks) => locationLinks,
    );
  }

  Future<List<SymbolInformation>> getWorkspaceSymbols(String query) {
    final request = makeRequest(
      Method.workspace_symbol,
      WorkspaceSymbolParams(query: query),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(SymbolInformation.fromJson));
  }

  RequestMessage makeRequest(Method method, ToJsonable? params) {
    final id = Either2<int, String>.t1(_id++);
    return RequestMessage(
      id: id,
      method: method,
      params: params,
      jsonrpc: jsonRpcVersion,
      clientRequestTime: includeClientRequestTime
          ? DateTime.now().millisecondsSinceEpoch
          : null,
    );
  }

  Position positionFromOffset(int offset, String contents) {
    final lineInfo = LineInfo.fromContent(contents);
    return toPosition(lineInfo.getLocation(offset));
  }

  Future<List<CallHierarchyItem>?> prepareCallHierarchy(Uri uri, Position pos) {
    final request = makeRequest(
      Method.textDocument_prepareCallHierarchy,
      CallHierarchyPrepareParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(CallHierarchyItem.fromJson));
  }

  Future<PlaceholderAndRange?> prepareRename(Uri uri, Position pos) {
    final request = makeRequest(
      Method.textDocument_prepareRename,
      TextDocumentPositionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(request, PlaceholderAndRange.fromJson);
  }

  Future<List<TypeHierarchyItem>?> prepareTypeHierarchy(Uri uri, Position pos) {
    final request = makeRequest(
      Method.textDocument_prepareTypeHierarchy,
      TypeHierarchyPrepareParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(TypeHierarchyItem.fromJson));
  }

  Future<CompletionItem> resolveCompletion(CompletionItem item) {
    final request = makeRequest(
      Method.completionItem_resolve,
      item,
    );
    return expectSuccessfulResponseTo(request, CompletionItem.fromJson);
  }

  Future<List<TypeHierarchyItem>?> typeHierarchySubtypes(
      TypeHierarchyItem item) {
    final request = makeRequest(
      Method.typeHierarchy_subtypes,
      TypeHierarchySubtypesParams(item: item),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(TypeHierarchyItem.fromJson));
  }

  Future<List<TypeHierarchyItem>?> typeHierarchySupertypes(
      TypeHierarchyItem item) {
    final request = makeRequest(
      Method.typeHierarchy_supertypes,
      TypeHierarchySupertypesParams(item: item),
    );
    return expectSuccessfulResponseTo(
        request, _fromJsonList(TypeHierarchyItem.fromJson));
  }

  bool Function(Object?, LspJsonReporter) _canParseList<T>(
          bool Function(Map<String, Object?>, LspJsonReporter) canParse) =>
      (input, reporter) =>
          input is List &&
          input
              .cast<Map<String, Object?>>()
              .every((item) => canParse(item, reporter));

  List<T> Function(List<Object?>) _fromJsonList<T>(
          T Function(Map<String, Object?>) fromJson) =>
      (input) => input.cast<Map<String, Object?>>().map(fromJson).toList();

  /// Creates a `canParse()` function for an `Either2<T1, T2>` using
  /// the `canParse` function for each type.
  static bool Function(Object?, LspJsonReporter) _generateCanParseFor<T1, T2>(
    bool Function(Object?, LspJsonReporter) canParse1,
    bool Function(Object?, LspJsonReporter) canParse2,
  ) {
    return (input, reporter) =>
        canParse1(input, reporter) || canParse2(input, reporter);
  }

  /// Creates a `fromJson()` function for an `Either2<T1, T2>` using
  /// the `canParse` and `fromJson` functions for each type.
  static Either2<T1, T2> Function(Object?) _generateFromJsonFor<T1, T2, R1, R2>(
      bool Function(Object?, LspJsonReporter) canParse1,
      T1 Function(R1) fromJson1,
      bool Function(Object?, LspJsonReporter) canParse2,
      T2 Function(R2) fromJson2,
      [LspJsonReporter? reporter]) {
    reporter ??= nullLspJsonReporter;
    return (input) {
      reporter!;
      if (canParse1(input, reporter)) {
        return Either2<T1, T2>.t1(fromJson1(input as R1));
      }
      if (canParse2(input, reporter)) {
        return Either2<T1, T2>.t2(fromJson2(input as R2));
      }
      throw '$input was not one of ($T1, $T2)';
    };
  }
}
