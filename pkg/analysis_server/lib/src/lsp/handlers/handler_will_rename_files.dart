// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';

class WillRenameFilesHandler
    extends LspMessageHandler<RenameFilesParams, WorkspaceEdit?> {
  WillRenameFilesHandler(super.server);
  @override
  Method get handlesMessage => Method.workspace_willRenameFiles;

  @override
  LspJsonHandler<RenameFilesParams> get jsonHandler =>
      RenameFilesParams.jsonHandler;

  @override
  Future<ErrorOr<WorkspaceEdit?>> handle(RenameFilesParams params,
      MessageInfo message, CancellationToken token) async {
    final files = params.files;
    // Although we support folders, currently only a single item in the list
    // is supported (eg. although you can rename a folder, you can't drag
    // multiple files between folders).
    if (files.length > 1) {
      return success(null);
    }

    final file = files.single;
    final oldPath = pathOfUri(Uri.tryParse(file.oldUri));
    final newPath = pathOfUri(Uri.tryParse(file.newUri));

    return oldPath.mapResult((oldPath) =>
        newPath.mapResult((newPath) => _renameFile(oldPath, newPath, token)));
  }

  Future<ErrorOr<WorkspaceEdit?>> _renameFile(
      String oldPath, String newPath, CancellationToken token) async {
    final refactoring = MoveFileRefactoring(
        server.resourceProvider, server.refactoringWorkspace, oldPath)
      ..newFile = newPath
      ..cancellationToken = token;

    // If we're unable to update imports for a rename, we should silently do
    // nothing rather than interrupt the users file rename with an error.
    final results = await refactoring.checkAllConditions();
    if (results.hasFatalError) {
      return success(null);
    }

    final change = await refactoring.createChange();
    final edit = createWorkspaceEdit(server, change);

    return success(edit);
  }
}
