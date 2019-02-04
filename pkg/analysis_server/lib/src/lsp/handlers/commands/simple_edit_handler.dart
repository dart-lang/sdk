// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' as engine;
import 'package:analyzer/src/dart/scanner/scanner.dart' as engine;
import 'package:analyzer/src/error/codes.dart' as engine;
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/parser.dart' as engine;
import 'package:analyzer_plugin/protocol/protocol_common.dart';

abstract class SimpleEditCommandHandler
    extends CommandHandler<ExecuteCommandParams, Object> {
  SimpleEditCommandHandler(LspAnalysisServer server) : super(server);

  String get commandName;

  Future<ErrorOr<void>> sendEditsToClient(
      VersionedTextDocumentIdentifier docIdentifier,
      CompilationUnit unit,
      List<SourceEdit> edits) async {
    // If there are no edits to apply, just complete the command without going
    // back to the client.
    if (edits.length == 0) {
      return success();
    }

    final workspaceEdit = toWorkspaceEdit(
      server.clientCapabilities?.workspace,
      [new FileEditInformation(docIdentifier, unit.lineInfo, edits)],
    );

    // Send the edit to the client via a applyEdit request (this is a request
    // from server -> client and the client will provide a response).
    final editResponse = await server.sendRequest(Method.workspace_applyEdit,
        new ApplyWorkspaceEditParams(commandName, workspaceEdit));

    if (editResponse.error != null) {
      return error(
        ServerErrorCodes.ClientFailedToApplyEdit,
        'Client failed to apply workspace edit for $commandName',
        editResponse.error.toString(),
      );
    }

    // Now respond to this command request telling the client whether it was
    // successful (since the client doesn't know that the workspace edit it was
    // sent - and may have failed to apply - was related to this command
    // execution).
    // We need to fromJson to convert the JSON map to the real types.
    final editResponseResult =
        ApplyWorkspaceEditResponse.fromJson(editResponse.result);
    if (editResponseResult.applied) {
      return success();
    } else {
      return error(
        ServerErrorCodes.ClientFailedToApplyEdit,
        'Client failed to apply workspace edit for $commandName',
        workspaceEdit.toString(),
      );
    }
  }

  bool hasScanParseErrors(List<engine.AnalysisError> errors) {
    return errors.any((error) =>
        error.errorCode is engine.ScannerErrorCode ||
        error.errorCode is engine.ParserErrorCode);
  }
}
