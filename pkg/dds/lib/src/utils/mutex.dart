// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

/// Used to protect global state accessed in blocks containing calls to
/// asynchronous methods.
class Mutex {
  /// Executes a block of code containing asynchronous calls atomically.
  ///
  /// If no other asynchronous context is currently executing within
  /// [criticalSection], it will immediately be called. Otherwise, the caller
  /// will be suspended and entered into a queue to be resumed once the lock is
  /// released.
  Future<T> runGuarded<T>(FutureOr<T> Function() criticalSection) async {
    try {
      await _acquireLock();
      return await criticalSection();
    } finally {
      _releaseLock();
    }
  }

  Future<void> _acquireLock() async {
    if (!_locked) {
      _locked = true;
      return;
    }
    final request = Completer<void>();
    _outstandingRequests.add(request);
    await request.future;
  }

  void _releaseLock() {
    _locked = false;
    if (_outstandingRequests.isNotEmpty) {
      final request = _outstandingRequests.removeFirst();
      request.complete();
    }
  }

  bool _locked = false;
  final _outstandingRequests = Queue<Completer<void>>();
}
