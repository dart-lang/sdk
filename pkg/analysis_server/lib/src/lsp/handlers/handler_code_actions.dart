// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analysis_server/src/protocol_server.dart' show SourceChange;
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart'
    show InconsistentAnalysisException;
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;

typedef ActionHandler = Future<List<Either2<Command, CodeAction>>> Function(
    HashSet<CodeActionKind>, bool, String, Range, ResolvedUnitResult);

class CodeActionHandler extends MessageHandler<CodeActionParams,
    List<Either2<Command, CodeAction>>> {
  CodeActionHandler(LspAnalysisServer server) : super(server);
  Method get handlesMessage => Method.textDocument_codeAction;

  @override
  CodeActionParams convertParams(Map<String, dynamic> json) =>
      CodeActionParams.fromJson(json);

  Future<ErrorOr<List<Either2<Command, CodeAction>>>> handle(
      CodeActionParams params) async {
    final capabilities = server?.clientCapabilities?.textDocument?.codeAction;

    final clientSupportsLiteralCodeActions =
        capabilities?.codeActionLiteralSupport != null;

    final clientSupportedCodeActionKinds = new HashSet<CodeActionKind>.of(
        capabilities?.codeActionLiteralSupport?.codeActionKind?.valueSet ?? []);

    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireUnit);
    return unit.mapResult((unit) => _getCodeActions(
        clientSupportedCodeActionKinds,
        clientSupportsLiteralCodeActions,
        path.result,
        params.range,
        unit));
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
            new CodeAction(command.title, kind, null, null, command),
          )
        : Either2<Command, CodeAction>.t1(command);
  }

  Either2<Command, CodeAction> _createFixAction(
      Fix fix, Diagnostic diagnostic) {
    return new Either2<Command, CodeAction>.t2(new CodeAction(
      fix.change.message,
      CodeActionKind.QuickFix,
      [diagnostic],
      _createWorkspaceEdit(fix.change),
      null,
    ));
  }

  WorkspaceEdit _createWorkspaceEdit(SourceChange change) {
    return toWorkspaceEdit(
        server.clientCapabilities?.workspace,
        change.edits
            .map((e) => new FileEditInformation(
                server.getVersionedDocumentIdentifier(e.file),
                server.getLineInfo(e.file),
                e.edits))
            .toList());
  }

  Future<List<Either2<Command, CodeAction>>> _getAssistActions(
    HashSet<CodeActionKind> clientSupportedCodeActionKinds,
    bool clientSupportsLiteralCodeActions,
    String path,
    Range range,
    ResolvedUnitResult unit,
  ) async {
    // TODO(dantup): Implement assists.
    return [];
  }

  Future<ErrorOr<List<Either2<Command, CodeAction>>>> _getCodeActions(
    HashSet<CodeActionKind> clientSupportedCodeActionKinds,
    bool clientSupportsLiteralCodeActions,
    String path,
    Range range,
    ResolvedUnitResult unit,
  ) async {
    // Join the results of computing all of our different types.
    final List<ActionHandler> handlers = [
      _getSourceActions,
      _getAssistActions,
      _getRefactorActions,
      _getFixActions,
    ];
    final futures = handlers.map((f) => f(
          clientSupportedCodeActionKinds,
          clientSupportsLiteralCodeActions,
          path,
          range,
          unit,
        ));
    final results = await Future.wait(futures);
    final flatResults = results.expand((x) => x).toList();
    return success(flatResults);
  }

  Future<List<Either2<Command, CodeAction>>> _getFixActions(
    HashSet<CodeActionKind> clientSupportedCodeActionKinds,
    bool clientSupportsLiteralCodeActions,
    String path,
    Range range,
    ResolvedUnitResult unit,
  ) async {
    // TODO(dantup): Is it acceptable not to support these for clients that can't
    // handle Code Action literals? (Doing so requires we encode this into a
    // command/arguments set and allow the client to call us back later).
    if (!clientSupportsLiteralCodeActions) {
      return const [];
    }
    // Keep trying until we run without getting an `InconsistentAnalysisException`.
    while (true) {
      final lineInfo = unit.lineInfo;
      final codeActions = <Either2<Command, CodeAction>>[];
      final fixContributor = new DartFixContributor();
      try {
        for (final error in unit.errors) {
          // Server lineNumber is one-based so subtract one.
          int errorLine = lineInfo.getLocation(error.offset).lineNumber - 1;
          if (errorLine >= range.start.line && errorLine <= range.end.line) {
            var context = new DartFixContextImpl(unit, error);
            final fixes = await fixContributor.computeFixes(context);
            if (fixes.isNotEmpty) {
              fixes.sort(Fix.SORT_BY_RELEVANCE);

              final diagnostic = toDiagnostic(lineInfo, error);
              codeActions.addAll(
                fixes.map((fix) => _createFixAction(fix, diagnostic)),
              );
            }
          }
        }

        return codeActions;
      } on InconsistentAnalysisException {
        // Loop around to try again to compute the fixes.
      }
    }
  }

  Future<List<Either2<Command, CodeAction>>> _getRefactorActions(
    HashSet<CodeActionKind> clientSupportedCodeActionKinds,
    bool clientSupportsLiteralCodeActions,
    String path,
    Range range,
    ResolvedUnitResult unit,
  ) async {
    // TODO(dantup): Implement refactors.
    return [];
  }

  /// Gets "Source" CodeActions, which are actions that apply to whole files of
  /// source such as Sort Members and Organise Imports.
  Future<List<Either2<Command, CodeAction>>> _getSourceActions(
    HashSet<CodeActionKind> clientSupportedCodeActionKinds,
    bool clientSupportsLiteralCodeActions,
    String path,
    Range range,
    ResolvedUnitResult unit,
  ) async {
    // The source actions supported are only valid for Dart files.
    if (!AnalysisEngine.isDartFileName(path)) {
      return [];
    }

    // If the client told us what kinds they support but it does not include
    // Source then don't return any.
    if (clientSupportsLiteralCodeActions &&
        !clientSupportedCodeActionKinds.contains(CodeActionKind.Source)) {
      return [];
    }

    return [
      _commandOrCodeAction(
        clientSupportsLiteralCodeActions,
        DartCodeActionKind.SortMembers,
        new Command('Sort Members', Commands.sortMembers, [path]),
      ),
      _commandOrCodeAction(
        clientSupportsLiteralCodeActions,
        CodeActionKind.SourceOrganizeImports,
        new Command('Organize Imports', Commands.organizeImports, [path]),
      ),
    ];
  }
}
