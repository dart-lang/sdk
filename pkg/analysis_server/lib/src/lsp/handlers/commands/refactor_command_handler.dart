// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/commands/simple_edit_handler.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_context.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_processor.dart';
import 'package:analysis_server/src/services/refactoring/framework/refactoring_producer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

/// A command handler for any of the commands used to implement refactorings.
class RefactorCommandHandler extends SimpleEditCommandHandler {
  @override
  final String commandName;

  final RefactoringProducerGenerator generator;

  RefactorCommandHandler(super.server, this.commandName, this.generator);

  @override
  Future<ErrorOr<void>> handle(
    MessageInfo message,
    Map<String, Object?> parameters,
    ProgressReporter progress,
    CancellationToken cancellationToken,
  ) async {
    var filePath = parameters['filePath'];
    var offset = parameters['selectionOffset'];
    var length = parameters['selectionLength'];
    var arguments = _validateArguments(parameters['arguments']);
    if (filePath is! String ||
        offset is! int ||
        length is! int ||
        arguments == null) {
      return ErrorOr.error(
        ResponseError(
          code: ServerErrorCodes.InvalidCommandArguments,
          message:
              'Refactoring operations require 4 parameters: '
              'filePath: String, '
              'offset: int, '
              'length: int, '
              'arguments: List',
        ),
      );
    }

    // Use the editor capabilities, since we're building edits to send to the
    // editor regardless of who called us.
    var clientCapabilities = server.editorClientCapabilities;
    if (clientCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return serverNotInitializedError;
    }

    var library = await requireResolvedLibrary(filePath);
    return library.mapResult((library) async {
      var unit = library.unitWithPath(filePath);
      if (unit == null) {
        return error(
          ErrorCodes.InternalError,
          'The library containing a path did not contain the path.',
        );
      }
      try {
        progress.begin('Refactoring…');
        return await _performRefactor(
          library,
          unit,
          clientCapabilities,
          offset,
          length,
          arguments,
        );
      } finally {
        progress.end();
      }
    });
  }

  /// Performs the refactor, including sending the edits to the client and
  /// waiting for them to be applied.
  Future<ErrorOr<void>> _performRefactor(
    ResolvedLibraryResult library,
    ResolvedUnitResult unit,
    LspClientCapabilities clientCapabilities,
    int offset,
    int length,
    List<Object?> arguments,
  ) async {
    var context = RefactoringContext(
      server: server,
      startSessions: await server.currentSessions,
      resolvedLibraryResult: library,
      resolvedUnitResult: unit,
      clientCapabilities: clientCapabilities,
      selectionOffset: offset,
      selectionLength: length,
      includeExperimental:
          server.lspClientConfiguration.global.experimentalRefactors,
    );
    var producer = generator(context);
    var builder = ChangeBuilder(
      workspace: context.workspace,
      eol: context.utils.endOfLine,
    );
    var status = await producer.compute(arguments, builder);

    if (status is ComputeStatusFailure) {
      var reason = status.reason ?? 'Cannot compute the change. No details.';
      return ErrorOr.error(
        ResponseError(
          code: ServerErrorCodes.RefactoringComputeStatusFailure,
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
            code: ServerErrorCodes.FileAnalysisFailed,
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

  /// If the [arguments] is a list, then return it. Otherwise, return `null`
  /// to indicate that they aren't what we were expecting.
  List<Object?>? _validateArguments(Object? arguments) {
    if (arguments is! List<Object?>) {
      return null;
    }
    return arguments;
  }
}
