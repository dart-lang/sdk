// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analysis_server/src/services/refactoring/legacy/move_file.dart';
import 'package:meta/meta.dart';

typedef StaticOptions = FileOperationRegistrationOptions?;

class WillRenameFilesHandler
    extends SharedMessageHandler<RenameFilesParams, WorkspaceEdit?> {
  /// A [Future] used by tests to allow inserting a delay during computation
  /// to allow forcing inconsistent analysis.
  @visibleForTesting
  static Future<void>? delayDuringComputeForTests;

  WillRenameFilesHandler(super.server);

  @override
  Method get handlesMessage => Method.workspace_willRenameFiles;

  @override
  LspJsonHandler<RenameFilesParams> get jsonHandler =>
      RenameFilesParams.jsonHandler;

  @override
  Future<ErrorOr<WorkspaceEdit?>> handle(RenameFilesParams params,
      MessageInfo message, CancellationToken token) async {
    final pathMapping = <String, String>{};

    for (final file in params.files) {
      final oldPath = pathOfUri(Uri.tryParse(file.oldUri));

      if (oldPath.isError) {
        return failure(oldPath);
      }

      final newPath = pathOfUri(Uri.tryParse(file.newUri));
      if (newPath.isError) {
        return failure(newPath);
      }

      pathMapping[oldPath.result] = newPath.result;
    }
    return _renameFiles(pathMapping, token);
  }

  Future<ErrorOr<WorkspaceEdit?>> _renameFiles(
      Map<String, String> renames, CancellationToken token) async {
    // This handler has a lot of async steps and may modify files that we don't
    // know about at the start (or in the case of LSP-over-Legacy that we even
    // have version numbers for). To ensure we never produce inconsistent edits,
    // capture all sessions at the start and ensure they are all consistent at the end.
    final sessions = await server.currentSessions;

    final refactoring = MoveFileRefactoringImpl.multi(
        server.resourceProvider, server.refactoringWorkspace, renames)
      ..cancellationToken = token;

    // If we're unable to update imports for a rename, we should silently do
    // nothing rather than interrupt the users file rename with an error.
    final results = await refactoring.checkAllConditions();
    if (token.isCancellationRequested) {
      return cancelled();
    }

    if (results.hasFatalError) {
      return success(null);
    }

    final change = await refactoring.createChange();
    if (delayDuringComputeForTests != null) {
      await delayDuringComputeForTests;
    }

    if (token.isCancellationRequested) {
      return cancelled();
    }

    server.checkConsistency(sessions);

    final edit = createWorkspaceEdit(server, change);
    return success(edit);
  }
}

class WillRenameFilesRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<StaticOptions> {
  WillRenameFilesRegistrations(super.info);

  @override
  FileOperationRegistrationOptions? get options =>
      fileOperationRegistrationOptions;

  @override
  Method get registrationMethod => Method.workspace_willRenameFiles;

  @override
  StaticOptions get staticOptions => options;

  @override
  bool get supportsDynamic =>
      updateImportsOnRename && clientDynamic.fileOperations;

  @override
  bool get supportsStatic => updateImportsOnRename;

  bool get updateImportsOnRename =>
      clientConfiguration.global.updateImportsOnRename;
}
