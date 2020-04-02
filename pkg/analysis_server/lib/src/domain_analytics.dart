// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
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

  AnalyticsDomainHandler(this.server);

  Analytics get analytics => server.analytics;

  String get _clientId => server.options.clientId ?? 'client';

  Response handleEnable(Request request) {
    var params = AnalyticsEnableParams.fromRequest(request);
    if (analytics != null) {
      analytics.enabled = params.value;
    }
    return AnalyticsEnableResult().toResponse(request.id);
  }

  Response handleIsEnabled(Request request) {
    return AnalyticsIsEnabledResult(analytics?.enabled ?? false)
        .toResponse(request.id);
  }

  @override
  Response handleRequest(Request request) {
    var requestName = request.method;

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
      return AnalyticsSendEventResult().toResponse(request.id);
    }

    var params = AnalyticsSendEventParams.fromRequest(request);
    analytics.sendEvent(_clientId, params.action);
    return AnalyticsSendEventResult().toResponse(request.id);
  }

  Response handleSendTiming(Request request) {
    if (analytics == null) {
      return AnalyticsSendTimingResult().toResponse(request.id);
    }

    var params = AnalyticsSendTimingParams.fromRequest(request);
    analytics.sendTiming(params.event, params.millis, category: _clientId);
    return AnalyticsSendTimingResult().toResponse(request.id);
  }
}
