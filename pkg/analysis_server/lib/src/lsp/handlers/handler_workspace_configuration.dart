// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class WorkspaceDidChangeConfigurationMessageHandler
    extends MessageHandler<DidChangeConfigurationParams, void> {
  WorkspaceDidChangeConfigurationMessageHandler(LspAnalysisServer server)
      : super(server);

  @override
  Method get handlesMessage => Method.workspace_didChangeConfiguration;

  @override
  LspJsonHandler<DidChangeConfigurationParams> get jsonHandler =>
      DidChangeConfigurationParams.jsonHandler;

  @override
  Future<ErrorOr<void>> handle(
      DidChangeConfigurationParams params, CancellationToken token) async {
    // In LSP, the `settings` field no longer contains changed settings because
    // they can be resource-scoped, so this is used only as a notification and
    // to keep settings up-to-date we must re-request them from the client
    // whenever we are told they may have changed.
    await server.fetchClientConfigurationAndPerformDynamicRegistration();

    return success();
  }
}
