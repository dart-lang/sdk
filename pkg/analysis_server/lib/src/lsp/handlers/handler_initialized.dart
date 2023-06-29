// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/handler_states.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';

class InitializedMessageHandler
    extends LspMessageHandler<InitializedParams, void> {
  final List<String> openWorkspacePaths;
  InitializedMessageHandler(
    super.server,
    this.openWorkspacePaths,
  );
  @override
  Method get handlesMessage => Method.initialized;

  @override
  LspJsonHandler<InitializedParams> get jsonHandler =>
      InitializedParams.jsonHandler;

  @override
  Future<ErrorOr<void>> handle(InitializedParams params, MessageInfo message,
      CancellationToken token) async {
    server.messageHandler = InitializedStateMessageHandler(
      server,
    );

    server.analyticsManager.initialized(openWorkspacePaths: openWorkspacePaths);

    if (server.initializationOptions.onlyAnalyzeProjectsWithOpenFiles) {
      await server.fetchClientConfigurationAndPerformDynamicRegistration();
    } else {
      // This method internally calls
      // fetchClientConfigurationAndPerformDynamicRegistration.
      await server.updateWorkspaceFolders(openWorkspacePaths, const []);
    }

    return success(null);
  }
}
