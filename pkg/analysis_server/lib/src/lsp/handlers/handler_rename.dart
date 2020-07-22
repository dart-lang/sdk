// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';

class PrepareRenameHandler
    extends MessageHandler<TextDocumentPositionParams, RangeAndPlaceholder> {
  PrepareRenameHandler(LspAnalysisServer server) : super(server);
  @override
  Method get handlesMessage => Method.textDocument_prepareRename;

  @override
  LspJsonHandler<TextDocumentPositionParams> get jsonHandler =>
      TextDocumentPositionParams.jsonHandler;

  @override
  Future<ErrorOr<RangeAndPlaceholder>> handle(
      TextDocumentPositionParams params, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    final pos = params.position;
    final path = pathOfDoc(params.textDocument);
    final unit = await path.mapResult(requireResolvedUnit);
    final offset = await unit.mapResult((unit) => toOffset(unit.lineInfo, pos));

    return offset.mapResult((offset) async {
      final node = await server.getNodeAtOffset(path.result, offset);
      final element = server.getElementOfNode(node);
      if (node == null || element == null) {
        return success(null);
      }

      final refactorDetails =
          RenameRefactoring.getElementToRename(node, element);
      final refactoring = RenameRefactoring(
          server.refactoringWorkspace, unit.result, refactorDetails.element);
      if (refactoring == null) {
        return success(null);
      }

      // Check the rename is valid here.
      final initStatus = await refactoring.checkInitialConditions();
      if (initStatus.hasFatalError) {
        return error(
            ServerErrorCodes.RenameNotValid, initStatus.problem.message, null);
      }

      return success(RangeAndPlaceholder(
        range: toRange(
          unit.result.lineInfo,
          // If the offset is set to -1 it means there is no location for the
          // old name. However since we must provide a range for LSP, we'll use
          // a 0-character span at the originally requested location to ensure
          // it's valid.
          refactorDetails.offset == -1 ? offset : refactorDetails.offset,
          refactorDetails.length,
        ),
        placeholder: refactoring.oldName,
      ));
    });
  }
}

class RenameHandler extends MessageHandler<RenameParams, WorkspaceEdit> {
  RenameHandler(LspAnalysisServer server) : super(server);

  @override
  Method get handlesMessage => Method.textDocument_rename;

  @override
  LspJsonHandler<RenameParams> get jsonHandler => RenameParams.jsonHandler;

  @override
  Future<ErrorOr<WorkspaceEdit>> handle(
      RenameParams params, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    final pos = params.position;
    final path = pathOfDoc(params.textDocument);
    // If the client provided us a version doc identifier, we'll use it to ensure
    // we're not computing a rename for an old document. If not, we'll just assume
    // the version the server had at the time of recieving the request is valid
    // and then use it to verify the document hadn't changed again before we
    // send the edits.
    final docIdentifier = await path.mapResult((path) => success(
        params.textDocument is VersionedTextDocumentIdentifier
            ? params.textDocument
            : server.getVersionedDocumentIdentifier(path)));
    final unit = await path.mapResult(requireResolvedUnit);
    final offset = await unit.mapResult((unit) => toOffset(unit.lineInfo, pos));

    return offset.mapResult((offset) async {
      final node = await server.getNodeAtOffset(path.result, offset);
      final element = server.getElementOfNode(node);
      if (node == null || element == null) {
        return success(null);
      }

      final refactorDetails =
          RenameRefactoring.getElementToRename(node, element);
      final refactoring = RenameRefactoring(
          server.refactoringWorkspace, unit.result, refactorDetails.element);
      if (refactoring == null) {
        return success(null);
      }

      // TODO(dantup): Consider using window/showMessageRequest to prompt
      // the user to see if they'd like to proceed with a rename if there
      // are non-fatal errors or warnings. For now we will reject all errors
      // (fatal and not) as this seems like the most logical behaviour when
      // without a prompt.

      // Check the rename is valid here.
      final initStatus = await refactoring.checkInitialConditions();
      if (token.isCancellationRequested) {
        return cancelled();
      }
      if (initStatus.hasError) {
        return error(
            ServerErrorCodes.RenameNotValid, initStatus.problem.message, null);
      }

      // Check the name is valid.
      refactoring.newName = params.newName;
      final optionsStatus = refactoring.checkNewName();
      if (optionsStatus.hasError) {
        return error(ServerErrorCodes.RenameNotValid,
            optionsStatus.problem.message, null);
      }

      // Final validation.
      final finalStatus = await refactoring.checkFinalConditions();
      if (token.isCancellationRequested) {
        return cancelled();
      }
      if (finalStatus.hasError) {
        return error(
            ServerErrorCodes.RenameNotValid, finalStatus.problem.message, null);
      }

      // Compute the actual change.
      final change = await refactoring.createChange();
      if (token.isCancellationRequested) {
        return cancelled();
      }

      // Before we send anything back, ensure the original file didn't change
      // while we were computing changes.
      if (server.getVersionedDocumentIdentifier(path.result) !=
          docIdentifier.result) {
        return error(ErrorCodes.ContentModified,
            'Document was modified while rename was being computed', null);
      }

      final workspaceEdit = createWorkspaceEdit(server, change.edits);
      return success(workspaceEdit);
    });
  }
}
