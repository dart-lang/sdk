// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart' show MessageType;
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/commands/abstract_refactor.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/protocol_server.dart' hide MessageType;
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
  bool get requiresTrustedCaller => false;

  @override
  FutureOr<ErrorOr<void>> execute(
    MessageInfo message,
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
    var editorCapabilities = server.editorClientCapabilities;
    if (editorCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return serverNotInitializedError;
    }

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

          if (status.hasError || status.hasWarning) {
            // For non-fatal errors/warnings, try to prompt the user to see if
            // they would like to continue anyway.
            var prompt = server.userPromptSender;
            if (!status.hasFatalError && prompt != null) {
              // Complete the message before we make the outbound request because when
              // the server is in non-overlapping request mode, we cannot have the
              // server stall because this request is blocked on user-input.
              message.completer?.complete();

              // Ask the user whether to proceed with the refactor.
              var userChoice = await prompt(
                MessageType.warning,
                status.message!,
                [UserPromptActions.refactorAnyway, UserPromptActions.cancel],
                cancellationToken,
              );

              // Unless they choose to refactor anyway, abort.
              if (userChoice != UserPromptActions.refactorAnyway) {
                return success(null);
              }
            } else {
              // Otherwise, client doesn't support prompting or the error is
              // fatal. Show the error to the user (if possible) but don't fail
              // the request, return null. Some LSP Clients (like VS Code) may
              // show a failed request in a way that looks like a server error
              // after we already showed a user-friendly message.
              if (server case LspAnalysisServer server) {
                // Error notifications are not supported for LSP-over-Legacy.
                server.showErrorMessageToUser(status.message!);
              }
              return success(null);
            }
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

          var edit = createWorkspaceEdit(server, editorCapabilities, change);
          return await sendWorkspaceEditToClient(edit);
        } finally {
          manager.end(cancelableToken);
          reporter.end();
        }
      });
    });
  }
}
