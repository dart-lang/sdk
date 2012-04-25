// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A library for writing dart unit tests.
 *
 * ##Concepts##
 *
 *  * Tests: Tests are specified via the top-level function [test], they can be
 *    organized together using [group].
 *  * Checks: Test expectations can be specified via [expect] (see methods in
 *    [Expectation]), [expectThrow], or using assertions with the [Expect]
 *    class.
 *  * Configuration: The framework can be adapted by calling [configure] with a
 *    [Configuration].  Common configurations can be found in this package
 *    under: 'dom\_config.dart', 'html\_config.dart', and 'vm\_config.dart'.
 *
 * ##Examples##
 *
 * A trivial test:
 *
 *     #import('path-to-dart/lib/unittest/unitest.dart');
 *     main() {
 *       test('this is a test', () {
 *         int x = 2 + 3;
 *         expect(x).equals(5);
 *       });
 *     }
 *
 * Multiple tests:
 *
 *     #import('path-to-dart/lib/unittest/unitest.dart');
 *     main() {
 *       test('this is a test', () {
 *         int x = 2 + 3;
 *         expect(x).equals(5);
 *       });
 *       test('this is another test', () {
 *         int x = 2 + 3;
 *         expect(x).equals(5);
 *       });
 *     }
 *
 * Multiple tests, grouped by category:
 *
 *     #import('path-to-dart/lib/unittest/unitest.dart');
 *     main() {
 *       group('group A', () {
 *         test('test A.1', () {
 *           int x = 2 + 3;
 *           expect(x).equals(5);
 *         });
 *         test('test A.2', () {
 *           int x = 2 + 3;
 *           expect(x).equals(5);
 *         });
 *       });
 *       group('group B', () {
 *         test('this B.1', () {
 *           int x = 2 + 3;
 *           expect(x).equals(5);
 *         });
 *       });
 *     }
 *
 * Asynchronous tests: under the current API (soon to be deprecated):
 *
 *     #import('path-to-dart/lib/unittest/unitest.dart');
 *     #import('dart:dom');
 *     main() {
 *       // use [asyncTest], indicate the expected number of callbacks:
 *       asyncTest('this is a test', 1, () {
 *         window.setTimeout(() {
 *           int x = 2 + 3;
 *           expect(x).equals(5);
 *           // invoke [callbackDone] at the end of the callback.
 *           callbackDone();
 *         }, 0);
 *       });
 *     }
 *
 * We plan to replace this with a different API, one API we are considering is:
 *
 *     #import('path-to-dart/lib/unittest/unitest.dart');
 *     #import('dart:dom');
 *     main() {
 *       test('this is a test', () {
 *         // wrap the callback of an asynchronous call with [later]
 *         window.setTimeout(later(() {
 *           int x = 2 + 3;
 *           expect(x).equals(5);
 *         }), 0);
 *       });
 *     }
 */
#library('unittest');

#import('dart:isolate');

#source('config.dart');
#source('expectation.dart');
#source('test_case.dart');

/** [Configuration] used by the unittest library. */
Configuration _config = null;

/** Set the [Configuration] used by the unittest library. */
void configure(Configuration config) {
  _config = config;
}

/**
 * Description text of the current test group. If multiple groups are nested,
 * this will contain all of their text concatenated.
 */
String _currentGroup = '';

/** Tests executed in this suite. */
List<TestCase> _tests;

/**
 * Callback used to run tests. Entrypoints can replace this with their own
 * if they want.
 */
Function _testRunner;

/** Current test being executed. */
int _currentTest = 0;

/** Total number of callbacks that have been executed in the current test. */
int _callbacksCalled = 0;

final _UNINITIALIZED = 0;
final _READY         = 1;
final _RUNNING_TEST  = 2;

/**
 * Whether an undetected error occurred while running the last test. These
 * errors are commonly caused by DOM callbacks that were not guarded in a
 * try-catch block.
 */
final _UNCAUGHT_ERROR = 3;

int _state = _UNINITIALIZED;

final _PASS  = 'pass';
final _FAIL  = 'fail';
final _ERROR = 'error';

/** Creates an expectation for the given value. */
Expectation expect(value) => new Expectation(value);

/** Evaluates the given function and validates that it throws an exception. */
void expectThrow(function) {
  bool threw = false;
  try {
    function();
  } catch (var e) {
    threw = true;
  }
  Expect.equals(true, threw, 'Expected exception but none was thrown.');
}

/**
 * Creates a new test case with the given description and body. The
 * description will include the descriptions of any surrounding group()
 * calls.
 */
void test(String spec, TestFunction body) {
  _ensureInitialized();

  _tests.add(new TestCase(_tests.length + 1, _fullSpec(spec), body, 0));
}

/**
 * Creates a new async test case with the given description and body. The
 * description will include the descriptions of any surrounding group()
 * calls.
 */
// TODO(sigmund): deprecate this API
void asyncTest(String spec, int callbacks, TestFunction body) {
  _ensureInitialized();

  final testCase = new TestCase(
      _tests.length + 1, _fullSpec(spec), body, callbacks);
  _tests.add(testCase);

  if (callbacks < 1) {
    testCase.error(
        'Async tests must wait for at least one callback ', '');
  }
}

/**
 * Indicate to the unittest framework that a 0-argument callback is expected.
 *
 * The framework will wait for the callback to run before it continues with the
 * following test. The callback must excute once and only once. Using [later]
 * will also ensure that errors that occur within the callback are tracked and
 * reported by the unittest framework.
 */
// TODO(sigmund): expose this functionality
Function _later0(Function callback) {
  Expect.isTrue(_currentTest < _tests.length);
  var testCase = _tests[_currentTest];
  testCase.callbacks++;
  return () {
    _guard(() => callback(), callbackDone);
  };
}

// TODO(sigmund): expose this functionality
/** Like [_later0] but expecting a callback with 1 argument. */
Function _later1(Function callback) {
  Expect.isTrue(_currentTest < _tests.length);
  var testCase = _tests[_currentTest];
  testCase.callbacks++;
  return (arg0) {
    _guard(() => callback(arg0), callbackDone);
  };
}

// TODO(sigmund): expose this functionality
/** Like [_later0] but expecting a callback with 2 arguments. */
Function _later2(Function callback) {
  Expect.isTrue(_currentTest < _tests.length);
  var testCase = _tests[_currentTest];
  testCase.callbacks++;
  return (arg0, arg1) {
    _guard(() => callback(arg0, arg1), callbackDone);
  };
}

/**
 * Creates a new named group of tests. Calls to group() or test() within the
 * body of the function passed to this will inherit this group's description.
 */
void group(String description, void body()) {
  _ensureInitialized();

  // Concatenate the new group.
  final oldGroup = _currentGroup;
  if (_currentGroup != '') {
    // Add a space.
    _currentGroup = '$_currentGroup $description';
  } else {
    // The first group.
    _currentGroup = description;
  }

  try {
    body();
  } finally {
    // Now that the group is over, restore the previous one.
    _currentGroup = oldGroup;
  }
}

/** Called by subclasses to indicate that an asynchronous test completed. */
void callbackDone() {
  _callbacksCalled++;
  final testCase = _tests[_currentTest];
  if (_callbacksCalled > testCase.callbacks) {
    final expected = testCase.callbacks;
    testCase.error(
        'More calls to callbackDone() than expected. '
        'Actual: ${_callbacksCalled}, expected: ${expected}', '');
    _state = _UNCAUGHT_ERROR;
  } else if ((_callbacksCalled == testCase.callbacks) &&
      (_state != _RUNNING_TEST)) {
    if (testCase.result == null) testCase.pass();
    _currentTest++;
    _testRunner();
  }
}

void notifyError(String msg, String trace) {
 if (_currentTest < _tests.length) {
    final testCase = _tests[_currentTest];
    testCase.error(msg, trace);
    _state = _UNCAUGHT_ERROR;
    if (testCase.callbacks > 0) {
      _currentTest++;
      _testRunner();
    }
  }
}

/** Runs [callback] at the end of the event loop. */
_defer(void callback()) {
  // Exploit isolate ports as a platform-independent mechanism to queue a
  // message at the end of the event loop.
  // TODO(sigmund): expose this functionality somewhere in our libraries.
  final port = new ReceivePort();
  port.receive((msg, reply) {
    callback();
    port.close();
  });
  port.toSendPort().send(null, null);
}

/** Runs all queued tests, one at a time. */
_runTests() {
  _config.onStart();

  _defer(() {
    assert (_currentTest == 0);
    _testRunner();
  });
}

/**
 * Run [tryBody] guarded in a try-catch block. If an exception is thrown, update
 * the [_currentTest] status accordingly.
 */
_guard(tryBody, [finallyBody]) {
  final testCase = _tests[_currentTest];
  try {
    tryBody();
  } catch (ExpectException e, var trace) {
    if (_state != _UNCAUGHT_ERROR) {
      //TODO(pquitslund) remove guard once dartc reliably propagates traces
      testCase.fail(e.message, trace == null ? '' : trace.toString());
    }
  } catch (var e, var trace) {
    if (_state != _UNCAUGHT_ERROR) {
      //TODO(pquitslund) remove guard once dartc reliably propagates traces
      testCase.error('Caught ${e}', trace == null ? '' : trace.toString());
    }
  } finally {
    _state = _READY;
    if (finallyBody != null) finallyBody();
  }
}

/**
 * Runs a batch of tests, yielding whenever an asynchronous test starts
 * running. Tests will resume executing when such asynchronous test calls
 * [done] or if it fails with an exception.
 */
_nextBatch() {
  while (_currentTest < _tests.length) {
    final testCase = _tests[_currentTest];

    _guard(() {
      _callbacksCalled = 0;
      _state = _RUNNING_TEST;

      testCase.test();

      if (_state != _UNCAUGHT_ERROR) {
        if (testCase.callbacks == _callbacksCalled) {
          testCase.pass();
        }
      }
    });

    if (!testCase.isComplete && testCase.callbacks > 0) return;

    _currentTest++;
  }

  _completeTests();
}

/** Publish results on the page and notify controller. */
_completeTests() {
  _state = _UNINITIALIZED;

  int testsPassed_ = 0;
  int testsFailed_ = 0;
  int testsErrors_ = 0;

  for (TestCase t in _tests) {
    switch (t.result) {
      case _PASS:  testsPassed_++; break;
      case _FAIL:  testsFailed_++; break;
      case _ERROR: testsErrors_++; break;
    }
  }

  _config.onDone(testsPassed_, testsFailed_, testsErrors_, _tests);
}

String _fullSpec(String spec) {
  if (spec === null) return '$_currentGroup';
  return _currentGroup != '' ? '$_currentGroup $spec' : spec;
}

/**
 * Lazily initializes the test library if not already initialized.
 */
_ensureInitialized() {
  if (_state != _UNINITIALIZED) return;

  _tests = <TestCase>[];
  _currentGroup = '';
  _state = _READY;
  _testRunner = _nextBatch;

  if (_config == null) {
    _config = new Configuration();
  }
  _config.onInit();

  // Immediately queue the suite up. It will run after a timeout (i.e. after
  // main() has returned).
  _defer(_runTests);
}

/** Signature for a test function. */
typedef void TestFunction();
