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
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/assist_internal.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart'
    show InconsistentAnalysisException;
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;

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
            new CodeAction(command.title, kind, null, null, command),
          )
        : Either2<Command, CodeAction>.t1(command);
  }

  /// Creates a CodeAction to apply this assist. Note: This code will fetch the
  /// version of each document being modified so it's important to call this
  /// immediately after computing edits to ensure the document is not modified
  /// before the version number is read.
  Either2<Command, CodeAction> _createAssistAction(Assist assist) {
    return new Either2<Command, CodeAction>.t2(new CodeAction(
      assist.change.message,
      CodeActionKind.Refactor,
      const [],
      createWorkspaceEdit(server, assist.change),
      null,
    ));
  }

  /// Creates a CodeAction to apply this fix. Note: This code will fetch the
  /// version of each document being modified so it's important to call this
  /// immediately after computing edits to ensure the document is not modified
  /// before the version number is read.
  Either2<Command, CodeAction> _createFixAction(
      Fix fix, Diagnostic diagnostic) {
    return new Either2<Command, CodeAction>.t2(new CodeAction(
      fix.change.message,
      CodeActionKind.QuickFix,
      [diagnostic],
      createWorkspaceEdit(server, fix.change),
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
    // TODO(dantup): Is it acceptable not to support these for clients that can't
    // handle Code Action literals? (Doing so requires we encode this into a
    // command/arguments set and allow the client to call us back later).
    if (!clientSupportsLiteralCodeActions ||
        !clientSupportedCodeActionKinds.contains(CodeActionKind.Refactor)) {
      return const [];
    }

    try {
      var context = new DartAssistContextImpl(
        DartChangeWorkspace(server.currentSessions),
        unit,
        offset,
        length,
      );
      final processor = new AssistProcessor(context);
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
    String path,
    Range range,
    int offset,
    int length,
    ResolvedUnitResult unit,
  ) async {
    final results = await Future.wait([
      _getSourceActions(kinds, supportsLiterals, path),
      _getAssistActions(kinds, supportsLiterals, offset, length, unit),
      _getRefactorActions(kinds, supportsLiterals, path, range, unit),
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
    // TODO(dantup): Is it acceptable not to support these for clients that can't
    // handle Code Action literals? (Doing so requires we encode this into a
    // command/arguments set and allow the client to call us back later).
    if (!clientSupportsLiteralCodeActions ||
        !clientSupportedCodeActionKinds.contains(CodeActionKind.QuickFix)) {
      return const [];
    }

    final lineInfo = unit.lineInfo;
    final codeActions = <Either2<Command, CodeAction>>[];
    final fixContributor = new DartFixContributor();

    try {
      for (final error in unit.errors) {
        // Server lineNumber is one-based so subtract one.
        int errorLine = lineInfo.getLocation(error.offset).lineNumber - 1;
        if (errorLine >= range.start.line && errorLine <= range.end.line) {
          var workspace = DartChangeWorkspace(server.currentSessions);
          var context = new DartFixContextImpl(workspace, unit, error);
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
    Range range,
    ResolvedUnitResult unit,
  ) async {
    // TODO(dantup): Is it acceptable not to support these for clients that can't
    // handle Code Action literals? (Doing so requires we encode this into a
    // command/arguments set and allow the client to call us back later).
    if (!clientSupportsLiteralCodeActions ||
        !clientSupportedCodeActionKinds.contains(CodeActionKind.Refactor)) {
      return const [];
    }

    try {
      // TODO(dantup): Implement refactors.
      return [];
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
    String path,
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
