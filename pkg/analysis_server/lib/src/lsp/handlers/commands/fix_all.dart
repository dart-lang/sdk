// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/commands/simple_edit_handler.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/lsp/temporary_overlay_operation.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server/src/utilities/source_change_merger.dart';
import 'package:analyzer/dart/analysis/results.dart';

class FixAllCommandHandler extends SimpleEditCommandHandler
    with LspHandlerHelperMixin {
  FixAllCommandHandler(super.server);

  @override
  String get commandName => 'Fix All';

  @override
  Future<ErrorOr<void>> handle(
    MessageInfo message,
    Map<String, Object?> parameters,
    ProgressReporter progress,
    CancellationToken cancellationToken,
  ) async {
    if (parameters['path'] is! String) {
      return ErrorOr.error(ResponseError(
        code: ServerErrorCodes.InvalidCommandArguments,
        message: '$commandName requires a Map argument containing a "path"',
      ));
    }

    // Get the version of the doc before we calculate edits so we can send it
    // back to the client so that they can discard this edit if the document has
    // been modified since.
    final path = parameters['path'] as String;
    final docIdentifier = server.getVersionedDocumentIdentifier(path);
    final autoTriggered = parameters['autoTriggered'] == true;

    final operation = _FixAllOperation(
      server: server,
      message: message,
      path: path,
      cancellationToken: cancellationToken,
      autoTriggered: autoTriggered,
    );
    final edit = await operation.computeEdits();

    return edit.mapResult((edit) async {
      if (edit == null) {
        return success(null);
      }

      // Before we send an edit back, ensure the original file didn't change
      // (or the request cancelled) while we were computing changes.
      if (cancellationToken.isCancellationRequested) {
        return error(ErrorCodes.RequestCancelled, 'Request was cancelled');
      }
      // If the client modified the file, it's possible (though unlikely since
      // we only just unlocked the queue and having had many 'await's) that the
      // document has already been updated, in which case we can fail the
      // request early.
      //
      // In the case of the modification not yet being processed, we will send
      // an edit to the client, but it contains the version number of the
      // document we had, so the client will notice that the versions don't
      // match and refuse to apply the edits.
      if (fileHasBeenModified(path, docIdentifier.version)) {
        return fileModifiedError;
      }

      // Sending the edit to the client must be outside of the lock because
      // otherwise the response will not be processed.
      return sendWorkspaceEditToClient(edit);
    });
  }
}

/// Computes edits for iterative fix-all using temporary overlays.
class _FixAllOperation extends TemporaryOverlayOperation
    with HandlerHelperMixin<LspAnalysisServer> {
  final MessageInfo message;
  final CancellationToken cancellationToken;
  final String path;
  final bool autoTriggered;

  _FixAllOperation({
    required LspAnalysisServer server,
    required this.message,
    required this.path,
    required this.cancellationToken,
    required this.autoTriggered,
  }) : super(server);

  Future<ErrorOr<WorkspaceEdit?>> computeEdits() async {
    return await lockRequestsWithTemporaryOverlays(() async {
      final result = await requireResolvedUnit(path);
      return result.mapResult(_computeEditsImpl);
    });
  }

  Future<ErrorOr<WorkspaceEdit?>> _computeEditsImpl(
      ResolvedUnitResult result) async {
    if (cancellationToken.isCancellationRequested) {
      return error(ErrorCodes.RequestCancelled, 'Request was cancelled');
    }

    final context = server.contextManager.getContextFor(path);
    if (context == null) {
      return success(null);
    }

    final processor = IterativeBulkFixProcessor(
      instrumentationService: server.instrumentationService,
      context: context,
      applyTemporaryOverlayEdits: applyTemporaryOverlayEdits,
      applyOverlays: applyOverlays,
      cancellationToken: cancellationToken,
    );

    var changes = await processor.fixErrorsForFile(message.performance, path,
        autoTriggered: autoTriggered);
    if (changes.isEmpty) {
      return success(null);
    }

    // We only need to merge if we know we did multiple passes.
    if (processor.passesWithEdits > 1) {
      changes = message.performance.run(
        'SourceChangeMerger.merge',
        (_) => SourceChangeMerger().merge(changes),
      );
    }

    // We must revert overlays before mapping edits, because we need any
    // LineInfos to reflect the original state while mapping to LSP.
    revertOverlays();

    final edit = createPlainWorkspaceEdit(server, changes);

    return success(edit);
  }
}
