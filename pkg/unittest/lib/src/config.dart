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
  // The VM won't shut down if a receive port is open. Use this to make sure
  // we correctly wait for asynchronous tests.
  ReceivePort _receivePort;

  /**
   * Subclasses can override this with something useful for diagnostics.
   * Particularly useful in cases where we have parent/child configurations
   * such as layout tests.
   */
  String get name => 'Configuration';

  /**
   * If true, then tests are started automatically (otherwise [runTests]
   * must be called explicitly after the tests are set up.
   */
  bool get autoStart => true;

  /**
   * Called as soon as the unittest framework becomes initialized. This is done
   * even before tests are added to the test framework. It might be used to
   * determine/debug errors that occur before the test harness starts executing.
   * It is also used to tell the vm or browser that tests are going to be run
   * asynchronously and that the process should wait until they are done.
   */
  void onInit() {
    _receivePort = new ReceivePort();
    _postMessage('unittest-suite-wait-for-done');
  }

  /** Called as soon as the unittest framework starts running. */
  void onStart() {}

  /**
   * Called when each test starts. Useful to show intermediate progress on
   * a test suite.
   */
  void onTestStart(TestCase testCase) {
    assert(testCase != null);	
  }

  /**
   * Called when each test is first completed. Useful to show intermediate
   * progress on a test suite.
   */
  void onTestResult(TestCase testCase) {
    assert(testCase != null);	
  }

  /**
   * Called when an already completed test changes state; for example a test
   * that was marked as passing may later be marked as being in error because
   * it still had callbacks being invoked.
   */
  void onTestResultChanged(TestCase testCase) {
    assert(testCase != null);
  }

  /**
   * Can be called by tests to log status. Tests should use this
   * instead of print. Subclasses should not override this; they
   * should instead override logMessage which is passed the test case.
   */
  void logMessage(String message) {
    if (currentTestCase == null) {
      // Before or after tests run. In this case we pass null for the test
      // case reference and let the config decide what to do with this.
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
  void onSummary(int passed, int failed, int errors, List<TestCase> results,
      String uncaughtError) {
    // Print each test's result.
    for (final t in _tests) {
      var resultString = "${t.result}".toUpperCase();
      print('$resultString: ${t.description}');

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
    if (passed == 0 && failed == 0 && errors == 0 && uncaughtError == null) {
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
  }

  /**
   * Called when the unittest framework is done running. [success] indicates
   * whether all tests passed successfully.
   */
  void onDone(bool success) {
    if (success) {
      _postMessage('unittest-suite-success');
      _receivePort.close();
    } else {
      _receivePort.close();
      throw new Exception('Some tests failed.');
    }
  }

  String _indent(String str) {
    // TODO(nweiz): Use this simpler code once issue 2980 is fixed.
    // return str.replaceAll(new RegExp("^", multiLine: true), "  ");

    return str.split("\n").map((line) => "  $line").join("\n");
  }

  /** Handle errors that happen outside the tests. */
  // TODO(vsm): figure out how to expose the stack trace here
  // Currently e.message works in dartium, but not in dartc.
  void handleExternalError(e, String message, [String stack = '']) =>
      _reportTestError('$message\nCaught $e', stack);

  _postMessage(String message) {
    // In dart2js browser tests, the JavaScript-based test controller
    // intercepts calls to print and listens for "secret" messages.
    print(message);
  }
}
