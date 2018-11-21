// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/handlers/handler_states.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class IntializedMessageHandler extends MessageHandler {
  final LspAnalysisServer server;
  final List<String> openWorkspacePaths;
  IntializedMessageHandler(this.server, this.openWorkspacePaths);

  @override
  List<String> get handlesMessages => const ['initialized'];

  InitializeResult handleInitialized() {
    server.messageHandler = new InitializedStateMessageHandler(server);

    server.setAnalysisRoots(openWorkspacePaths, [], {});
    return null;
  }

  @override
  FutureOr<Object> handleMessage(IncomingMessage message) {
    return handleInitialized();
  }
}
