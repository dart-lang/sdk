// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';

import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_abstract.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analysis_server/src/protocol_server.dart';

/**
 * A [RequestHandler] that handles requests in the `flutter` domain.
 */
class FlutterDomainHandler extends AbstractRequestHandler {
  /**
   * Initialize a newly created handler to handle requests for the given [server].
   */
  FlutterDomainHandler(AnalysisServer server) : super(server);

  @override
  Response handleRequest(Request request) {
    try {
      String requestName = request.method;
      if (requestName == FLUTTER_REQUEST_SET_SUBSCRIPTIONS) {
        return setSubscriptions(request);
      }
    } on RequestFailure catch (exception) {
      return exception.response;
    }
    return null;
  }

  /**
   * Implement the 'flutter.setSubscriptions' request.
   */
  Response setSubscriptions(Request request) {
    var params = new FlutterSetSubscriptionsParams.fromRequest(request);
    Map<FlutterService, Set<String>> subMap = mapMap(params.subscriptions,
        valueCallback: (List<String> subscriptions) => subscriptions.toSet());
    server.setFlutterSubscriptions(subMap);
    return new FlutterSetSubscriptionsResult().toResponse(request.id);
  }
}
