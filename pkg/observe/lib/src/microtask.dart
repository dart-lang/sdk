// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * *Warning*: this library is **internal**, and APIs are subject to change.
 *
 * Wraps a callback using [wrapMicrotask] and provides the ability to pump all
 * observable objects and [runAsync] calls via [performMicrotaskCheckpoint].
 */
library observe.src.microtask;

import 'dart:async' show Completer, runZonedExperimental;
import 'package:observe/observe.dart' show Observable;

// TODO(jmesserly): remove "microtask" from these names and instead import
// the library "as microtask"?

/**
 * This change pumps events relevant to observers and data-binding tests.
 * This must be used inside an [observeTest].
 *
 * Executes all pending [runAsync] calls on the event loop, as well as
 * performing [Observable.dirtyCheck], until there are no more pending events.
 * It will always dirty check at least once.
 */
void performMicrotaskCheckpoint() {
  Observable.dirtyCheck();

  while (_pending.length > 0) {
    var pending = _pending;
    _pending = [];

    for (var callback in pending) {
      try {
        callback();
      } catch (e, s) {
        new Completer().completeError(e, s);
      }
    }

    Observable.dirtyCheck();
  }
}

List<Function> _pending = [];

/**
 * Wraps the [testCase] in a zone that supports [performMicrotaskCheckpoint],
 * and returns the test case.
 */
wrapMicrotask(testCase()) {
  return () {
    return runZonedExperimental(() {
      try {
        return testCase();
      } finally {
        performMicrotaskCheckpoint();
      }
    }, onRunAsync: (callback) => _pending.add(callback));
  };
}
