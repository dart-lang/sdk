// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/utilities/progress.dart';

/// Instances of the class [ServerDomainHandler] implement a [RequestHandler]
/// that handles requests in the server domain.
class ServerDomainHandler implements RequestHandler {
  /// The analysis server that is using this handler to process requests.
  final AnalysisServer server;

  /// Initialize a newly created handler to handle requests for the given
  /// [server].
  ServerDomainHandler(this.server);

  Response cancelRequest(Request request) {
    final id = ServerCancelRequestParams.fromRequest(request).id;
    server.cancelRequest(id);

    return ServerCancelRequestResult().toResponse(request.id);
  }

  /// Return the version number of the analysis server.
  Response getVersion(Request request) {
    return ServerGetVersionResult(
      server.options.reportProtocolVersion ?? PROTOCOL_VERSION,
    ).toResponse(request.id);
  }

  @override
  Response? handleRequest(
      Request request, CancellationToken cancellationToken) {
    try {
      var requestName = request.method;
      if (requestName == SERVER_REQUEST_GET_VERSION) {
        return getVersion(request);
      } else if (requestName == SERVER_REQUEST_SET_SUBSCRIPTIONS) {
        return setSubscriptions(request);
      } else if (requestName == SERVER_REQUEST_SHUTDOWN) {
        shutdown(request);
        return Response.DELAYED_RESPONSE;
      } else if (requestName == SERVER_REQUEST_CANCEL_REQUEST) {
        return cancelRequest(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  /// Subscribe for services.
  ///
  /// All previous subscriptions are replaced by the given set of subscriptions.
  Response setSubscriptions(Request request) {
    server.serverServices =
        ServerSetSubscriptionsParams.fromRequest(request).subscriptions.toSet();

    server.requestStatistics?.isNotificationSubscribed =
        server.serverServices.contains(ServerService.LOG);

    return ServerSetSubscriptionsResult().toResponse(request.id);
  }

  /// Cleanly shutdown the analysis server.
  Future<void> shutdown(Request request) async {
    await server.shutdown();
    var response = ServerShutdownResult().toResponse(request.id);
    server.sendResponse(response);
  }
}
