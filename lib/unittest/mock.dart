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

/** The ways in which a call to a mock method can be handled. */
final RETURN = 0;
final THROW = 1;
final PROXY = 2;

/**
 * The behavior of a method call in the mock library is specified
 * with [Responder]s. A [Responder] has a [value] to throw
 * or return (depending on whether [isThrow] is true or not, respectively),
 * and can either be one-shot, multi-shot, or infinitely repeating,
 * depending on the value of [count (1, greater than 1, or 0 respectively).
 */
class Responder {
  var value;
  int action;
  int count;
  Responder(this.value, [this.count = 1, this.action = RETURN]);
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
    if (method != this.name) {
      return false;
    }
    if (arguments.length < argMatchers.length) {
      throw new Exception("Less arguments than matchers for $name");
    }
    for (var i = 0; i < argMatchers.length; i++) {
      if (!argMatchers[i].matches(arguments[i])) {
        return false;
      }
    }
    return true;
  }
}

/** [callsTo] returns a CallMatcher for the specified signature. */
CallMatcher callsTo(String method, [ arg0 = _noArg,
                        arg1 = _noArg,
                        arg2 = _noArg,
                        arg3 = _noArg,
                        arg4 = _noArg,
                        arg5 = _noArg,
                        arg6 = _noArg,
                        arg7 = _noArg,
                        arg8 = _noArg,
                        arg9 = _noArg]) {
  return new CallMatcher(method, arg0, arg1, arg2, arg3, arg4,
      arg5, arg6, arg7, arg8, arg9);
}

/**
 * A [Behavior] represents how a [Mock] will respond to one particular
 * type of method call.
 */
class Behavior {
  CallMatcher matcher; // The method call matcher.
  List<Responder> actions; // The values to return/throw or proxies to call.

  Behavior (this.matcher) {
    actions = new List<Responder>();
  }

  /**
   * Adds a [Responder] that returns a [value] for [count] calls
   * (1 by default).
   */
  Behavior thenReturn(value, [count = 1]) {
    actions.add(new Responder(value, count, RETURN));
    return this; // For chaining calls.
  }

  /** Adds a [Responder] that repeatedly returns a [value]. */
  Behavior alwaysReturn(value) {
    return thenReturn(value, 0);
  }

  /**
   * Adds a [Responder] that throws [value] [count]
   * times (1 by default).
   */
  Behavior thenThrow(value, [count = 1]) {
    actions.add(new Responder(value, count, THROW));
    return this; // For chaining calls.
  }

  /** Adds a [Responder] that throws [value] endlessly. */
  Behavior alwaysThrow(value) {
    return thenThrow(value, 0);
  }

  /**
   * [thenCall] creates a proxy Responder, that is called [count]
   * times (1 by default; 0 is used for unlimited calls, and is
   * exposed as [alwaysCall]). [value] is the function that will
   * be called with the same arguments that were passed to the
   * mock. Proxies can be used to wrap real objects or to define
   * more complex return/throw behavior. You could even (if you
   * wanted) use proxies to emulate the behavior of thenReturn;
   * e.g.:
   *
   *     m.when(callsTo('foo')).thenReturn(0)
   *
   * is equivalent to:
   *
   *     m.when(callsTo('foo')).thenCall(() => 0)
   */
  Behavior thenCall(value, [count = 1]) {
    actions.add(new Responder(value, count, PROXY));
    return this; // For chaining calls.
  }

  /** Creates a repeating proxy call. */
  Behavior alwaysCall(value) {
    return thenCall(value, 0);
  }

  /** Returns true if a method call matches the [Behavior]. */
  bool matches(name, args) => matcher.matches(name, args);

  /** Returns the [matcher]'s representation. */
  String toString() => matcher.toString();
}

/**
 * Every call to a [Mock] object method is logged. The logs are
 * kept in instances of [LogEntry].
 */
class LogEntry {
  final String name; // The method name.
  final List args; // The parameters.
  final int action; // The behavior that resulted.
  final value; // The value that was returned (if no throw).

  const LogEntry(this.name, this.args, this.action, [this.value = null]);
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
   * this list that match the specified [logfilter]. If [destructive]
   * is true, the log entries are removed from the original list.
   */
  LogEntryList getMatches(CallMatcher logfilter, bool destructive) {
    LogEntryList rtn =
        new LogEntryList(new List<LogEntry>(), logfilter.toString());
    for (var i = 0; i < logs.length; i++) {
      LogEntry entry = logs[i];
      if (logfilter.matches(entry.name, entry.args)) {
        rtn.add(entry);
        if (destructive) {
          logs.removeRange(i--, 1);
        }
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

/** Special values for use with [_ResultMatcher] [frequency]. */
final int ALL = 0;
final int SOME = 1;
final int NONE = 2;
/**
 * [_ResultMatcher]s are used to make assertions about the results
 * of method calls. When filtering an execution log by calling
 * [forThe], a [LogEntrySet] of matching call logs is returned;
 * [_ResultMatcher]s can then assert various things about this
 * (sub)set of logs.
 */
class _ResultMatcher extends BaseMatcher {
  final int action;
  final value;
  final int frequency; // -1 for all, 0 for none, 1 for some.

  const _ResultMatcher(this.action, this.value, this.frequency);

  bool matches(log) {
    for (LogEntry entry in log) {
      // normalize the action; PROXY is like RETURN.
      int eaction = (entry.action == THROW) ? THROW : RETURN;
      if (eaction == action && value.matches(entry.value)) {
        if (frequency == NONE) {
          return false;
        } else if (frequency == SOME) {
          return true;
        }
      } else {
        // Mismatch.
        if (frequency == ALL) { // We need just one mismatch to fail.
          return false;
        }
      }
    }
    // If we get here, then if count is ALL we got all matches and
    // this is success; otherwise we got all mismatched which is
    // success for count == NONE and failure for count == SOME.
    return (frequency != SOME);
  }

  Description describe(Description description) {
    description.add(' to ');
    description.add(frequency == ALL ? 'alway ' :
        (frequency == NONE ? 'never ' : 'sometimes '));
    if (action == RETURN || action == PROXY)
      description.add('return ');
    else
      description.add('throw ');
    return description.addDescriptionOf(value);
  }

  Description describeMismatch(log, Description mismatchDescription) {
    if (frequency != SOME) {
      for (LogEntry entry in log) {
        if (entry.action != action || !value.matches(entry.value)) {
          if (entry.action == RETURN || entry.action == PROXY)
            mismatchDescription.add('returned ');
          else
            mismatchDescription.add('threw ');
          mismatchDescription.add(entry.value);
          mismatchDescription.add(' at least once');
          break;
        }
      }
    } else {
      mismatchDescription.add('never did');
    }
    return mismatchDescription;
  }
}

/**
 *[alwaysReturned] asserts that all matching calls to a method returned
 * a value that matched [value].
 */
Matcher alwaysReturned(value) =>
    new _ResultMatcher(RETURN, wrapMatcher(value), ALL);

/**
 *[sometimeReturned] asserts that at least one matching call to a method
 * returned a value that matched [value].
 */
Matcher sometimeReturned(value) =>
    new _ResultMatcher(RETURN, wrapMatcher(value), SOME);

/**
 *[neverReturned] asserts that no matching calls to a method returned
 * a value that matched [value].
 */
Matcher neverReturned(value) =>
    new _ResultMatcher(RETURN, wrapMatcher(value), NONE);

/**
 *[alwaysThrew] asserts that all matching calls to a method threw
 * a value that matched [value].
 */
Matcher alwaysThrew(value) =>
    new _ResultMatcher(THROW, wrapMatcher(value), ALL);

/**
 *[sometimeThrew] asserts that at least one matching call to a method threw
 * a value that matched [value].
 */
Matcher sometimeThrew(value) =>
  new _ResultMatcher(THROW, wrapMatcher(value), SOME);

/**
 *[neverThrew] asserts that no matching call to a method threw
 * a value that matched [value].
 */
Matcher neverThrew(value) =>
  new _ResultMatcher(THROW, wrapMatcher(value), NONE);

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
 * [alwaysReturn], [thenThrow], [alwaysThrow], [thenCall] or [alwaysCall].
 * [thenReturn], [thenThrow] and [thenCall] are one-shot so you would
 * typically call these more than once to specify a sequence of actions;
 * this can be done with chained calls, e.g.:
 *
 *      m.when(callsTo('foo')).
 *          thenReturn(0).thenReturn(1).thenReturn(2);
 *
 * [thenCall] and [alwaysCall] allow you to proxy mocked methods, chaining
 * to some other implementation. This provides a way to implement 'spies'.
 *
 * You can then use the mock object. Once you are done, to verify the
 * behavior, use [forThe] to extract a relevant subset of method call
 * logs and apply [Matchers] to these through calling [verify].
 *
 * Limitations:
 * - only positional parameters are supported (up to 10);
 * - to mock getters you will need to include parentheses in the call
 *       (e.g. m.length() will work but not m.length).
 *
 * Here is a simple example:
 *
 *     class MockList extends Mock implements List {};
 *
 *     List m = new MockList();
 *     m.when(callsTo('add', anything)).alwaysReturn(0);
 *
 *     m.add('foo');
 *     m.add('bar');
 *
 *     getLogs(m, callsTo('add', anything)).verify(calledExactly(2));
 *     getLogs(m, callsTo('add', 'foo')).verify(calledOnce);
 *     getLogs(m, callsTo('add', 'isNull)).verify(neverCalled);
 *
 * Note that we don't need to provide argument matchers for all arguments,
 * but we do need to provide arguments for all matchers. So this is allowed:
 *
 *     m.when(callsTo('add')).alwaysReturn(0);
 *     m.add(1, 2);
 *
 * But this is not allowed and will throw an exception:
 *
 *     m.when(callsTo('add', anything, anything)).alwaysReturn(0);
 *     m.add(1);
 *
 * Here is a way to implement a 'spy', which is where we log the call
 * but then hand it off to some other function, which is the same
 * method in a real instance of the class being mocked:
 *
 *     class Foo {
 *       bar(a, b, c) => a + b + c;
 *     }
 *
 *     class MockFoo extends Mock implements Foo {
 *       Foo real;
 *       MockFoo() {
 *         real = new Foo();
 *         this.when(callsTo('bar')).alwaysCall(real.bar);
 *       }
 *     }
 *
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
   * A [CallMatcher] [filter] must be supplied, and the [Behavior]s for
   * that signature are returned (being created first if needed).
   *
   * Typical use case:
   *
   *     mock.when(callsTo(...)).alwaysReturn(...);
   */
  Behavior when(CallMatcher logFilter) {
    String key = logFilter.toString();
    if (!behaviors.containsKey(key)) {
      Behavior b = new Behavior(logFilter);
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
        List actions = b.actions;
        if (actions == null || actions.length == 0) {
          continue; // No return values left in this Behavior.
        }
        // Get the first response.
        Responder response = actions[0];
        // If it is exhausted, remove it from the list.
        // Note that for endlessly repeating values, we started the count at
        // 0, so we get a potentially useful value here, which is the
        // (negation of) the number of times we returned the value.
        if (--response.count == 0) {
          actions.removeRange(0, 1);
          if (actions.length == 0) {
            // Remove the behavior. Note that in the future there
            // may be some value in preserving the behaviors for
            // auditing purposes (e.g. how many times was this behavior used?).
            // If we do decide to keep them and perf is an issue instead of
            // deleting we could move this to a separate list.
            behaviors.remove(k);
          }
        }
        // Do the response.
        var action = response.action;
        var value = response.value;
        switch (action) {
          case RETURN:
            log.add(new LogEntry(name, args, action, value));
            return value;
          case THROW:
            log.add(new LogEntry(name, args, action, value));
            throw value;
          case PROXY:
            var rtn;
            switch (args.length) {
              case 0:
                rtn = value();
                break;
              case 1:
                rtn = value(args[0]);
                break;
              case 2:
                rtn = value(args[0], args[1]);
                break;
              case 3:
                rtn = value(args[0], args[1], args[2]);
                break;
              case 4:
                rtn = value(args[0], args[1], args[2], args[3]);
                break;
              case 5:
                rtn = value(args[0], args[1], args[2], args[3], args[4]);
                break;
              case 6:
                rtn = value(args[0], args[1], args[2], args[3],
                    args[4], args[5]);
                break;
              case 7:
                rtn = value(args[0], args[1], args[2], args[3],
                    args[4], args[5], args[6]);
                break;
              case 8:
                rtn = value(args[0], args[1], args[2], args[3],
                    args[4], args[5], args[6], args[7]);
                break;
              case 9:
                rtn = value(args[0], args[1], args[2], args[3],
                    args[4], args[5], args[6], args[7], args[8]);
                break;
              case 9:
                rtn = value(args[0], args[1], args[2], args[3],
                    args[4], args[5], args[6], args[7], args[8], args[9]);
                break;
              default:
                throw new Exception(
                    "Cannot proxy calls with more than 10 parameters");
            }
            log.add(new LogEntry(name, args, action, rtn));
            return rtn;
        }
      }
    }
    throw new Exception('No behavior specified for method $name');
  }

  /** [verifyZeroInteractions] returns true if no calls were made */
  bool verifyZeroInteractions() => log.logs.length == 0;
}

/**
 * [getLogs] extracts all calls from the call log of [mock] that match the
 * [logFilter] [CallMatcher], and returns the matching list of
 * [LogEntry]s. If [destructive] is false (the default) the matching
 * calls are left in the mock object's log, else they are removed.
 * Removal allows us to verify a set of interactions and then verify
 * that there are no other interactions left.
 *
 * Typical usage:
 *
 *     getLogs(mock, callsTo(...)).verify(...);
 */
LogEntryList getLogs(Mock mock, CallMatcher logFilter,
                    [bool destructive = false]) {
    return mock.log.getMatches(logFilter, destructive);
}


