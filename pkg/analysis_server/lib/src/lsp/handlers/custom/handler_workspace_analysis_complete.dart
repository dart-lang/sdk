// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class WorkspaceAnalysisCompleteHandler
    extends SharedMessageHandler<void, void> {
  new(super.server);

  @override
  Method get handlesMessage => CustomMethods.workspaceAnalysisComplete;

  @override
  LspJsonHandler<void> get jsonHandler => nullJsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<void>> handle(
    void params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    // LSP Workspace Folder updates can trigger async work before the analysis
    // context rebuilds start.
    if (server case LspAnalysisServer server) {
      await server.workspaceFolderUpdate;
    }

    // Wait for any in-progress analysis context builds. The driver scheduler
    // might appear idle while these are still in progress before work begins.
    await server.analysisContextsRebuilt;

    // Wait for server to become idle.
    await server.analysisDriverScheduler.waitForIdle();

    // TODO(dantup): Handle plugins here. We must wait if they are still
    //  initializing, then allow for them to start and complete analysis.

    return success(null);
  }
}
