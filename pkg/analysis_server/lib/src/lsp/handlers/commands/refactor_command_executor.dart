// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/commands/refactor_command_handler_mixin.dart';
import 'package:analysis_server/src/lsp/handlers/commands/simple_edit_handler.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_context.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_processor.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analyzer/dart/analysis/results.dart';
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
  ) async {
    try {
      // ignore: unawaited_futures
      progress.begin('Refactoring…');
      return await _performRefactor(
        library,
        unit,
        clientCapabilities,
        context,
        arguments,
      );
    } finally {
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
  ) async {
    var producer = generator(context);
    var builder = ChangeBuilder(
      workspace: context.workspace,
      defaultEol: context.utils.endOfLine,
    );
    var status = await producer.compute(arguments, builder);

    if (status is ComputeStatusFailure) {
      var reason = status.reason ?? 'Cannot compute the change. No details.';
      return ErrorOr.error(
        ResponseError(
          code: ServerErrorCodes.refactoringComputeStatusFailure,
          message: reason,
        ),
      );
    }

    var edits = builder.sourceChange.edits;
    if (edits.isEmpty) {
      return success(null);
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
    return sendWorkspaceEditToClient(workspaceEdit);
  }
}
