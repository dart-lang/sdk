// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/commands/abstract_refactor.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:meta/meta.dart';

class PerformRefactorCommandHandler extends AbstractRefactorCommandHandler {
  /// A [Future] used by tests to allow inserting a delay between resolving
  /// the initial unit and the refactor running.
  @visibleForTesting
  static Future<void>? delayAfterResolveForTests;

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
    LspClientCapabilities clientCapabilities,
    CancellationToken cancellationToken,
    ProgressReporter reporter,
    int? docVersion,
  ) async {
    var actionName = 'dart.refactor.${kind.toLowerCase()}';
    server.analyticsManager.executedCommand(actionName);

    var result = await requireResolvedUnit(path);
    if (delayAfterResolveForTests != null) {
      await delayAfterResolveForTests;
    }

    return result.mapResult((result) async {
      var refactoring = await getRefactoring(
        RefactoringKind.values.byName(kind),
        result,
        offset,
        length,
        options,
      );
      return refactoring.mapResult((refactoring) async {
        // Don't include potential edits in refactorings until there is some UI
        // for the user to control this.
        refactoring.includePotential = false;

        // If the token we were given is not cancelable, wrap it with one that
        // is for the rest of this request as a future refactor may need to
        // cancel this request.
        var cancelableToken = cancellationToken.asCancelable();
        manager.begin(cancelableToken);

        try {
          reporter.begin('Refactoring…');
          var status = await refactoring.checkAllConditions();

          if (status.hasError) {
            // Show the error to the user but don't fail the request, as the
            // LSP Client may show a failed request in a way that looks like a
            // server error.
            server.showErrorMessageToUser(status.message!);
            return success(null);
          }

          if (cancelableToken.isCancellationRequested) {
            return cancelled(cancelableToken);
          }

          var change = await refactoring.createChange();

          if (cancelableToken.isCancellationRequested) {
            return cancelled(cancelableToken);
          }

          if (change.edits.isEmpty) {
            return success(null);
          }

          // If the file changed while we were validating and preparing the change,
          // we should fail to avoid sending bad edits.
          if (fileHasBeenModified(path, docVersion)) {
            return fileModifiedError;
          }

          var edit = createWorkspaceEdit(server, clientCapabilities, change);
          return await sendWorkspaceEditToClient(edit);
        } finally {
          manager.end(cancelableToken);
          reporter.end();
        }
      });
    });
  }
}
