// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';

typedef StaticOptions = Either2<bool, String>;

class ChangeWorkspaceFoldersHandler
    extends LspMessageHandler<DidChangeWorkspaceFoldersParams, void> {
  // Whether to update analysis roots based on the open workspace folders.
  bool updateAnalysisRoots;

  ChangeWorkspaceFoldersHandler(super.server)
      : updateAnalysisRoots =
            !server.initializationOptions.onlyAnalyzeProjectsWithOpenFiles;

  @override
  Method get handlesMessage => Method.workspace_didChangeWorkspaceFolders;

  @override
  LspJsonHandler<DidChangeWorkspaceFoldersParams> get jsonHandler =>
      DidChangeWorkspaceFoldersParams.jsonHandler;

  @override
  Future<ErrorOr<void>> handle(DidChangeWorkspaceFoldersParams params,
      MessageInfo message, CancellationToken token) async {
    // Don't do anything if our analysis roots are not based on open workspaces.
    if (!updateAnalysisRoots) {
      return success(null);
    }

    final added = _convertWorkspaceFolders(params.event.added);
    final removed = _convertWorkspaceFolders(params.event.removed);

    server.analyticsManager
        .changedWorkspaceFolders(added: added, removed: removed);

    await server.updateWorkspaceFolders(added, removed);

    return success(null);
  }

  /// Return the result of converting the list of workspace [folders] to file
  /// paths.
  List<String> _convertWorkspaceFolders(List<WorkspaceFolder> folders) {
    return folders.map((wf) => pathContext.fromUri(wf.uri)).toList();
  }
}

class ChangeWorkspaceFoldersRegistrations extends FeatureRegistration
    with StaticRegistration<StaticOptions> {
  ChangeWorkspaceFoldersRegistrations(super.info);

  @override
  List<LspDynamicRegistration> get dynamicRegistrations => [];

  @override
  StaticOptions get staticOptions => Either2.t1(true);

  @override
  bool get supportsDynamic => false;
}
