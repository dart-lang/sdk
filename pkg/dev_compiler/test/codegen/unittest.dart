// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jmesserly): replace this with the real package:test.
// Not possible yet due to various bugs we still have.
library minitest;

import 'dart:async';
import 'dart:js';
import 'package:matcher/matcher.dart';
export 'package:matcher/matcher.dart';

// from matcher/throws_matcher.dart

Function _wrapAsync = (Function f, [id]) => f;

/// This can be used to match two kinds of objects:
///
///   * A [Function] that throws an exception when called. The function cannot
///     take any arguments. If you want to test that a function expecting
///     arguments throws, wrap it in another zero-argument function that calls
///     the one you want to test.
///
///   * A [Future] that completes with an exception. Note that this creates an
///     asynchronous expectation. The call to `expect()` that includes this will
///     return immediately and execution will continue. Later, when the future
///     completes, the actual expectation will run.
const Matcher throws = const Throws();

/// This can be used to match two kinds of objects:
///
///   * A [Function] that throws an exception when called. The function cannot
///     take any arguments. If you want to test that a function expecting
///     arguments throws, wrap it in another zero-argument function that calls
///     the one you want to test.
///
///   * A [Future] that completes with an exception. Note that this creates an
///     asynchronous expectation. The call to `expect()` that includes this will
///     return immediately and execution will continue. Later, when the future
///     completes, the actual expectation will run.
///
/// In both cases, when an exception is thrown, this will test that the exception
/// object matches [matcher]. If [matcher] is not an instance of [Matcher], it
/// will implicitly be treated as `equals(matcher)`.
Matcher throwsA(matcher) => new Throws(wrapMatcher(matcher));

class Throws extends Matcher {
  final Matcher _matcher;

  const Throws([Matcher matcher]) : this._matcher = matcher;

  bool matches(item, Map matchState) {
    if (item is! Function && item is! Future) return false;
    if (item is Future) {
      var done = _wrapAsync((fn) => fn());

      // Queue up an asynchronous expectation that validates when the future
      // completes.
      item.then((value) {
        done(() {
          fail("Expected future to fail, but succeeded with '$value'.");
        });
      }, onError: (error, trace) {
        done(() {
          if (_matcher == null) return;
          var reason;
          if (trace != null) {
            var stackTrace = trace.toString();
            stackTrace = "  ${stackTrace.replaceAll("\n", "\n  ")}";
            reason = "Actual exception trace:\n$stackTrace";
          }
          expect(error, _matcher, reason: reason);
        });
      });
      // It hasn't failed yet.
      return true;
    }

    try {
      item();
      return false;
    } catch (e, s) {
      if (_matcher == null || _matcher.matches(e, matchState)) {
        return true;
      } else {
        addStateInfo(matchState, {'exception': e, 'stack': s});
        return false;
      }
    }
  }

  Description describe(Description description) {
    if (_matcher == null) {
      return description.add("throws");
    } else {
      return description.add('throws ').addDescriptionOf(_matcher);
    }
  }

  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    if (item is! Function && item is! Future) {
      return mismatchDescription.add('is not a Function or Future');
    } else if (_matcher == null || matchState['exception'] == null) {
      return mismatchDescription.add('did not throw');
    } else {
      mismatchDescription
          .add('threw ')
          .addDescriptionOf(matchState['exception']);
      if (verbose) {
        mismatchDescription.add(' at ').add(matchState['stack'].toString());
      }
      return mismatchDescription;
    }
  }
}

// End of matcher/throws_matcher.dart

void group(String name, void body()) => context.callMethod('suite', [name, body]);

void test(String name, body(), {String skip}) {
  if (skip != null) {
    print('SKIP $name: $skip');
    return;
  }
  JsObject result = context.callMethod('test', [name, (JsFunction done) {
    _finishTest(f) {
      if (f is Future) {
        f.then(_finishTest);
      } else {
        done.apply([]);
      }
    }
    _finishTest(body());
  }]);
  result['async'] = 1;
}

// TODO(jmesserly): everything below this was stolen from
// package:test/src/frontend/expect.dart

/// An exception thrown when a test assertion fails.
class TestFailure {
  final String message;

  TestFailure(this.message);

  String toString() => message;
}

/// An individual unit test.
abstract class TestCase {
  /// A unique numeric identifier for this test case.
  int get id;

  /// A description of what the test is specifying.
  String get description;

  /// The error or failure message for the tests.
  ///
  /// Initially an empty string.
  String get message;

  /// The result of the test case.
  ///
  /// If the test case has is completed, this will be one of [PASS], [FAIL], or
  /// [ERROR]. Otherwise, it will be `null`.
  String get result;

  /// Returns whether this test case passed.
  bool get passed;

  /// The stack trace for the error that caused this test case to fail, or
  /// `null` if it succeeded.
  StackTrace get stackTrace;

  /// The name of the group within which this test is running.
  String get currentGroup;

  /// The time the test case started running.
  ///
  /// `null` if the test hasn't yet begun running.
  DateTime get startTime;

  /// The amount of time the test case took.
  ///
  /// `null` if the test hasn't finished running.
  Duration get runningTime;

  /// Whether this test is enabled.
  ///
  /// Disabled tests won't be run.
  bool get enabled;

  /// Whether this test case has finished running.
  bool get isComplete => !enabled || result != null;
}

/// The type used for functions that can be used to build up error reports
/// upon failures in [expect].
typedef String ErrorFormatter(
    actual, Matcher matcher, String reason, Map matchState, bool verbose);

/// Assert that [actual] matches [matcher].
///
/// This is the main assertion function. [reason] is optional and is typically
/// not supplied, as a reason is generated from [matcher]; if [reason]
/// is included it is appended to the reason generated by the matcher.
///
/// [matcher] can be a value in which case it will be wrapped in an
/// [equals] matcher.
///
/// If the assertion fails a [TestFailure] is thrown.
///
/// In some cases extra diagnostic info can be produced on failure (for
/// example, stack traces on mismatched exceptions). To enable these,
/// [verbose] should be specified as `true`.
void expect(actual, matcher,
    {String reason, bool verbose: false, ErrorFormatter formatter}) {

  matcher = wrapMatcher(matcher);
  var matchState = {};
  try {
    if (matcher.matches(actual, matchState)) return;
  } catch (e, trace) {
    if (reason == null) {
      reason = '${(e is String) ? e : e.toString()} at $trace';
    }
  }
  if (formatter == null) formatter = _defaultFailFormatter;
  fail(formatter(actual, matcher, reason, matchState, verbose));
}

/// Convenience method for throwing a new [TestFailure] with the provided
/// [message].
void fail(String message) => throw new TestFailure(message);

// The default error formatter.
String _defaultFailFormatter(
    actual, Matcher matcher, String reason, Map matchState, bool verbose) {
  var description = new StringDescription();
  description.add('Expected: ').addDescriptionOf(matcher).add('\n');
  description.add('  Actual: ').addDescriptionOf(actual).add('\n');

  var mismatchDescription = new StringDescription();
  matcher.describeMismatch(actual, mismatchDescription, matchState, verbose);

  if (mismatchDescription.length > 0) {
    description.add('   Which: ${mismatchDescription}\n');
  }
  if (reason != null) description.add(reason).add('\n');
  return description.toString();
}

// from html_configuration
void useHtmlConfiguration([bool isLayoutTest = false]) { }
