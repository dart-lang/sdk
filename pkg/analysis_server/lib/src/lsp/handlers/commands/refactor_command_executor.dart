// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide MessageType;
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/commands/abstract_refactor.dart';
import 'package:analysis_server/src/lsp/handlers/commands/refactor_command_handler_mixin.dart';
import 'package:analysis_server/src/lsp/handlers/commands/simple_edit_handler.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_context.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_processor.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/utilities/cancellation.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// A command handler that executes commands used to implement refactorings
/// that can describe their inputs (either via the original Dart protocol or
/// the updated Interactive Forms protocol).
class RefactorCommandExecutor extends SimpleEditCommandHandler<AnalysisServer>
    with RefactorCommandHandlerMixin<void> {
  @override
  final String commandName;

  final RefactoringProducerGenerator generator;

  new(super.server, this.commandName, this.generator);

  /// The (singleton) [LspRefactorManager] used for cancelling refactors when
  /// another is started.
  LspRefactorManager get manager => LspRefactorManager.instance;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<void>> execute(
    ProgressReporter progress,
    ResolvedLibraryResult library,
    ResolvedUnitResult unit,
    LspClientCapabilities clientCapabilities,
    RefactoringContext context,
    List<Object?> arguments,
    CancellationToken cancellationToken,
    int? docVersion,
  ) async {
    // If the token we were given is not cancelable, wrap it with one that
    // is for the rest of this request as a future refactor may need to
    // cancel this request.
    var cancelableToken = cancellationToken.asCancelable();
    manager.begin(cancelableToken);

    try {
      // ignore: unawaited_futures
      progress.begin('Refactoring…');
      return await _performRefactor(
        library,
        unit,
        clientCapabilities,
        context,
        arguments,
        cancelableToken,
        docVersion,
      );
    } finally {
      manager.end(cancelableToken);
      // ignore: unawaited_futures
      progress.end();
    }
  }

  /// Performs the refactor, including sending the edits to the client and
  /// waiting for them to be applied.
  Future<ErrorOr<void>> _performRefactor(
    ResolvedLibraryResult library,
    ResolvedUnitResult unit,
    LspClientCapabilities clientCapabilities,
    RefactoringContext context,
    List<Object?> arguments,
    CancellationToken cancellationToken,
    int? docVersion,
  ) async {
    var producer = generator(context);
    var builder = ChangeBuilder(
      workspace: context.workspace,
      defaultEol: context.utils.endOfLine,
    );
    var status = await producer.compute(arguments, builder);

    if (cancellationToken.isCancellationRequested) {
      return cancelled(cancellationToken);
    }

    if (status is ComputeStatusFailure) {
      var reason = status.reason ?? 'Cannot compute the change. No details.';
      return ErrorOr.error(
        ResponseError(
          code: ServerErrorCodes.refactoringComputeStatusFailure,
          message: reason,
        ),
      );
    }

    // If the refactor has issues and the client supports prompts, we should
    // ask whether to proceed.
    if (status is ComputeStatusWarning) {
      var prompt = server.userPromptSender;

      if (prompt == null) {
        // The client doesn't support prompts, so just reject the refactor with
        // the message like we did before.
        return ErrorOr.error(
          ResponseError(
            code: ServerErrorCodes.refactoringComputeStatusFailure,
            message: status.message,
          ),
        );
      }

      // Ask the user whether to proceed with the refactor.
      var userChoice = await prompt(MessageType.warning, status.message, [
        UserPromptActions.refactorAnyway,
        UserPromptActions.cancel,
      ], cancellationToken);

      if (cancellationToken.isCancellationRequested) {
        return cancelled(cancellationToken);
      }

      // Unless they choose to refactor anyway, abort.
      if (userChoice != UserPromptActions.refactorAnyway) {
        return success(null);
      }
    }

    var edits = builder.sourceChange.edits;
    if (edits.isEmpty) {
      return success(null);
    }

    // If the file changed while we were validating and preparing the change,
    // we should fail to avoid sending bad edits.
    if (fileHasBeenModified(unit.path, docVersion)) {
      return fileModifiedError;
    }

    var fileEdits = <FileEditInformation>[];
    for (var edit in edits) {
      var path = edit.file;
      var fileResult = context.session.getFile(path);
      if (fileResult is! FileResult) {
        return ErrorOr.error(
          ResponseError(
            code: ServerErrorCodes.fileAnalysisFailed,
            message: 'Could not access "$path".',
          ),
        );
      }
      var docIdentifier = server.getVersionedDocumentIdentifier(path);
      fileEdits.add(
        FileEditInformation(
          docIdentifier,
          fileResult.lineInfo,
          edit.edits,
          newFile: edit.fileStamp == -1,
        ),
      );
    }
    var workspaceEdit = toWorkspaceEdit(clientCapabilities, fileEdits);
    return await sendWorkspaceEditToClient(workspaceEdit);
  }
}
