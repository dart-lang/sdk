// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple unit test entrypoint for running tests on node compiled with frog.
 */
#library("unittest");

#import('../../../frog/lib/node/node.dart');

#source("shared.dart");

_platformInitialize() {
  // Do nothing.
}

_platformDefer(void callback()) {
  setTimeout(callback, 0);
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
