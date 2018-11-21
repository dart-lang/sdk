// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class ShutdownMessageHandler extends MessageHandler {
  final LspAnalysisServer server;

  ShutdownMessageHandler(this.server);

  @override
  List<String> get handlesMessages => const ['shutdown'];

  @override
  FutureOr<Object> handleMessage(IncomingMessage message) {
    // We can clean up and shut down here, but we cannot terminate the server
    // because that must be done after the exit notification.
    return null;
  }
}
