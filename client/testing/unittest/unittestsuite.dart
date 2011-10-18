// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(rnystrom): This code is gradually moving from a Java/JUnit style to
// something closer to JS/Jasmine. Eventually, the UnitTestSuite class can go
// away completely (or become private to this library) and the only exposed API
// will be group()/test()/expect(). Until then, both ways are supported, which
// is why things look a bit weird in here.

UnitTestSuite _currentSuite;

/**
 * Description text of the current test group. If multiple groups are nested,
 * this will contain all of their text concatenated.
 */
String _currentGroup = '';

/** Base class for unit test suites run in a browser. */
class UnitTestSuite {

  /** Tests executed in this suite. */
  List<TestCase> _tests;

  /** Whether this suite is run within dartium layout tests. */
  bool _isLayoutTest;

  /** Current test being executed. */
  int _currentTest;

  /** Total number of callbacks that have been executed in the current test. */
  int _callbacksCalled;

  /**
   * Whether an undetected error occurred while running the last test.  This
   * errors are commonly caused by DOM callbacks that were not guarded in a
   * try-catch block.
   */
  bool _uncaughtError;
  EventListener _onErrorClosure;

  bool _queuedToRun = false;

  // TODO(sigmund): remove isLayoutTest argument after converting all DOM tests
  // to use the named constructor below.
  // TODO(vsm): remove the ignoredWindow parameter once all tests are fixed.
  UnitTestSuite([var ignoredWindow = null, bool isLayoutTest = false])
    : _isLayoutTest = isLayoutTest,
      _tests = new List<TestCase>(),
      _currentTest = 0,
      _callbacksCalled = 0 {
    _onErrorClosure = (e) { _onError(e); };
    if (_currentSuite != null) {
      throw 'Cannot have two UnitTestSuites in flight at the same time.';
    }
    _currentSuite = this;

    // Immediately queue the suite up. It will run after a timeout (i.e. after
    // main() has returned).
    run();
  }

  // TODO(jacobr): remove the ignoredWindow parameter once all tests are fixed.
  UnitTestSuite.forLayoutTests([var ignoredWindow = null]) : this(null, true);

  /** Starts running the testsuite. */
  void run() {
    if (_queuedToRun) {
      return;
    }

    _queuedToRun = true;

    listener(e) {
      _currentGroup = '';
      setUpTestSuite();
      runTests();
    };

    try {
      window.dynamic.on.contentLoaded.add(listener);
    } catch(var e) {
    // TODO(jacobr): remove this horrible hack to work around dartc bugs.
      window.dynamic.addEventListener("DOMContentLoaded", listener, false);
    }
  }

  /** Subclasses should override this method to register tests. */
  void setUpTestSuite() {}

  /** Enqueues a synchronous test. */
  void addTest(TestFunction body) {
    test(null, body);
  }

  /** Adds the tests defined by the given TestSet to this suite. */
  void addTestSet(TestSet test) {
    test._bindToSuite(this);
    test.setup();
  }

  /** Adds the tests defined by the given TestSets to this suite. */
  void addTestSets(Iterable<TestSet> tests) {
    for (TestSet test in tests) {
      addTestSet(test);
    }
  }

  /** Enqueues an asynchronous test that waits for [callbacks] callbacks. */
  void addAsyncTest(TestFunction body, int callbacks) {
    asyncTest(null, callbacks, body);
  }

  /** Runs all queued tests, one at a time. */
  void runTests() {
    window.dynamic/*TODO(5389254)*/.postMessage('unittest-suite-start', '*');
    // Isolate.bind makes sure the closure runs in the same isolate (i.e. this
    // one) where it has been created.
    window.setTimeout(Isolate.bind(() {
      assert (_currentTest == 0);
      // Listen for uncaught errors (see [_uncaughtError]).
      // TODO(jacobr): remove this horrible hack when dartc bugs are fixed.
      try {
        window.dynamic.on.error.add(_onErrorClosure);
      } catch(var e) {
        window.dynamic.onerror = _onErrorClosure;
      }
      _nextBatch();
    }), 0);
  }

  void _onError(e) {
   if (_currentTest < _tests.length) {
      final testCase = _tests[_currentTest];
      // TODO(vsm): figure out how to expose the stack trace here
      // Currently e.message works in dartium, but not in dartc.
      testCase.recordError('(DOM callback has errors) Caught ${e}', '');
      _uncaughtError = true;
      if (testCase.callbacks > 0) {
        _currentTest++;
        _nextBatch();
      }
    }
  }

  /** Called by subclasses to indicate that an asynchronous test completed. */
  void callbackDone() {
    _callbacksCalled++;
    final testCase = _tests[_currentTest];
    if (testCase.callbacks == 0) {
      testCase.recordError(
          "Can't call callbackDone() on a synchronous test", '');
      _uncaughtError = true;
    } else if (_callbacksCalled > testCase.callbacks) {
      final expected = testCase.callbacks;
      testCase.recordError(
          'More calls to callbackDone() than expected. '
          + 'Actual: ${_callbacksCalled}, expected: ${expected}', '');
      _uncaughtError = true;
    } else if (_callbacksCalled == testCase.callbacks) {
      testCase.recordSuccess();
      _currentTest++;
      _nextBatch();
    }
  }

  /**
   * Runs a batch of tests, yielding whenever an asynchronous test starts
   * running. Tests will resume executing when such asynchronous test calls
   * [done] or if it fails with an exception.
   */
  void _nextBatch() {
    while (_currentTest < _tests.length) {
      final testCase = _tests[_currentTest];
      runTest(testCase);
      if (!testCase.isComplete() && testCase.callbacks > 0) {
        return;
      }
      _currentTest++;
    }
    _completeTests();
  }

  /** Runs a single test. */
  void runTest(TestCase testCase) {
    // TODO(sigmund): remove this declaration once dartc supports trapping error
    // traces.
    var trace = '';
    _uncaughtError = false;
    _callbacksCalled = 0;
    try {
      (testCase.test)();
      if (!_uncaughtError) {
        if (testCase.callbacks == _callbacksCalled) {
          testCase.recordSuccess();
        }
      }
    } catch (ExpectException e, var trace) {
      if (!_uncaughtError) {
        testCase.recordFail(e.message, trace.toString());
      }
    } catch (var e, var trace) {
      if (!_uncaughtError) {
        testCase.recordError('Caught ${e}', trace.toString());
      }
    }
  }

  /** Publish results on the page and notify controller. */
  void _completeTests() {
    try {
      window.dynamic.on.error.remove(_onErrorClosure);
    } catch (var e) {
      // TODO(jacobr): remove this horrible hack to work around dartc bugs.
      window.dynamic.onerror = null;
    }

    // This suite is done now, so discard it.
    _currentSuite = null;

    int testsFailed = 0;
    int testsErrors = 0;
    int testsPassed = 0;

    for (TestCase t in _tests) {
      if (t.success) {
        testsPassed++;
      }
      if (t.fail) {
        testsFailed++;
      }
      if (t.error) {
        testsErrors++;
      }
    }

    if (_isLayoutTest && testsPassed == _tests.length) {
      document.body.innerHTML = "PASS";
    } else {
      StringBuffer newBody = new StringBuffer();
      newBody.add("<table class='unittest-table'><tbody>");
      newBody.add(testsPassed == _tests.length
          ? "<tr><td colspan='3' class='unittest-pass'>PASS</td></tr>"
          : "<tr><td colspan='3' class='unittest-fail'>FAIL</td></tr>");

      for (TestCase t in _tests) {
        newBody.add(t.message);
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
}

/** Creates an expectation for the given value. */
Expectation expect(value) => new Expectation(value);

/**
 * Creates a new test case with the given description and body. The
 * description will include the descriptions of any surrounding group()
 * calls.
 */
void test(String spec, TestFunction body) {
  _ensureActiveSuite();

  _currentSuite._tests.add(new TestCase(
      _currentSuite._tests.length + 1, _fullSpec(spec), body, 0));
}

/**
 * Creates a new async test case with the given description and body. The
 * description will include the descriptions of any surrounding group()
 * calls.
 */
void asyncTest(String spec, int callbacks, TestFunction body) {
  _ensureActiveSuite();

  final testCase = new TestCase(
      _currentSuite._tests.length + 1, _fullSpec(spec), body, callbacks);
  _currentSuite._tests.add(testCase);

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
  _ensureActiveSuite();

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

void callbackDone() {
  if (_currentSuite == null) {
    throw 'There is no currently-running test suite.';
  }
  _currentSuite.callbackDone();
}

void forLayoutTests() {
  _ensureActiveSuite();
  _currentSuite._isLayoutTest = true;
}

String _fullSpec(String spec) {
  if (spec === null) return '$_currentGroup';
  return _currentGroup != '' ? '$_currentGroup $spec' : spec;
}

/**
 * Lazily creates a UnitTestSuite if there isn't already an active one. Returns
 * whether or not one was created.
 */
_ensureActiveSuite() {
  if (_currentSuite != null) {
    return;
  }

  _currentSuite = new UnitTestSuite();
}

/**
 * Wraps an value and provides an "==" operator that can be used to verify that
 * the value matches a given expectation.
 */
class Expectation {
  final _value;

  Expectation(this._value);

  /** Asserts that the value is equivalent to the given expected value. */
  void equals(expected) {
    Expect.equals(expected, _value);
  }

  /**
   * Failure if the difference between expected and actual is greater than the
   * given tolerance. If no tolerance is given, tolerance is assumed to be the
   * value 4 significant digits smaller than the value given for expected.
   */
  void approxEquals(num expected,
      [num tolerance = null, String reason = null]) {
    Expect.approxEquals(expected, _value, tolerance: tolerance, reason: reason);
  }

  /** Asserts that the value is null. */
  void isNull() {
    Expect.equals(null, _value);
  }

  /** Asserts that the value is not null. */
  void isNotNull() {
    Expect.notEquals(null, _value);
  }

  /** Asserts that the value is true. */
  void isTrue() {
    Expect.equals(true, _value);
  }

  /** Asserts that the value is null. */
  void isFalse() {
    Expect.equals(false, _value);
  }

  /** Asserts that the value has the same elements as the given collection. */
  void equalsCollection(Collection expected) {
    Expect.listEquals(expected, _value);
  }
}

/**
 * A TestSet lets you break a test suite down into a collection of classes to
 * keep things manageable. It exposes the same interface as UnitTestSuite
 * (test(), group(), expect(), etc.) but defers to a parent suite that owns it.
 */
class TestSet {
  UnitTestSuite _currentSuite = null;

  // TODO(rnystrom): Remove this when default constructors are supported.
  TestSet();

  void _bindToSuite(UnitTestSuite suite) {
    _currentSuite = suite;
  }

  /** Override this to define the specifications for this test set. */
  void setup() {
    // Do nothing.
  }

  /** Enqueues a synchronous test. */
  void addTest(TestFunction test) {
    _currentSuite.addTest(test);
  }

  /** Adds the tests defined by the given TestSet to this suite. */
  void addTestSet(TestSet test) {
    _currentSuite.addTestSet(test);
  }

  /** Adds the tests defined by the given TestSets to this suite. */
  void addTestSets(Iterable<TestSet> tests) {
    _currentSuite.addTestSets(tests);
  }

  /** Enqueues an asynchronous test that waits for [callbacks] callbacks. */
  void addAsyncTest(TestFunction test, int callbacks) {
    _currentSuite.addAsyncTest(test, callbacks);
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
    message = """<tr>
          <td>${id}</td>
          <td class='unittest-error'>NO STATUS</td>
          <td>Test did not complete</td>
        </tr>""";
  }

  bool isComplete() => success || fail || error;

  void recordSuccess() {
    message = "<tr><td>${id}</td><td class='unittest-pass'>PASS</td></tr>";
    success = true;
  }

  void recordError(String msg, String stackTrace) {
    message = """
        <tr>
          <td>${id}</td>
          <td class='unittest-error'>ERROR</td>
          <td>${msg}</td>
        </tr>""";
    if (stackTrace != null) {
      message +=
          "<tr><td></td><td colspan='2'><pre>${stackTrace}</pre></td></tr>";
    }
    error = true;
  }

  void recordFail(String msg, String stackTrace) {
    // Include the spec description if we have one.
    // TODO(rnystrom): When all of our tests are using group() and test(), we
    // can assume description will be non-null and eliminate this check.
    if (description != null) {
      msg = 'Expectation: $description. $msg';
    }

    message = """
        <tr>
          <td>${id}</td>
          <td class='unittest-fail'>FAIL</td>
          <td>${msg}</td>
        </tr>""";
    if (stackTrace != null) {
      message +=
          "<tr><td></td><td colspan='2'><pre>${stackTrace}</pre></td></tr>";
    }
    fail = true;
  }
}

typedef void TestFunction();
