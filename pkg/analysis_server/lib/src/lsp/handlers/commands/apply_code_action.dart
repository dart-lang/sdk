// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/code_action_computer.dart';
import 'package:analysis_server/src/lsp/handlers/commands/simple_edit_handler.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:language_server_protocol/json_parsing.dart';

/// A handler for the 'applyCodeAction' command.
///
/// This command recomputes a code action from a document/range/CodeActionKind
/// and then sends the edit to the editor via workspace/applyEdit.
///
/// This allows another client (for example a DTD client like the Property
/// Editor) to trigger code actions.
///
/// This command is only intended to be used by executing a command produced by
/// the server in the same session and therefore the arguments are not specified
/// and can easily change - the server only needs to be consistent with itself.
class ApplyCodeActionCommandHandler
    extends SimpleEditCommandHandler<AnalysisServer> {
  ApplyCodeActionCommandHandler(super.server);

  @override
  String get commandName => 'Apply Code Action';

  @override
  bool get recordsOwnAnalytics => true;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<void>> handle(
    MessageInfo message,
    Map<String, Object?> parameters,
    ProgressReporter progress,
    CancellationToken cancellationToken,
  ) async {
    // Log that this command was executed. This is not done automatically
    // because we set [recordsOwnAnalytics] so that we can also record the
    // action (below).
    server.analyticsManager.executedCommand(Commands.applyCodeAction);

    var performance = message.performance;
    var editorCapabilities = server.editorClientCapabilities;
    var callerCapabilities = message.clientCapabilities;
    if (editorCapabilities == null || callerCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return serverNotInitializedError;
    }

    if (!(server.editorClientCapabilities?.applyEdit ?? false)) {
      return ErrorOr.error(
        ResponseError(
          code: ServerErrorCodes.stateError,
          message: 'The editor does not support workspace/applyEdit',
        ),
      );
    }

    // Read the parameters. The code here mirrors the arguments that are added
    // to commands in the `createApplyCodeActionCommand` function.

    var textDocumentParameter = parameters['textDocument'];
    var rangeParameter = parameters['range'];
    var kindParameter = parameters['kind'];
    var loggedActionParameter = parameters['loggedAction'];

    var errors = <String>[];

    if (!OptionalVersionedTextDocumentIdentifier.canParse(
      textDocumentParameter,
      nullLspJsonReporter,
    )) {
      errors.add(
        'textDocument was not a valid OptionalVersionedTextDocumentIdentifier',
      );
    }

    if (!Range.canParse(rangeParameter, nullLspJsonReporter)) {
      errors.add('range was not a valid Range');
    }

    if (kindParameter is! String) {
      errors.add('kind was not a valid String');
    }

    if (loggedActionParameter is! String?) {
      errors.add('loggedAction was not a valid String');
    }

    if (errors.isNotEmpty) {
      return ErrorOr.error(
        ResponseError(
          code: ServerErrorCodes.invalidCommandArguments,
          message:
              '${Commands.applyCodeAction} requires 3 parameters: '
              'textDocument: Map<String, Object?> (OptionalVersionedTextDocumentIdentifier), '
              'range: Map<String, Object?> (Range), '
              'kind: String (CodeActionKind) '
              'but ${errors.join(', ')}',
        ),
      );
    }

    // The checks above validate these are the correct types so these can be
    // safely cast.
    var textDocument = OptionalVersionedTextDocumentIdentifier.fromJson(
      textDocumentParameter as Map<String, Object?>,
    );
    var range = Range.fromJson(rangeParameter as Map<String, Object?>);
    var kind = CodeActionKind(kindParameter as String);
    var loggedAction = loggedActionParameter as String?;

    // Verify the document is still fresh.
    var filePath = server.uriConverter.fromClientUri(textDocument.uri);
    if (fileHasBeenModified(filePath, textDocument.version)) {
      return fileModifiedError;
    }

    // Also record the action we're triggering.
    if (loggedAction != null) {
      server.analyticsManager.executedCommand(loggedAction);
    }

    // Fetch the code action to execute.
    var computer = CodeActionComputer(
      server,
      textDocument,
      range,
      editorCapabilities: editorCapabilities,
      callerCapabilities: callerCapabilities,
      only: [kind],
      supportedKinds: null, // 'only' overrides this
      triggerKind: CodeActionTriggerKind.Invoked,
      performance: performance,

      // Always use literals here regardless of the capabilities because we need
      // to extract edits and cannot handle recursive commands. The editors
      // ability to applyEdit has been checked at the top of this method.
      allowCommands: false,
      allowCodeActionLiterals: true,

      // We don't support non-standard snippets for `workspace/applyEdit`, only
      // CodeActionLiterals.
      allowSnippets: false,
    );
    var actions = await computer.compute();

    if (cancellationToken.isCancellationRequested) {
      return cancelled(cancellationToken);
    }

    return actions.mapResult((actions) async {
      return switch (actions) {
        null || [] => error(
          ServerErrorCodes.invalidCommandArguments,
          'The code action $kind is not valid at this location',
        ),
        [var action] => await _applyAction(action),
        [...] => error(
          ServerErrorCodes.invalidCommandArguments,
          'The code action $kind is ambigious at this location',
        ),
      };
    });
  }

  /// Applies a [CodeAction]s edits by sending them to the client and waiting
  /// for acknowledgement.
  Future<ErrorOr<void>> _applyAction(CodeAction action) async {
    var edit = action.map((literal) => literal.edit, (command) => null);

    if (edit == null) {
      return error(
        ErrorCodes.InternalError,
        'Server computed a Command instead of a CodeActionLiteral',
      );
    }

    return await sendWorkspaceEditToClient(edit);
  }
}
