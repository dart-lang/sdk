// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';

class ReanalyzeHandler extends LspMessageHandler<void, void> {
  ReanalyzeHandler(super.server);

  @override
  Method get handlesMessage => CustomMethods.reanalyze;

  @override
  LspJsonHandler<void> get jsonHandler => NullJsonHandler;

  @override
  Future<ErrorOr<void>> handle(
      void params, MessageInfo message, CancellationToken token) async {
    // This command just starts a refresh, it does not wait for it to
    // complete before responding to the client.
    unawaited(server.reanalyze());
    return success(null);
  }
}
