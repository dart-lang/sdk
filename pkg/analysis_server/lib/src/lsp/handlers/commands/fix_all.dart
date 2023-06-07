// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/commands/simple_edit_handler.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server/src/services/correction/change_workspace.dart';

class FixAllCommandHandler extends SimpleEditCommandHandler {
  FixAllCommandHandler(super.server);

  @override
  String get commandName => 'Fix All';

  @override
  Future<ErrorOr<void>> handle(Map<String, Object?> parameters,
      ProgressReporter progress, CancellationToken cancellationToken) async {
    if (parameters['path'] is! String) {
      return ErrorOr.error(ResponseError(
        code: ServerErrorCodes.InvalidCommandArguments,
        message: '$commandName requires a Map argument containing a "path"',
      ));
    }

    // Get the version of the doc before we calculate edits so we can send it back
    // to the client so that they can discard this edit if the document has been
    // modified since.
    final path = parameters['path'] as String;
    final docIdentifier = server.getVersionedDocumentIdentifier(path);
    final autoTriggered = parameters['autoTriggered'] == true;

    final result = await requireResolvedUnit(path);

    if (cancellationToken.isCancellationRequested) {
      return error(ErrorCodes.RequestCancelled, 'Request was cancelled');
    }

    return result.mapResult((result) async {
      final workspace = DartChangeWorkspace(
        await server.currentSessions,
      );
      final processor = BulkFixProcessor(
          server.instrumentationService, workspace,
          cancellationToken: cancellationToken);

      final context = server.contextManager.getContextFor(path);
      if (context == null) {
        return success(null);
      }

      final changeBuilder = await processor.fixErrorsForFile(context, path,
          removeUnusedImports: !autoTriggered);
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
