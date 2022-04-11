// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/plugin/request_converter.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analysis_server/src/utilities/progress.dart';

/// The handler for the `analysis.setSubscriptions` request.
class AnalysisSetSubscriptionsHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  AnalysisSetSubscriptionsHandler(AnalysisServer server, Request request,
      CancellationToken cancellationToken)
      : super(server, request, cancellationToken);

  @override
  Future<void> handle() async {
    var params = AnalysisSetSubscriptionsParams.fromRequest(request);

    for (var fileList in params.subscriptions.values) {
      for (var file in fileList) {
        if (!server.isAbsoluteAndNormalized(file)) {
          sendResponse(Response.invalidFilePathFormat(request, file));
        }
      }
    }

    // parse subscriptions
    var subMap =
        mapMap<AnalysisService, List<String>, AnalysisService, Set<String>>(
            params.subscriptions,
            valueCallback: (List<String> subscriptions) =>
                subscriptions.toSet());
    server.setAnalysisSubscriptions(subMap);
    //
    // Forward the request to the plugins.
    //
    var converter = RequestConverter();
    server.pluginManager.setAnalysisSetSubscriptionsParams(
        converter.convertAnalysisSetSubscriptionsParams(params));
    //
    // Send the response.
    //
    sendResult(AnalysisSetSubscriptionsResult());
  }
}
