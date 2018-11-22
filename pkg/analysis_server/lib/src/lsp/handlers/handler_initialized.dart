// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/handlers/handler_states.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class IntializedMessageHandler extends MessageHandler<InitializedParams, void> {
  final LspAnalysisServer server;
  String get handlesMessage => 'initialized';
  final List<String> openWorkspacePaths;
  IntializedMessageHandler(this.server, this.openWorkspacePaths)
      : super(InitializedParams.fromJson);

  void handle(InitializedParams params) {
    server.messageHandler = new InitializedStateMessageHandler(server);

    server.setAnalysisRoots(openWorkspacePaths, [], {});
  }
}
