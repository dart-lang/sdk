// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class TextDocumentChangeHandler
    extends MessageHandler<DidChangeTextDocumentParams, void> {
  final LspAnalysisServer server;
  String get handlesMessage => 'textDocument/didChange';
  TextDocumentChangeHandler(this.server)
      : super(DidChangeTextDocumentParams.fromJson);

  void handle(DidChangeTextDocumentParams params) {
    server.changeTextDocument(params.textDocument, params.contentChanges);
  }
}

class TextDocumentCloseHandler
    extends MessageHandler<DidCloseTextDocumentParams, void> {
  final LspAnalysisServer server;
  String get handlesMessage => 'textDocument/didClose';
  TextDocumentCloseHandler(this.server)
      : super(DidCloseTextDocumentParams.fromJson);

  void handle(DidCloseTextDocumentParams params) {
    server.closeTextDocument(params.textDocument);
  }
}

class TextDocumentOpenHandler
    extends MessageHandler<DidOpenTextDocumentParams, void> {
  final LspAnalysisServer server;
  String get handlesMessage => 'textDocument/didOpen';
  TextDocumentOpenHandler(this.server)
      : super(DidOpenTextDocumentParams.fromJson);

  void handle(DidOpenTextDocumentParams params) {
    server.openTextDocument(params.textDocument);
  }
}
