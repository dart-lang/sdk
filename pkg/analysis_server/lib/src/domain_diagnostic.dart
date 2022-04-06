// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/handler/legacy/diagnostic_get_diagnostics.dart';
import 'package:analysis_server/src/handler/legacy/diagnostic_get_server_port.dart';
import 'package:analyzer/src/utilities/cancellation.dart';

/// Instances of the class [DiagnosticDomainHandler] implement a
/// [RequestHandler] that handles requests in the `diagnostic` domain.
class DiagnosticDomainHandler implements RequestHandler {
  /// The analysis server that is using this handler to process requests.
  final AnalysisServer server;

  /// Initialize a newly created handler to handle requests for the given
  /// [server].
  DiagnosticDomainHandler(this.server);

  @override
  Response? handleRequest(
      Request request, CancellationToken cancellationToken) {
    try {
      var requestName = request.method;
      if (requestName == DIAGNOSTIC_REQUEST_GET_DIAGNOSTICS) {
        DiagnosticGetDiagnosticsHandler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == DIAGNOSTIC_REQUEST_GET_SERVER_PORT) {
        DiagnosticGetServerPortHandler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }
}
