// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Description text of the current test group. If multiple groups are nested,
 * this will contain all of their text concatenated.
 */
String _currentGroup = '';

/** Tests executed in this suite. */
List<TestCase> _tests;

/** Whether this is run within dartium layout tests. */
bool _isLayoutTest = false;

/** Current test being executed. */
int _currentTest = 0;

/** Total number of callbacks that have been executed in the current test. */
int _callbacksCalled = 0;

// TODO(rnystrom): Get rid of this if we get canonical closures for methods.
EventListener _onErrorClosure;

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
    testCase.recordError(
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
    testCase.recordError(
        "Can't call callbackDone() on a synchronous test", '');
    _state = _UNCAUGHT_ERROR;
  } else if (_callbacksCalled > testCase.callbacks) {
    final expected = testCase.callbacks;
    testCase.recordError(
        'More calls to callbackDone() than expected. '
        + 'Actual: ${_callbacksCalled}, expected: ${expected}', '');
    _state = _UNCAUGHT_ERROR;
  } else if ((_callbacksCalled == testCase.callbacks) &&
      (_state != _RUNNING_TEST)) {
    testCase.recordSuccess();
    _currentTest++;
    _nextBatch();
  }
}

void forLayoutTests() {
  _isLayoutTest = true;
}

/** Runs all queued tests, one at a time. */
_runTests() {
  window.postMessage('unittest-suite-start', '*');
  window.setTimeout(() {
    assert (_currentTest == 0);
    // Listen for uncaught errors.
    try {
      window.on.error.add(_onErrorClosure);
    } catch(var e) {
      // TODO(jacobr): remove this horrible hack when dartc bugs are fixed.
      window.dynamic.onerror = _onErrorClosure;
    }
    _nextBatch();
  }, 0);
}

/** Runs a single test. */
_runTest(TestCase testCase) {
  try {
    // TODO(sigmund): remove this declaration once dartc supports trapping error
    // traces.
    var trace = '';
    _callbacksCalled = 0;
    _state = _RUNNING_TEST;

    testCase.test();

    if (_state != _UNCAUGHT_ERROR) {
      if (testCase.callbacks == _callbacksCalled) {
        testCase.recordSuccess();
      }
    }
  } catch (ExpectException e, var trace) {
    if (_state != _UNCAUGHT_ERROR) {
      testCase.recordFail(e.message, trace.toString());
    }
  } catch (var e, var trace) {
    if (_state != _UNCAUGHT_ERROR) {
      testCase.recordError('Caught ${e}', trace.toString());
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
  try {
    window.on.error.remove(_onErrorClosure);
  } catch (var e) {
    // TODO(jacobr): remove this horrible hack to work around dartc bugs.
    window.dynamic.onerror = null;
  }

  _state = _UNINITIALIZED;

  int testsFailed = 0;
  int testsErrors = 0;
  int testsPassed = 0;

  for (TestCase t in _tests) {
    if (t.success) testsPassed++;
    if (t.fail) testsFailed++;
    if (t.error) testsErrors++;
  }

  if (_isLayoutTest && testsPassed == _tests.length) {
    document.body.innerHTML = "PASS";
  } else {
    var newBody = new StringBuffer();
    newBody.add("<table class='unittest-table'><tbody>");
    newBody.add(testsPassed == _tests.length
        ? "<tr><td colspan='3' class='unittest-pass'>PASS</td></tr>"
        : "<tr><td colspan='3' class='unittest-fail'>FAIL</td></tr>");

    for (final test in _tests) {
      newBody.add(test.message);
    }

    if (testsPassed == _tests.length) {
      newBody.add("<tr><td colspan='3' class='unittest-pass'>All "
          + testsPassed + " tests passed</td></tr>");
    } else {
      newBody.add("""
          <tr><td colspan='3'>Total
            <span class='unittest-pass'>${testsPassed} passed</span>,
            <span class='unittest-fail'>${testsFailed} failed</span>
            <span class='unittest-error'>${testsErrors} errors</span>
          </td></tr>""");
    }
    newBody.add("</tbody></table>");
    document.body.innerHTML = newBody.toString();
  }

  window.dynamic/*TODO(5389254)*/.postMessage('unittest-suite-done', '*');
}

void _onError(e) {
 if (_currentTest < _tests.length) {
    final testCase = _tests[_currentTest];
    // TODO(vsm): figure out how to expose the stack trace here
    // Currently e.message works in dartium, but not in dartc.
    testCase.recordError('(DOM callback has errors) Caught ${e}', '');
    _state = _UNCAUGHT_ERROR;
    if (testCase.callbacks > 0) {
      _currentTest++;
      _nextBatch();
    }
  }
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
  _onErrorClosure = (e) { _onError(e); };

  // Immediately queue the suite up. It will run after a timeout (i.e. after
  // main() has returned).
  listener() {
    _currentGroup = '';
    _runTests();
  };

  window.setTimeout(listener, 0);

  _state = _READY;
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
    Expect.equals(expected, _value);
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

  /** Whether this test case was succesful. */
  bool success;

  /** Whether an Expect call failed in this test. */
  bool fail;

  /** Whether this test case had a runtime error. */
  bool error;

  /** Messages to display at the end of the test run. */
  String message;

  TestCase(this.id, this.description, this.test, this.callbacks)
    : success = false,
      fail = false,
      error = false {
    message = '''<tr>
          <td>${id}</td>
          <td class="unittest-error">NO STATUS</td>
          <td>Test did not complete</td>
        </tr>''';
  }

  bool get isComplete() => success || fail || error;

  void recordSuccess() {
    _setMessage('pass', '', null);
    success = true;
  }

  void recordError(String msg, String stackTrace) {
    _setMessage('error', msg, stackTrace);
    error = true;
  }

  void recordFail(String msg, String stackTrace) {
    _setMessage('fail', msg, stackTrace);
    fail = true;
  }

  void _setMessage(String type, String msg, String stackTrace) {
    message =
        '''
        <tr>
          <td>${id}</td>
          <td class="unittest-$type">${type.toUpperCase()}</td>
          <td>Expectation: $description. $msg</td>
        </tr>
        ''';

    if (stackTrace != null) {
      message +=
          '<tr><td></td><td colspan="2"><pre>${stackTrace}</pre></td></tr>';
    }
  }
}

typedef void TestFunction();
