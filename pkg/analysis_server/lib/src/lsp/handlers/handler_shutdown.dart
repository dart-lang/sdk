// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class ShutdownMessageHandler extends MessageHandler<void, void> {
  final LspAnalysisServer server;
  String get handlesMessage => 'shutdown';
  ShutdownMessageHandler(this.server) : super(null);

  @override
  void handle(void _) {
    // We can clean up and shut down here, but we cannot terminate the server
    // because that must be done after the exit notification.
  }
}
