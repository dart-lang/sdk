// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * The error formatter for mocking is a bit different from the default one
 * for unit testing; instead of the third argument being a 'reason'
 * it is instead a [signature] describing the method signature filter
 * that was used to select the logs that were verified.
 */
String _mockingErrorFormatter(actual, Matcher matcher, String signature) {
  var description = new StringDescription();
  description.add('Expected ${signature} ').addDescriptionOf(matcher).
      add('\n     but: ');
  matcher.describeMismatch(actual, description);
  return description.toString();
}

/**
 * The failure handler for the [expect()] calls that occur in [verify()]
 * methods in the mock objects. This calls the real failure handler used
 * by the unit test library after formatting the error message with
 * the custom formatter.
 */
class _MockFailureHandler implements FailureHandler {
  FailureHandler proxy;
  _MockFailureHandler(this.proxy);
  void fail(String reason) {
    proxy.fail(reason);
  }
  void failMatch(actual, Matcher matcher, String reason) {
    proxy.fail(_mockingErrorFormatter(actual, matcher, reason));
  }
}

_MockFailureHandler _mockFailureHandler = null;

/**
 * [_noArg] is a sentinel value representing no argument.
 */
final _noArg = const _Sentinel();

/**
 * The behavior of a method call in the mock library is specified
 * with [BehaviorValue]s. A [BehaviorValue] has a [value] to throw
 * or return (depending on whether [isThrow] is true or not, respectively),
 * and can either be one-shot, multi-shot, or infinitely repeating,
 * depending on the value of [count (1, greater than 1, or 0 respectively).
 */
class BehaviorValue {
  var value;
  bool isThrow;
  int count;
  BehaviorValue(this.value, [this.count = 1, this.isThrow = false]);
}

/**
 * A [CallMatcher] is a special matcher used to match method calls (i.e.
 * a method name and set of arguments). It is not a [Matcher] like the
 * unit test [Matcher], but instead represents a collection of [Matcher]s,
 * one per argument, that will be applied to the parameters to decide if
 * the method call is a match.
 */
class CallMatcher {
  String name;
  List<Matcher> argMatchers;

  CallMatcher(String method, [
              arg0 = _noArg,
              arg1 = _noArg,
              arg2 = _noArg,
              arg3 = _noArg,
              arg4 = _noArg,
              arg5 = _noArg,
              arg6 = _noArg,
              arg7 = _noArg,
              arg8 = _noArg,
              arg9 = _noArg]) {
    name = method;
    argMatchers = new List<Matcher>();
    if (arg0 == _noArg) return;
    argMatchers.add(wrapMatcher(arg0));
    if (arg1 == _noArg) return;
    argMatchers.add(wrapMatcher(arg1));
    if (arg2 == _noArg) return;
    argMatchers.add(wrapMatcher(arg2));
    if (arg3 == _noArg) return;
    argMatchers.add(wrapMatcher(arg3));
    if (arg4 == _noArg) return;
    argMatchers.add(wrapMatcher(arg4));
    if (arg5 == _noArg) return;
    argMatchers.add(wrapMatcher(arg5));
    if (arg6 == _noArg) return;
    argMatchers.add(wrapMatcher(arg6));
    if (arg7 == _noArg) return;
    argMatchers.add(wrapMatcher(arg7));
    if (arg8 == _noArg) return;
    argMatchers.add(wrapMatcher(arg8));
    if (arg9 == _noArg) return;
    argMatchers.add(wrapMatcher(arg9));
  }

  /**
   * We keep our behavior specifications in a Map, which is keyed
   * by the [CallMatcher]. To make the keys unique and to get a
   * descriptive value for the [CallMatcher] we have this override
   * of [toString()].
   */
  String toString() {
    Description d = new StringDescription();
    d.add(name).add('(');
    for (var i = 0; i < argMatchers.length; i++) {
      if (i > 0) d.add(', ');
      d.addDescriptionOf(argMatchers[i]);
    }
    d.add(')');
    return d.toString();
  }

  /**
   * Given a [method] name oand list of [arguments], return true
   * if it matches this [CallMatcher.
   */
  bool matches(String method, List arguments) {
    if (method != this.name || arguments.length != argMatchers.length) {
      return false;
    }
    for (var i = 0; i < arguments.length; i++) {
      if (!argMatchers[i].matches(arguments[i])) {
        return false;
      }
    }
    return true;
  }
}

/**
 * A [Behavior] represents how a [Mock] will respond to one particular
 * type of method call.
 */
class Behavior {
  CallMatcher matcher; // The method call matcher.
  List<BehaviorValue> returnValues; // The values to return/throw.

  Behavior (this.matcher) {
    returnValues = new List<BehaviorValue>();
  }

  /**
   * [thenReturn] creates a return value, that is returned [count]
   * times (1 by default).
   */
  Behavior thenReturn(value, [count = 1]) {
    returnValues.add(new BehaviorValue(value, count));
    return this; // For chaining calls.
  }

  /** [alwaysReturn] creates a repeating return value. */
  Behavior alwaysReturn(value) {
    return thenReturn(value, 0);
  }

  /**
   * [thenThrow] creates an exception, that is thrown [count]
   * times (1 by default).
   */
  Behavior thenThrow(value, [count = 1]) {
    returnValues.add(new BehaviorValue(value, count, true));
    return this; // For chaining calls.
  }

  /** [alwaysThrow] creates a repeating exception. */
  Behavior alwaysThrow(value) {
    return thenThrow(value, 0);
  }

  /** [matches] return true if a method call matches the [Behavior]. */
  bool matches(name, args) => matcher.matches(name, args);
}

/**
 * Every call to a [Mock] object method is logged. The logs are
 * kept in instances of [LogEntry].
 */
class LogEntry {
  final String name; // The method name.
  final List args; // The parameters.
  final BehaviorValue result; // The behavior that resulted.

  const LogEntry(this.name, this.args, this.result);
}

/**
 * We do verification on a list of [LogEntry]s. To allow chaining
 * of calls to verify, we encapsulate such a list in the [LogEntryList]
 * class.
 */
class LogEntryList {
  final String filter;
  final List<LogEntry> logs;
  const LogEntryList(this.logs, [this.filter = null]);

  /** Add a [LogEntry] to the log. */
  add(LogEntry entry) => logs.add(entry);

  /**
   * Create a new [LogEntryList] consisting of [LogEntry]s from
   * this list that match the specified [logfilter].
   */
  LogEntryList getMatches(CallMatcher logfilter) {
    LogEntryList rtn =
        new LogEntryList(new List<LogEntry>(), logfilter.toString());
    for (var i = 0; i < logs.length; i++) {
      LogEntry entry = logs[i];
      if (logfilter.matches(entry.name, entry.args)) {
        rtn.add(entry);
      }
    }
    return rtn;
  }

  /** Apply a unit test [Matcher] to the [LogEntryList]. */
  LogEntryList verify(Matcher matcher) {
    if (_mockFailureHandler == null) {
      _mockFailureHandler =
          new _MockFailureHandler(getOrCreateExpectFailureHandler());
    }
    expect(logs, matcher, filter, _mockFailureHandler);
    return this;
  }
}

/**
 * [_TimesMatcher]s are used to make assertions about the number of
 * times a method was called.
 */
class _TimesMatcher extends BaseMatcher {
  final int min, max;
  const _TimesMatcher(this.min, [this.max = -1]);
  bool matches(log) => log.length >= min && (max < 0 || log.length <= max);
  Description describe(Description description) {
    description.add(' to be called ');
    if (max < 0) {
      description.add('at least $min');
    } else if (max == min) {
      description.add('$max');
    } else if (min == 0) {
      description.add('at most $max');
    } else {
      description.add('between $min and $max');
    }
    return description.add(' times');
  }
  Description describeMismatch(log, Description mismatchDescription) =>
      mismatchDescription.add('was called ${log.length} times');
}

/** [calledExactly] matches an exact number of calls. */
Matcher calledExactly(count) {
  return new _TimesMatcher(count, count);
}

/** [calledAtLeast] matches a minimum number of calls. */
Matcher calledAtLeast(count) {
  return new _TimesMatcher(count);
}

/** [calledAtMost] matches a maximum number of calls. */
Matcher calledAtMost(count) {
  return new _TimesMatcher(0, count);
}

/** [neverCalled] matches zero calls. */
final Matcher neverCalled = const _TimesMatcher(0, 0);

/** [calledOnce] matches exactly one call. */
final Matcher calledOnce = const _TimesMatcher(1, 1);

/** [calledAtLeastOnce] matches one or more calls. */
final Matcher calledAtLeastOnce = const _TimesMatcher(1);

/** [calledAtMostOnce] matches zero or one call. */
final Matcher calledAtMostOnce = const _TimesMatcher(0, 1);

/**
 * [Mock] is the base class for all mocked objects, with
 * support for basic mocking.
 *
 * To create a mock objects for some class T, create a new class using:
 *
 *     class MockT extends Mock implements T {};
 *
 * Then specify the behavior of the Mock for different methods using
 * [when] (to select the method and parameters) and [thenReturn],
 * [alwaysReturn], [thenThrow] and/or [alwaysThrow].
 *
 * You can then use the mock object. Once you are done, to verify the
 * behavior, use [verify] to extract a relevant subset of method call
 * logs and apply [Matchers] to these.
 *
 * Limitations:
 * - only positional parameters are supported (up to 10);
 * - to mock getters you will need to include parentheses.
 *
 * Here is a simple example:
 *
 *     class MockList extends Mock implements List {};
 *
 *     List m = new MockList();
 *     m.when('add', anything).alwaysReturn(0);
 *
 *     m.add('foo');
 *     m.add('bar');
 *
 *     m.verify('add', anything, was:calledExactly(2));
 *     m.verify('add', 'foo', was:calledOnce);
 *     m.verify('add', 'isNull, was:neverCalled);
 */
class Mock {
  Map<String,Behavior> behaviors; /** The set of [behavior]s supported. */
  LogEntryList log; /** The [log] of calls made. */

  Mock() {
    behaviors = new Map<String,Behavior>();
    log = new LogEntryList(new List<LogEntry>());
  }

  /**
   * [when] is used to create a new or extend an existing [Behavior].
   * The [method] name and the argument [Matcher] is specified. A
   * corresponding [CallMatcher] is created, and the [Behavior]s for
   * its signature are returned (being created first if needed).
   */
  Behavior when(String method, [
       arg0 = _noArg,
       arg1 = _noArg,
       arg2 = _noArg,
       arg3 = _noArg,
       arg4 = _noArg,
       arg5 = _noArg,
       arg6 = _noArg,
       arg7 = _noArg,
       arg8 = _noArg,
       arg9 = _noArg]) {
    CallMatcher logfilter = new CallMatcher(method,
        arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9);
    String key = logfilter.toString();
    if (!behaviors.containsKey(key)) {
      Behavior b = new Behavior(logfilter);
      behaviors[key] = b;
      return b;
    } else {
      return behaviors[key];
    }
  }

  /**
   * This is the handler for method calls. We loo through the list
   * of [Behavior]s, and find the first match that still has return
   * values available, and then do the action specified by that
   * return value. If we find no [Behavior] to apply an exception is
   * thrown.
   */
  noSuchMethod(String name, List args) {
    for (String k in behaviors.getKeys()) {
      Behavior b = behaviors[k];
      if (b.matches(name, args)) {
        List rv = b.returnValues;
        if (rv == null || rv.length == 0) {
          continue; // No return values left in this Behavior.
        }
        // Get the first response.
        BehaviorValue bv = rv[0];
        // If it is exhausted, remove it from the list.
        // Note that for endlessly repeating values, we started the count at
        // 0, so we get a potentially useful value here, which is the
        // (negation of) the number of times we returned the value.
        if (--bv.count == 0) {
          rv.removeRange(0, 1);
          if (rv.length == 0) {
            // Remove the behavior. Note that in the future there
            // may be some value in preserving the behaviors for
            // auditing purposes (e.g. how many times was this behavior used?).
            // If we do decide to keep them and perf is an issue instead of
            // deleting we could move this to a separate list.
            behaviors.remove(k);
          }
        }
        // Log the method call and the response.
        log.add(new LogEntry(name, args, bv));
        // Do the response.
        if (bv.isThrow) {
          throw bv.value;
        } else {
          return bv.value;
        }
      }
    }
    throw new Exception('No behavior specified for method $name');
  }

  /**
   * [verify] extracts all calls from the object log that match the
   * method signature, then applies the [was] matcher. The matching
   * list of [LogEntry]s is returned so that further calls to verify()
   * can be chained .
   */
  LogEntryList verify(String method, [ arg0 = _noArg,
                          arg1 = _noArg,
                          arg2 = _noArg,
                          arg3 = _noArg,
                          arg4 = _noArg,
                          arg5 = _noArg,
                          arg6 = _noArg,
                          arg7 = _noArg,
                          arg8 = _noArg,
                          arg9 = _noArg,
                          Matcher was = calledOnce]) {
    CallMatcher logfilter = new CallMatcher(method,
      arg0, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9);
    LogEntryList _logs = log.getMatches(logfilter);
    _logs.verify(was);
    return _logs;
  }

  /** [verifyZeroInteractions] returns true if no calls were made */
  bool verifyZeroInteractions() => log.logs.length == 0;

}

