// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/handler/legacy/server_cancel_request.dart';
import 'package:analysis_server/src/handler/legacy/server_get_version.dart';
import 'package:analysis_server/src/handler/legacy/server_set_subscriptions.dart';
import 'package:analysis_server/src/handler/legacy/server_shutdown.dart';
import 'package:analysis_server/src/utilities/progress.dart';

/// Instances of the class [ServerDomainHandler] implement a [RequestHandler]
/// that handles requests in the server domain.
class ServerDomainHandler implements RequestHandler {
  /// The analysis server that is using this handler to process requests.
  final AnalysisServer server;

  /// Initialize a newly created handler to handle requests for the given
  /// [server].
  ServerDomainHandler(this.server);

  @override
  Response? handleRequest(
      Request request, CancellationToken cancellationToken) {
    try {
      var requestName = request.method;
      if (requestName == SERVER_REQUEST_GET_VERSION) {
        ServerGetVersionHandler(server, request, cancellationToken).handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == SERVER_REQUEST_SET_SUBSCRIPTIONS) {
        ServerSetSubscriptionsHandler(server, request, cancellationToken)
            .handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == SERVER_REQUEST_SHUTDOWN) {
        ServerShutdownHandler(server, request, cancellationToken).handle();
        return Response.DELAYED_RESPONSE;
      } else if (requestName == SERVER_REQUEST_CANCEL_REQUEST) {
        ServerCancelRequestHandler(server, request, cancellationToken).handle();
        return Response.DELAYED_RESPONSE;
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }
}
