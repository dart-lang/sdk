// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/error/error.dart' as engine;
import 'package:analysis_server/src/services/correction/sort_members.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart' as engine;
import 'package:analyzer/src/error/codes.dart' as engine;
import 'package:analyzer/src/generated/engine.dart' as engine;
import 'package:analyzer/src/generated/parser.dart' as engine;

class SortMembersCommandHandler
    extends CommandHandler<ExecuteCommandParams, Object> {
  SortMembersCommandHandler(LspAnalysisServer server) : super(server);

  @override
  Future<ErrorOr<void>> handle(List<dynamic> arguments) async {
    if (arguments == null || arguments.length != 1 || arguments[0] is! String) {
      return ErrorOr.error(new ResponseError(
        ServerErrorCodes.InvalidCommandArguments,
        '${Commands.sortMembers} requires a single String parameter containing the path of a Dart file',
        null,
      ));
    }

    final path = arguments.single;
    var driver = server.getAnalysisDriver(path);
    // Get the version of the doc before we calculate edits so we can send it back
    // to the client so that they can discard this edit if the document has been
    // modified since.
    final docIdentifier = server.getVersionedDocumentIdentifier(path);
    final result = await driver?.parseFile(path);
    if (result == null) {
      return ErrorOr.error(new ResponseError(
        ServerErrorCodes.FileNotAnalyzed,
        '${Commands.sortMembers} requires a single String parameter containing the path of a Dart file',
        null,
      ));
    }
    final code = result.content;
    final unit = result.unit;
    final errors = result.errors;

    if (_hasScanParseErrors(errors)) {
      return ErrorOr.error(new ResponseError(
        ServerErrorCodes.FileHasErrors,
        'Unable to sort file because it contains parse errors',
        path,
      ));
    }

    final sorter = new MemberSorter(code, unit);
    final edits = sorter.sort();
    final workspaceEdit = toWorkspaceEdit(docIdentifier, unit.lineInfo, edits);

    // Send the edit to the client via a applyEdit request (this is a request
    // from server -> client and the client will provide a response).
    final editResponse = await server.sendRequest(Method.workspace_applyEdit,
        new ApplyWorkspaceEditParams('Sort Members', workspaceEdit));

    if (editResponse.error != null) {
      return error(
        ServerErrorCodes.ClientFailedToApplyEdit,
        'Client failed to apply workspace edit for ${Commands.sortMembers} command',
        editResponse.error,
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
        'Client failed to apply workspace edit for ${Commands.sortMembers} command',
        workspaceEdit,
      );
    }
  }

  static bool _hasScanParseErrors(List<engine.AnalysisError> errors) {
    return errors.any((error) =>
        error.errorCode is engine.ScannerErrorCode ||
        error.errorCode is engine.ParserErrorCode);
  }
}
