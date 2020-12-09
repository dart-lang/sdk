// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_custom_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class DiagnosticServerHandler
    extends MessageHandler<void, DartDiagnosticServer> {
  DiagnosticServerHandler(LspAnalysisServer server) : super(server);
  @override
  Method get handlesMessage => CustomMethods.diagnosticServer;

  @override
  LspJsonHandler<void> get jsonHandler => NullJsonHandler;

  @override
  Future<ErrorOr<DartDiagnosticServer>> handle(
      void _, CancellationToken token) async {
    final port = await server.diagnosticServer.getServerPort();
    return success(DartDiagnosticServer(port: port));
  }
}
