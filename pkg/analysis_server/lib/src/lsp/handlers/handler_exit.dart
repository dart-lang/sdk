// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';

class ExitMessageHandler extends LspMessageHandler<void, void> {
  final bool clientDidCallShutdown;

  ExitMessageHandler(
    super.server, {
    this.clientDidCallShutdown = false,
  });

  @override
  Method get handlesMessage => Method.exit;

  @override
  LspJsonHandler<void> get jsonHandler => NullJsonHandler;

  @override
  Future<ErrorOr<void>> handle(
      void params, MessageInfo message, CancellationToken token) async {
    // Set a flag that the server shutdown is being controlled here to ensure
    // that the normal code that shuts down the server when the channel closes
    // does not fire.
    server.willExit = true;

    await server.shutdown();
    // Use Future to schedule the exit after we have responded to this request
    // (so the client gets the response). Do not await it as it will prevent the
    // response from completing.
    unawaited(Future(() => exit(clientDidCallShutdown ? 0 : 1)));
    return success(null);
  }
}
