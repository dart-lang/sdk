// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of unittest;

/**
 * Hooks to configure the unittest library for different platforms. This class
 * implements the API in a platform-independent way. Tests that want to take
 * advantage of the platform can create a subclass and override methods from
 * this class.
 */

class Configuration {
  TestCase currentTestCase = null;

  /**
   * Subclasses can override this with something useful for diagnostics.
   * Particularly useful in cases where we have parent/child configurations
   * such as layout tests.
   */
  get name => 'Configuration';
  /**
   * If true, then tests are started automatically (otherwise [runTests]
   * must be called explicitly after the tests are set up.
   */
  get autoStart => true;

  /**
   * Called as soon as the unittest framework becomes initialized. This is done
   * even before tests are added to the test framework. It might be used to
   * determine/debug errors that occur before the test harness starts executing.
   */
  void onInit() {}

  /**
   * Called as soon as the unittest framework starts running. Used commonly to
   * tell the vm or browser that tests are still running and the process should
   * wait until they are done.
   */
  void onStart() {
    _postMessage('unittest-suite-wait-for-done');
  }

  /**
   * Called when each test starts. Useful to show intermediate progress on
   * a test suite.
   */
  void onTestStart(TestCase testCase) {
    currentTestCase = testCase;
  }

  /**
   * Called when each test is completed. Useful to show intermediate progress on
   * a test suite.
   */
  void onTestResult(TestCase testCase) {
    currentTestCase = null;
  }

  /**
   * Can be called by tests to log status. Tests should use this
   * instead of print. Subclasses should not override this; they
   * should instead override logMessage which is passed the test case.
   */
  void logMessage(String message) {
    if (currentTestCase == null || _currentTest >= _tests.length ||
        currentTestCase.id != _tests[_currentTest].id) {
      // Before or after tests run, or with a mismatch between what the
      // config and the test harness think is the current test. In this
      // case we pass null for the test case reference and let the config
      // decide what to do with this.
      logTestCaseMessage(null, message);
    } else {
      logTestCaseMessage(currentTestCase, message);
    }
  }

  /**
   * Handles the logging of messages by a test case. The default in
   * this base configuration is to call print();
   */
  void logTestCaseMessage(TestCase testCase, String message) {
    print(message);
  }

  /**
   * Called with the result of all test cases. The default implementation prints
   * the result summary using the built-in [print] command. Browser tests
   * commonly override this to reformat the output.
   *
   * When [uncaughtError] is not null, it contains an error that occured outside
   * of tests (e.g. setting up the test).
   */
  void onDone(int passed, int failed, int errors, List<TestCase> results,
      String uncaughtError) {
    // Print each test's result.
    for (final t in _tests) {
      print('${t.result.toUpperCase()}: ${t.description}');

      if (t.message != '') {
        print(_indent(t.message));
      }

      if (t.stackTrace != null && t.stackTrace != '') {
        print(_indent(t.stackTrace));
      }
    }

    // Show the summary.
    print('');

    var success = false;
    if (passed == 0 && failed == 0 && errors == 0) {
      print('No tests found.');
      // This is considered a failure too.
    } else if (failed == 0 && errors == 0 && uncaughtError == null) {
      print('All $passed tests passed.');
      success = true;
    } else {
      if (uncaughtError != null) {
        print('Top-level uncaught error: $uncaughtError');
      }
      print('$passed PASSED, $failed FAILED, $errors ERRORS');
    }

    if (success) {
      _postMessage('unittest-suite-success');
    } else {
      throw new Exception('Some tests failed.');
    }
  }

  String _indent(String str) {
    // TODO(nweiz): Use this simpler code once issue 2980 is fixed.
    // return str.replaceAll(new RegExp("^", multiLine: true), "  ");

    return Strings.join(str.split("\n").map((line) => "  $line"), "\n");
  }

  /** Handle errors that happen outside the tests. */
  // TODO(vsm): figure out how to expose the stack trace here
  // Currently e.message works in dartium, but not in dartc.
  handleExternalError(e, String message) =>
      _reportTestError('$message\nCaught $e', '');

  _postMessage(String message) {
    // In dart2js browser tests, the JavaScript-based test controller
    // intercepts calls to print and listens for "secret" messages.
    print(message);
  }
}
