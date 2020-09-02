// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/handlers/handler_states.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class IntializedMessageHandler extends MessageHandler<InitializedParams, void> {
  final List<String> openWorkspacePaths;
  IntializedMessageHandler(
    LspAnalysisServer server,
    this.openWorkspacePaths,
  ) : super(server);
  @override
  Method get handlesMessage => Method.initialized;

  @override
  LspJsonHandler<InitializedParams> get jsonHandler =>
      InitializedParams.jsonHandler;

  @override
  Future<ErrorOr<void>> handle(
      InitializedParams params, CancellationToken token) async {
    server.messageHandler = InitializedStateMessageHandler(
      server,
    );

    await server.fetchClientConfigurationAndPerformDynamicRegistration();

    if (!server.initializationOptions.onlyAnalyzeProjectsWithOpenFiles) {
      server.updateAnalysisRoots(openWorkspacePaths, const []);
    }

    return success();
  }
}
