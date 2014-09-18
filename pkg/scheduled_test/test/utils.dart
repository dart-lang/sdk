// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_utils;

import 'dart:async';

import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/src/utils.dart';
import 'package:scheduled_test/src/mock_clock.dart' as mock_clock;

import 'package:metatest/metatest.dart';

export 'package:scheduled_test/src/utils.dart';

/// Wraps [input] to provide a timeout. If [input] completes before
/// [milliseconds] have passed, then the return value completes in the same way.
/// However, if [milliseconds] pass before [input] has completed, [onTimeout] is
/// run and its result is passed to [input] (with chaining, if it returns a
/// [Future]).
///
/// Note that timing out will not cancel the asynchronous operation behind
/// [input].
Future timeout(Future input, int milliseconds, onTimeout()) {
  var completer = new Completer();
  var timer = new Timer(new Duration(milliseconds: milliseconds), () {
    chainToCompleter(syncFuture(onTimeout), completer);
  });
  input.then((value) {
    if (completer.isCompleted) return;
    timer.cancel();
    completer.complete(value);
  }).catchError((error, stackTrace) {
    if (completer.isCompleted) return;
    timer.cancel();
    completer.completeError(error, stackTrace);
  });
  return completer.future;
}

/// Returns a [Future] that will complete in [milliseconds].
Future sleep(int milliseconds) {
  var completer = new Completer();
  mock_clock.newTimer(new Duration(milliseconds: milliseconds), () {
    completer.complete();
  });
  return completer.future;
}

/// Sets up a timeout for every metatest in this file.
void setUpTimeout() {
  metaSetUp(() {
    // TODO(nweiz): We used to only increase the timeout to 10s for the Windows
    // bots, but the Linux and Mac bots have started taking upwards of 5s when
    // running pumpEventQueue, so we're increasing the timeout across the board
    // (see issue 9248).
    currentSchedule.timeout = new Duration(seconds: 10);
  });
}

/// Creates a metatest with [body] and asserts that it passes.
///
/// This is like [expectTestsPass], but the [test] is set up automatically.
void expectTestPasses(String description, body()) =>
  expectTestsPass(description, () => test('test', body));

/// Creates a metatest that runs [testBody], captures its schedule errors, and
/// passes them to [validator].
///
/// [testBody] is expected to produce an error, while [validator] is expected to
/// produce none.
void expectTestFails(String description, Future testBody(),
    void validator(List<ScheduleError> errors)) {
  expectTestsPass(description, () {
    var errors;
    test('test body', () {
      currentSchedule.onException.schedule(() {
        errors = currentSchedule.errors;
      });

      testBody();
    });

    test('validate errors', () {
      expect(errors, everyElement(new isInstanceOf<ScheduleError>()));
      validator(errors);
    });
  }, passing: ['validate errors']);
}
