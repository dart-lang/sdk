// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/commands/simple_edit_handler.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/operations/fix_all_in_workspace.dart';
import 'package:analysis_server/src/lsp/progress.dart';

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
    // This implementation is similar to the `dart/workspace/fixes/get`, but
    // whereas that returns fixes, this command applies them (by sending a
    // reverse-request to the editor). It is a command, instead of a request.

    // Use the editor capabilities, since we're building edits to send to the
    // editor regardless of who called us. This is different to the
    // `dart/workspace/fixes/get` request where we return them to the caller.
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

    var operation = FixAllInWorkspaceOperation(
      server: server,
      message: message,
      cancellationToken: cancellationToken,
      requireConfirmation: requireConfirmation,
    );

    // ignore: unawaited_futures
    progress.begin('Computing fixes…');
    try {
      var result = await operation.compute();
      return await result.mapResult((result) async {
        var (edit, _) = result;
        if (edit == null) {
          return success(null);
        }
        return await sendWorkspaceEditToClient(edit);
      });
    } finally {
      // ignore: unawaited_futures
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
