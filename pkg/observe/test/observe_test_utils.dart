// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe.test.observe_test_utils;

import 'dart:async';
import 'package:observe/observe.dart';
import 'package:unittest/unittest.dart';

// TODO(jmesserly): use matchers when we have a way to compare ChangeRecords.
// For now just use the toString.
expectChanges(actual, expected, {reason}) =>
    expect('$actual', '$expected', reason: reason);

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
wrapMicrotask(void testCase()) {
  return () {
    runZonedExperimental(() {
      try {
        testCase();
      } finally {
        performMicrotaskCheckpoint();
      }
    }, onRunAsync: (callback) => _pending.add(callback));
  };
}

/**
 * This is a special kind of unit [test], that supports
 * calling [performMicrotaskCheckpoint] during the test to pump events
 * that original from observable objects.
 */
observeTest(name, testCase) => test(name, wrapMicrotask(testCase));

/** The [solo_test] version of [observeTest]. */
solo_observeTest(name, testCase) => solo_test(name, wrapMicrotask(testCase));
