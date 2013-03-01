// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of unittest;

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

  Function get setUp => _setUp;
  set setUp(Function value) => _setUp = value;

  /** The teardown function to call after the test, if any. */
  Function _tearDown;

  Function get tearDown => _tearDown;
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
   * One of [PASS], [FAIL], [ERROR], or [null] if the test hasn't run yet.
   */
  String result;

  /** Stack trace associated with this test, or null if it succeeded. */
  String stackTrace;

  /** The group (or groups) under which this test is running. */
  final String currentGroup;

  DateTime startTime;

  Duration runningTime;

  bool enabled = true;

  bool _doneTeardown = false;

  Completer _testComplete;

  TestCase(this.id, this.description, this.test,
           this.callbackFunctionsOutstanding)
  : currentGroup = _currentGroup,
    _setUp = _testSetup,
    _tearDown = _testTeardown;

  bool get isComplete => !enabled || result != null;

  void _prepTest() {
    _config.onTestStart(this);
    startTime = new DateTime.now();
    runningTime = null;
  }

  Future _runTest() {
    _prepTest();
    // Increment/decrement callbackFunctionsOutstanding to prevent
    // synchronous 'async' callbacks from causing the  test to be
    // marked as complete before the body is completely executed.
    ++callbackFunctionsOutstanding;
    var f = test();
    --callbackFunctionsOutstanding;
    if (f is Future) {
      f.then((_) => _finishTest())
       .catchError((e) => fail("${e.error}"));
      return f;
    } else {
      _finishTest();
      return null;
    }
  }

  void _finishTest() {
    if (result == null && callbackFunctionsOutstanding == 0) {
      pass();
    }
  }

  /**
   * Perform any associated [setUp] function and run the test. Returns
   * a [Future] that can be used to schedule the next test. If the test runs
   * to completion synchronously, or is disabled, we return null, to
   * tell unittest to schedule the next test immediately.
   */
  Future run() {
    if (!enabled) return null;

    result = stackTrace = null;
    message = '';
    _doneTeardown = false;
    var rtn = _setUp == null ? null : _setUp();
    if (rtn is Future) {
      rtn.then((_) => _runTest())
         .catchError((e) {
          _prepTest();
          // Calling error() will result in the tearDown being done.
          // One could debate whether tearDown should be done after
          // a failed setUp. There is no right answer, but doing it
          // seems to be the more conservative approach, because 
          // unittest will not stop at a test failure.
          error("$description: Test setup failed: ${e.error}");
        });
    } else {
      var f = _runTest();
      if (f != null) {
        return f;
      }
    }
    if (result == null) { // Not complete.
      _testComplete = new Completer();
      return _testComplete.future;
    }
    return null;
  }

  void _notifyComplete() {
    if (_testComplete != null) {
      _testComplete.complete(this);
      _testComplete = null;
    }
  }

  // Set the results, notify the config, and return true if this
  // is the first time the result is being set.
  void _setResult(String testResult, String messageText, String stack) {
    message = messageText;
    stackTrace = stack;
    if (result == null) {
      result = testResult;
      _config.onTestResult(this);
    } else {
      result = testResult;
      _config.onTestResultChanged(this);
    }
  }

  void _complete(String testResult,
                [String messageText = '',
                 String stack = '']) {
    if (runningTime == null) {
      // TODO(gram): currently the duration measurement code is blocked
      // by issue 4437. When that is fixed replace the line below with:
      //    runningTime = new DateTime.now().difference(startTime);
      runningTime = new Duration(milliseconds: 0);
    }
    _setResult(testResult, messageText, stack);
    if (!_doneTeardown) {
      _doneTeardown = true;
      if (_tearDown != null) {
        var rtn = _tearDown();
        if (rtn is Future) {
          rtn.then((_) {
            _notifyComplete();
          })
          .catchError((e) {
            // We don't call fail() as that will potentially result in
            // spurious messages like 'test failed more than once'.
            _setResult(ERROR, "$description: Test teardown failed: ${e.error}",
                e.stackTrace.toString());
            _notifyComplete();
          });
          return;
        }
      }
    }
    _notifyComplete();
  }

  void pass() {
    _complete(PASS);
  }

  void fail(String messageText, [String stack = '']) {
    if (result != null) {
      String newMessage = (result == PASS)
          ? 'Test failed after initially passing: $messageText'
          : 'Test failed more than once: $messageText';
      // TODO(gram): Should we combine the stack with the old one?
      _complete(ERROR, newMessage, stack);
    } else {
      _complete(FAIL, messageText, stack);
    }
  }

  void error(String messageText, [String stack = '']) {
    _complete(ERROR, messageText, stack);
  }

  void markCallbackComplete() {
    if (--callbackFunctionsOutstanding == 0 && !isComplete) {
      pass();
    }
  }
}
