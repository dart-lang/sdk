// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';

class DiagnosticServerHandler
    extends LspMessageHandler<void, DartDiagnosticServer> {
  DiagnosticServerHandler(super.server);

  @override
  Method get handlesMessage => CustomMethods.diagnosticServer;

  @override
  LspJsonHandler<void> get jsonHandler => nullJsonHandler;

  @override
  Future<ErrorOr<DartDiagnosticServer>> handle(
    void params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    var diagnosticServer = server.diagnosticServer;
    if (diagnosticServer == null) {
      return error(
        ServerErrorCodes.featureDisabled,
        'The diagnostic server is not available',
      );
    }

    var port = await diagnosticServer.getServerPort();
    return success(DartDiagnosticServer(port: port));
  }
}
