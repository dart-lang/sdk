// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of unittest;

// A custom failure handler for [expect] that routes expect failures
// to the config.
class _ExpectFailureHandler extends DefaultFailureHandler {
  Configuration _config;

  _ExpectFailureHandler(this._config) : super();

  void fail(String reason) {
    _config.onExpectFailure(reason);
  }
}

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
  final String name = 'Configuration';

  /**
   * If true, then tests are started automatically (otherwise [runTests]
   * must be called explicitly after the tests are set up.
   */
  final bool autoStart = true;

  /**
   * If true (the default), throw an exception at the end if any tests failed.
   */
  bool throwOnTestFailures = true;

  /**
   * If true (the default), then tests will stop after the first failed
   * [expect]. If false, failed [expect]s will not cause the test
   * to stop (other exceptions will still terminate the test).
   */
  bool stopTestOnExpectFailure = true;

  // If stopTestOnExpectFailure is false, we need to capture failures, which
  // we do with this List.
  List _testLogBuffer = new List();
  
  /**
   * The constructor sets up a failure handler for [expect] that redirects
   * [expect] failures to [onExpectFailure].
   */
  Configuration() {
    configureExpectFailureHandler(new _ExpectFailureHandler(this));
  }
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
   * a test suite. Derived classes should call this first before their own
   * override code.
   */
  void onTestStart(TestCase testCase) {
    assert(testCase != null);
    _testLogBuffer.clear();
  }

  /**
   * Called when each test is first completed. Useful to show intermediate
   * progress on a test suite. Derived classes should call this first 
   * before their own override code.
   */
  void onTestResult(TestCase testCase) {
    assert(testCase != null);
    if (!stopTestOnExpectFailure && _testLogBuffer.length > 0) {
      // Write the message/stack pairs up to the last pairs.
      var reason = new StringBuffer();
      for (var i = 0; i < _testLogBuffer.length - 2; i += 2) {
        reason.write(_testLogBuffer[i]);
        reason.write('\n');
        reason.write(_formatStack(_testLogBuffer[i+1]));
        reason.write('\n');
      }
      // Write the last message.
      reason.write(_testLogBuffer[_testLogBuffer.length - 2]);
      if (testCase.result == PASS) {
        testCase._result = FAIL;
        testCase._message = reason.toString();
        // Use the last stack as the overall failure stack.    
        testCase._stackTrace = 
            _formatStack(_testLogBuffer[_testLogBuffer.length - 1]);
      } else {
        // Add the last stack to the message; we have a further stack
        // caused by some other failure.
        reason.write(_formatStack(_testLogBuffer[_testLogBuffer.length - 1]));
        reason.write('\n');
        // Add the existing reason to the end of the expect log to 
        // create the final message.
        testCase._message = '${reason.toString()}\n${testCase._message}';
      }
    }
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
   * Handles the logging of messages by a test case. The default in
   * this base configuration is to call print();
   */
  void onLogMessage(TestCase testCase, String message) {
    print(message);
  }

  /**
   * Handles failures from expect(). The default in
   * this base configuration is to throw an exception;
   */
  void onExpectFailure(String reason) {
    if (stopTestOnExpectFailure) {
      throw new TestFailure(reason);
    } else {
      _testLogBuffer.add(reason);
      try {
        throw '';
      } catch (_, stack) {
        _testLogBuffer.add(stack);
      }
    }
  }
  
  /**
   * Format a test result.
   */
  String formatResult(TestCase testCase) {
    var result = new StringBuffer();
    result.write(testCase.result.toUpperCase());
    result.write(": ");
    result.write(testCase.description);
    result.write("\n");

    if (testCase.message != '') {
      result.write(_indent(testCase.message));
      result.write("\n");
    }

    if (testCase.stackTrace != null && testCase.stackTrace != '') {
      result.write(_indent(testCase.stackTrace));
      result.write("\n");
    }
    return result.toString();
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
    for (final t in results) {
      print(formatResult(t));
    }

    // Show the summary.
    print('');

    if (passed == 0 && failed == 0 && errors == 0 && uncaughtError == null) {
      print('No tests found.');
      // This is considered a failure too.
    } else if (failed == 0 && errors == 0 && uncaughtError == null) {
      print('All $passed tests passed.');
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
      if (throwOnTestFailures) {
        throw new Exception('Some tests failed.');
      }
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
