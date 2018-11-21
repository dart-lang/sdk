// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class TextDocumentChangeHandler extends MessageHandler {
  /**
   * The analysis server that is using this handler to process requests.
   */
  final LspAnalysisServer server;

  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  TextDocumentChangeHandler(this.server);

  /**
   * The messages that this handler can handle.
   */
  @override
  List<String> get handlesMessages => const [
        'textDocument/didOpen',
        'textDocument/didChange',
        'textDocument/didClose'
      ];

  void handleChange(DidChangeTextDocumentParams params) {
    server.changeTextDocument(params.textDocument, params.contentChanges);
  }

  void handleClose(DidCloseTextDocumentParams params) {
    server.closeTextDocument(params.textDocument);
  }

  @override
  Object handleMessage(IncomingMessage message) {
    // TODO(dantup): Make all handlers handle on a single request (we can
    // split this into three, but keep together in this file) then simplify
    // this boilerplate so the convert params can be done further up (though
    // we'll need to provide the fromJson function in a super constructor
    // call or similar).

    if (message is! NotificationMessage) {
      throw 'Unexpected message (expected NotificationMessage but got ${message.runtimeType})';
    }
    if (message.method == 'textDocument/didOpen') {
      final params = convertParams(message, DidOpenTextDocumentParams.fromJson);
      handleOpen(params);
      return null;
    } else if (message.method == 'textDocument/didChange') {
      final params =
          convertParams(message, DidChangeTextDocumentParams.fromJson);
      handleChange(params);
      return null;
    } else if (message.method == 'textDocument/didClose') {
      final params =
          convertParams(message, DidCloseTextDocumentParams.fromJson);
      handleClose(params);
      return null;
    } else {
      throw 'Unexpected method (${message.method})';
    }
  }

  void handleOpen(DidOpenTextDocumentParams params) {
    server.openTextDocument(params.textDocument);
  }
}
