// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
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

class FixAllCommandHandler extends SimpleEditCommandHandler {
  FixAllCommandHandler(LspAnalysisServer server) : super(server);

  @override
  String get commandName => 'Fix All';

  @override
  Future<ErrorOr<void>> handle(List<Object?>? arguments,
      ProgressReporter reporter, CancellationToken cancellationToken) async {
    if (arguments == null || arguments.length != 1 || arguments[0] is! String) {
      return ErrorOr.error(ResponseError(
        code: ServerErrorCodes.InvalidCommandArguments,
        message:
            '$commandName requires a single String parameter containing the path of a Dart file',
      ));
    }

    // Get the version of the doc before we calculate edits so we can send it back
    // to the client so that they can discard this edit if the document has been
    // modified since.
    final path = arguments.single as String;
    final docIdentifier = server.getVersionedDocumentIdentifier(path);

    final result = await requireResolvedUnit(path);

    if (cancellationToken.isCancellationRequested) {
      return error(ErrorCodes.RequestCancelled, 'Request was cancelled');
    }

    return result.mapResult((result) async {
      final workspace = DartChangeWorkspace(server.currentSessions);
      final processor =
          BulkFixProcessor(server.instrumentationService, workspace);

      final context = server.contextManager.getContextFor(path);
      if (context == null) {
        return success(null);
      }

      final changeBuilder = await processor.fixErrorsForFile(context, path);
      final change = changeBuilder.sourceChange;
      if (change.edits.isEmpty) {
        return success(null);
      }

      // Before we send anything back, ensure the original file didn't change
      // while we were computing changes.
      if (fileHasBeenModified(path, docIdentifier.version)) {
        return fileModifiedError;
      }

      final edit = createWorkspaceEdit(server, change);
      return sendWorkspaceEditToClient(edit);
    });
  }
}
