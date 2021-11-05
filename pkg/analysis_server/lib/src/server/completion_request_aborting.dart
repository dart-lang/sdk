// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:meta/meta.dart';

class CompletionRequestAborting {
  /// IDs of requests to abort on another completion request.
  final Set<String> _pendingRequests = {};

  /// IDs from [_pendingRequests] that we decided to abort.
  final Set<String> _abortedRequests = {};

  /// The function to be invoked when requests are aborted.
  @visibleForTesting
  void Function(Set<String> id)? onAbort;

  /// Abort requests that were pending.
  void abort() {
    onAbort?.call(_pendingRequests);
    _abortedRequests.addAll(_pendingRequests);
  }

  /// Return `true` if the [request] should be aborted because there is
  /// another request in the queue, so [abort] was invoked while pumping the
  /// event queue.
  Future<bool> waitIfAborted(Request request) async {
    // Mark the current request as pending.
    var id = request.id;
    _pendingRequests.add(id);

    // Wait for more requests to arrive and abort this one.
    await _pumpEventQueue(64);

    // We are done waiting.
    _pendingRequests.remove(id);

    // See it the request was aborted.
    return _abortedRequests.remove(id);
  }

  static Future<void> _pumpEventQueue(int times) {
    if (times == 0) return Future.value();
    return Future(() => _pumpEventQueue(times - 1));
  }
}
