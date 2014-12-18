// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library domain.server;

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';

/**
 * Instances of the class [ServerDomainHandler] implement a [RequestHandler]
 * that handles requests in the server domain.
 */
class ServerDomainHandler implements RequestHandler {
  /**
   * The analysis server that is using this handler to process requests.
   */
  final AnalysisServer server;

  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  ServerDomainHandler(this.server);

  /**
   * Return the version number of the analysis server.
   */
  Response getVersion(Request request) {
    return new ServerGetVersionResult('0.0.1').toResponse(request.id);
  }

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == SERVER_GET_VERSION) {
        return getVersion(request);
      } else if (requestName == SERVER_SET_SUBSCRIPTIONS) {
        return setSubscriptions(request);
      } else if (requestName == SERVER_SHUTDOWN) {
        return shutdown(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  /**
   * Subscribe for services.
   *
   * All previous subscriptions are replaced by the given set of subscriptions.
   */
  Response setSubscriptions(Request request) {
    server.serverServices =
        new ServerSetSubscriptionsParams.fromRequest(request).subscriptions.toSet();
    return new ServerSetSubscriptionsResult().toResponse(request.id);
  }

  /**
   * Cleanly shutdown the analysis server.
   */
  Response shutdown(Request request) {
    server.shutdown();
    Response response = new ServerShutdownResult().toResponse(request.id);
    return response;
  }
}
