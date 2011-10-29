// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple unit test library for running tests on the VM.
 */
#library("unittest");

#source("shared.dart");

_platformInitialize() {
  // Do nothing.
}

_platformDefer(void callback()) {
  new Timer((timer) {
    callback();
  }, 0, false);
}

_platformStartTests() {
  // Do nothing.
}

_platformCompleteTests(int testsPassed, int testsFailed, int testsErrors) {
  // Print each test's result.
  for (final test in _tests) {
    print('${test.result.toUpperCase()}: ${test.description}');

    if (test.message != '') {
      print('  ${test.message}');
    }
  }

  // Show the summary.
  print('');

  if (testsPassed == 0 && testsFailed == 0 && testsErrors == 0) {
    print('No tests found.');
  } else if (testsFailed == 0 && testsErrors == 0) {
    print('All $testsPassed tests passed.');
  } else {
    print('$testsPassed PASSED, $testsFailed FAILED, $testsErrors ERRORS');
  }
}
