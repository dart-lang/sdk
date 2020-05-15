// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix/dart/top_level_declarations.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart'
    show InconsistentAnalysisException;
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;

class CodeActionHandler extends MessageHandler<CodeActionParams,
    List<Either2<Command, CodeAction>>> {
  CodeActionHandler(LspAnalysisServer server) : super(server);
  @override
  Method get handlesMessage => Method.textDocument_codeAction;

  @override
  LspJsonHandler<CodeActionParams> get jsonHandler =>
      CodeActionParams.jsonHandler;

  @override
  Future<ErrorOr<List<Either2<Command, CodeAction>>>> handle(
      CodeActionParams params, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(const []);
    }

    final capabilities = server?.clientCapabilities?.textDocument?.codeAction;

    final clientSupportsWorkspaceApplyEdit =
        server?.clientCapabilities?.workspace?.applyEdit == true;

    final clientSupportsLiteralCodeActions =
        capabilities?.codeActionLiteralSupport != null;

    final clientSupportedCodeActionKinds = HashSet<CodeActionKind>.of(
        capabilities?.codeActionLiteralSupport?.codeActionKind?.valueSet ?? []);

    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);

    return unit.mapResult((unit) {
      final startOffset = toOffset(unit.lineInfo, params.range.start);
      final endOffset = toOffset(unit.lineInfo, params.range.end);
      return startOffset.mapResult((startOffset) {
        return endOffset.mapResult((endOffset) {
          final offset = startOffset;
          final length = endOffset - startOffset;
          return _getCodeActions(
              clientSupportedCodeActionKinds,
              clientSupportsLiteralCodeActions,
              clientSupportsWorkspaceApplyEdit,
              path.result,
              params.range,
              offset,
              length,
              unit);
        });
      });
    });
  }

  /// Wraps a command in a CodeAction if the client supports it so that a
  /// CodeActionKind can be supplied.
  Either2<Command, CodeAction> _commandOrCodeAction(
    bool clientSupportsLiteralCodeActions,
    CodeActionKind kind,
    Command command,
  ) {
    return clientSupportsLiteralCodeActions
        ? Either2<Command, CodeAction>.t2(
            CodeAction(command.title, kind, null, null, command),
          )
        : Either2<Command, CodeAction>.t1(command);
  }

  /// Creates a CodeAction to apply this assist. Note: This code will fetch the
  /// version of each document being modified so it's important to call this
  /// immediately after computing edits to ensure the document is not modified
  /// before the version number is read.
  Either2<Command, CodeAction> _createAssistAction(Assist assist) {
    return Either2<Command, CodeAction>.t2(CodeAction(
      assist.change.message,
      toCodeActionKind(assist.change.id, CodeActionKind.Refactor),
      const [],
      createWorkspaceEdit(server, assist.change.edits),
      null,
    ));
  }

  /// Creates a CodeAction to apply this fix. Note: This code will fetch the
  /// version of each document being modified so it's important to call this
  /// immediately after computing edits to ensure the document is not modified
  /// before the version number is read.
  Either2<Command, CodeAction> _createFixAction(
      Fix fix, Diagnostic diagnostic) {
    return Either2<Command, CodeAction>.t2(CodeAction(
      fix.change.message,
      toCodeActionKind(fix.change.id, CodeActionKind.QuickFix),
      [diagnostic],
      createWorkspaceEdit(server, fix.change.edits),
      null,
    ));
  }

  Future<List<Either2<Command, CodeAction>>> _getAssistActions(
    HashSet<CodeActionKind> clientSupportedCodeActionKinds,
    bool clientSupportsLiteralCodeActions,
    int offset,
    int length,
    ResolvedUnitResult unit,
  ) async {
    // We only support these for clients that advertise codeActionLiteralSupport.
    if (!clientSupportsLiteralCodeActions ||
        !clientSupportedCodeActionKinds.contains(CodeActionKind.Refactor)) {
      return const [];
    }

    try {
      var context = DartAssistContextImpl(
        DartChangeWorkspace(server.currentSessions),
        unit,
        offset,
        length,
      );
      final processor = AssistProcessor(context);
      final assists = await processor.compute();
      assists.sort(Assist.SORT_BY_RELEVANCE);

      return assists.map(_createAssistAction).toList();
    } on InconsistentAnalysisException {
      // If an InconsistentAnalysisException occurs, it's likely the user modified
      // the source and therefore is no longer interested in the results, so
      // just return an empty set.
      return [];
    }
  }

  Future<ErrorOr<List<Either2<Command, CodeAction>>>> _getCodeActions(
    HashSet<CodeActionKind> kinds,
    bool supportsLiterals,
    bool supportsWorkspaceApplyEdit,
    String path,
    Range range,
    int offset,
    int length,
    ResolvedUnitResult unit,
  ) async {
    final results = await Future.wait([
      _getSourceActions(
          kinds, supportsLiterals, supportsWorkspaceApplyEdit, path),
      _getAssistActions(kinds, supportsLiterals, offset, length, unit),
      _getRefactorActions(kinds, supportsLiterals, path, offset, length, unit),
      _getFixActions(kinds, supportsLiterals, range, unit),
    ]);
    final flatResults = results.expand((x) => x).toList();
    return success(flatResults);
  }

  Future<List<Either2<Command, CodeAction>>> _getFixActions(
    HashSet<CodeActionKind> clientSupportedCodeActionKinds,
    bool clientSupportsLiteralCodeActions,
    Range range,
    ResolvedUnitResult unit,
  ) async {
    // We only support these for clients that advertise codeActionLiteralSupport.
    if (!clientSupportsLiteralCodeActions ||
        !clientSupportedCodeActionKinds.contains(CodeActionKind.QuickFix)) {
      return const [];
    }

    final lineInfo = unit.lineInfo;
    final codeActions = <Either2<Command, CodeAction>>[];
    final fixContributor = DartFixContributor();

    try {
      for (final error in unit.errors) {
        // Server lineNumber is one-based so subtract one.
        var errorLine = lineInfo.getLocation(error.offset).lineNumber - 1;
        if (errorLine >= range.start.line && errorLine <= range.end.line) {
          var workspace = DartChangeWorkspace(server.currentSessions);
          var context = DartFixContextImpl(workspace, unit, error, (name) {
            var tracker = server.declarationsTracker;
            return TopLevelDeclarationsProvider(tracker).get(
              unit.session.analysisContext,
              unit.path,
              name,
            );
          });
          final fixes = await fixContributor.computeFixes(context);
          if (fixes.isNotEmpty) {
            fixes.sort(Fix.SORT_BY_RELEVANCE);

            final diagnostic = toDiagnostic(unit, error);
            codeActions.addAll(
              fixes.map((fix) => _createFixAction(fix, diagnostic)),
            );
          }
        }
      }
      return codeActions;
    } on InconsistentAnalysisException {
      // If an InconsistentAnalysisException occurs, it's likely the user modified
      // the source and therefore is no longer interested in the results, so
      // just return an empty set.
      return [];
    }
  }

  Future<List<Either2<Command, CodeAction>>> _getRefactorActions(
    HashSet<CodeActionKind> clientSupportedCodeActionKinds,
    bool clientSupportsLiteralCodeActions,
    String path,
    int offset,
    int length,
    ResolvedUnitResult unit,
  ) async {
    // The refactor actions supported are only valid for Dart files.
    if (!AnalysisEngine.isDartFileName(path)) {
      return const [];
    }

    // If the client told us what kinds they support but it does not include
    // Refactor then don't return any.
    if (clientSupportsLiteralCodeActions &&
        !clientSupportedCodeActionKinds.contains(CodeActionKind.Refactor)) {
      return const [];
    }

    /// Helper to create refactors that execute commands provided with
    /// the current file, location and document version.
    Either2<Command, CodeAction> createRefactor(
      CodeActionKind actionKind,
      String name,
      RefactoringKind refactorKind, [
      Map<String, dynamic> options,
    ]) {
      return _commandOrCodeAction(
          clientSupportsLiteralCodeActions,
          actionKind,
          Command(name, Commands.performRefactor, [
            refactorKind.toJson(),
            path,
            server.getVersionedDocumentIdentifier(path).version,
            offset,
            length,
            options,
          ]));
    }

    try {
      final refactorActions = <Either2<Command, CodeAction>>[];

      // Extract Method
      if (ExtractMethodRefactoring(server.searchEngine, unit, offset, length)
          .isAvailable()) {
        refactorActions.add(createRefactor(CodeActionKind.RefactorExtract,
            'Extract Method', RefactoringKind.EXTRACT_METHOD));
      }

      // Extract Widget
      if (ExtractWidgetRefactoring(server.searchEngine, unit, offset, length)
          .isAvailable()) {
        refactorActions.add(createRefactor(CodeActionKind.RefactorExtract,
            'Extract Widget', RefactoringKind.EXTRACT_WIDGET));
      }

      return refactorActions;
    } on InconsistentAnalysisException {
      // If an InconsistentAnalysisException occurs, it's likely the user modified
      // the source and therefore is no longer interested in the results, so
      // just return an empty set.
      return [];
    }
  }

  /// Gets "Source" CodeActions, which are actions that apply to whole files of
  /// source such as Sort Members and Organise Imports.
  Future<List<Either2<Command, CodeAction>>> _getSourceActions(
    HashSet<CodeActionKind> clientSupportedCodeActionKinds,
    bool clientSupportsLiteralCodeActions,
    bool clientSupportsWorkspaceApplyEdit,
    String path,
  ) async {
    // The source actions supported are only valid for Dart files.
    if (!AnalysisEngine.isDartFileName(path)) {
      return const [];
    }

    // If the client told us what kinds they support but it does not include
    // Source then don't return any.
    if (clientSupportsLiteralCodeActions &&
        !clientSupportedCodeActionKinds.contains(CodeActionKind.Source)) {
      return const [];
    }

    // If the client does not support workspace/applyEdit, we won't be able to
    // run any of these.
    if (!clientSupportsWorkspaceApplyEdit) {
      return const [];
    }

    return [
      _commandOrCodeAction(
        clientSupportsLiteralCodeActions,
        DartCodeActionKind.SortMembers,
        Command('Sort Members', Commands.sortMembers, [path]),
      ),
      _commandOrCodeAction(
        clientSupportsLiteralCodeActions,
        CodeActionKind.SourceOrganizeImports,
        Command('Organize Imports', Commands.organizeImports, [path]),
      ),
    ];
  }
}
