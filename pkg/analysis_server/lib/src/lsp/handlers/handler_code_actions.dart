// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisEngine;

class CodeActionHandler extends MessageHandler<CodeActionParams,
    List<Either2<Command, CodeAction>>> {
  CodeActionHandler(LspAnalysisServer server) : super(server);
  Method get handlesMessage => Method.textDocument_codeAction;

  /// Wraps a command in a CodeAction if the client supports it so that a
  /// CodeActionKind can be supplied.
  Either2<Command, CodeAction> commandOrCodeAction(
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
        unit));
  }

  List<Either2<Command, CodeAction>> _getAssistActions(
    HashSet<CodeActionKind> clientSupportedCodeActionKinds,
    bool clientSupportsLiteralCodeActions,
    String path,
    ResolvedUnitResult unit,
  ) {
    // TODO(dantup): Implement assists.
    return [];
  }

  ErrorOr<List<Either2<Command, CodeAction>>> _getCodeActions(
    HashSet<CodeActionKind> clientSupportedCodeActionKinds,
    bool clientSupportsLiteralCodeActions,
    String path,
    ResolvedUnitResult unit,
  ) {
    // Join the results of computing all of our different types.
    final allActions = [
      _getSourceActions,
      _getAssistActions,
      _getRefactorActions,
      _getFixActions,
    ]
        .expand((f) => f(
              clientSupportedCodeActionKinds,
              clientSupportsLiteralCodeActions,
              path,
              unit,
            ))
        .toList();

    return success(allActions);
  }

  List<Either2<Command, CodeAction>> _getFixActions(
    HashSet<CodeActionKind> clientSupportedCodeActionKinds,
    bool clientSupportsLiteralCodeActions,
    String path,
    ResolvedUnitResult unit,
  ) {
    // TODO(dantup): Implement fixes.
    return [];
  }

  List<Either2<Command, CodeAction>> _getRefactorActions(
    HashSet<CodeActionKind> clientSupportedCodeActionKinds,
    bool clientSupportsLiteralCodeActions,
    String path,
    ResolvedUnitResult unit,
  ) {
    // TODO(dantup): Implement refactors.
    return [];
  }

  /// Gets "Source" CodeActions, which are actions that apply to whole files of
  /// source such as Sort Members and Organise Imports.
  List<Either2<Command, CodeAction>> _getSourceActions(
    HashSet<CodeActionKind> clientSupportedCodeActionKinds,
    bool clientSupportsLiteralCodeActions,
    String path,
    ResolvedUnitResult unit,
  ) {
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
      commandOrCodeAction(
        clientSupportsLiteralCodeActions,
        DartCodeActionKind.SortMembers,
        new Command('Sort Members', Commands.sortMembers, [path]),
      ),
      commandOrCodeAction(
        clientSupportsLiteralCodeActions,
        CodeActionKind.SourceOrganizeImports,
        new Command('Organize Imports', Commands.organizeImports, [path]),
      ),
    ];
  }
}
