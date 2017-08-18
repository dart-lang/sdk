// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';

/// Instances of the class [AnalyticsDomainHandler] implement a [RequestHandler]
/// that handles requests in the `analytics` domain.
class AnalyticsDomainHandler implements RequestHandler {
  final AnalysisServer server;

  bool enabled = false;

  AnalyticsDomainHandler(this.server);

  // TODO(devoncarew): This implementation is currently mocked out.
  Response handleEnable(Request request) {
    // TODO(devoncarew): Implement.
    AnalyticsEnableParams params =
        new AnalyticsEnableParams.fromRequest(request);
    enabled = params.value;
    return new AnalyticsEnableResult().toResponse(request.id);
  }

  Response handleIsEnabled(Request request) {
    // TODO(devoncarew): Implement.
    return new AnalyticsIsEnabledResult(enabled).toResponse(request.id);
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
    // TODO(devoncarew): Implement.
    return new AnalyticsSendEventResult().toResponse(request.id);
  }

  Response handleSendTiming(Request request) {
    // TODO(devoncarew): Implement.
    return new AnalyticsSendTimingResult().toResponse(request.id);
  }
}
