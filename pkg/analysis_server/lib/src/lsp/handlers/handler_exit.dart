// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class ExitMessageHandler extends MessageHandler<void, void> {
  final LspAnalysisServer server;
  String get handlesMessage => 'exit';
  ExitMessageHandler(this.server) : super(null);

  @override
  Future<void> handle(void _) {
    return server.shutdown();
  }
}
