// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library substitute_future;

import 'dart:async';

/// A wrapper for [Future] that allows other [Future]s to be substituted in as
/// the wrapped [Future]. This is used for injecting timeout errors into
/// long-running [Future]s.
class SubstituteFuture<T> implements Future<T> {
  /// The wrapped [Future].
  Future<T> _inner;

  /// The completer that corresponds to [this]'s result.
  final Completer<T> _completer = new Completer<T>();

  /// Whether or not [this] has been completed yet.
  bool _complete = false;

  SubstituteFuture(Future wrapped) {
    substitute(wrapped);
  }

  Stream<T> asStream() => _completer.future.asStream();
  Future catchError(Function onError, {bool test(error)}) =>
    _completer.future.catchError(onError, test: test);
  Future then(onValue(T value), {Function onError}) =>
    _completer.future.then(onValue, onError: onError);
  Future<T> whenComplete(action()) => _completer.future.whenComplete(action);
  Future timeout(Duration timeLimit, {void onTimeout()}) =>
      _completer.future.timeout(timeLimit, onTimeout: onTimeout);

  /// Substitutes [newFuture] for the currently wrapped [Future], which is
  /// returned.
  Future<T> substitute(Future<T> newFuture) {
    if (_complete) {
      throw new StateError("You may not call substitute on a SubstituteFuture "
          "that's already complete.");
    }

    var oldFuture = _inner;
    _inner = newFuture;
    _inner.then((value) {
      if (_inner != newFuture) return;
      _completer.complete(value);
      _complete = true;
    }).catchError((error, stackTrace) {
      if (_inner != newFuture) return;
      _completer.completeError(error, stackTrace);
      _complete = true;
    });
    return oldFuture;
  }
}
