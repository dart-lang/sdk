// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class ExitMessageHandler extends MessageHandler<void, void> {
  final bool clientDidCallShutdown;

  ExitMessageHandler(
    LspAnalysisServer server, {
    this.clientDidCallShutdown = false,
  }) : super(server);

  @override
  Method get handlesMessage => Method.exit;

  @override
  LspJsonHandler<void> get jsonHandler => NullJsonHandler;

  @override
  Future<ErrorOr<void>> handle(void _, CancellationToken token) async {
    // Set a flag that the server shutdown is being controlled here to ensure
    // that the normal code that shuts down the server when the channel closes
    // does not fire.
    server.willExit = true;

    await server.shutdown();
    Future(() {
      exit(clientDidCallShutdown ? 0 : 1);
    });
    return success();
  }
}
