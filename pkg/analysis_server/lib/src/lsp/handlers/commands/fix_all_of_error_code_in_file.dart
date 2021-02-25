// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/commands/simple_edit_handler.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';

/// This command allows a client to request request applying all fixes for a
/// type of error.
class FixAllOfErrorCodeInFileCommandHandler extends SimpleEditCommandHandler {
  FixAllOfErrorCodeInFileCommandHandler(LspAnalysisServer server)
      : super(server);

  @override
  String get commandName => 'Fix All of Error Code in File';

  @override
  Future<ErrorOr<void>> handle(List<dynamic> arguments,
      ProgressReporter reporter, CancellationToken cancellationToken) async {
    if (arguments == null ||
        arguments.length != 3 ||
        arguments[0] is! String ||
        arguments[1] is! String ||
        (arguments[2] is! int && arguments[2] != null)) {
      return ErrorOr.error(ResponseError(
        code: ServerErrorCodes.InvalidCommandArguments,
        message: '$commandName requires three arguments: '
            '1) an ErrorCode, '
            '2) a file path, '
            '3) a document version',
      ));
    }

    final errorCode = arguments[0] as String;
    final path = arguments[1] as String;
    final clientDocumentVersion = arguments[2] as int;

    if (fileHasBeenModified(path, clientDocumentVersion)) {
      return fileModifiedError;
    }

    final result = await requireResolvedUnit(path);

    if (cancellationToken.isCancellationRequested) {
      return error(ErrorCodes.RequestCancelled, 'Request was cancelled');
    }

    return result.mapResult((result) async {
      final workspace = DartChangeWorkspace(server.currentSessions);
      final processor =
          BulkFixProcessor(server.instrumentationService, workspace);

      final changeBuilder = await processor.fixOfTypeInUnit(result, errorCode);

      final edit =
          createWorkspaceEdit(server, changeBuilder.sourceChange.edits);

      return await sendWorkspaceEditToClient(edit);
    });
  }
}
