// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.with_test_environment_test;

import 'package:unittest/unittest.dart';

void runUnittests(Function callback) {
  unittestConfiguration = new SimpleConfiguration();
  callback();
}

void runTests() {
  test('test', () => expect(2 + 3, equals(5)));
}

void runTests1() {
  test('test1', () => expect(4 + 3, equals(7)));
}

// Test that we can run two different sets of tests in the same run using the
// withTestEnvironment method.
void main() {
  // First check that we cannot call runUnittests twice in a row without it
  // throwing a StateError due to the unittestConfiguration being set globally
  // in the first call.
  try {
    runUnittests(runTests);
    runUnittests(runTests1);
    throw 'Expected this to be unreachable since 2nd run above should throw';
  } on StateError catch (error) {
    // expected, silently ignore.
  }

  // Second test that we can run both when encapsulating in their own private
  // test environment.
  withTestEnvironment(() => runUnittests(runTests));
  withTestEnvironment(() => runUnittests(runTests1));

  // Third test that we can run with two nested test environments.
  withTestEnvironment(() {
    runUnittests(runTests);
    withTestEnvironment(() {
      runUnittests(runTests1);
    });
  });
}
