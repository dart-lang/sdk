// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple unit test library for running tests on the VM.
 */
#library('unittest');

#import('dart:io');
#source('shared.dart');

_platformInitialize() {
  // Do nothing.
}

_platformDefer(void callback()) {
  new Timer(0, (timer) {
    callback();
  });
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

  var success = false;
  if (testsPassed == 0 && testsFailed == 0 && testsErrors == 0) {
    print('No tests found.');
    // This is considered a failure too: if this happens you probably have a
    // bug in your unit tests.
  } else if (testsFailed == 0 && testsErrors == 0) {
    print('All $testsPassed tests passed.');
    success = true;
  } else {
    print('$testsPassed PASSED, $testsFailed FAILED, $testsErrors ERRORS');
  }

  // A non-zero exit code is used by the test infrastructure to detect failure.
  if (!success) exit(1);
}
