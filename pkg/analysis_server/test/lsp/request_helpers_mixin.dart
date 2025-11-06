// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/extensions/positions.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/services/completion/dart/feature_computer.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer_plugin/src/utilities/client_uri_converter.dart';
import 'package:collection/collection.dart';
import 'package:language_server_protocol/json_parsing.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart' as test show expect;
import 'package:test/test.dart';

import '../utils/lsp_protocol_extensions.dart';
import 'change_verifier.dart';
import 'server_abstract.dart';

/// A mixin with helpers for applying LSP edits to strings.
mixin LspEditHelpersMixin {
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
    for (var change1 in changes) {
      for (var change2 in changes) {
        if (change1 != change2 && change1.range.intersects(change2.range)) {
          throw 'Test helper applyTextEdits does not support applying multiple edits '
              'where the edits are not in reverse order.';
        }
      }
    }

    var indexedEdits = changes.mapIndexed(TextEditWithIndex.new).toList();
    indexedEdits.sort(TextEditWithIndex.compare);

    var lineInfo = LineInfo.fromContent(content);
    var buffer = StringBuffer();
    var currentOffset = 0;

    // Build a new string by appending parts of the original string and then
    // the new text from each edit into a buffer. This is faster for multiple
    // edits than sorting in reverse and repeatedly applying sequentially as it
    // cuts out a lot of (potentially large) intermediate strings.
    for (var edit in indexedEdits.map((e) => e.edit)) {
      var startPos = edit.range.start;
      var endPos = edit.range.end;
      var start = lineInfo.getOffsetOfLine(startPos.line) + startPos.character;
      var end = lineInfo.getOffsetOfLine(endPos.line) + endPos.character;

      // Append any text between the current position and the start of this edit
      if (start != currentOffset) {
        buffer.write(content.substring(currentOffset, start));
      }
      // Append the replacement text
      buffer.write(edit.newText);
      // Move the current position to the end of this edit
      currentOffset = end;
    }

    // Finally, add any remainder from after the last edit.
    if (currentOffset != content.length) {
      buffer.write(content.substring(currentOffset));
    }

    return buffer.toString();
  }

  /// Returns the text for [range] in [content].
  String getTextForRange(String content, Range range) {
    var lineInfo = LineInfo.fromContent(content);
    var sourceRange = toSourceRange(lineInfo, range).result;
    return content.substring(sourceRange.offset, sourceRange.end);
  }
}

/// Helpers to simplify handling LSP notifications.
mixin LspNotificationHelpersMixin {
  /// A stream of [DartTextDocumentContentDidChangeParams] for any
  /// `dart/textDocumentContentDidChange` notifications.
  Stream<DartTextDocumentContentDidChangeParams>
  get dartTextDocumentContentDidChangeNotifications => notificationsFromServer
      .where(
        (notification) =>
            notification.method ==
            CustomMethods.dartTextDocumentContentDidChange,
      )
      .map(
        (message) => DartTextDocumentContentDidChangeParams.fromJson(
          message.params as Map<String, Object?>,
        ),
      );

  Stream<NotificationMessage> get notificationsFromServer;
}

mixin LspProgressNotificationsMixin {
  Stream<NotificationMessage> get notificationsFromServer;

  /// A stream of strings (CREATE, BEGIN, END) corresponding to progress
  /// requests and notifications for convenience in testing.
  ///
  /// Analyzing statuses are not included.
  Stream<String> get progressUpdates {
    var controller = StreamController<String>();

    requestsFromServer
        .where((r) => r.method == Method.window_workDoneProgress_create)
        .listen((request) {
          var params = WorkDoneProgressCreateParams.fromJson(
            request.params as Map<String, Object?>,
          );
          if (params.token != analyzingProgressToken) {
            controller.add('CREATE');
          }
        }, onDone: controller.close);
    notificationsFromServer.where((n) => n.method == Method.progress).listen((
      notification,
    ) {
      var params = ProgressParams.fromJson(
        notification.params as Map<String, Object?>,
      );
      if (params.token != analyzingProgressToken) {
        if (WorkDoneProgressBegin.canParse(params.value, nullLspJsonReporter)) {
          controller.add('BEGIN');
        } else if (WorkDoneProgressEnd.canParse(
          params.value,
          nullLspJsonReporter,
        )) {
          controller.add('END');
        }
      }
    });

    return controller.stream;
  }

  Stream<RequestMessage> get requestsFromServer;
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
    end: Position(line: 0, character: 0),
  );

  /// Whether to include 'clientRequestTime' fields in outgoing messages.
  bool includeClientRequestTime = false;

  /// A progress token used in tests where the client-provides the token, which
  /// should not be validated as being created by the server first.
  final clientProvidedTestWorkDoneToken = ProgressToken.t2('client-test');

  Future<List<CallHierarchyIncomingCall>?> callHierarchyIncoming(
    CallHierarchyItem item,
  ) {
    var request = makeRequest(
      Method.callHierarchy_incomingCalls,
      CallHierarchyIncomingCallsParams(item: item),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(CallHierarchyIncomingCall.fromJson),
    );
  }

  Future<List<CallHierarchyOutgoingCall>?> callHierarchyOutgoing(
    CallHierarchyItem item,
  ) {
    var request = makeRequest(
      Method.callHierarchy_outgoingCalls,
      CallHierarchyOutgoingCallsParams(item: item),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(CallHierarchyOutgoingCall.fromJson),
    );
  }

  Future<Null> connectToDtd(Uri uri, {bool? registerExperimentalHandlers}) {
    var request = makeRequest(
      CustomMethods.connectToDtd,
      ConnectToDtdParams(
        uri: uri,
        registerExperimentalHandlers: registerExperimentalHandlers,
      ),
    );
    return expectSuccessfulResponseTo<Null, Null>(request, (Null n) => n);
  }

  Future<Null> editArgument(Uri uri, Position pos, ArgumentEdit edit) {
    var request = makeRequest(
      CustomMethods.dartTextDocumentEditArgument,
      EditArgumentParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
        edit: edit,
      ),
    );
    return expectSuccessfulResponseTo(request, (Null n) => n);
  }

  /// Gets the entire range for [code].
  Range entireRange(String code) =>
      Range(start: startOfDocPos, end: positionFromOffset(code.length, code));

  Future<T> executeCommand<T>(
    Command command, {
    T Function(Map<String, Object?>)? decoder,
    ProgressToken? workDoneToken,
  }) {
    var request = makeRequest(
      Method.workspace_executeCommand,
      ExecuteCommandParams(
        command: command.command,
        arguments: command.arguments,
        workDoneToken: workDoneToken,
      ),
    );
    return expectSuccessfulResponseTo<T, Map<String, Object?>>(
      request,
      decoder ?? (result) => result as T,
    );
  }

  void expect(Object? actual, Matcher matcher, {String? reason}) =>
      test.expect(actual, matcher, reason: reason);

  Future<T> expectSuccessfulResponseTo<T, R>(
    RequestMessage request,
    T Function(R) fromJson,
  );

  Future<List<TextEdit>?> formatDocument(Uri fileUri) {
    var request = makeRequest(
      Method.textDocument_formatting,
      DocumentFormattingParams(
        textDocument: TextDocumentIdentifier(uri: fileUri),
        options: FormattingOptions(
          tabSize: 2,
          insertSpaces: true,
        ), // These currently don't do anything
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(TextEdit.fromJson),
    );
  }

  Future<List<TextEdit>?> formatOnType(
    Uri fileUri,
    Position pos,
    String character,
  ) {
    var request = makeRequest(
      Method.textDocument_onTypeFormatting,
      DocumentOnTypeFormattingParams(
        ch: character,
        options: FormattingOptions(
          tabSize: 2,
          insertSpaces: true,
        ), // These currently don't do anything
        textDocument: TextDocumentIdentifier(uri: fileUri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(TextEdit.fromJson),
    );
  }

  Future<List<TextEdit>?> formatRange(Uri fileUri, Range range) {
    var request = makeRequest(
      Method.textDocument_rangeFormatting,
      DocumentRangeFormattingParams(
        options: FormattingOptions(
          tabSize: 2,
          insertSpaces: true,
        ), // These currently don't do anything
        textDocument: TextDocumentIdentifier(uri: fileUri),
        range: range,
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(TextEdit.fromJson),
    );
  }

  Future<Location?> getAugmentation(Uri uri, Position pos) {
    var request = makeRequest(
      CustomMethods.augmentation,
      TextDocumentPositionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(request, Location.fromJson);
  }

  Future<Location?> getAugmented(Uri uri, Position pos) {
    var request = makeRequest(
      CustomMethods.augmented,
      TextDocumentPositionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(request, Location.fromJson);
  }

  Future<List<CodeAction>> getCodeActions(
    Uri fileUri, {
    Range? range,
    Position? position,
    List<CodeActionKind>? kinds,
    CodeActionTriggerKind? triggerKind,
    ProgressToken? workDoneToken,
  }) async {
    range ??= position != null
        ? Range(start: position, end: position)
        : throw 'Supply either a Range or Position for CodeActions requests';
    var request = makeRequest(
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

    var actions = await expectSuccessfulResponseTo(
      request,
      _fromJsonList(
        _generateFromJsonFor(
          CodeActionLiteral.canParse,
          CodeActionLiteral.fromJson,
          Command.canParse,
          Command.fromJson,
        ),
      ),
    );

    // As an additional check, ensure all returned values are either exact
    // matches or sub-kinds of the requested kind(s).
    if (kinds != null && kinds.isNotEmpty) {
      // Kinds must either by an exact match, or start with the
      // requested value followed by a dot (a sub-kind).
      var allowedKinds = kinds
          .expand((kind) => [equals('$kind'), startsWith('$kind.')])
          .toList();

      // Only CodeActionLiterals can be checked because bare commands do not
      // have CodeActionKinds (once they've left the server).
      var literals = actions.where((action) => action.isCodeActionLiteral);
      for (var result in literals) {
        expect(result.asCodeActionLiteral.kind.toString(), anyOf(allowedKinds));
      }
    }

    return actions;
  }

  Future<TextDocumentCodeLensResult> getCodeLens(Uri uri) {
    var request = makeRequest(
      Method.textDocument_codeLens,
      CodeLensParams(textDocument: TextDocumentIdentifier(uri: uri)),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(CodeLens.fromJson),
    );
  }

  Future<List<ColorPresentation>> getColorPresentation(
    Uri fileUri,
    Range range,
    Color color,
  ) {
    var request = makeRequest(
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

  Future<List<CompletionItem>> getCompletion(
    Uri uri,
    Position pos, {
    CompletionContext? context,
  }) async {
    var response = await getCompletionList(uri, pos, context: context);
    return response.items;
  }

  Future<CompletionList> getCompletionList(
    Uri uri,
    Position pos, {
    CompletionContext? context,
  }) async {
    var request = makeRequest(
      Method.textDocument_completion,
      CompletionParams(
        context: context,
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    var completions = await expectSuccessfulResponseTo(
      request,
      CompletionList.fromJson,
    );
    _assertMinimalCompletionListPayload(completions);
    return completions;
  }

  Future<DartTextDocumentContent?> getDartTextDocumentContent(Uri uri) {
    var request = makeRequest(
      CustomMethods.dartTextDocumentContent,
      DartTextDocumentContentParams(uri: uri),
    );
    return expectSuccessfulResponseTo(
      request,
      DartTextDocumentContent.fromJson,
    );
  }

  Future<Either2<List<Location>, List<LocationLink>>> getDefinition(
    Uri uri,
    Position pos,
  ) {
    var request = makeRequest(
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
        _fromJsonList(LocationLink.fromJson),
      ),
    );
  }

  Future<List<Location>> getDefinitionAsLocation(Uri uri, Position pos) async {
    var results = await getDefinition(uri, pos);
    return results.map(
      (locations) => locations,
      (locationLinks) => throw 'Expected List<Location> got List<LocationLink>',
    );
  }

  Future<List<LocationLink>> getDefinitionAsLocationLinks(
    Uri uri,
    Position pos,
  ) async {
    var results = await getDefinition(uri, pos);
    return results.map(
      (locations) => throw 'Expected List<LocationLink> got List<Location>',
      (locationLinks) => locationLinks,
    );
  }

  Future<DartDiagnosticServer> getDiagnosticServer() {
    var request = makeRequest(CustomMethods.diagnosticServer, null);
    return expectSuccessfulResponseTo(request, DartDiagnosticServer.fromJson);
  }

  Future<List<ColorInformation>> getDocumentColors(Uri fileUri) {
    var request = makeRequest(
      Method.textDocument_documentColor,
      DocumentColorParams(textDocument: TextDocumentIdentifier(uri: fileUri)),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(ColorInformation.fromJson),
    );
  }

  Future<List<DocumentHighlight>?> getDocumentHighlights(
    Uri uri,
    Position pos,
  ) {
    var request = makeRequest(
      Method.textDocument_documentHighlight,
      TextDocumentPositionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(DocumentHighlight.fromJson),
    );
  }

  Future<List<DocumentLink>?> getDocumentLinks(Uri uri) {
    var request = makeRequest(
      Method.textDocument_documentLink,
      DocumentLinkParams(textDocument: TextDocumentIdentifier(uri: uri)),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(DocumentLink.fromJson),
    );
  }

  Future<Either2<List<DocumentSymbol>, List<SymbolInformation>>>
  getDocumentSymbols(Uri uri) {
    var request = makeRequest(
      Method.textDocument_documentSymbol,
      DocumentSymbolParams(textDocument: TextDocumentIdentifier(uri: uri)),
    );
    return expectSuccessfulResponseTo(
      request,
      _generateFromJsonFor(
        _canParseList(DocumentSymbol.canParse),
        _fromJsonList(DocumentSymbol.fromJson),
        _canParseList(SymbolInformation.canParse),
        _fromJsonList(SymbolInformation.fromJson),
      ),
    );
  }

  Future<EditableArguments?> getEditableArguments(Uri uri, Position pos) {
    var request = makeRequest(
      CustomMethods.dartTextDocumentEditableArguments,
      TextDocumentPositionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(request, EditableArguments.fromJson);
  }

  Future<List<FoldingRange>> getFoldingRanges(Uri uri) {
    var request = makeRequest(
      Method.textDocument_foldingRange,
      FoldingRangeParams(textDocument: TextDocumentIdentifier(uri: uri)),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(FoldingRange.fromJson),
    );
  }

  Future<Hover?> getHover(Uri uri, Position pos) {
    var request = makeRequest(
      Method.textDocument_hover,
      TextDocumentPositionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(request, Hover.fromJson);
  }

  Future<List<Location>> getImplementations(
    Uri uri,
    Position pos, {
    includeDeclarations = false,
  }) {
    var request = makeRequest(
      Method.textDocument_implementation,
      TextDocumentPositionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(Location.fromJson),
    );
  }

  Future<List<Location>?> getImports(Uri uri, Position pos) {
    var request = makeRequest(
      CustomMethods.imports,
      TextDocumentPositionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(Location.fromJson),
    );
  }

  Future<List<InlayHint>> getInlayHints(Uri uri, Range range) {
    var request = makeRequest(
      Method.textDocument_inlayHint,
      InlayHintParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        range: range,
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(InlayHint.fromJson),
    );
  }

  Future<List<InlineValue>?> getInlineValues(
    Uri uri, {
    required Range visibleRange,
    required Position stoppedAt,
  }) {
    var request = makeRequest(
      Method.textDocument_inlineValue,
      InlineValueParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        range: visibleRange,
        context: InlineValueContext(
          frameId: 0,
          stoppedLocation: Range(start: stoppedAt, end: stoppedAt),
        ),
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      // Use a custom function to deserialise the response into the correct
      // kind of `InlineValue`.
      _fromJsonList((Map<String, Object?> input) {
        var reporter = nullLspJsonReporter;
        // The overlap of these types is such that a Variable or Text would also
        // match `InlineValueEvaluatableExpression.canParse` (because
        // `expression` is optional), so the order of calling canParse here
        // matters.
        if (InlineValueVariableLookup.canParse(input, reporter)) {
          return InlineValue.t3(InlineValueVariableLookup.fromJson(input));
        }
        if (InlineValueText.canParse(input, reporter)) {
          return InlineValue.t2(InlineValueText.fromJson(input));
        }
        if (InlineValueEvaluatableExpression.canParse(input, reporter)) {
          return InlineValue.t1(
            InlineValueEvaluatableExpression.fromJson(input),
          );
        }
        throw 'InlineValue did not match any valid types';
      }),
    );
  }

  Future<List<Location>> getReferences(
    Uri uri,
    Position pos, {
    bool includeDeclarations = false,
  }) {
    var request = makeRequest(
      Method.textDocument_references,
      ReferenceParams(
        context: ReferenceContext(includeDeclaration: includeDeclarations),
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(Location.fromJson),
    );
  }

  Future<CompletionItem> getResolvedCompletion(
    Uri uri,
    Position pos,
    String label, {
    CompletionContext? context,
  }) async {
    var completions = await getCompletion(uri, pos, context: context);

    var completion = completions.singleWhere((c) => c.label == label);
    expect(completion, isNotNull);

    var result = await resolveCompletion(completion);
    _assertMinimalCompletionItemPayload(result);
    return result;
  }

  Future<List<SelectionRange>?> getSelectionRanges(
    Uri uri,
    List<Position> positions,
  ) {
    var request = makeRequest(
      Method.textDocument_selectionRange,
      SelectionRangeParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        positions: positions,
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(SelectionRange.fromJson),
    );
  }

  Future<SemanticTokens> getSemanticTokens(Uri uri) {
    var request = makeRequest(
      Method.textDocument_semanticTokens_full,
      SemanticTokensParams(textDocument: TextDocumentIdentifier(uri: uri)),
    );
    return expectSuccessfulResponseTo(request, SemanticTokens.fromJson);
  }

  Future<SemanticTokens> getSemanticTokensRange(Uri uri, Range range) {
    var request = makeRequest(
      Method.textDocument_semanticTokens_range,
      SemanticTokensRangeParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        range: range,
      ),
    );
    return expectSuccessfulResponseTo(request, SemanticTokens.fromJson);
  }

  Future<SignatureHelp?> getSignatureHelp(
    Uri uri,
    Position pos, [
    SignatureHelpContext? context,
  ]) {
    var request = makeRequest(
      Method.textDocument_signatureHelp,
      SignatureHelpParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
        context: context,
      ),
    );
    return expectSuccessfulResponseTo(request, SignatureHelp.fromJson);
  }

  Future<DocumentSummary> getSummary(Uri uri) {
    var request = makeRequest(
      CustomMethods.summary,
      DartTextDocumentSummaryParams(uri: uri),
    );
    return expectSuccessfulResponseTo(request, DocumentSummary.fromJson);
  }

  Future<Location> getSuper(Uri uri, Position pos) {
    var request = makeRequest(
      CustomMethods.super_,
      TextDocumentPositionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(request, Location.fromJson);
  }

  Future<TextDocumentTypeDefinitionResult> getTypeDefinition(
    Uri uri,
    Position pos,
  ) {
    var request = makeRequest(
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
    var definitionCanParse = _generateCanParseFor(
      _canParseList(Location.canParse),
      Location.canParse,
    );
    var definitionFromJson = _generateFromJsonFor(
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
        _fromJsonList(DefinitionLink.fromJson),
      ),
    );
  }

  Future<List<Location>> getTypeDefinitionAsLocation(
    Uri uri,
    Position pos,
  ) async {
    var results = (await getTypeDefinition(uri, pos))!;
    return results.map(
      (locationOrList) => locationOrList.map(
        (locations) => locations,
        (location) => [location],
      ),
      (locationLinks) => throw 'Expected Locations, got LocationLinks',
    );
  }

  Future<List<LocationLink>> getTypeDefinitionAsLocationLinks(
    Uri uri,
    Position pos,
  ) async {
    var results = (await getTypeDefinition(uri, pos))!;
    return results.map(
      (locationOrList) => throw 'Expected LocationLinks, got Locations',
      (locationLinks) => locationLinks,
    );
  }

  Future<List<SymbolInformation>> getWorkspaceSymbols(String query) {
    var request = makeRequest(
      Method.workspace_symbol,
      WorkspaceSymbolParams(query: query),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(SymbolInformation.fromJson),
    );
  }

  RequestMessage makeRequest(Method method, Object? params) {
    var id = Either2<int, String>.t1(_id++);
    return RequestMessage(
      id: id,
      method: method,
      params: params is ToJsonable ? params.toJson() : params,
      jsonrpc: jsonRpcVersion,
      clientRequestTime: includeClientRequestTime
          ? DateTime.now().millisecondsSinceEpoch
          : null,
    );
  }

  Future<WorkspaceEdit> onWillRename(List<FileRename> renames) {
    var request = makeRequest(
      Method.workspace_willRenameFiles,
      RenameFilesParams(files: renames),
    );
    return expectSuccessfulResponseTo(request, WorkspaceEdit.fromJson);
  }

  Position positionFromOffset(int offset, String contents) {
    var lineInfo = LineInfo.fromContent(contents);
    return toPosition(lineInfo.getLocation(offset));
  }

  Future<List<CallHierarchyItem>?> prepareCallHierarchy(Uri uri, Position pos) {
    var request = makeRequest(
      Method.textDocument_prepareCallHierarchy,
      CallHierarchyPrepareParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(CallHierarchyItem.fromJson),
    );
  }

  Future<PrepareRenamePlaceholder?> prepareRename(Uri uri, Position pos) {
    var request = makeRequest(
      Method.textDocument_prepareRename,
      TextDocumentPositionParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      PrepareRenamePlaceholder.fromJson,
    );
  }

  Future<List<TypeHierarchyItem>?> prepareTypeHierarchy(Uri uri, Position pos) {
    var request = makeRequest(
      Method.textDocument_prepareTypeHierarchy,
      TypeHierarchyPrepareParams(
        textDocument: TextDocumentIdentifier(uri: uri),
        position: pos,
      ),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(TypeHierarchyItem.fromJson),
    );
  }

  Future<CompletionItem> resolveCompletion(CompletionItem item) {
    var request = makeRequest(Method.completionItem_resolve, item);
    return expectSuccessfulResponseTo(request, CompletionItem.fromJson);
  }

  Future<ResponseMessage> sendRequestToServer(RequestMessage request);

  Future<List<TypeHierarchyItem>?> typeHierarchySubtypes(
    TypeHierarchyItem item,
  ) {
    var request = makeRequest(
      Method.typeHierarchy_subtypes,
      TypeHierarchySubtypesParams(item: item),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(TypeHierarchyItem.fromJson),
    );
  }

  Future<List<TypeHierarchyItem>?> typeHierarchySupertypes(
    TypeHierarchyItem item,
  ) {
    var request = makeRequest(
      Method.typeHierarchy_supertypes,
      TypeHierarchySupertypesParams(item: item),
    );
    return expectSuccessfulResponseTo(
      request,
      _fromJsonList(TypeHierarchyItem.fromJson),
    );
  }

  Future<void> updateDiagnosticInformation(Map<String, Object?>? params) {
    var request = makeRequest(
      CustomMethods.updateDiagnosticInformation,
      params,
    );
    return expectSuccessfulResponseTo(request, (Null n) => n);
  }

  /// A helper that performs some checks on a completion sent back during
  /// tests to check for any unnecessary data in the payload that could be
  /// reduced.
  void _assertMinimalCompletionItemPayload(CompletionItem completion) {
    var labelDetails = completion.labelDetails;
    var textEditInsertRange = completion.textEdit?.map(
      (ranges) => ranges.insert,
      (range) => null,
    );
    var textEditReplaceRange = completion.textEdit?.map(
      (ranges) => ranges.replace,
      (range) => null,
    );
    var sortText = completion.sortText;

    // Check fields that default to label if not supplied.
    void expectNotLabel(String? value, String name) {
      expect(
        value,
        isNot(completion.label),
        reason: '$name should not be set if same as label',
      );
    }

    expectNotLabel(completion.insertText, 'insertText');
    expectNotLabel(completion.filterText, 'filterText');
    expectNotLabel(completion.sortText, 'sortText');
    expectNotLabel(completion.textEditText, 'textEditText');

    // If we have separate insert/replace ranges, they should not be the same.
    if (textEditInsertRange != null) {
      expect(textEditReplaceRange, isNot(textEditInsertRange));
    }

    // Check for empty labelDetails.
    if (labelDetails != null) {
      expect(
        labelDetails.description != null || labelDetails.detail != null,
        isTrue,
        reason: 'labelDetails should be null if all fields are null',
      );
    }

    // Check for empty lists.
    void expectNotEmpty(Object? value, String name) {
      expect(
        value,
        anyOf(isNull, isNotEmpty),
        reason: '$name should be null if no items',
      );
    }

    expectNotEmpty(completion.additionalTextEdits, 'additionalTextEdits');
    expectNotEmpty(completion.commitCharacters, 'commitCharacters');
    expectNotEmpty(completion.tags, 'tags');

    // We convert numeric relevance scores into text because LSP uses text
    // for sorting. We never need to use more digits in the sortText than there
    // are in the maximum relevance for this.
    //
    // Only do this for sort texts that are numeric because we also use zzz
    // prefixes with text for snippets.
    if (sortText != null && int.tryParse(sortText) != null) {
      expect(
        sortText.length,
        lessThanOrEqualTo(maximumRelevance.toString().length),
        reason:
            'sortText never needs to have more characters '
            'than "$maximumRelevance" (${maximumRelevance.bitLength})',
      );
    }
  }

  /// A helper that performs some checks on all completions sent back during
  /// tests to check for any unnecessary data in the payload that could be
  /// reduced.
  void _assertMinimalCompletionListPayload(CompletionList completions) {
    for (var completion in completions.items) {
      var data = completion.data;
      var commitCharacters = completion.commitCharacters;
      var insertRange = completion.textEdit?.map(
        (insertReplace) => insertReplace.insert,
        (textEdit) => null,
      );
      var replaceRange = completion.textEdit?.map(
        (insertReplace) => insertReplace.replace,
        (textEdit) => null,
      );
      var combinedRange = completion.textEdit?.map(
        (insertReplace) => null,
        (textEdit) => textEdit.range,
      );
      var insertTextFormat = completion.insertTextFormat;
      var insertTextMode = completion.insertTextMode;

      var defaults = completions.itemDefaults;
      var defaultInsertRange = defaults?.editRange?.map(
        (editRange) => editRange.insert,
        (range) => null,
      );
      var defaultReplaceRange = defaults?.editRange?.map(
        (editRange) => editRange.replace,
        (range) => null,
      );
      var defaultCombinedRange = defaults?.editRange?.map(
        (editRange) => null,
        (range) => range,
      );

      _assertMinimalCompletionItemPayload(completion);

      // Check for fields matching defaults.
      if (defaults != null) {
        void expectNotDefault(Object? value, Object? default_, String name) {
          if (value == null) return;
          expect(
            value,
            isNot(default_),
            reason: '$name should be omitted if same as default',
          );
        }

        expectNotDefault(data?.toJson(), defaults.data, 'data');
        expectNotDefault(
          commitCharacters,
          defaults.commitCharacters,
          'commitCharacters',
        );

        expectNotDefault(insertRange, defaultInsertRange, 'insertRange');
        expectNotDefault(replaceRange, defaultReplaceRange, 'replaceRange');
        expectNotDefault(combinedRange, defaultCombinedRange, 'combined range');
        expectNotDefault(
          insertTextFormat,
          defaults.insertTextFormat,
          'insertTextFormat',
        );
        expectNotDefault(
          insertTextMode,
          defaults.insertTextMode,
          'insertTextMode',
        );
      }

      // If we have separate insert/replace ranges, they should not be the same.
      if (defaultInsertRange != null) {
        expect(defaultReplaceRange, isNot(defaultInsertRange));
      }
    }
  }

  bool Function(Object?, LspJsonReporter) _canParseList<T>(
    bool Function(Map<String, Object?>, LspJsonReporter) canParse,
  ) =>
      (input, reporter) =>
          input is List &&
          input.cast<Map<String, Object?>>().every(
            (item) => canParse(item, reporter),
          );

  List<T> Function(List<Object?>) _fromJsonList<T>(
    T Function(Map<String, Object?>) fromJson,
  ) =>
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
    T2 Function(R2) fromJson2, [
    LspJsonReporter? reporter,
  ]) {
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

/// Helpers to simplify handling LSP reverse-requests.
///
/// The sending of responses must be supplied by the implementing class
/// via [sendResponseToServer].
mixin LspReverseRequestHelpersMixin {
  /// A stream of reverse-requests from the server that can be responded to via
  /// [sendResponseToServer].
  ///
  /// Only LSP message requests (`lsp.handle`) from the server are included
  /// here.
  Stream<RequestMessage> get requestsFromServer;

  /// Expects a [method] request from the server after executing [f].
  Future<RequestMessage> expectRequest(
    Method method,
    FutureOr<void> Function() f, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    var firstRequest = requestsFromServer.firstWhere((n) => n.method == method);
    await f();

    var requestFromServer = await firstRequest.timeout(
      timeout,
      onTimeout: () => throw TimeoutException(
        'Did not receive the expected $method request from the server in the timeout period',
        timeout,
      ),
    );

    expect(requestFromServer, isNotNull);
    return requestFromServer;
  }

  /// Executes [f] then waits for a request of type [method] from the server which
  /// is passed to [handler] to process, then waits for (and returns) the
  /// response to the original request.
  ///
  /// This is used for testing things like code actions, where the client initiates
  /// a request but the server does not respond to it until it's sent its own
  /// request to the client and it received a response.
  ///
  ///     Client                                 Server
  ///     1. |- Req: textDocument/codeAction      ->
  ///     1. <- Resp: textDocument/codeAction     -|
  ///
  ///     2. |- Req: workspace/executeCommand  ->
  ///           3. <- Req: textDocument/applyEdits  -|
  ///           3. |- Resp: textDocument/applyEdits ->
  ///     2. <- Resp: workspace/executeCommand -|
  ///
  /// Request 2 from the client is not responded to until the server has its own
  /// response to the request it sends (3).
  Future<T> handleExpectedRequest<T, R, RR>(
    Method method,
    R Function(Map<String, dynamic>) fromJson,
    Future<T> Function() f, {
    required FutureOr<RR> Function(R) handler,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    late Future<T> outboundRequest;
    Object? outboundRequestError;

    // Run [f] and wait for the incoming request from the server.
    var incomingRequest =
        await expectRequest(method, () {
          // Don't return/await the response yet, as this may not complete until
          // after we have handled the request that comes from the server.
          outboundRequest = f();

          // Because we don't await this future until "later", if it throws the
          // error is treated as unhandled and will fail the test even if expected.
          // Instead, capture the error and suppress it. But if we time out (in
          // which case we will never return outboundRequest), then we'll raise this
          // error.
          outboundRequest.then(
            (_) {},
            onError: (e) {
              outboundRequestError = e;
              return null;
            },
          );
        }, timeout: timeout).catchError((Object timeoutException) {
          // We timed out waiting for the request from the server. Probably this is
          // because our outbound request for some reason, so if we have an error
          // for that, then throw it. Otherwise, propogate the timeout.
          throw outboundRequestError ?? timeoutException;
        }, test: (e) => e is TimeoutException);

    // Handle the request from the server and send the response back.
    var clientsResponse = await handler(
      fromJson(incomingRequest.params as Map<String, Object?>),
    );
    respondTo(incomingRequest, clientsResponse);

    // Return a future that completes when the response to the original request
    // (from [f]) returns.
    return outboundRequest;
  }

  /// Sends [responseParams] to the server as a successful response to
  /// a server-initiated [request].
  void respondTo<T>(RequestMessage request, T responseParams) {
    sendResponseToServer(
      ResponseMessage(
        id: request.id,
        result: responseParams,
        jsonrpc: jsonRpcVersion,
      ),
    );
  }

  /// Sends a ResponseMessage to the server, completing a reverse
  /// (server-to-client) request.
  void sendResponseToServer(ResponseMessage response);
}

/// A mixin with helpers for verifying LSP edits in a given project.
///
/// Extends [LspEditHelpersMixin] with methods for accessing file state and
/// information about the project to build paths.
mixin LspVerifyEditHelpersMixin
    on LspEditHelpersMixin, ClientCapabilitiesHelperMixin {
  LspClientCapabilities get editorClientCapabilities => LspClientCapabilities(
    ClientCapabilities(
      workspace: workspaceCapabilities,
      textDocument: textDocumentCapabilities,
      window: windowCapabilities,
      experimental: experimentalCapabilities,
    ),
  );

  path.Context get pathContext;

  String get projectFolderPath;

  ClientUriConverter get uriConverter;

  Future<T> executeCommand<T>(
    Command command, {
    T Function(Map<String, Object?>)? decoder,
    ProgressToken? workDoneToken,
  });

  /// Executes [command] which is expected to call back to the client to apply
  /// a [WorkspaceEdit].
  ///
  /// Returns a [LspChangeVerifier] that can be used to verify changes.
  Future<LspChangeVerifier> executeCommandForEdits(
    Command command, {
    ProgressToken? workDoneToken,
  }) {
    return executeForEdits(
      () => executeCommand(command, workDoneToken: workDoneToken),
    );
  }

  /// Executes a function which is expected to call back to the client to apply
  /// a [WorkspaceEdit].
  ///
  /// Returns a [LspChangeVerifier] that can be used to verify changes.
  Future<LspChangeVerifier> executeForEdits(
    Future<Object?> Function() function, {
    ApplyWorkspaceEditResult? applyEditResult,
  }) async {
    ApplyWorkspaceEditParams? editParams;

    var commandResponse =
        await handleExpectedRequest<
          Object?,
          ApplyWorkspaceEditParams,
          ApplyWorkspaceEditResult
        >(
          Method.workspace_applyEdit,
          ApplyWorkspaceEditParams.fromJson,
          function,
          handler: (edit) {
            // When the server sends the edit back, just keep a copy and say we
            // applied successfully (it'll be verified by the caller).
            editParams = edit;
            return applyEditResult ?? ApplyWorkspaceEditResult(applied: true);
          },
        );
    // Successful edits return an empty success() response.
    expect(commandResponse, isNull);

    // Ensure the edit came back, and using the expected change type.
    expect(editParams, isNotNull);
    var edit = editParams!.edit;

    var expectDocumentChanges = editorClientCapabilities.documentChanges;
    expect(edit.documentChanges, expectDocumentChanges ? isNotNull : isNull);
    expect(edit.changes, expectDocumentChanges ? isNull : isNotNull);

    return LspChangeVerifier(this, edit);
  }

  /// A function to get the current contents of a file to apply edits.
  String? getCurrentFileContent(Uri uri);

  Future<T> handleExpectedRequest<T, R, RR>(
    Method method,
    R Function(Map<String, dynamic>) fromJson,
    Future<T> Function() f, {
    required FutureOr<RR> Function(R) handler,
    Duration timeout = const Duration(seconds: 5),
  });

  /// Formats a path relative to the project root always using forward slashes.
  ///
  /// This is used in the text format for comparing edits.
  String relativePath(String filePath) => pathContext
      .relative(filePath, from: projectFolderPath)
      .replaceAll(r'\', '/');

  /// Formats a path relative to the project root always using forward slashes.
  ///
  /// This is used in the text format for comparing edits.
  String relativeUri(Uri uri) => relativePath(uriConverter.fromClientUri(uri));

  /// Verifies that executing the given command on the server results in an edit
  /// being sent in the client that updates the files to match the expected
  /// content.
  Future<LspChangeVerifier> verifyCommandEdits(
    Command command,
    String expectedContent, {
    ProgressToken? workDoneToken,
  }) async {
    var verifier = await executeCommandForEdits(
      command,
      workDoneToken: workDoneToken,
    );

    verifier.verifyFiles(expectedContent);
    return verifier;
  }

  LspChangeVerifier verifyEdit(
    WorkspaceEdit edit,
    String expected, {
    Map<Uri, int>? expectedVersions,
  }) {
    var expectDocumentChanges =
        workspaceCapabilities.workspaceEdit?.documentChanges ?? false;
    expect(edit.documentChanges, expectDocumentChanges ? isNotNull : isNull);
    expect(edit.changes, expectDocumentChanges ? isNull : isNotNull);

    var verifier = LspChangeVerifier(this, edit);
    verifier.verifyFiles(expected, expectedVersions: expectedVersions);
    return verifier;
  }
}
