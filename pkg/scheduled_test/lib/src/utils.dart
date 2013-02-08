// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils;

import 'dart:async';

/// Configures [future] so that its result (success or exception) is passed on
/// to [completer].
void chainToCompleter(Future future, Completer completer) {
  future.then((value) => completer.complete(value),
      onError: (e) => completer.completeError(e.error, e.stackTrace));
}

/// Prepends each line in [text] with [prefix].
String prefixLines(String text, {String prefix: '| '}) =>
  text.split('\n').map((line) => '$prefix$line').join('\n');

/// Returns a [Future] that completes in [milliseconds].
Future sleep(int milliseconds) {
  var completer = new Completer();
  new Timer(milliseconds, (_) => completer.complete());
  return completer.future;
}

/// Wraps [input] to provide a timeout. If [input] completes before
/// [milliseconds] have passed, then the return value completes in the same way.
/// However, if [milliseconds] pass before [input] has completed, [onTimeout] is
/// run and its result is passed to [input] (with chaining, if it returns a
/// [Future]).
///
/// Note that timing out will not cancel the asynchronous operation behind
/// [input].
Future timeout(Future input, int milliseconds, onTimeout()) {
  bool completed = false;
  var completer = new Completer();
  var timer = new Timer(milliseconds, (_) {
    completed = true;
    chainToCompleter(new Future.immediate(null).then((_) => onTimeout()),
        completer);
  });
  input.then((value) {
    if (completed) return;
    timer.cancel();
    completer.complete(value);
  }).catchError((e) {
    if (completed) return;
    timer.cancel();
    completer.completeError(e.error, e.stackTrace);
  });
  return completer.future;
}
