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
import 'package:analyzer/dart/analysis/results.dart';

/// A handler that performs legacy refactors such as EXTRACT_WIDGET.
class PerformRefactorCommandHandler extends AbstractRefactorCommandHandler {
  new(super.server);

  @override
  String get commandName => 'Perform Refactor';

  @override
  bool get recordsOwnAnalytics => true;

  @override
  bool get requiresTrustedCaller => false;

  @override
  FutureOr<ErrorOr<void>> execute(
    MessageInfo message,
    ResolvedUnitResult unit,
    String kind,
    int offset,
    int length,
    Map<String, Object?>? options,
    LspClientCapabilities clientCapabilities,
    CancellationToken cancellationToken,
    ProgressReporter reporter,
    ErrorOr<void>? Function() checkAbort,
  ) async {
    var editorCapabilities = server.editorClientCapabilities;
    if (editorCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return serverNotInitializedError;
    }

    var actionName = 'dart.refactor.${kind.toLowerCase()}';
    server.analyticsManager.executedCommand(actionName);

    var refactoringResult = await getRefactoring(
      RefactoringKind.values.byName(kind),
      unit,
      offset,
      length,
      options,
    );
    if (checkAbort() case var reason?) return reason;

    return refactoringResult.mapResult((refactoring) async {
      // Don't include potential edits in refactorings until there is some UI
      // for the user to control this.
      refactoring.includePotential = false;

      // If the token we were given is not cancelable, wrap it with one that
      // is for the rest of this request as a future refactor may need to
      // cancel this request.
      var cancelableToken = cancellationToken.asCancelable();
      manager.begin(cancelableToken);
      checkAbort = appendToken(checkAbort, cancelableToken);

      try {
        // ignore: unawaited_futures
        reporter.begin('Refactoring…');
        var status = await refactoring.checkAllConditions();
        if (checkAbort() case var reason?) return reason;

        if (status.hasError || status.hasWarning) {
          // For non-fatal errors/warnings, try to prompt the user to see if
          // they would like to continue anyway.
          var prompt = server.userPromptSender;
          if (!status.hasFatalError && prompt != null) {
            // Complete the message before we make the outbound request because when
            // the server is in non-overlapping request mode, we cannot have the
            // server stall because this request is blocked on user-input.
            message.completer?.complete();

            var promptMessage = status.summarizedMessage!;

            // Ask the user whether to proceed with the refactor.
            var userChoice = await prompt(MessageType.warning, promptMessage, [
              UserPromptActions.refactorAnyway,
              UserPromptActions.cancel,
            ], cancellationToken);

            // Unless they choose to refactor anyway, abort.
            if (userChoice != UserPromptActions.refactorAnyway) {
              return success(null);
            }

            if (checkAbort() case var reason?) return reason;
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

        if (checkAbort() case var reason?) return reason;

        var change = await refactoring.createChange();
        if (change.edits.isEmpty) {
          return success(null);
        }

        // Check if we should abort due to cancellation or file modifications.
        if (checkAbort() case var reason?) return reason;

        var edit = createWorkspaceEdit(server, editorCapabilities, change);
        return await sendWorkspaceEditToClient(edit);
      } finally {
        manager.end(cancelableToken);
        // ignore: unawaited_futures
        reporter.end();
      }
    });
  }
}
