// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library value_future;

import 'dart:async';

/// A [Future] wrapper that provides synchronous access to the value of the
/// wrapped [Future] once it's completed.
class ValueFuture<T> implements Future<T> {
  /// The wrapped [Future].
  Future<T> _future;

  /// The [value] of the wrapped [Future], if it's completed succesfully. If it
  /// hasn't completed yet or has completed with an error, this will be `null`.
  T get value => _value;
  T _value;

  /// Whether the wrapped [Future] has completed successfully.
  bool get hasValue => _hasValue;
  var _hasValue = false;

  ValueFuture(Future<T> future) {
    _future = future.then((value) {
      _value = value;
      _hasValue = true;
      return value;
    });
  }

  Stream<T> asStream() => _future.asStream();
  Future catchError(onError(Object error), {bool test(error)}) =>
    _future.catchError(onError, test: test);
  Future then(onValue(T value), {onError(Object error)}) =>
    _future.then(onValue, onError: onError);
  Future<T> whenComplete(action()) => _future.whenComplete(action);
}
