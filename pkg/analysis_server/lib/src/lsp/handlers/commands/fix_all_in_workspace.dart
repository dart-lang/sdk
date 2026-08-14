// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/commands/simple_edit_handler.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analysis_server/src/lsp/temporary_overlay_operation.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server/src/utilities/source_change_merger.dart';

abstract class AbstractFixAllInWorkspaceCommandHandler
    extends SimpleEditCommandHandler<LspAnalysisServer> {
  new(super.server);

  /// Whether to require confirmation from the user to apply these changes.
  ///
  /// In VS Code, this will result in a preview/diff view being shown and the
  /// user can choose which changes to apply.
  bool get requireConfirmation;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<void>> handle(
    MessageInfo message,
    Map<String, Object?> parameters,
    ProgressReporter progress,
    CancellationToken cancellationToken,
  ) async {
    // Use the editor capabilities, since we're building edits to send to the
    // editor regardless of who called us.
    var clientCapabilities = server.editorClientCapabilities;
    if (clientCapabilities == null) {
      return serverNotInitializedError;
    }

    if (!clientCapabilities.applyEdit) {
      return error(
        ServerErrorCodes.featureDisabled,
        '"$commandName" is only available for clients that support workspace/applyEdit',
      );
    }

    if (!clientCapabilities.changeAnnotations) {
      return error(
        ServerErrorCodes.featureDisabled,
        '"$commandName" is only available for clients that support change annotations',
      );
    }

    var operation = _FixAllOperation(
      server: server,
      message: message,
      cancellationToken: cancellationToken,
      requireConfirmation: requireConfirmation,
    );

    progress.begin('Computing fixes…');
    try {
      var result = await operation.computeEdits();
      return await result.mapResult((edit) async {
        if (edit == null) {
          return success(null);
        }
        return await sendWorkspaceEditToClient(edit);
      });
    } finally {
      progress.end();
    }
  }
}

class FixAllInWorkspaceCommandHandler
    extends AbstractFixAllInWorkspaceCommandHandler {
  new(super.server);

  @override
  String get commandName => 'Apply All Fixes in Workspace';

  @override
  bool get requireConfirmation => false;
}

class PreviewFixAllInWorkspaceCommandHandler
    extends AbstractFixAllInWorkspaceCommandHandler {
  new(super.server);

  @override
  String get commandName => 'Preview All Fixes in Workspace';

  @override
  bool get requireConfirmation => true;
}

/// Computes edits for iterative fix-all using temporary overlays.
class _FixAllOperation extends TemporaryOverlayOperation
    with HandlerHelperMixin<AnalysisServer> {
  final MessageInfo message;
  final CancellationToken cancellationToken;
  final bool requireConfirmation;

  new({
    required AnalysisServer server,
    required this.message,
    required this.cancellationToken,
    required this.requireConfirmation,
  }) : super(server);

  Future<ErrorOr<WorkspaceEdit?>> computeEdits() async {
    return await pauseSchedulerWithTemporaryOverlays(_computeEditsImpl);
  }

  Future<ErrorOr<WorkspaceEdit?>> _computeEditsImpl() async {
    if (cancellationToken.isCancellationRequested) {
      return cancelled(cancellationToken);
    }

    var contexts = server.contextManager.analysisContexts;
    var processor = IterativeBulkFixProcessor(
      instrumentationService: server.instrumentationService,
      byteStore: server.byteStore,
      applyTemporaryOverlayEdits: applyTemporaryOverlayEdits,
      applyOverlays: applyOverlays,
      cancellationToken: cancellationToken,
    );

    var result = await processor.fixErrors(message.performance, contexts);
    var errorMessage = result.errorMessage;
    if (errorMessage != null) {
      return ErrorOr.error(
        ResponseError(code: ErrorCodes.RequestFailed, message: errorMessage),
      );
    }
    var changes = result.edits;
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
    await revertOverlays();

    var edit = createPlainWorkspaceEdit(
      server,
      server.editorClientCapabilities!,
      changes,
      annotateChanges: requireConfirmation
          ? ChangeAnnotations.requireConfirmation
          : ChangeAnnotations.include,
    );

    return success(edit);
  }
}
