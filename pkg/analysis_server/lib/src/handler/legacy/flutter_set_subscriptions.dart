// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';

/// The handler for the `flutter.setSubscriptions` request.
class FlutterSetSubscriptionsHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  FlutterSetSubscriptionsHandler(
      super.server, super.request, super.cancellationToken);

  @override
  Future<void> handle() async {
    var params = FlutterSetSubscriptionsParams.fromRequest(request);
    var subMap =
        mapMap<FlutterService, List<String>, FlutterService, Set<String>>(
            params.subscriptions,
            valueCallback: (List<String> subscriptions) =>
                subscriptions.toSet());
    server.setFlutterSubscriptions(subMap);
    sendResult(FlutterSetSubscriptionsResult());
  }
}
