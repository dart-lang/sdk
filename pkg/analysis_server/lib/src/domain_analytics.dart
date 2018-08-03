// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:telemetry/telemetry.dart';

/// Instances of the class [AnalyticsDomainHandler] implement a [RequestHandler]
/// that handles requests in the `analytics` domain.
class AnalyticsDomainHandler implements RequestHandler {
  final AnalysisServer server;

  Analytics get analytics => server.analytics;

  AnalyticsDomainHandler(this.server);

  Response handleEnable(Request request) {
    AnalyticsEnableParams params =
        new AnalyticsEnableParams.fromRequest(request);
    if (analytics != null) {
      analytics.enabled = params.value;
    }
    return new AnalyticsEnableResult().toResponse(request.id);
  }

  Response handleIsEnabled(Request request) {
    return new AnalyticsIsEnabledResult(analytics?.enabled ?? false)
        .toResponse(request.id);
  }

  @override
  Response handleRequest(Request request) {
    String requestName = request.method;

    if (requestName == ANALYTICS_REQUEST_IS_ENABLED) {
      return handleIsEnabled(request);
    } else if (requestName == ANALYTICS_REQUEST_ENABLE) {
      return handleEnable(request);
    } else if (requestName == ANALYTICS_REQUEST_SEND_EVENT) {
      return handleSendEvent(request);
    } else if (requestName == ANALYTICS_REQUEST_SEND_TIMING) {
      return handleSendTiming(request);
    }

    return null;
  }

  Response handleSendEvent(Request request) {
    if (analytics == null) {
      return new AnalyticsSendEventResult().toResponse(request.id);
    }

    AnalyticsSendEventParams params =
        new AnalyticsSendEventParams.fromRequest(request);
    analytics.sendEvent(_clientId, params.action);
    return new AnalyticsSendEventResult().toResponse(request.id);
  }

  Response handleSendTiming(Request request) {
    if (analytics == null) {
      return new AnalyticsSendTimingResult().toResponse(request.id);
    }

    AnalyticsSendTimingParams params =
        new AnalyticsSendTimingParams.fromRequest(request);
    analytics.sendTiming(params.event, params.millis, category: _clientId);
    return new AnalyticsSendTimingResult().toResponse(request.id);
  }

  String get _clientId => server.options.clientId ?? 'client';
}
