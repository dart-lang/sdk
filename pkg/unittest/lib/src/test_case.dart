// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of unittest;

/// Represents the state for an individual unit test.
///
/// Create by calling [test] or [solo_test].
class TestCase {
  /// Identifier for this test.
  final int id;

  /// A description of what the test is specifying.
  final String description;

  /// The setup function to call before the test, if any.
  Function _setUp;

  /// The teardown function to call after the test, if any.
  Function _tearDown;

  /// The body of the test case.
  TestFunction _testFunction;

  /// Remaining number of callbacks functions that must reach a 'done' state
  /// to wait for before the test completes.
  int _callbackFunctionsOutstanding = 0;

  String _message = '';
  /// Error or failure message.
  String get message => _message;

  String _result;
  /// One of [PASS], [FAIL], [ERROR], or [:null:] if the test hasn't run yet.
  String get result => _result;

  /// Returns whether this test case passed.
  bool get passed => _result == PASS;

  StackTrace _stackTrace;
  /// Stack trace associated with this test, or [:null:] if it succeeded.
  StackTrace get stackTrace => _stackTrace;

  /// The group (or groups) under which this test is running.
  final String currentGroup;

  DateTime _startTime;
  DateTime get startTime => _startTime;

  Duration _runningTime;
  Duration get runningTime => _runningTime;

  bool _enabled = true;

  bool get enabled => _enabled;

  bool _doneTeardown = false;

  Completer _testComplete;

  TestCase._internal(this.id, this.description, this._testFunction)
      : currentGroup = _currentContext.fullName,
        _setUp = _currentContext.testSetup,
        _tearDown = _currentContext.testTeardown;

  bool get isComplete => !enabled || result != null;

  Function _errorHandler(String stage) => (e, stack) {
    if (stack == null && e is Error) {
      stack = e.stackTrace;
    }
    if (result == null || result == PASS) {
      if (e is TestFailure) {
        _fail("$e", stack);
      } else {
        _error("$stage failed: Caught $e", stack);
      }
    }
  };

  /// Perform any associated [_setUp] function and run the test. Returns
  /// a [Future] that can be used to schedule the next test. If the test runs
  /// to completion synchronously, or is disabled, null is returned, to
  /// tell unittest to schedule the next test immediately.
  Future _run() {
    if (!enabled) return new Future.value();

    _result = _stackTrace = null;
    _message = '';

    // Avoid calling [new Future] to avoid issue 11911.
    return new Future.value().then((_) {
      if (_setUp != null) return _setUp();
    }).catchError(_errorHandler('Setup')).then((_) {
      // Skip the test if setup failed.
      if (result != null) return new Future.value();
      _config.onTestStart(this);
      _startTime = new DateTime.now();
      _runningTime = null;
      ++_callbackFunctionsOutstanding;
      var testReturn = _testFunction();
      // If _testFunction() returned a future, we want to wait for it like we
      // would a callback, so if a failure occurs while waiting, we can abort.
      if (testReturn is Future) {
        ++_callbackFunctionsOutstanding;
        testReturn.catchError(_errorHandler('Test'))
            .whenComplete(_markCallbackComplete);
      }
    }).catchError(_errorHandler('Test')).then((_) {
      _markCallbackComplete();
      if (result == null) {
        // Outstanding callbacks exist; we need to return a Future.
        _testComplete = new Completer();
        return _testComplete.future.whenComplete(() {
          if (_tearDown != null) {
            return _tearDown();
          }
        }).catchError(_errorHandler('Teardown'));
      } else if (_tearDown != null) {
        return _tearDown();
      }
    }).catchError(_errorHandler('Teardown')).whenComplete(() {
      _setUp = null;
      _tearDown = null;
      _testFunction = null;
    });
  }

  // Set the results, notify the config, and return true if this
  // is the first time the result is being set.
  void _setResult(String testResult, String messageText, StackTrace stack) {
    _message = messageText;
    _stackTrace = getTrace(stack, formatStacks, filterStacks);
    if (_stackTrace == null) _stackTrace = stack;
    if (result == null) {
      _result = testResult;
      _config.onTestResult(this);
    } else {
      _result = testResult;
      _config.onTestResultChanged(this);
    }
  }

  void _complete(String testResult, [String messageText = '',
      StackTrace stack]) {
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
    if (_testComplete != null) {
      var t = _testComplete;
      _testComplete = null;
      t.complete(this);
    }
  }

  void _pass() {
    _complete(PASS);
  }

  void _fail(String messageText, [StackTrace stack]) {
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

  void _error(String messageText, [StackTrace stack]) {
    _complete(ERROR, messageText, stack);
  }

  void _markCallbackComplete() {
    if (--_callbackFunctionsOutstanding == 0 && !isComplete) {
      _pass();
    }
  }

  String toString() => _result != null ? "$description: $result" : description;
}
