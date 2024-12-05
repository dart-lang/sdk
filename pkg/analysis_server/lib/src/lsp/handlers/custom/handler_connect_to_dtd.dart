// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';

/// A handler for the [CustomMethods.connectToDtd] custom request.
///
/// This request allows a client to provide a URI for DTD, which the server will
/// connect to and provide access to a subset of LSP requests.
///
/// A response is sent only once the server has connected to DTD and registered
/// all services, or the connection failed.
///
/// This handler is only available to trusted callers (those with direct access
/// to the protocol over stdin/stdout).
class ConnectToDtdHandler
    extends SharedMessageHandler<ConnectToDtdParams, Null> {
  ConnectToDtdHandler(super.server);

  @override
  Method get handlesMessage => CustomMethods.connectToDtd;

  @override
  LspJsonHandler<ConnectToDtdParams> get jsonHandler =>
      ConnectToDtdParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => true;

  @override
  Future<ErrorOr<Null>> handle(
    ConnectToDtdParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    return await server.connectToDtd(params.uri);
  }
}
