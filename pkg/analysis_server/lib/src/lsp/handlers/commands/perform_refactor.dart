// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/commands/abstract_refactor.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/protocol_server.dart';

class PerformRefactorCommandHandler extends AbstractRefactorCommandHandler {
  PerformRefactorCommandHandler(super.server);

  @override
  String get commandName => 'Perform Refactor';

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
    final result = await requireResolvedUnit(path);
    return result.mapResult((result) async {
      final refactoring = await getRefactoring(
          RefactoringKind(kind), result, offset, length, options);
      return refactoring.mapResult((refactoring) async {
        // If the token we were given is not cancellable, replace it with one that
        // is for the rest of this request, as a future refactor may need to cancel
        // this request.
        // The original token should be kept and also checked for cancellation.
        final cancelableToken = cancellationToken is CancelableToken
            ? cancellationToken
            : CancelableToken();
        manager.begin(cancelableToken);

        try {
          reporter.begin('Refactoring…');
          final status = await refactoring.checkAllConditions();

          if (status.hasError) {
            return error(ServerErrorCodes.RefactorFailed, status.message!);
          }

          if (cancellationToken.isCancellationRequested ||
              cancelableToken.isCancellationRequested) {
            return error(ErrorCodes.RequestCancelled, 'Request was cancelled');
          }

          final change = await refactoring.createChange();

          if (cancellationToken.isCancellationRequested ||
              cancelableToken.isCancellationRequested) {
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
