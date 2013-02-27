// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A library for writing dart unit tests.
 *
 * To import this library, use the pub package manager.
 * Create a pubspec.yaml file in your project and add
 * a dependency on unittest with the following lines:
 *     dependencies:
 *       unittest: any
 *
 * Then run 'pub install' from your project directory or using
 * the DartEditor.
 *
 * Please see [Pub Getting Started](http://pub.dartlang.org/doc)
 * for more details about the pub package manager.
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
 *     import 'package:unittest/unittest.dart';
 *     main() {
 *       test('this is a test', () {
 *         int x = 2 + 3;
 *         expect(x, equals(5));
 *       });
 *     }
 *
 * Multiple tests:
 *
 *     import 'package:unittest/unittest.dart';
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
 *     import 'package:unittest/unittest.dart';
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
 *     import 'package:unittest/unittest.dart';
 *     import 'dart:isolate';
 *     main() {
 *       test('callback is executed once', () {
 *         // wrap the callback of an asynchronous call with [expectAsync0] if
 *         // the callback takes 0 arguments...
 *         var timer = Timer.run(expectAsync0(() {
 *           int x = 2 + 3;
 *           expect(x, equals(5));
 *         }));
 *       });
 *
 *       test('callback is executed twice', () {
 *         var callback = expectAsync0(() {
 *           int x = 2 + 3;
 *           expect(x, equals(5));
 *         }, count: 2); // <-- we can indicate multiplicity to [expectAsync0]
 *         Timer.run(callback);
 *         Timer.run(callback);
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
 * A variation on this is expectAsyncUntilX(), which takes a callback as the
 * first parameter and a predicate function as the second parameter; after each
 * time * the callback is called, the predicate function will be called; if it
 * returns false the test will still be considered incomplete.
 *
 * Test functions can return [Future]s, which provide another way of doing
 * asynchronous tests. The test framework will handle exceptions thrown by
 * the Future, and will advance to the next test when the Future is complete.
 * It is still important to use expectAsync/guardAsync with any parts of the
 * test that may be invoked from a top level context (for example, with
 * Timer.run()], as the Future exception handler may not capture exceptions
 * in such code.
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
 *     import 'package:unittest/unittest.dart';
 *     import 'dart:isolate';
 *     main() {
 *       test('callback is executed', () {
 *         // indicate ahead of time that an async callback is expected.
 *         var async = startAsync();
 *         Timer.run(() {
 *           // Guard the body of the callback, so errors are propagated
 *           // correctly.
 *           guardAsync(() {
 *             int x = 2 + 3;
 *             expect(x, equals(5));
 *           });
 *           // indicate that the asynchronous callback was invoked.
 *           async.complete();
 *         });
 *       });
 *     }
 *
 */
library unittest;

import 'dart:async';
import 'dart:isolate';
import 'matcher.dart';
export 'matcher.dart';

// TODO(amouravski): We should not need to import mock here, but it's necessary
// to enable dartdoc on the mock library, as it's not picked up normally.
import 'mock.dart';

part 'src/config.dart';
part 'src/test_case.dart';

/** [Configuration] used by the unittest library. */
Configuration _config = null;

Configuration get config => _config;

/**
 * Set the [Configuration] used by the unittest library. Returns any
 * previous configuration.
 * TODO: consider deprecating in favor of a setter now we have a getter.
 */
Configuration configure(Configuration config) {
  Configuration _oldConfig = _config;
  _config = config;
  return _oldConfig;
}

void logMessage(String message) => _config.logMessage(message);

/**
 * Description text of the current test group. If multiple groups are nested,
 * this will contain all of their text concatenated.
 */
String _currentGroup = '';

/** Separator used between group names and test names. */
String groupSep = ' ';

/** Tests executed in this suite. */
List<TestCase> _tests;

/** Get the list of tests. */
get testCases => _tests;

/**
 * Callback used to run tests. Entrypoints can replace this with their own
 * if they want.
 */
Function _testRunner;

/** Setup function called before each test in a group */
Function _testSetup;

/** Teardown function called after each test in a group */
Function _testTeardown;

/** Current test being executed. */
int _currentTest = 0;

/** Whether the framework is in an initialized state. */
bool _initialized = false;

String _uncaughtErrorMessage = null;

/** Test case result strings. */
// TODO(gram) we should change these constants to use a different string
// (so that writing 'FAIL' in the middle of a test doesn't
// imply that the test fails). We can't do it without also changing
// the testrunner and test.dart though.
const PASS  = 'pass';
const FAIL  = 'fail';
const ERROR = 'error';

/** If set, then all other test cases will be ignored. */
TestCase _soloTest;

/**
 * A map that can be used to communicate state between a test driver
 * or main() function and the tests, particularly when these two
 * are otherwise independent. For example, a test driver that starts
 * an HTTP server and then runs tests that access that server could use
 * this as a way of communicating the server port to the tests.
 */
Map testState = {};

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

/** Simulates spread arguments using named arguments. */
// TODO(sigmund): remove this class and simply use a closure with named
// arguments (if still applicable).
class _SpreadArgsHelper {
  Function _callback;
  int _expectedCalls;
  int _actualCalls = 0;
  int _testNum;
  TestCase _testCase;
  Function _shouldCallBack;
  Function _isDone;
  String _id;
  static const _sentinel = const _Sentinel();

  _init(Function callback, Function shouldCallBack, Function isDone,
       [expectedCalls = 0]) {
    ensureInitialized();
    if (!(_currentTest >= 0 &&
           _currentTest < _tests.length &&
           _tests[_currentTest] != null)) {
      print("No valid test, did you forget to run your test inside a call "
          "to test()?");
    }
    assert(_currentTest >= 0 &&
           _currentTest < _tests.length &&
           _tests[_currentTest] != null);
    _callback = callback;
    _shouldCallBack = shouldCallBack;
    _isDone = isDone;
    _expectedCalls = expectedCalls;
    _testNum = _currentTest;
    _testCase = _tests[_currentTest];
    if (expectedCalls > 0) {
      _testCase.callbackFunctionsOutstanding++;
    }
    _id = '';
    // If the callback is not an anonymous closure, try to get the
    // name.
    var fname = callback.toString();
    var prefix = "Function '";
    var pos = fname.indexOf(prefix);
    if (pos > 0) {
      pos += prefix.length;
      var epos = fname.indexOf("'", pos);
      if (epos > 0) {
        _id = "${fname.substring(pos, epos)} ";
      }
    }
  }

  _SpreadArgsHelper(callback, shouldCallBack, isDone) {
    _init(callback, shouldCallBack, isDone);
  }

  _SpreadArgsHelper.fixedCallCount(callback, expectedCalls, id) {
    _init(callback, _checkCallCount, _allCallsDone, expectedCalls);
    if (id != null) {
      _id = "$id ";
    }
  }

  _SpreadArgsHelper.variableCallCount(callback, isDone) {
    _init(callback, _always, isDone, 1);
   }

  _SpreadArgsHelper.optionalCalls(callback) {
    _init(callback, _always, () => false, 0);
   }

  _after() {
    if (_isDone()) {
      _handleCallbackFunctionComplete(_testNum, _id);
    }
  }

  _allCallsDone() => _actualCalls == _expectedCalls;

  _always() {
    // Always run except if the test is done.
    if (_testCase.isComplete) {
      _testCase.error(
          'Callback ${_id}called after already being marked '
          'as done ($_actualCalls).',
          '');
      return false;
    } else {
      return true;
    }
  }

  invoke([arg0 = _sentinel, arg1 = _sentinel, arg2 = _sentinel,
          arg3 = _sentinel, arg4 = _sentinel]) {
    return guardAsync(() {
      ++_actualCalls;
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
           'unittest lib does not support callbacks with more than'
              ' 4 arguments.',
           '');
      }
    },
    _after, _testNum);
  }

  invoke0() {
    return guardAsync(
        () {
          ++_actualCalls;
          if (_shouldCallBack()) {
            return _callback();
          }
        },
        _after, _testNum);
  }

  invoke1(arg1) {
    return guardAsync(
        () {
          ++_actualCalls;
          if (_shouldCallBack()) {
            return _callback(arg1);
          }
        },
        _after, _testNum);
  }

  invoke2(arg1, arg2) {
    return guardAsync(
        () {
          ++_actualCalls;
          if (_shouldCallBack()) {
            return _callback(arg1, arg2);
          }
        },
        _after, _testNum);
  }

  /** Returns false if we exceded the number of expected calls. */
  bool _checkCallCount() {
    if (_actualCalls > _expectedCalls) {
      _testCase.error('Callback ${_id}called more times than expected '
             '($_actualCalls > $_expectedCalls).', '');
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
 * arguments (named arguments are not supported here). [id] can be used
 * to provide more descriptive error messages if the callback is called more
 * often than expected.
 */
Function _expectAsync(Function callback, {int count: 1, String id}) {
  return new _SpreadArgsHelper.
      fixedCallCount(callback, count, id).invoke;
}

/**
 * Indicate that [callback] is expected to be called a [count] number of times
 * (by default 1). The unittest framework will wait for the callback to run the
 * specified [count] times before it continues with the following test.  Using
 * [expectAsync0] will also ensure that errors that occur within [callback] are
 * tracked and reported. [callback] should take 0 positional arguments (named
 * arguments are not supported). [id] can be used to provide more
 * descriptive error messages if the callback is called more often than
 * expected.
 */
// TODO(sigmund): deprecate this API when issue 2706 is fixed.
Function expectAsync0(Function callback, {int count: 1, String id}) {
  return new _SpreadArgsHelper.
      fixedCallCount(callback, count, id).invoke0;
}

/** Like [expectAsync0] but [callback] should take 1 positional argument. */
// TODO(sigmund): deprecate this API when issue 2706 is fixed.
Function expectAsync1(Function callback, {int count: 1, String id}) {
  return new _SpreadArgsHelper.
      fixedCallCount(callback, count, id).invoke1;
}

/** Like [expectAsync0] but [callback] should take 2 positional arguments. */
// TODO(sigmund): deprecate this API when issue 2706 is fixed.
Function expectAsync2(Function callback, {int count: 1, String id}) {
  return new _SpreadArgsHelper.
      fixedCallCount(callback, count, id).invoke2;
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
 * Wraps the [callback] in a new function and returns that function. The new
 * function will be able to handle exceptions by directing them to the correct
 * test. This is thus similar to expectAsync0. Use it to wrap any callbacks that
 * might optionally be called but may never be called during the test.
 * [callback] should take between 0 and 4 positional arguments (named arguments
 * are not supported).
 */
Function _protectAsync(Function callback) {
  return new _SpreadArgsHelper.optionalCalls(callback).invoke;
}

/**
 * Wraps the [callback] in a new function and returns that function. The new
 * function will be able to handle exceptions by directing them to the correct
 * test. This is thus similar to expectAsync0. Use it to wrap any callbacks that
 * might optionally be called but may never be called during the test.
 * [callback] should take 0 positional arguments (named arguments are not
 * supported).
 */
// TODO(sigmund): deprecate this API when issue 2706 is fixed.
Function protectAsync0(Function callback) {
  return new _SpreadArgsHelper.optionalCalls(callback).invoke0;
}

/**
 * Like [protectAsync0] but [callback] should take 1 positional argument.
 */
// TODO(sigmund): deprecate this API when issue 2706 is fixed.
Function protectAsync1(Function callback) {
  return new _SpreadArgsHelper.optionalCalls(callback).invoke1;
}

/**
 * Like [protectAsync0] but [callback] should take 2 positional arguments.
 */
// TODO(sigmund): deprecate this API when issue 2706 is fixed.
Function protectAsync2(Function callback) {
  return new _SpreadArgsHelper.optionalCalls(callback).invoke2;
}

/**
 * Creates a new named group of tests. Calls to group() or test() within the
 * body of the function passed to this will inherit this group's description.
 */
void group(String description, void body()) {
  ensureInitialized();
  // Concatenate the new group.
  final parentGroup = _currentGroup;
  if (_currentGroup != '') {
    // Add a space.
    _currentGroup = '$_currentGroup$groupSep$description';
  } else {
    // The first group.
    _currentGroup = description;
  }

  // Groups can be nested, so we need to preserve the current
  // settings for test setup/teardown.
  Function parentSetup = _testSetup;
  Function parentTeardown = _testTeardown;

  try {
    _testSetup = null;
    _testTeardown = null;
    body();
  } catch (e, trace) {
    var stack = (trace == null) ? '' : ': ${trace.toString()}';
    _uncaughtErrorMessage = "${e.toString()}$stack";
  } finally {
    // Now that the group is over, restore the previous one.
    _currentGroup = parentGroup;
    _testSetup = parentSetup;
    _testTeardown = parentTeardown;
  }
}

/**
 * Register a [setUp] function for a test [group]. This function will
 * be called before each test in the group is run. Note that if groups
 * are nested only the most locally scoped [setUpTest] function will be run.
 * [setUp] and [tearDown] should be called within the [group] before any
 * calls to [test]. The [setupTest] function can be asynchronous; in this
 * case it must return a [Future].
 */
void setUp(Function setupTest) {
  _testSetup = setupTest;
}

/**
 * Register a [tearDown] function for a test [group]. This function will
 * be called after each test in the group is run. Note that if groups
 * are nested only the most locally scoped [teardownTest] function will be run.
 * [setUp] and [tearDown] should be called within the [group] before any
 * calls to [test]. The [teardownTest] function can be asynchronous; in this
 * case it must return a [Future].
 */
void tearDown(Function teardownTest) {
  _testTeardown = teardownTest;
}

/**
 * Called when one of the callback functions is done with all expected
 * calls.
 */
void _handleCallbackFunctionComplete(testNum, [id = '']) {
  // TODO (gram): we defer this to give the nextBatch recursive
  // stack a chance to unwind. This is a temporary hack but
  // really a bunch of code here needs to be fixed. We have a
  // single array that is being iterated through by nextBatch(),
  // which is recursively invoked in the case of async tests that
  // run synchronously. Bad things can then happen.
  _defer(() {
    if (_currentTest != testNum) {
      if (_tests[testNum].result == PASS) {
        _tests[testNum].error("${id}Unexpected extra callbacks", '');
      }
    } else if (_currentTest < _tests.length) {
      final testCase = _tests[_currentTest];
      --testCase.callbackFunctionsOutstanding;
      if (testCase.callbackFunctionsOutstanding < 0) {
        // TODO(gram): Check: Can this even happen?
        testCase.error(
            'More calls to _handleCallbackFunctionComplete() than expected.',
             '');
      } else if (testCase.callbackFunctionsOutstanding == 0 &&
                 !testCase.isComplete) {
        testCase.pass();
      }
    }
  });
}

/** Advance to the next test case. */
void _nextTestCase() {
  _defer(() {
    _currentTest++;
    _testRunner();
  });
}

/**
 * Temporary hack: expose old API.
 * TODO(gram) remove this when WebKit tests are working with new framework
 */
void callbackDone() {
  _handleCallbackFunctionComplete(_currentTest);
}

/**
 * Utility function that can be used to notify the test framework that an
 *  error was caught outside of this library.
 */
void _reportTestError(String msg, String trace) {
 if (_currentTest < _tests.length) {
    final testCase = _tests[_currentTest];
    testCase.error(msg, trace);
  } else {
    _uncaughtErrorMessage = "$msg: $trace";
  }
}

/**
 * Runs [callback] at the end of the event loop. Note that we don't wrap
 * the callback in guardAsync; this is for test framework functions which
 * should not be throwing unexpected exceptions that end up failing test
 * cases! Furthermore, we need the final exception to be thrown but not
 * caught by the test framework if any test cases failed. However, tests
 * that make use of a similar defer function *should* wrap the callback
 * (as we do in unitttest_test.dart).
 */
_defer(void callback()) {
  (new Future.immediate(null)).then((_) => callback());
}

rerunTests() {
  _uncaughtErrorMessage = null;
  _initialized = true; // We don't want to reset the test array.
  runTests();
}

/**
 * Filter the tests. [testFilter] can be a [RegExp], a [String] or a
 * predicate function. This is different to enabling/disabling tests
 * in that it removes the tests completely.
 */
void filterTests(testFilter) {
  var filterFunction;
  if (testFilter is String) {
    RegExp re = new RegExp(testFilter);
    filterFunction = (t) => re.hasMatch(t.description);
  } else if (testFilter is RegExp) {
    filterFunction = (t) => testFilter.hasMatch(t.description);
  } else if (testFilter is Function) {
    filterFunction = testFilter;
  }
  _tests.retainMatching(filterFunction);
}

/** Runs all queued tests, one at a time. */
runTests() {
  _currentTest = 0;
  _currentGroup = '';

  // If we are soloing a test, remove all the others.
  if (_soloTest != null) {
    filterTests((t) => t == _soloTest);
  }

  _config.onStart();

  _defer(() {
    _testRunner();
  });
}

/**
 * Run [tryBody] guarded in a try-catch block. If an exception is thrown, update
 * the [_currentTest] status accordingly.
 */
guardAsync(tryBody, [finallyBody, testNum = -1]) {
  if (testNum < 0) testNum = _currentTest;
  try {
    return tryBody();
  } catch (e, trace) {
    _registerException(testNum, e, trace);
  } finally {
    if (finallyBody != null) finallyBody();
  }
}

/**
 * Registers that an exception was caught for the current test.
 */
registerException(e, [trace]) {
  _registerException(_currentTest, e, trace);
}

/**
 * Registers that an exception was caught for the current test.
 */
_registerException(testNum, e, [trace]) {
  trace = trace == null ? '' : trace.toString();
  if (_tests[testNum].result == null) {
    String message = (e is ExpectException) ? e.message : 'Caught $e';
    _tests[testNum].fail(message, trace);
  } else {
    _tests[testNum].error('Caught $e', trace);
  }
}

/**
 * Runs a batch of tests, yielding whenever an asynchronous test starts
 * running. Tests will resume executing when such asynchronous test calls
 * [done] or if it fails with an exception.
 */
_nextBatch() {
  while (true) {
    if (_currentTest >= _tests.length) {
      _completeTests();
      break;
    }
    final testCase = _tests[_currentTest];
    var f = guardAsync(testCase.run, null, _currentTest);
    if (f != null) {
      f.whenComplete(() {
        _nextTestCase(); // Schedule the next test.
      });
      break;
    }
    _currentTest++;
  }
}

/** Publish results on the page and notify controller. */
_completeTests() {
  if (!_initialized) return;
  int passed = 0;
  int failed = 0;
  int errors = 0;

  for (TestCase t in _tests) {
    switch (t.result) {
      case PASS:  passed++; break;
      case FAIL:  failed++; break;
      case ERROR: errors++; break;
    }
  }
  _config.onSummary(passed, failed, errors, _tests, _uncaughtErrorMessage);
  _config.onDone(passed > 0 && failed == 0 && errors == 0 &&
      _uncaughtErrorMessage == null);
  _initialized = false;
}

String _fullSpec(String spec) {
  if (spec == null) return '$_currentGroup';
  return _currentGroup != '' ? '$_currentGroup$groupSep$spec' : spec;
}

void fail(String message) {
  throw new ExpectException(message);
}

/**
 * Lazily initializes the test library if not already initialized.
 */
ensureInitialized() {
  if (_initialized) {
    return;
  }
  _initialized = true;
  // Hook our async guard into the matcher library.
  wrapAsync = expectAsync1;

  _tests = <TestCase>[];
  _testRunner = _nextBatch;
  _uncaughtErrorMessage = null;

  if (_config == null) {
    _config = new Configuration();
  }
  _config.onInit();

  if (_config.autoStart) {
    // Immediately queue the suite up. It will run after a timeout (i.e. after
    // main() has returned).
    _defer(runTests);
  }
}

/** Select a solo test by ID. */
void setSoloTest(int id) {
  for (var i = 0; i < _tests.length; i++) {
    if (_tests[i].id == id) {
      _soloTest = _tests[i];
      break;
    }
  }
}

/** Enable/disable a test by ID. */
void _setTestEnabledState(int testId, bool state) {
  // Try fast path first.
  if (_tests.length > testId && _tests[testId].id == testId) {
    _tests[testId].enabled = state;
  } else {
    for (var i = 0; i < _tests.length; i++) {
      if (_tests[i].id == testId) {
        _tests[i].enabled = state;
        break;
      }
    }
  }
}

/** Enable a test by ID. */
void enableTest(int testId) => _setTestEnabledState(testId, true);

/** Disable a test by ID. */
void disableTest(int testId) => _setTestEnabledState(testId, false);

/** Signature for a test function. */
typedef void TestFunction();
