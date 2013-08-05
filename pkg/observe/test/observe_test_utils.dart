// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observe.test.observe_test_utils;

import 'dart:async';
import 'package:observe/observe.dart';
import 'package:unittest/unittest.dart';

import 'package:observe/src/microtask.dart';
export 'package:observe/src/microtask.dart';

// TODO(jmesserly): use matchers when we have a way to compare ChangeRecords.
// For now just use the toString.
expectChanges(actual, expected, {reason}) =>
    expect('$actual', '$expected', reason: reason);

/**
 * This is a special kind of unit [test], that supports
 * calling [performMicrotaskCheckpoint] during the test to pump events
 * that original from observable objects.
 */
observeTest(name, testCase) => test(name, wrapMicrotask(testCase));

/** The [solo_test] version of [observeTest]. */
solo_observeTest(name, testCase) => solo_test(name, wrapMicrotask(testCase));
