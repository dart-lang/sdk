// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of unittest;

/**
 * Represents the state for an individual unit test.
 *
 * Create by calling [test] or [solo_test].
 */
class TestCase {
  /** Identifier for this test. */
  final int id;

  /** A description of what the test is specifying. */
  final String description;

  /** The setup function to call before the test, if any. */
  Function setUp;

  /** The teardown function to call after the test, if any. */
  Function tearDown;

  /** The body of the test case. */
  TestFunction testFunction;

  /**
   * Remaining number of callbacks functions that must reach a 'done' state
   * to wait for before the test completes.
   */
  int _callbackFunctionsOutstanding = 0;

  String _message = '';
  /** Error or failure message. */
  String get message => _message;

  String _result;
  /**
   * One of [PASS], [FAIL], [ERROR], or [null] if the test hasn't run yet.
   */
  String get result => _result;

  String _stackTrace;
  /** Stack trace associated with this test, or [null] if it succeeded. */
  String get stackTrace => _stackTrace;

  /** The group (or groups) under which this test is running. */
  final String currentGroup;

  DateTime _startTime;
  DateTime get startTime => _startTime;

  Duration _runningTime;
  Duration get runningTime => _runningTime;

  bool enabled = true;

  bool _doneTeardown = false;

  Completer _testComplete;

  TestCase._internal(this.id, this.description, this.testFunction)
  : currentGroup = _currentContext.fullName,
    setUp = _currentContext.testSetup,
    tearDown = _currentContext.testTeardown;

  bool get isComplete => !enabled || result != null;

  void _prepTest() {
    _config.onTestStart(this);
    _startTime = new DateTime.now();
    _runningTime = null;
  }

  Future _runTest() {
    _prepTest();
    // Increment/decrement callbackFunctionsOutstanding to prevent
    // synchronous 'async' callbacks from causing the  test to be
    // marked as complete before the body is completely executed.
    ++_callbackFunctionsOutstanding;
    var f = testFunction();
    --_callbackFunctionsOutstanding;
    if (f is Future) {
      return f.then((_) => _finishTest())
       .catchError((error) => fail("${error}"));
    } else {
      _finishTest();
      return null;
    }
  }

  void _finishTest() {
    if (result == null && _callbackFunctionsOutstanding == 0) {
      pass();
    }
  }

  /**
   * Perform any associated [_setUp] function and run the test. Returns
   * a [Future] that can be used to schedule the next test. If the test runs
   * to completion synchronously, or is disabled, null is returned, to
   * tell unittest to schedule the next test immediately.
   */
  Future _run() {
    if (!enabled) return null;

    _result = _stackTrace = null;
    _message = '';
    _doneTeardown = false;
    var rtn = setUp == null ? null : setUp();
    if (rtn is Future) {
      rtn.then((_) => _runTest())
         .catchError((e) {
          _prepTest();
          // Calling error() will result in the tearDown being done.
          // One could debate whether tearDown should be done after
          // a failed setUp. There is no right answer, but doing it
          // seems to be the more conservative approach, because
          // unittest will not stop at a test failure.
          error("$description: Test setup failed: $e");
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
    _message = messageText;
    _stackTrace = stack;
    if (result == null) {
      _result = testResult;
      _config.onTestResult(this);
    } else {
      _result = testResult;
      _config.onTestResultChanged(this);
    }
  }

  void _complete(String testResult,
                [String messageText = '',
                 String stack = '']) {
    if (runningTime == null) {
      // The startTime can be `null` if an error happened during setup. In this
      // case we simply report a running time of 0.
      if (startTime != null) {
        _runningTime = new DateTime.now().difference(startTime);
      } else {
        _runningTime = const Duration(seconds: 0);
      }
    }
    _setResult(testResult, messageText, stack);
    if (!_doneTeardown) {
      _doneTeardown = true;
      if (tearDown != null) {
        var rtn = tearDown();
        if (rtn is Future) {
          rtn.then((_) {
            _notifyComplete();
          })
          .catchError((error) {
            var trace = getAttachedStackTrace(error);
            // We don't call fail() as that will potentially result in
            // spurious messages like 'test failed more than once'.
            _setResult(ERROR, "$description: Test teardown failed: ${error}",
                trace == null ? "" : trace.toString());
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

  void _markCallbackComplete() {
    if (--_callbackFunctionsOutstanding == 0 && !isComplete) {
      pass();
    }
  }
}
