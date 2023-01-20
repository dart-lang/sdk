// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';

/// The handler for the `analytics.sendTiming` request.
class AnalyticsSendTimingHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  AnalyticsSendTimingHandler(
      super.server, super.request, super.cancellationToken, super.performance);

  String get _clientId => server.options.clientId ?? 'client';

  @override
  Future<void> handle() async {
    final analytics = server.options.analytics;
    if (analytics == null) {
      sendResult(AnalyticsSendTimingResult());
      return;
    }

    var params = AnalyticsSendTimingParams.fromRequest(request);
    unawaited(
        analytics.sendTiming(params.event, params.millis, category: _clientId));
    sendResult(AnalyticsSendTimingResult());
  }
}
