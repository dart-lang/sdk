// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/handlers/handler_states.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';

class ShutdownMessageHandler extends LspMessageHandler<void, void> {
  ShutdownMessageHandler(super.server);

  @override
  Method get handlesMessage => Method.shutdown;

  @override
  LspJsonHandler<void> get jsonHandler => NullJsonHandler;

  @override
  ErrorOr<void> handle(
      void params, MessageInfo message, CancellationToken token) {
    // Move to the Shutting Down state so we won't process any more
    // requests and the Exit notification will know it was a clean shutdown.
    server.messageHandler = ShuttingDownStateMessageHandler(server);

    // We can clean up and shut down here, but we cannot terminate the server
    // because that must be done after the exit notification.

    return success(null);
  }
}
