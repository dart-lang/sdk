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

/// Returns a [Future] that completes after pumping the event queue [times]
/// times. By default, this should pump the event queue enough times to allow
/// any code to run, as long as it's not waiting on some external event.
Future pumpEventQueue([int times=20]) {
  if (times == 0) return new Future.immediate(null);
  return new Future.immediate(null).then((_) => pumpEventQueue(times - 1));
}

/// Returns whether [iterable1] has the same elements in the same order as
/// [iterable2]. The elements are compared using `==`.
bool orderedIterableEquals(Iterable iterable1, Iterable iterable2) {
  var iter1 = iterable1.iterator;
  var iter2 = iterable2.iterator;

  while (true) {
    var hasNext1 = iter1.moveNext();
    var hasNext2 = iter2.moveNext();
    if (hasNext1 != hasNext2) return false;
    if (!hasNext1) return true;
    if (iter1.current != iter2.current) return false;
  }
}

// TODO(nweiz): remove this when issue 8731 is fixed.
/// Returns a [Stream] that will immediately emit [error] and then close.
Stream errorStream(error) => new Future.immediateError(error).asStream();

/// Returns a buffered stream that will emit the same values as the stream
/// returned by [future] once [future] completes. If [future] completes to an
/// error, the return value will emit that error and then close.
Stream futureStream(Future<Stream> future) {
  var controller = new StreamController();
  future.then((stream) {
    stream.listen(
        controller.add,
        onError: (error) => controller.signalError(error),
        onDone: controller.close);
  }).catchError((e) {
    controller.signalError(e);
    controller.close();
  });
  return controller.stream;
}
