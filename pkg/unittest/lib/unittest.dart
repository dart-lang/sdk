// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Support for writing Dart unit tests.
///
/// For information on installing and importing this library, see the
/// [unittest package on pub.dartlang.org]
/// (http://pub.dartlang.org/packages/unittest).
///
/// **See also:**
/// [Unit Testing with Dart]
/// (http://www.dartlang.org/articles/dart-unit-tests/)
///
/// ##Concepts
///
///  * __Tests__: Tests are specified via the top-level function [test], they can be
///    organized together using [group].
///
///  * __Checks__: Test expectations can be specified via [expect]
///
///  * __Matchers__: [expect] assertions are written declaratively using the
///    [Matcher] class.
///
///  * __Configuration__: The framework can be adapted by setting
///    [unittestConfiguration] with a [Configuration]. See the other libraries
///    in the `unittest` package for alternative implementations of
///    [Configuration] including `compact_vm_config.dart`, `html_config.dart`
///    and `html_enhanced_config.dart`.
///
/// ##Examples
///
/// A trivial test:
///
///     import 'package:unittest/unittest.dart';
///     main() {
///       test('this is a test', () {
///         int x = 2 + 3;
///         expect(x, equals(5));
///       });
///     }
///
/// Multiple tests:
///
///     import 'package:unittest/unittest.dart';
///     main() {
///       test('this is a test', () {
///         int x = 2 + 3;
///         expect(x, equals(5));
///       });
///       test('this is another test', () {
///         int x = 2 + 3;
///         expect(x, equals(5));
///       });
///     }
///
/// Multiple tests, grouped by category:
///
///     import 'package:unittest/unittest.dart';
///     main() {
///       group('group A', () {
///         test('test A.1', () {
///           int x = 2 + 3;
///           expect(x, equals(5));
///         });
///         test('test A.2', () {
///           int x = 2 + 3;
///           expect(x, equals(5));
///         });
///       });
///       group('group B', () {
///         test('this B.1', () {
///           int x = 2 + 3;
///           expect(x, equals(5));
///         });
///       });
///     }
///
/// Asynchronous tests: if callbacks expect between 0 and 6 positional
/// arguments, [expectAsync] will wrap a function into a new callback and will
/// not consider the test complete until that callback is run. A count argument
/// can be provided to specify the number of times the callback should be called
/// (the default is 1).
///
///     import 'dart:async';
///     import 'package:unittest/unittest.dart';
///     void main() {
///       test('callback is executed once', () {
///         // wrap the callback of an asynchronous call with [expectAsync] if
///         // the callback takes 0 arguments...
///         var timer = Timer.run(expectAsync(() {
///           int x = 2 + 3;
///           expect(x, equals(5));
///         }));
///       });
///
///       test('callback is executed twice', () {
///         var callback = expectAsync(() {
///           int x = 2 + 3;
///           expect(x, equals(5));
///         }, count: 2); // <-- we can indicate multiplicity to [expectAsync]
///         Timer.run(callback);
///         Timer.run(callback);
///       });
///     }
///
/// There may be times when the number of times a callback should be called is
/// non-deterministic. In this case a dummy callback can be created with
/// expectAsync((){}) and this can be called from the real callback when it is
/// finally complete.
///
/// A variation on this is [expectAsyncUntil], which takes a callback as the
/// first parameter and a predicate function as the second parameter. After each
/// time the callback is called, the predicate function will be called. If it
/// returns `false` the test will still be considered incomplete.
///
/// Test functions can return [Future]s, which provide another way of doing
/// asynchronous tests. The test framework will handle exceptions thrown by
/// the Future, and will advance to the next test when the Future is complete.
///
///     import 'dart:async';
///     import 'package:unittest/unittest.dart';
///     void main() {
///       test('test that time has passed', () {
///         var duration = const Duration(milliseconds: 200);
///         var time = new DateTime.now();
///
///         return new Future.delayed(duration).then((_) {
///           var delta = new DateTime.now().difference(time);
///
///           expect(delta, greaterThanOrEqualTo(duration));
///         });
///       });
///     }
library unittest;

import 'dart:async';
import 'dart:collection';
import 'dart:isolate';

import 'package:matcher/matcher.dart' show DefaultFailureHandler,
    configureExpectFailureHandler, TestFailure, wrapAsync;
export 'package:matcher/matcher.dart';

import 'src/utils.dart';

import 'src/configuration.dart';
export 'src/configuration.dart';

part 'src/simple_configuration.dart';
part 'src/group_context.dart';
part 'src/spread_args_helper.dart';
part 'src/test_case.dart';

Configuration _config;

/// [Configuration] used by the unittest library.
///
/// Note that if a configuration has not been set, calling this getter will
/// create a default configuration.
Configuration get unittestConfiguration {
  if (_config == null) {
    _config = new Configuration();
  }
  return _config;
}

/// Sets the [Configuration] used by the unittest library.
///
/// Throws a [StateError] if there is an existing, incompatible value.
void set unittestConfiguration(Configuration value) {
  if (!identical(_config, value)) {
    if (_config != null) {
      throw new StateError('unittestConfiguration has already been set');
    }
    _config = value;
  }
}

/// Can be called by tests to log status. Tests should use this
/// instead of [print].
void logMessage(String message) =>
    _config.onLogMessage(currentTestCase, message);

/// Separator used between group names and test names.
String groupSep = ' ';

final List<TestCase> _testCases = new List<TestCase>();

/// Tests executed in this suite.
final List<TestCase> testCases = new UnmodifiableListView<TestCase>(_testCases);

/// Interval (in msecs) after which synchronous tests will insert an async
/// delay to allow DOM or other updates.
const int BREATH_INTERVAL = 200;

/// The set of tests to run can be restricted by using [solo_test] and
/// [solo_group].
/// As groups can be nested we use a counter to keep track of the nest level
/// of soloing, and a flag to tell if we have seen any solo tests.
int _soloNestingLevel = 0;
bool _soloTestSeen = false;

// We use a 'dummy' context for the top level to eliminate null
// checks when querying the context. This allows us to easily
//  support top-level setUp/tearDown functions as well.
final _rootContext = new _GroupContext();
_GroupContext _currentContext = _rootContext;

/// Represents the index of the currently running test case
/// == -1 implies the test system is not running
/// == [number of test cases] is a short-lived state flagging that the last test
///    has completed
int _currentTestCaseIndex = -1;

/// [TestCase] currently being executed.
TestCase get currentTestCase =>
    (_currentTestCaseIndex >= 0 && _currentTestCaseIndex < testCases.length)
        ? testCases[_currentTestCaseIndex]
        : null;

/// Whether the framework is in an initialized state.
bool _initialized = false;

String _uncaughtErrorMessage = null;

/// Time since we last gave non-sync code a chance to be scheduled.
int _lastBreath = new DateTime.now().millisecondsSinceEpoch;

/* Test case result strings. */
// TODO(gram) we should change these constants to use a different string
// (so that writing 'FAIL' in the middle of a test doesn't
// imply that the test fails). We can't do it without also changing
// the testrunner and test.dart though.
/// Result string for a passing test case.
const PASS = 'pass';
/// Result string for a failing test case.
const FAIL = 'fail';
/// Result string for an test case with an error.
const ERROR = 'error';

/// Creates a new test case with the given description and body. The
/// description will include the descriptions of any surrounding group()
/// calls.
void test(String spec, TestFunction body) {
  _requireNotRunning();
  ensureInitialized();
  if (!_soloTestSeen || _soloNestingLevel > 0) {
    var testcase = new TestCase._internal(testCases.length + 1, _fullSpec(spec),
        body);
    _testCases.add(testcase);
  }
}

/// Convenience function for skipping a test.
void skip_test(String spec, TestFunction body) {}

/// Creates a new test case with the given description and body. The
/// description will include the descriptions of any surrounding group()
/// calls.
///
/// If we use [solo_test] (or [solo_group]) instead of test, then all non-solo
/// tests will be disabled. Note that if we use [solo_group], all tests in
/// the group will be enabled, regardless of whether they use [test] or
/// [solo_test], or whether they are in a nested [group] vs [solo_group]. Put
/// another way, if there are any calls to [solo_test] or [solo_group] in a test
/// file, all tests that are not inside a [solo_group] will be disabled unless
/// they are [solo_test]s.
///
/// [skip_test] and [skip_group] take precedence over soloing, by virtue of the
/// fact that they are effectively no-ops.
void solo_test(String spec, TestFunction body) {
  _requireNotRunning();
  ensureInitialized();
  if (!_soloTestSeen) {
    _soloTestSeen = true;
    // This is the first solo-ed test. Discard all tests up to now.
    _testCases.clear();
  }
  ++_soloNestingLevel;
  try {
    test(spec, body);
  } finally {
    --_soloNestingLevel;
  }
}

/// Indicate that [callback] is expected to be called a [count] number of times
/// (by default 1).
///
/// The unittest framework will wait for the callback to run the
/// specified [count] times before it continues with the following test.  Using
/// [expectAsync] will also ensure that errors that occur within [callback] are
/// tracked and reported. [callback] should take 0 positional arguments (named
/// arguments are not supported). [id] can be used to provide more
/// descriptive error messages if the callback is called more often than
/// expected.
///
/// [max] can be used to specify an upper bound on the number of
/// calls; if this is exceeded the test will fail (or be marked as in error if
/// it was already complete). A value of 0 for [max] (the default) will set
/// the upper bound to the same value as [count]; i.e. the callback should be
/// called exactly [count] times. A value of -1 for [max] will mean no upper
/// bound.
///
/// [reason] is optional and is typically not supplied, as a reason is generated
/// by the unittest package; if reason is included it is appended to the
/// generated reason.
Function expectAsync(Function callback,
    {int count: 1, int max: 0, String id, String reason}) =>
  new _SpreadArgsHelper(callback, count, max, id, reason).func;

/// Indicate that [callback] is expected to be called until [isDone] returns
/// true.
///
/// The unittest framework checks [isDone] after each callback and only
/// when it returns true will it continue with the following test. Using
/// [expectAsyncUntil] will also ensure that errors that occur within
/// [callback] are tracked and reported. [callback] should take 0 positional
/// arguments (named arguments are not supported). [id] can be used to
/// identify the callback in error messages (for example if it is called
/// after the test case is complete).
///
/// [reason] is optional and is typically not supplied, as a reason is generated
/// by the unittest package; if reason is included it is appended to the
/// generated reason.
Function expectAsyncUntil(Function callback, bool isDone(),
    {String id, String reason}) =>
  new _SpreadArgsHelper(callback, 0, -1, id, reason, isDone: isDone).func;

/// Creates a new named group of tests.
///
/// Calls to group() or test() within the body of the function passed to this
/// named group will inherit this group's description.
void group(String description, void body()) {
  ensureInitialized();
  _requireNotRunning();
  _currentContext = new _GroupContext(_currentContext, description);
  try {
    body();
  } catch (e, trace) {
    var stack = (trace == null) ? '' : ': ${trace.toString()}';
    _uncaughtErrorMessage = "${e.toString()}$stack";
  } finally {
    // Now that the group is over, restore the previous one.
    _currentContext = _currentContext.parent;
  }
}

/// Like [skip_test], but for groups.
void skip_group(String description, void body()) {}

/// Like [solo_test], but for groups.
void solo_group(String description, void body()) {
  _requireNotRunning();
  ensureInitialized();
  if (!_soloTestSeen) {
    _soloTestSeen = true;
    // This is the first solo-ed group. Discard all tests up to now.
    _testCases.clear();
  }
  ++_soloNestingLevel;
  try {
    group(description, body);
  } finally {
    --_soloNestingLevel;
  }
}

/// Register a [setUp] function for a test [group].
///
/// This function will be called before each test in the group is run.
/// [setUp] and [tearDown] should be called within the [group] before any
/// calls to [test]. The [setupTest] function can be asynchronous; in this
/// case it must return a [Future].
void setUp(Function setupTest) {
  _requireNotRunning();
  _currentContext.testSetup = setupTest;
}

/// Register a [tearDown] function for a test [group].
///
/// This function will be called after each test in the group is run.
///
/// Note that if groups are nested only the most locally scoped [teardownTest]
/// function will be run. [setUp] and [tearDown] should be called within the
/// [group] before any calls to [test]. The [teardownTest] function can be
/// asynchronous; in this case it must return a [Future].
void tearDown(Function teardownTest) {
  _requireNotRunning();
  _currentContext.testTeardown = teardownTest;
}

/// Advance to the next test case.
void _nextTestCase() {
  _currentTestCaseIndex++;
  _runTest();
}

/// Handle errors that happen outside the tests.
// TODO(vsm): figure out how to expose the stack trace here
// Currently e.message works in dartium, but not in dartc.
void handleExternalError(e, String message, [stack]) {
  var msg = '$message\nCaught $e';

  if (currentTestCase != null) {
    currentTestCase._error(msg, stack);
  } else {
    _uncaughtErrorMessage = "$msg: $stack";
  }
}

/// Filter the tests by [testFilter].
///
/// [testFilter] can be a [RegExp], a [String] or a
/// predicate function. This is different from enabling or disabling tests
/// in that it removes the tests completely.
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
  _testCases.retainWhere(filterFunction);
}

/// Runs all queued tests, one at a time.
void runTests() {
  _requireNotRunning();
  _ensureInitialized(false);
  _currentTestCaseIndex = 0;
  _config.onStart();
  _runTest();
}

/// Registers that an exception was caught for the current test.
void registerException(e, [trace]) {
  _registerException(currentTestCase, e, trace);
}

/// Registers that an exception was caught for the current test.
void _registerException(TestCase testCase, e, [trace]) {
  String message = (e is TestFailure) ? e.message : 'Caught $e';
  if (testCase.result == null) {
    testCase._fail(message, trace);
  } else {
    testCase._error(message, trace);
  }
}

/// Runs the next test.
void _runTest() {
  if (_currentTestCaseIndex >= testCases.length) {
    assert(_currentTestCaseIndex == testCases.length);
    _completeTests();
  } else {
    var testCase = testCases[_currentTestCaseIndex];
    Future f = runZoned(testCase._run, onError: (error, stack) {
      // TODO(kevmoo) Do a better job of flagging these are async errors.
      // https://code.google.com/p/dart/issues/detail?id=16530
      _registerException(testCase, error, stack);
    });

    var timeout = unittestConfiguration.timeout;

    Timer timer;
    if (timeout != null) {
      try {
        timer = new Timer(timeout, () {
          testCase._error("Test timed out after ${timeout.inSeconds} seconds.");
          _nextTestCase();
        });
      } on UnsupportedError catch (e) {
        if (e.message != "Timer greater than 0.") rethrow;
        // Support running on d8 and jsshell which don't support timers.
      }
    }
    f.whenComplete(() {
      if (timer != null) timer.cancel();
      var now = new DateTime.now().millisecondsSinceEpoch;
      if ((now - _lastBreath) >= BREATH_INTERVAL) {
        _lastBreath = now;
        Timer.run(_nextTestCase);
      } else {
        scheduleMicrotask(_nextTestCase); // Schedule the next test.
      }
    });
  }
}

/// Publish results on the page and notify controller.
void _completeTests() {
  if (!_initialized) return;
  int passed = 0;
  int failed = 0;
  int errors = 0;

  for (TestCase t in testCases) {
    switch (t.result) {
      case PASS:  passed++; break;
      case FAIL:  failed++; break;
      case ERROR: errors++; break;
    }
  }
  _config.onSummary(passed, failed, errors, testCases, _uncaughtErrorMessage);
  _config.onDone(passed > 0 && failed == 0 && errors == 0 &&
      _uncaughtErrorMessage == null);
  _initialized = false;
  _currentTestCaseIndex = -1;
}

String _fullSpec(String spec) {
  var group = '${_currentContext.fullName}';
  if (spec == null) return group;
  return group != '' ? '$group$groupSep$spec' : spec;
}

/// Lazily initializes the test library if not already initialized.
void ensureInitialized() {
  _ensureInitialized(true);
}

void _ensureInitialized(bool configAutoStart) {
  if (_initialized) {
    return;
  }
  _initialized = true;
  // Hook our async guard into the matcher library.
  wrapAsync = (f, [id]) => expectAsync(f, id: id);

  _uncaughtErrorMessage = null;

  unittestConfiguration.onInit();

  if (configAutoStart && _config.autoStart) {
    // Immediately queue the suite up. It will run after a timeout (i.e. after
    // main() has returned).
    scheduleMicrotask(runTests);
  }
}

/// Select a solo test by ID.
void setSoloTest(int id) => _testCases.retainWhere((t) => t.id == id);

/// Enable/disable a test by ID.
void _setTestEnabledState(int testId, bool state) {
  // Try fast path first.
  if (testCases.length > testId && testCases[testId].id == testId) {
    testCases[testId]._enabled = state;
  } else {
    for (var i = 0; i < testCases.length; i++) {
      if (testCases[i].id == testId) {
        testCases[i]._enabled = state;
        break;
      }
    }
  }
}

/// Enable a test by ID.
void enableTest(int testId) => _setTestEnabledState(testId, true);

/// Disable a test by ID.
void disableTest(int testId) => _setTestEnabledState(testId, false);

/// Signature for a test function.
typedef dynamic TestFunction();

/// A flag that controls whether we hide unittest and core library details in
/// exception stacks.
///
/// Useful to disable when debugging unittest or matcher customizations.
bool formatStacks = true;

/// A flag that controls whether we try to filter out irrelevant frames from
/// the stack trace.
///
/// Requires [formatStacks] to be set.
bool filterStacks = true;

void _requireNotRunning() {
  if (_currentTestCaseIndex != -1) {
    throw new StateError('Not allowed when tests are running.');
  }
}
