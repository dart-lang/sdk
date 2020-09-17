// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/// This library helps run parallel thread-like closures asynchronously.
/// Borrowed from dartdoc:src/io_utils.dart.

Future<T> retryClosure<T>(Future<T> Function() closure,
    {Duration baseInterval = const Duration(milliseconds: 200),
    double factor = 2,
    int retries = 5}) async {
  Future<T> handleError(Object _) async {
    return await Future.delayed(
        baseInterval,
        () => retryClosure(closure,
            baseInterval: baseInterval * factor,
            factor: factor,
            retries: retries - 1));
  }

  if (retries > 0) {
    return await Future.sync(closure).catchError(handleError);
  } else {
    return closure();
  }
}

// TODO(jcollins-g): like SubprocessLauncher, merge with io_utils in dartdoc
// before cut-and-paste gets out of hand.
class MultiFutureTracker {
  /// Maximum number of simultaneously incomplete [Future]s.
  final int parallel;

  final Set<Future<void>> _trackedFutures = <Future<void>>{};

  MultiFutureTracker(this.parallel);

  /// Wait until fewer or equal to this many Futures are outstanding.
  Future<void> _waitUntil(int max) async {
    assert(_trackedFutures.length <= parallel);
    while (_trackedFutures.length > max) {
      await Future.any(_trackedFutures);
    }
  }

  /// Generates a [Future] from the given closure and adds it to the queue,
  /// once the queue is sufficiently empty.  The returned future completes
  /// when the generated [Future] has been added to the queue.
  Future<void> addFutureFromClosure(Future<void> Function() closure) async {
    assert(_trackedFutures.length <= parallel);
    // Can't use _waitUntil because we might not return directly to this
    // invocation of addFutureFromClosure.
    while (_trackedFutures.length > parallel - 1) {
      await Future.any(_trackedFutures);
    }
    Future<void> future = closure();
    _trackedFutures.add(future);
    future.then((f) => _trackedFutures.remove(future));
  }

  /// Generates a [Future] from the given closure and adds it to the queue,
  /// once the queue is sufficiently empty.  Completes when the generated
  /// closure completes.
  Future<T> runFutureFromClosure<T>(FutureOr<T> Function() closure) async {
    Completer<T> futureComplete = Completer();
    await addFutureFromClosure(() async {
      futureComplete.complete(await closure());
    });
    return futureComplete.future;
  }

  /// Wait until all futures added so far have completed.
  Future<void> wait() => _waitUntil(0);
}
