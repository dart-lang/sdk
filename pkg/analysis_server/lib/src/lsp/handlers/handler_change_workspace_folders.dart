// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class WorkspaceFoldersHandler
    extends MessageHandler<DidChangeWorkspaceFoldersParams, void> {
  // Whether to update analysis roots based on the open workspace folders.
  bool updateAnalysisRoots;

  WorkspaceFoldersHandler(LspAnalysisServer server, this.updateAnalysisRoots)
      : super(server);

  @override
  Method get handlesMessage => Method.workspace_didChangeWorkspaceFolders;

  @override
  LspJsonHandler<DidChangeWorkspaceFoldersParams> get jsonHandler =>
      DidChangeWorkspaceFoldersParams.jsonHandler;

  @override
  ErrorOr<void> handle(
      DidChangeWorkspaceFoldersParams params, CancellationToken token) {
    // Don't do anything if our analysis roots are not based on open workspaces.
    if (!updateAnalysisRoots) {
      return success();
    }

    final added = params?.event?.added
        ?.map((wf) => Uri.parse(wf.uri).toFilePath())
        ?.toList();

    final removed = params?.event?.removed
        ?.map((wf) => Uri.parse(wf.uri).toFilePath())
        ?.toList();

    server.updateAnalysisRoots(added, removed);

    return success();
  }
}
