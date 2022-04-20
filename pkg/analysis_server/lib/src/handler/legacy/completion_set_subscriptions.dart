// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/domains/completion/available_suggestions.dart';
import 'package:analysis_server/src/handler/legacy/legacy_handler.dart';

/// The handler for the `completion.setSubscriptions` request.
class CompletionSetSubscriptionsHandler extends LegacyHandler {
  /// Initialize a newly created handler to be able to service requests for the
  /// [server].
  CompletionSetSubscriptionsHandler(
      super.server, super.request, super.cancellationToken);

  @override
  Future<void> handle() async {
    var params = CompletionSetSubscriptionsParams.fromRequest(request);

    var subscriptions = server.completionState.subscriptions;
    subscriptions.clear();
    subscriptions.addAll(params.subscriptions);

    var data = server.declarationsTrackerData;
    if (data != null) {
      if (subscriptions.contains(CompletionService.AVAILABLE_SUGGESTION_SETS)) {
        var soFarLibraries = data.startListening((change) {
          server.sendNotification(
            createCompletionAvailableSuggestionsNotification(
              change.changed,
              change.removed,
            ),
          );
        });
        server.sendNotification(
          createCompletionAvailableSuggestionsNotification(
            soFarLibraries,
            [],
          ),
        );
      } else {
        data.stopListening();
      }
    }
    sendResult(CompletionSetSubscriptionsResult());
  }
}
