// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.with_test_environment_test;

import 'dart:async';
import 'package:unittest/unittest.dart';

class TestConfiguration extends SimpleConfiguration {
  final Completer _completer = new Completer();
  List<TestCase> _results;

  TestConfiguration();

  void onSummary(int passed, int failed, int errors, List<TestCase> results,
                 String uncaughtError) {
    super.onSummary(passed, failed, errors, results, uncaughtError);
    _results = results;
  }

  Future get done => _completer.future;

  onDone(success) {
    new Future.sync(() {
      super.onDone(success);
    }).then((_) => _completer.complete(_))
    .catchError((error, stack) => _completer.completeError(error, stack));
  }

  bool checkIfTestRan(String testName) {
    for (final t in _results) {
      if (t.description == testName) {
        return true;
      }
    }
    return false;
  }
}

Future runUnittests(Function callback) {
  var config = new TestConfiguration();
  unittestConfiguration = config;
  callback();

  return config.done;
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

  // Test that we can run both when encapsulating in their own private test
  // environment. Also test that the tests actually running are the ones
  // scheduled in the runTests/runTests1 methods.
  withTestEnvironment(() {
    runUnittests(runTests).whenComplete(() {
      TestConfiguration config = unittestConfiguration;
      expect(config.checkIfTestRan('test'), true);
      expect(config.checkIfTestRan('test1'), false);
    });
  });
  withTestEnvironment(() {
    runUnittests(runTests1).whenComplete(() {
      TestConfiguration config = unittestConfiguration;
      expect(config.checkIfTestRan('test'), false);
      expect(config.checkIfTestRan('test1'), true);
    });
  });

  // Third test that we can run with two nested test environments.
  withTestEnvironment(() {
    runUnittests(runTests);
    withTestEnvironment(() {
      runUnittests(runTests1);
    });
  });
}
