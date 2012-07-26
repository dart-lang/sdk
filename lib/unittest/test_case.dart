// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * testcase.dart: this file is sourced by unittest.dart. It defines [TestCase]
 * and assumes unittest defines the type [TestFunction].
 */

/** Summarizes information about a single test case. */
class TestCase {
  /** Identifier for this test. */
  final int id;

  /** A description of what the test is specifying. */
  final String description;

  /** The setup function to call before the test, if any. */
  final _setup;

  /** The teardown function to call after the test, if any. */
  final _teardown;

  /** The body of the test case. */
  TestFunction test;

  /** Total number of callbacks to wait for before the test completes. */
  int callbacks;

  /** Error or failure message. */
  String message = '';

  /**
   * One of [_PASS], [_FAIL], [_ERROR], or [null] if the test hasn't run yet.
   */
  String result;

  /** Stack trace associated with this test, or null if it succeeded. */
  String stackTrace;

  /** The group (or groups) under which this test is running. */
  final String currentGroup;

  Date startTime;

  Duration runningTime;

  bool enabled = true;

  TestCase(this.id, this.description, this.test, this.callbacks)
  : currentGroup = _currentGroup,
    _setup = _testSetup,
    _teardown = _testTeardown;

  bool get isComplete() => !enabled || result != null;

  void run() {
    if (enabled) {
      result = stackTrace = null;
      message = '';

      if (_setup != null) {
        _setup();
      }
      try {
        _config.onTestStart(this);
        test();
      } finally {
        if (_teardown != null) {
          _teardown();
        }
      }
    }
  }

  void pass() {
    result = _PASS;
    _config.onTestResult(this);
  }

  void fail(String messageText, String stack) {
    result = _FAIL;
    message = messageText;
    stackTrace = stack;
    _config.onTestResult(this);
  }

  void error(String messageText, String stack) {
    result = _ERROR;
    message = messageText;
    stackTrace = stack;
    _config.onTestResult(this);
  }
}
