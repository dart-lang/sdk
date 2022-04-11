// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/handler/legacy/analytics_enable.dart';
import 'package:analysis_server/src/handler/legacy/analytics_is_enabled.dart';
import 'package:analysis_server/src/handler/legacy/analytics_send_event.dart';
import 'package:analysis_server/src/handler/legacy/analytics_send_timing.dart';
import 'package:analysis_server/src/utilities/progress.dart';

/// Instances of the class [AnalyticsDomainHandler] implement a [RequestHandler]
/// that handles requests in the `analytics` domain.
class AnalyticsDomainHandler implements RequestHandler {
  final AnalysisServer server;

  AnalyticsDomainHandler(this.server);

  @override
  Response? handleRequest(
      Request request, CancellationToken cancellationToken) {
    var requestName = request.method;

    if (requestName == ANALYTICS_REQUEST_IS_ENABLED) {
      AnalyticsIsEnabledHandler(server, request, cancellationToken).handle();
      return Response.DELAYED_RESPONSE;
    } else if (requestName == ANALYTICS_REQUEST_ENABLE) {
      AnalyticsEnableHandler(server, request, cancellationToken).handle();
      return Response.DELAYED_RESPONSE;
    } else if (requestName == ANALYTICS_REQUEST_SEND_EVENT) {
      AnalyticsSendEventHandler(server, request, cancellationToken).handle();
      return Response.DELAYED_RESPONSE;
    } else if (requestName == ANALYTICS_REQUEST_SEND_TIMING) {
      AnalyticsSendTimingHandler(server, request, cancellationToken).handle();
      return Response.DELAYED_RESPONSE;
    }
    return null;
  }
}
