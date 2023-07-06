// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/commands/abstract_refactor.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/protocol_server.dart';

class PerformRefactorCommandHandler extends AbstractRefactorCommandHandler
    with LspHandlerHelperMixin {
  PerformRefactorCommandHandler(super.server);

  @override
  String get commandName => 'Perform Refactor';

  @override
  bool get recordsOwnAnalytics => true;

  @override
  FutureOr<ErrorOr<void>> execute(
    String path,
    String kind,
    int offset,
    int length,
    Map<String, Object?>? options,
    CancellationToken cancellationToken,
    ProgressReporter reporter,
    int? docVersion,
  ) async {
    final actionName = 'dart.refactor.${kind.toLowerCase()}';
    server.analyticsManager.executedCommand(actionName);

    final result = await requireResolvedUnit(path);
    return result.mapResult((result) async {
      final refactoring = await getRefactoring(
          RefactoringKind(kind), result, offset, length, options);
      return refactoring.mapResult((refactoring) async {
        // Don't include potential edits in refactorings until there is some UI
        // for the user to control this.
        refactoring.includePotential = false;

        // If the token we were given is not cancelable, wrap it with one that
        // is for the rest of this request as a future refactor may need to
        // cancel this request.
        final cancelableToken = cancellationToken.asCancelable();
        manager.begin(cancelableToken);

        try {
          reporter.begin('Refactoring…');
          final status = await refactoring.checkAllConditions();

          if (status.hasError) {
            // Show the error to the user but don't fail the request, as the
            // LSP Client may show a failed request in a way that looks like a
            // server error.
            server.showErrorMessageToUser(status.message!);
            return success(null);
          }

          if (cancelableToken.isCancellationRequested) {
            return error(ErrorCodes.RequestCancelled, 'Request was cancelled');
          }

          final change = await refactoring.createChange();

          if (cancelableToken.isCancellationRequested) {
            return error(ErrorCodes.RequestCancelled, 'Request was cancelled');
          }

          if (change.edits.isEmpty) {
            return success(null);
          }

          // If the file changed while we were validating and preparing the change,
          // we should fail to avoid sending bad edits.
          if (fileHasBeenModified(path, docVersion)) {
            return fileModifiedError;
          }

          final edit = createWorkspaceEdit(server, change);
          return await sendWorkspaceEditToClient(edit);
        } finally {
          manager.end(cancelableToken);
          reporter.end();
        }
      });
    });
  }
}
