// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A library for writing dart unit tests.
 *
 * To import this library, specify the relative path to
 * lib/unittest/unittest.dart.
 *
 * ##Concepts##
 *
 *  * Tests: Tests are specified via the top-level function [test], they can be
 *    organized together using [group].
 *  * Checks: Test expectations can be specified via [expect]
 *  * Matchers: [expect] assertions are written declaratively using [Matcher]s
 *  * Configuration: The framework can be adapted by calling [configure] with a
 *    [Configuration].  Common configurations can be found in this package
 *    under: 'dom\_config.dart' (deprecated), 'html\_config.dart' (for running
 *    tests compiled to Javascript in a browser), and 'vm\_config.dart' (for
 *    running native Dart tests on the VM).
 *
 * ##Examples##
 *
 * A trivial test:
 *
 *     #import('path-to-dart/lib/unittest/unitest.dart');
 *     main() {
 *       test('this is a test', () {
 *         int x = 2 + 3;
 *         expect(x, equals(5));
 *       });
 *     }
 *
 * Multiple tests:
 *
 *     #import('path-to-dart/lib/unittest/unitest.dart');
 *     main() {
 *       test('this is a test', () {
 *         int x = 2 + 3;
 *         expect(x, equals(5));
 *       });
 *       test('this is another test', () {
 *         int x = 2 + 3;
 *         expect(x, equals(5));
 *       });
 *     }
 *
 * Multiple tests, grouped by category:
 *
 *     #import('path-to-dart/lib/unittest/unitest.dart');
 *     main() {
 *       group('group A', () {
 *         test('test A.1', () {
 *           int x = 2 + 3;
 *           expect(x, equals(5));
 *         });
 *         test('test A.2', () {
 *           int x = 2 + 3;
 *           expect(x, equals(5));
 *         });
 *       });
 *       group('group B', () {
 *         test('this B.1', () {
 *           int x = 2 + 3;
 *           expect(x, equals(5));
 *         });
 *       });
 *     }
 *
 * Asynchronous tests: if callbacks expect between 0 and 2 positional arguments,
 * depending on the suffix of expectAsyncX(). expectAsyncX() will wrap a
 * function into a new callback and will not consider the test complete until
 * that callback is run. A count argument can be provided to specify the number
 * of times the callback should be called (the default is 1).
 *
 *     #import('path-to-dart/lib/unittest/unitest.dart');
 *     #import('dart:dom_deprecated');
 *     main() {
 *       test('calllback is executed once', () {
 *         // wrap the callback of an asynchronous call with [expectAsync0] if
 *         // the callback takes 0 arguments...
 *         window.setTimeout(expectAsync0(() {
 *           int x = 2 + 3;
 *           expect(x, equals(5));
 *         }), 0);
 *       });
 *
 *       test('calllback is executed twice', () {
 *         var callback = expectAsync0(() {
 *           int x = 2 + 3;
 *           expect(x, equals(5));
 *         }, count: 2); // <-- we can indicate multiplicity to [expectAsync0]
 *         window.setTimeout(callback, 0);
 *         window.setTimeout(callback, 0);
 *       });
 *     }
 *
 * expectAsyncX() will wrap the callback code in a try/catch handler to handle
 * exceptions (treated as test failures). There may be times when the number of
 * times a callback should be called is non-deterministic. In this case a dummy
 * callback can be created with expectAsync0((){}) and this can be called from
 * the real callback when it is finally complete. In this case the body of the
 * callback should be protected within a call to guardAsync(); this will ensure
 * that exceptions are properly handled.
 *
 * Note: due to some language limitations we have to use different functions
 * depending on the number of positional arguments of the callback. In the
 * future, we plan to expose a single `expectAsync` function that can be used
 * regardless of the number of positional arguments. This requires new langauge
 * features or fixes to the current spec (e.g. see
 * [Issue 2706](http://dartbug.com/2706)).
 *
 * Meanwhile, we plan to add this alternative API for callbacks of more than 2
 * arguments or that take named parameters. (this is not implemented yet,
 * but will be coming here soon).
 *
 *     #import('path-to-dart/lib/unittest/unitest.dart');
 *     #import('dart:dom_deprecated');
 *     main() {
 *       test('calllback is executed', () {
 *         // indicate ahead of time that an async callback is expected.
 *         var async = startAsync();
 *         window.setTimeout(() {
 *           // Guard the body of the callback, so errors are propagated
 *           // correctly
 *           guardAsync(() {
 *             int x = 2 + 3;
 *             expect(x, equals(5));
 *           });
 *           // indicate that the asynchronous callback was invoked.
 *           async.complete();
 *         }), 0);
 *       });
 *
 */
#library('unittest');

#import('dart:isolate');

#source('collection_matchers.dart');
#source('config.dart');
#source('core_matchers.dart');
#source('description.dart');
#source('expect.dart');
#source('future_matchers.dart');
#source('interfaces.dart');
#source('map_matchers.dart');
#source('matcher.dart');
#source('numeric_matchers.dart');
#source('operator_matchers.dart');
#source('string_matchers.dart');
#source('test_case.dart');

/** [Configuration] used by the unittest library. */
Configuration _config = null;

/** Set the [Configuration] used by the unittest library. */
void configure(Configuration config) {
  _config = config;
}

/**
 * Description text of the current test group. If multiple groups are nested,
 * this will contain all of their text concatenated.
 */
String _currentGroup = '';

/** Tests executed in this suite. */
List<TestCase> _tests;

/**
 * Callback used to run tests. Entrypoints can replace this with their own
 * if they want.
 */
Function _testRunner;

/** Current test being executed. */
int _currentTest = 0;

/** Total number of callbacks that have been executed in the current test. */
int _callbacksCalled = 0;

final _UNINITIALIZED = 0;
final _READY         = 1;
final _RUNNING_TEST  = 2;

/**
 * Whether an undetected error occurred while running the last test. These
 * errors are commonly caused by DOM callbacks that were not guarded in a
 * try-catch block.
 */
final _UNCAUGHT_ERROR = 3;

int _state = _UNINITIALIZED;
String _uncaughtErrorMessage = null;

final _PASS  = 'pass';
final _FAIL  = 'fail';
final _ERROR = 'error';

/** If set, then all other test cases will be ignored. */
TestCase _soloTest;

/**
 * (Deprecated) Evaluates the [function] and validates that it throws an
 * exception. If [callback] is provided, then it will be invoked with the
 * thrown exception. The callback may do any validation it wants. In addition,
 * if it returns `false`, that also indicates an expectation failure.
 */
void expectThrow(function, [bool callback(exception)]) {
  bool threw = false;
  try {
    function();
  } catch (var e) {
    threw = true;

    // Also let the callback look at it.
    if (callback != null) {
      var result = callback(e);

      // If the callback explicitly returned false, treat that like an
      // expectation too. (If it returns null, though, don't.)
      if (result == false) {
        _fail('Exception:\n$e\ndid not match expectation.');
      }
    }
  }

  if (threw != true) _fail('An expected exception was not thrown.');
}

/**
 * Creates a new test case with the given description and body. The
 * description will include the descriptions of any surrounding group()
 * calls.
 */
void test(String spec, TestFunction body) {
  ensureInitialized();

  _tests.add(new TestCase(_tests.length + 1, _fullSpec(spec), body, 0));
}

/**
 * (Deprecated) Creates a new async test case with the given description
 * and body. The description will include the descriptions of any surrounding
 * group() calls.
 */
// TODO(sigmund): deprecate this API
void asyncTest(String spec, int callbacks, TestFunction body) {
  ensureInitialized();

  final testCase = new TestCase(
      _tests.length + 1, _fullSpec(spec), body, callbacks);
  _tests.add(testCase);

  if (callbacks < 1) {
    testCase.error(
        'Async tests must wait for at least one callback ', '');
  }
}

/**
 * Creates a new test case with the given description and body. The
 * description will include the descriptions of any surrounding group()
 * calls.
 *
 * "solo_" means that this will be the only test that is run. All other tests
 * will be skipped. This is a convenience function to let you quickly isolate
 * a single test by adding "solo_" before it to temporarily disable all other
 * tests.
 */
void solo_test(String spec, TestFunction body) {
  // TODO(rnystrom): Support multiple solos. If more than one test is solo-ed,
  // all of the solo-ed tests and none of the non-solo-ed ones should run.
  if (_soloTest != null) {
    throw new Exception('Only one test can be soloed right now.');
  }

  ensureInitialized();

  _soloTest = new TestCase(_tests.length + 1, _fullSpec(spec), body, 0);
  _tests.add(_soloTest);
}

/** Sentinel value for [_SpreadArgsHelper]. */
class _Sentinel {
  const _Sentinel();
}

// TODO(sigmund): make a singleton const field when frog supports passing those
// as default values to named arguments.
final _sentinel = const _Sentinel();

/** Simulates spread arguments using named arguments. */
// TODO(sigmund): remove this class and simply use a closure with named
// arguments (if still applicable).
class _SpreadArgsHelper {
  Function _callback;
  int _expectedCalls;
  int _calls = 0;
  TestCase _testCase;
  Function _shouldCallBack;
  Function _isDone;

  _init(Function callback, Function shouldCallBack, Function isDone,
       [expectedCalls = 0]) {
    assert(_currentTest < _tests.length);
    _callback = callback;
    _shouldCallBack = shouldCallBack;
    _isDone = isDone;
    _expectedCalls = expectedCalls;
    _testCase = _tests[_currentTest];
    if (expectedCalls > 0) {
      _testCase.callbacks++;
    }
  }

  _SpreadArgsHelper(callback, shouldCallBack, isDone) {
    _init(callback, shouldCallBack, isDone);
  }

  _SpreadArgsHelper.fixedCallCount(callback, expectedCalls) {
    _init(callback, _checkCallCount, _allCallsDone, expectedCalls);
  }

  _SpreadArgsHelper.variableCallCount(callback, isDone) {
    _init(callback, _always, isDone);
  }

  _after() {
    if (_isDone()) {
      _handleAllCallbacksDone();
    }
  }

  _allCallsDone() => _calls == _expectedCalls;

  _always() {
    // Always run except if the test is done.
    if (_testCase.isComplete) {
      _testCase.error(
          'Callback called after already being marked as done ($_calls)',
          '');
      _state = _UNCAUGHT_ERROR;
      return false;
    } else {
      return true;
    }
  }

  invoke([arg0 = _sentinel, arg1 = _sentinel, arg2 = _sentinel,
          arg3 = _sentinel, arg4 = _sentinel]) {
    return guardAsync(() {
      ++_calls;
      if (!_shouldCallBack()) {
        return;
      } else if (arg0 == _sentinel) {
        return _callback();
      } else if (arg1 == _sentinel) {
        return _callback(arg0);
      } else if (arg2 == _sentinel) {
        return _callback(arg0, arg1);
      } else if (arg3 == _sentinel) {
        return _callback(arg0, arg1, arg2);
      } else if (arg4 == _sentinel) {
        return _callback(arg0, arg1, arg2, arg3);
      } else {
        _testCase.error(
           'unittest lib does not support callbacks with more than 4 arguments',
           '');
        _state = _UNCAUGHT_ERROR;
      }
    },
    _after);
  }

  invoke0() {
    return guardAsync(
        () {
          ++_calls;
          if (_shouldCallBack()) {
            return _callback();
          }
        },
        _after);
  }

  invoke1(arg1) {
    return guardAsync(
        () {
          ++_calls;
          if (_shouldCallBack()) {
            return _callback(arg1);
          }
        },
        _after);
  }

  invoke2(arg1, arg2) {
    return guardAsync(
        () {
          ++_calls;
          if (_shouldCallBack()) {
            return _callback(arg1, arg2);
          }
        },
        _after);
  }

  /** Returns false if we exceded the number of expected calls. */
  bool _checkCallCount() {
    if (_calls > _expectedCalls) {
      _testCase.error(
          'Callback called more times than expected '
             '($_calls > $_expectedCalls)',
          '');
      _state = _UNCAUGHT_ERROR;
      return false;
    }
    return true;
  }
}

/**
 * Indicate that [callback] is expected to be called a [count] number of times
 * (by default 1). The unittest framework will wait for the callback to run the
 * specified [count] times before it continues with the following test.  Using
 * [_expectAsync] will also ensure that errors that occur within [callback] are
 * tracked and reported. [callback] should take between 0 and 4 positional
 * arguments (named arguments are not supported here).
 */
Function _expectAsync(Function callback, [int count = 1]) {
  return new _SpreadArgsHelper.fixedCallCount(callback, count).invoke;
}

/**
 * Indicate that [callback] is expected to be called a [count] number of times
 * (by default 1). The unittest framework will wait for the callback to run the
 * specified [count] times before it continues with the following test.  Using
 * [expectAsync0] will also ensure that errors that occur within [callback] are
 * tracked and reported. [callback] should take 0 positional arguments (named
 * arguments are not supported).
 */
// TODO(sigmund): deprecate this API when issue 2706 is fixed.
Function expectAsync0(Function callback, [int count = 1]) {
  return new _SpreadArgsHelper.fixedCallCount(callback, count).invoke0;
}

/** Like [expectAsync0] but [callback] should take 1 positional argument. */
// TODO(sigmund): deprecate this API when issue 2706 is fixed.
Function expectAsync1(Function callback, [int count = 1]) {
  return new _SpreadArgsHelper.fixedCallCount(callback, count).invoke1;
}

/** Like [expectAsync0] but [callback] should take 2 positional arguments. */
// TODO(sigmund): deprecate this API when issue 2706 is fixed.
Function expectAsync2(Function callback, [int count = 1]) {
  return new _SpreadArgsHelper.fixedCallCount(callback, count).invoke2;
}

/**
 * Indicate that [callback] is expected to be called until [isDone] returns
 * true. The unittest framework checks [isDone] after each callback and only
 * when it returns true will it continue with the following test. Using
 * [expectAsyncUntil] will also ensure that errors that occur within
 * [callback] are tracked and reported. [callback] should take between 0 and
 * 4 positional arguments (named arguments are not supported).
 */
Function _expectAsyncUntil(Function callback, Function isDone) {
  return new _SpreadArgsHelper.variableCallCount(callback, isDone).invoke;
}

/**
 * Indicate that [callback] is expected to be called until [isDone] returns
 * true. The unittest framework check [isDone] after each callback and only
 * when it returns true will it continue with the following test. Using
 * [expectAsyncUntil0] will also ensure that errors that occur within
 * [callback] are tracked and reported. [callback] should take 0 positional
 * arguments (named arguments are not supported).
 */
// TODO(sigmund): deprecate this API when issue 2706 is fixed.
Function expectAsyncUntil0(Function callback, Function isDone) {
  return new _SpreadArgsHelper.variableCallCount(callback, isDone).invoke0;
}

/**
 * Like [expectAsyncUntil0] but [callback] should take 1 positional argument.
 */
// TODO(sigmund): deprecate this API when issue 2706 is fixed.
Function expectAsyncUntil1(Function callback, Function isDone) {
  return new _SpreadArgsHelper.variableCallCount(callback, isDone).invoke1;
}

/**
 * Like [expectAsyncUntil0] but [callback] should take 2 positional arguments.
 */
// TODO(sigmund): deprecate this API when issue 2706 is fixed.
Function expectAsyncUntil2(Function callback, Function isDone) {
  return new _SpreadArgsHelper.variableCallCount(callback, isDone).invoke2;
}

/**
 * Creates a new named group of tests. Calls to group() or test() within the
 * body of the function passed to this will inherit this group's description.
 */
void group(String description, void body()) {
  ensureInitialized();

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

/** Called by subclasses to indicate that an asynchronous test completed. */
void _handleAllCallbacksDone() {
  // TODO (gram): we defer this to give the nextBatch recursive
  // stack a chance to unwind. This is a temporary hack but
  // really a bunch of code here needs to be fixed. We have a
  // single array that is being iterated through by nextBatch(),
  // which is recursively invoked in the case of async tests that
  // run synchronously. Bad things can then happen.
  _defer(() {
    _callbacksCalled++;
    if (_currentTest < _tests.length) {
      final testCase = _tests[_currentTest];
      if (_callbacksCalled > testCase.callbacks) {
        final expected = testCase.callbacks;
        testCase.error(
            'More calls to callbackDone() than expected. '
            'Actual: ${_callbacksCalled}, expected: ${expected}', '');
        _state = _UNCAUGHT_ERROR;
      } else if ((_callbacksCalled == testCase.callbacks) &&
          (_state != _RUNNING_TEST)) {
        if (testCase.result == null) {
          testCase.pass();
        }
        _currentTest++;
        _testRunner();
      }
    }
  });
}

/**
 * Temporary hack: expose old API.
 * TODO(gram) remove this when WebKit tests are working with new framework
 */
void callbackDone() { _handleAllCallbacksDone(); }

/**
 * Utility function that can be used to notify the test framework that an
 *  error was caught outside of this library.
 */
void reportTestError(String msg, String trace) {
 if (_currentTest < _tests.length) {
    final testCase = _tests[_currentTest];
    testCase.error(msg, trace);
    _state = _UNCAUGHT_ERROR;
    if (testCase.callbacks > 0) {
      _currentTest++;
      _testRunner();
    }
  } else {
    _uncaughtErrorMessage = "$msg: $trace";
  }
}

/** Runs [callback] at the end of the event loop. */
_defer(void callback()) {
  // Exploit isolate ports as a platform-independent mechanism to queue a
  // message at the end of the event loop.
  // TODO(sigmund): expose this functionality somewhere in our libraries.
  final port = new ReceivePort();
  port.receive((msg, reply) {
    callback();
    port.close();
  });
  port.toSendPort().send(null, null);
}

/** Runs all queued tests, one at a time. */
_runTests() {
  // If we are soloing a test, remove all the others.
  if (_soloTest != null) {
    _tests = _tests.filter((t) => t == _soloTest);
  }

  _config.onStart();

  _defer(() {
    assert (_currentTest == 0);
    _testRunner();
  });
}

/**
 * Run [tryBody] guarded in a try-catch block. If an exception is thrown, update
 * the [_currentTest] status accordingly.
 */
guardAsync(tryBody, [finallyBody]) {
  try {
    return tryBody();
  } catch (ExpectException e, var trace) {
    Expect.isTrue(_currentTest < _tests.length);
    if (_state != _UNCAUGHT_ERROR) {
      _tests[_currentTest].fail(e.message,
          trace == null ? '' : trace.toString());
    }
  } catch (var e, var trace) {
    if (_state == _RUNNING_TEST) {
      // If a random exception is thrown from within a test, we consider that
      // a test failure too. A test case implicitly has an expectation that it
      // will run to completion without an uncaught exception being thrown.
      _tests[_currentTest].fail('Caught $e',
          trace == null ? '' : trace.toString());
    } else if (_state != _UNCAUGHT_ERROR) {
      _tests[_currentTest].error('Caught $e',
          trace == null ? '' : trace.toString());
    }
  } finally {
    _state = _READY;
    if (finallyBody != null) finallyBody();
  }
}

/**
 * Runs a batch of tests, yielding whenever an asynchronous test starts
 * running. Tests will resume executing when such asynchronous test calls
 * [done] or if it fails with an exception.
 */
_nextBatch() {
  while (_currentTest < _tests.length) {
    final testCase = _tests[_currentTest];
    guardAsync(() {
      _callbacksCalled = 0;
      _state = _RUNNING_TEST;
      testCase.test();

      if (_state != _UNCAUGHT_ERROR) {
        if (testCase.callbacks == _callbacksCalled) {
          testCase.pass();
        }
      }
    });

    if (!testCase.isComplete && testCase.callbacks > 0) return;

    _currentTest++;
  }

  _completeTests();
}

/** Publish results on the page and notify controller. */
_completeTests() {
  _state = _UNINITIALIZED;

  int testsPassed_ = 0;
  int testsFailed_ = 0;
  int testsErrors_ = 0;

  for (TestCase t in _tests) {
    switch (t.result) {
      case _PASS:  testsPassed_++; break;
      case _FAIL:  testsFailed_++; break;
      case _ERROR: testsErrors_++; break;
    }
  }

  _config.onDone(testsPassed_, testsFailed_, testsErrors_, _tests,
      _uncaughtErrorMessage);
}

String _fullSpec(String spec) {
  if (spec === null) return '$_currentGroup';
  return _currentGroup != '' ? '$_currentGroup $spec' : spec;
}

void _fail(String message) {
  throw new ExpectException(message);
}

/**
 * Lazily initializes the test library if not already initialized.
 */
ensureInitialized() {
  if (_state != _UNINITIALIZED) return;

  _tests = <TestCase>[];
  _uncaughtErrorMessage = null;
  _currentTest = 0;
  _currentGroup = '';
  _state = _READY;
  _testRunner = _nextBatch;

  if (_config == null) {
    _config = new Configuration();
  }
  _config.onInit();

  // Immediately queue the suite up. It will run after a timeout (i.e. after
  // main() has returned).
  _defer(_runTests);
}

/** Signature for a test function. */
typedef void TestFunction();

