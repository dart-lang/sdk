// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/commands/simple_edit_handler.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/progress.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';
import 'package:analysis_server/src/services/correction/bulk_fix_processor.dart';
import 'package:analysis_server_plugin/src/correction/dart_change_workspace.dart';

abstract class AbstractFixAllInWorkspaceCommandHandler
    extends SimpleEditCommandHandler {
  AbstractFixAllInWorkspaceCommandHandler(super.server);

  /// Whether to require confirmation from the user to apply these changes.
  ///
  /// In VS Code, this will result in a preview/diff view being shown and the
  /// user can choose which changes to apply.
  bool get requireConfirmation;

  @override
  Future<ErrorOr<void>> handle(
    MessageInfo message,
    Map<String, Object?> parameters,
    ProgressReporter progress,
    CancellationToken cancellationToken,
  ) async {
    if (!(server.lspClientCapabilities?.applyEdit ?? false)) {
      return error(
        ServerErrorCodes.FeatureDisabled,
        '"$commandName" is only available for clients that support workspace/applyEdit',
      );
    }

    if (!(server.lspClientCapabilities?.changeAnnotations ?? false)) {
      return error(
        ServerErrorCodes.FeatureDisabled,
        '"$commandName" is only available for clients that support change annotations',
      );
    }

    var workspace = DartChangeWorkspace(
      await server.currentSessions,
    );
    var processor = BulkFixProcessor(server.instrumentationService, workspace);

    var result =
        await processor.fixErrors(server.contextManager.analysisContexts);
    var errorMessage = result.errorMessage;
    if (errorMessage != null) {
      return error(ErrorCodes.RequestFailed, errorMessage);
    }

    var changeBuilder = result.builder!;
    var change = changeBuilder.sourceChange;
    if (change.edits.isEmpty) {
      return success(null);
    }

    var edit = createWorkspaceEdit(
      server,
      change,
      annotateChanges: requireConfirmation
          ? ChangeAnnotations.requireConfirmation
          : ChangeAnnotations.include,
    );
    return sendWorkspaceEditToClient(edit);
  }
}

class FixAllInWorkspaceCommandHandler
    extends AbstractFixAllInWorkspaceCommandHandler {
  FixAllInWorkspaceCommandHandler(super.server);

  @override
  String get commandName => 'Apply All Fixes in Workspace';

  @override
  bool get requireConfirmation => false;
}

class PreviewFixAllInWorkspaceCommandHandler
    extends AbstractFixAllInWorkspaceCommandHandler {
  PreviewFixAllInWorkspaceCommandHandler(super.server);

  @override
  String get commandName => 'Preview All Fixes in Workspace';

  @override
  bool get requireConfirmation => true;
}
