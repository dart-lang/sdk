// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';

class WillRenameFilesHandler extends MessageHandler<RenameFilesParams, void> {
  WillRenameFilesHandler(LspAnalysisServer server) : super(server);
  @override
  Method get handlesMessage => Method.workspace_willRenameFiles;

  @override
  LspJsonHandler<RenameFilesParams> get jsonHandler =>
      RenameFilesParams.jsonHandler;

  @override
  Future<ErrorOr<WorkspaceEdit>> handle(
      RenameFilesParams params, CancellationToken token) async {
    final files = params?.files ?? [];
    // For performance reasons, only single-file rename/moves are currently supported.
    if (files.length > 1 || files.any((f) => !f.oldUri.endsWith('.dart'))) {
      return success(null);
    }

    final file = files.single;
    final oldPath = pathOfUri(Uri.tryParse(file.oldUri));
    final newPath = pathOfUri(Uri.tryParse(file.newUri));
    return oldPath.mapResult((oldPath) =>
        newPath.mapResult((newPath) => _renameFile(oldPath, newPath)));
  }

  Future<ErrorOr<WorkspaceEdit>> _renameFile(
      String oldPath, String newPath) async {
    final resolvedUnit = await server.getResolvedUnit(oldPath);
    if (resolvedUnit == null) {
      return success(null);
    }

    final refactoring = MoveFileRefactoring(server.resourceProvider,
        server.refactoringWorkspace, resolvedUnit, oldPath)
      ..newFile = newPath;

    // If we're unable to update imports for a rename, we should silently do
    // nothing rather than interrupt the users file rename with an error.
    final results = await refactoring.checkAllConditions();
    if (results.hasFatalError) {
      return success(null);
    }

    final change = await refactoring.createChange();
    final edit = createWorkspaceEdit(server, change.edits);

    return success(edit);
  }
}
