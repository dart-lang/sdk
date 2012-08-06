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
  Function _setUp;

  Function get setUp() => _setUp;
  set setUp(Function value) => _setUp = value;

  /** The teardown function to call after the test, if any. */
  Function _tearDown;

  Function get tearDown() => _tearDown;
  set tearDown(Function value) => _tearDown = value;

  /** The body of the test case. */
  TestFunction test;

  /**
   * Remaining number of callbacks functions that must reach a 'done' state
   * to wait for before the test completes.
   */
  int callbackFunctionsOutstanding;

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

  bool _doneTeardown;

  TestCase(this.id, this.description, this.test,
           this.callbackFunctionsOutstanding)
  : currentGroup = _currentGroup,
    _setUp = _testSetup,
    _tearDown = _testTeardown;

  bool get isComplete() => !enabled || result != null;

  void run() {
    if (enabled) {
      result = stackTrace = null;
      message = '';
      _doneTeardown = false;
      if (_setUp != null) {
        _setUp();
      }
      _config.onTestStart(this);
      test();
    }
  }

  void _complete() {
    if (!_doneTeardown) {
      if (_tearDown != null) {
        _tearDown();
      }
      _doneTeardown = true;
    }
    _config.onTestResult(this);
  }

  void pass() {
    result = _PASS;
    _complete();
  }

  void fail(String messageText, String stack) {
    result = _FAIL;
    message = messageText;
    stackTrace = stack;
    _complete();
  }

  void error(String messageText, String stack) {
    result = _ERROR;
    message = messageText;
    stackTrace = stack;
    _complete();
  }
}
