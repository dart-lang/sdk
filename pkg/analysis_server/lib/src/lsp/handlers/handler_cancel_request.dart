// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class CancelRequestHandler extends MessageHandler<CancelParams, void> {
  final Map<String, CancelableToken> _tokens = {};

  CancelRequestHandler(LspAnalysisServer server) : super(server);

  @override
  Method get handlesMessage => Method.cancelRequest;

  @override
  LspJsonHandler<CancelParams> get jsonHandler => CancelParams.jsonHandler;

  void clearToken(RequestMessage message) {
    _tokens.remove(message.id.toString());
  }

  CancelableToken createToken(RequestMessage message) {
    final token = CancelableToken();
    _tokens[message.id.toString()] = token;
    return token;
  }

  @override
  ErrorOr<void> handle(CancelParams params, CancellationToken token) {
    // Don't assume this is in the map as it's possible the client sent a
    // cancellation that we processed after already starting to send the response
    // and cleared the token.
    _tokens[params.id.toString()]?.cancel();
    return success();
  }
}
