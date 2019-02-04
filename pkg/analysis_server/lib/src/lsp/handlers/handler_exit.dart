// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class ExitMessageHandler extends MessageHandler<void, void> {
  ExitMessageHandler(LspAnalysisServer server) : super(server);
  Method get handlesMessage => Method.exit;

  @override
  void convertParams(Map<String, dynamic> json) => null;

  @override
  Future<ErrorOr<void>> handle(void _) async {
    // TODO(dantup): Spec says we should exit with a code of 1 if we had not
    // received a shutdown request prior to exit.
    // TODO(dantup): Probably we should add a new state for "shutting down"
    // that refuses any more requests between shutdown and exit.
    await server.shutdown();
    return success();
  }
}
