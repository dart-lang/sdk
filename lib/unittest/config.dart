// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** This file is sourced by unitest.dart. */

/**
 * Hooks to configure the unittest library for different platforms. This class
 * implements the API in a platform-independent way. Tests that want to take
 * advantage of the platform can create a subclass and override methods from
 * this class.
 */
class Configuration {
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
  void onStart() {}

  /**
   * Called when each test is completed. Useful to show intermediate progress on
   * a test suite.
   */
  void onTestResult(TestCase testCase) {}

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
        print('  ${t.message}');
      }
    }

    // Show the summary.
    print('');

    var success = false;
    if (passed == 0 && failed == 0 && errors == 0) {
      print('No tests found.');
      // This is considered a failure too: if this happens you probably have a
      // bug in your unit tests.
    } else if (failed == 0 && errors == 0 && uncaughtError == null) {
      print('All $passed tests passed.');
      success = true;
    } else {
      if (uncaughtError != null) {
        print('Top-level uncaught error: $uncaughtError');
      }
      print('$passed PASSED, $failed FAILED, $errors ERRORS');
    }

    // An exception is used by the test infrastructure to detect failure.
    if (!success) throw new Exception("Some tests failed.");
  }
}
