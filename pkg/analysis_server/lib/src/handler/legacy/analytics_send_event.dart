// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/utilities/progress.dart';

/// The handler for the `analytics.sendEvent` request.
class AnalyticsSendEventHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  AnalyticsSendEventHandler(AnalysisServer server, Request request,
      CancellationToken cancellationToken)
      : super(server, request, cancellationToken);

  String get _clientId => server.options.clientId ?? 'client';

  @override
  Future<void> handle() async {
    final analytics = server.analytics;
    if (analytics == null) {
      sendResult(AnalyticsSendEventResult());
      return;
    }

    var params = AnalyticsSendEventParams.fromRequest(request);
    analytics.sendEvent(_clientId, params.action);
    sendResult(AnalyticsSendEventResult());
  }
}
