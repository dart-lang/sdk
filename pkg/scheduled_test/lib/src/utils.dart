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
Future pumpEventQueue([int times=200]) {
  if (times == 0) return new Future.immediate(null);
  return new Future.immediate(null).then((_) => pumpEventQueue(times - 1));
}
