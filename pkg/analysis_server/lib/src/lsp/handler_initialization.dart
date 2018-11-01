// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class InitializationHandler extends MessageHandler {
  /**
   * The analysis server that is using this handler to process requests.
   */
  final LspAnalysisServer server;

  /**
   * The messages that this handler can handle.
   */
  List<String> get handlesMessages => const ['initialize'];

  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  InitializationHandler(this.server);

  @override
  Object handleMessage(IncomingMessage message) {
    if (message.method == "initialize") {
      final params = convertParams(message, InitializeParams.fromJson);
      return handleInitialize(params);
    }

    throw 'Unexpected message';
  }

  InitializeResult handleInitialize(InitializeParams params) {
    server.setClientCapabilities(params.capabilities);

    // TODO(dantup): This needs a real implementation. For this request we
    // should store the client capabilities on this.server and return what
    // we support.
    return new InitializeResult(new ServerCapabilities(
        null,
        true, // Hover
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null));
  }
}
