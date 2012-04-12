// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This file is sourced from unittest_html, unittest_dom, and unittest_vm.
 * These libraries shold also source 'config.dart' and should define a class
 * called [PlatformConfiguration] that implements [Configuration].
 */

/** [Configuration] used by the unittest library. */
Configuration _config = null;

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
  if (testCase.callbacks == 0) {
    testCase.error(
        "Can't call callbackDone() on a synchronous test", '');
    _state = _UNCAUGHT_ERROR;
  } else if (_callbacksCalled > testCase.callbacks) {
    final expected = testCase.callbacks;
    testCase.error(
        'More calls to callbackDone() than expected. '
        + 'Actual: ${_callbacksCalled}, expected: ${expected}', '');
    _state = _UNCAUGHT_ERROR;
  } else if ((_callbacksCalled == testCase.callbacks) &&
      (_state != _RUNNING_TEST)) {
    testCase.pass();
    _currentTest++;
    _testRunner();
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

/** Runs a single test. */
_runTest(TestCase testCase) {
  try {
    _callbacksCalled = 0;
    _state = _RUNNING_TEST;

    testCase.test();

    if (_state != _UNCAUGHT_ERROR) {
      if (testCase.callbacks == _callbacksCalled) {
        testCase.pass();
      }
    }

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

    _runTest(testCase);

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
    // TODO(sigmund): make this [new Configuration], set configuration
    // for each platform in test.dart
    _config = new PlatformConfiguration();
  }
  _config.onInit();

  // Immediately queue the suite up. It will run after a timeout (i.e. after
  // main() has returned).
  _defer(_runTests);
}

/**
 * Wraps an value and provides an "==" operator that can be used to verify that
 * the value matches a given expectation.
 */
class Expectation {
  final _value;

  Expectation(this._value);

  /** Asserts that the value is equivalent to [expected]. */
  void equals(expected) {
    // Use the type-specialized versions when appropriate to give better
    // error messages.
    if (_value is String && expected is String) {
      Expect.stringEquals(expected, _value);
    } else if (_value is Map && expected is Map) {
      Expect.mapEquals(expected, _value);
    } else if (_value is Set && expected is Set) {
      Expect.setEquals(expected, _value);
    } else {
      Expect.equals(expected, _value);
    }
  }

  /**
   * Asserts that the difference between [expected] and the value is within
   * [tolerance]. If no tolerance is given, it is assumed to be the value 4
   * significant digits smaller than the expected value.
   */
  void approxEquals(num expected,
      [num tolerance = null, String reason = null]) {
    Expect.approxEquals(expected, _value, tolerance: tolerance, reason: reason);
  }

  /** Asserts that the value is [null]. */
  void isNull() {
    Expect.equals(null, _value);
  }

  /** Asserts that the value is not [null]. */
  void isNotNull() {
    Expect.notEquals(null, _value);
  }

  /** Asserts that the value is [true]. */
  void isTrue() {
    Expect.equals(true, _value);
  }

  /** Asserts that the value is [false]. */
  void isFalse() {
    Expect.equals(false, _value);
  }

  /** Asserts that the value has the same elements as [expected]. */
  void equalsCollection(Collection expected) {
    Expect.listEquals(expected, _value);
  }

  /**
   * Checks that every element of [expected] is also in [actual], and that
   * every element of [actual] is also in [expected].
   */
  void equalsSet(Iterable expected) {
    Expect.setEquals(expected, _value);
  }
}

/** Summarizes information about a single test case. */
class TestCase {
  /** Identifier for this test. */
  final id;

  /** A description of what the test is specifying. */
  final String description;

  /** The body of the test case. */
  final TestFunction test;

  /** Total number of callbacks to wait for before the test completes. */
  int callbacks;

  /** Error or failure message. */
  String message  = '';

  /**
   * One of [_PASS], [_FAIL], or [_ERROR] or [null] if the test hasn't run yet.
   */
  String result;

  /** Stack trace associated with this test, or null if it succeeded. */
  String stackTrace;

  Date startTime;

  Duration runningTime;

  TestCase(this.id, this.description, this.test, this.callbacks);

  bool get isComplete() => result != null;

  void pass() {
    result = _PASS;
  }

  void fail(String message_, String stackTrace_) {
    result = _FAIL;
    this.message = message_;
    this.stackTrace = stackTrace_;
  }

  void error(String message_, String stackTrace_) {
    result = _ERROR;
    this.message = message_;
    this.stackTrace = stackTrace_;
  }
}

typedef void TestFunction();
