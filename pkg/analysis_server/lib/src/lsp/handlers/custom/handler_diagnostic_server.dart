// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_custom_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class DiagnosticServerHandler
    extends MessageHandler<void, DartDiagnosticServer> {
  DiagnosticServerHandler(LspAnalysisServer server) : super(server);
  Method get handlesMessage => CustomMethods.DiagnosticServer;

  @override
  void convertParams(Map<String, dynamic> json) => null;

  @override
  Future<ErrorOr<DartDiagnosticServer>> handle(void _) async {
    final port = await server.diagnosticServer.getServerPort();
    return success(new DartDiagnosticServer(port));
  }
}
