// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.cancelable_future;

import 'dart:async';

/// A wrapper for [Future] that can be cancelled.
///
/// When this is cancelled, that means it won't complete either successfully or
/// with an error, regardless of whether the wrapped Future completes.
/// Cancelling this won't stop whatever code is feeding the wrapped future from
/// running.
class CancelableFuture<T> implements Future<T> {
  bool _canceled = false;
  final _completer = new Completer<T>();

  CancelableFuture(Future<T> inner) {
    inner.then((result) {
      if (_canceled) return;
      _completer.complete(result);
    }).catchError((error, stackTrace) {
      if (_canceled) return;
      _completer.completeError(error, stackTrace);
    });
  }

  Stream<T> asStream() => _completer.future.asStream();
  Future catchError(Function onError, {bool test(error)}) =>
    _completer.future.catchError(onError, test: test);
  Future then(onValue(T value), {Function onError}) =>
    _completer.future.then(onValue, onError: onError);
  Future<T> whenComplete(action()) => _completer.future.whenComplete(action);
  Future timeout(Duration timeLimit, {void onTimeout()}) =>
    _completer.future.timeout(timeLimit, onTimeout: onTimeout);
  /// Cancels this future.
  void cancel() {
    _canceled = true;
  }
}
