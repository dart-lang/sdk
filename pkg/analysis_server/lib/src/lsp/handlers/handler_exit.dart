// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class ExitMessageHandler extends MessageHandler {
  final LspAnalysisServer server;

  ExitMessageHandler(this.server);

  @override
  List<String> get handlesMessages => const ['exit'];

  @override
  FutureOr<Object> handleMessage(IncomingMessage message) {
    return server.shutdown();
  }
}
