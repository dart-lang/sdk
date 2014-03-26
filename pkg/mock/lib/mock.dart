// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A simple mocking/spy library.
 *
 * To create a mock objects for some class T, create a new class using:
 *
 *     class MockT extends Mock implements T {};
 *
 * Then specify the [Behavior] of the Mock for different methods using
 * [when] (to select the method and parameters) and then the [Action]s
 * for the [Behavior] by calling [thenReturn], [alwaysReturn], [thenThrow],
 * [alwaysThrow], [thenCall] or [alwaysCall].
 *
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
 * For getters and setters, use "get foo" and "set foo"-style arguments
 * to [callsTo].
 *
 * You can disable logging for a particular [Behavior] easily:
 *
 *     m.when(callsTo('bar')).logging = false;
 *
 * You can then use the mock object. Once you are done, to verify the
 * behavior, use [getLogs] to extract a relevant subset of method call
 * logs and apply [Matchers] to these through calling [verify].
 *
 * A Mock can be given a name when constructed. In this case instead of
 * keeping its own log, it uses a shared log. This can be useful to get an
 * audit trail of interleaved behavior. It is the responsibility of the user
 * to ensure that mock names, if used, are unique.
 *
 * Limitations:
 *
 * * only positional parameters are supported (up to 10);
 * * to mock getters you will need to include parentheses in the call
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
 *     getLogs(m, callsTo('add', anything)).verify(happenedExactly(2));
 *     getLogs(m, callsTo('add', 'foo')).verify(happenedOnce);
 *     getLogs(m, callsTo('add', 'isNull)).verify(neverHappened);
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
 * However, there is an even easier way, by calling [Mock.spy], e.g.:
 *
 *      var foo = new Foo();
 *      var spy = new Mock.spy(foo);
 *      print(spy.bar(1, 2, 3));
 *
 * Spys created with Mock.spy do not have user-defined behavior;
 * they are simply proxies,  and thus will throw an exception if
 * you call [when]. They capture all calls in the log, so you can
 * do assertions on their history, such as:
 *
 *       spy.getLogs(callsTo('bar')).verify(happenedOnce);
 *
 * [pub]: http://pub.dartlang.org
 */

library mock;

import 'dart:mirrors';
import 'dart:collection' show LinkedHashMap;

import 'package:matcher/matcher.dart';

/**
 * The error formatter for mocking is a bit different from the default one
 * for unit testing; instead of the third argument being a 'reason'
 * it is instead a [signature] describing the method signature filter
 * that was used to select the logs that were verified.
 */
String _mockingErrorFormatter(actual, Matcher matcher, String signature,
                              Map matchState, bool verbose) {
  var description = new StringDescription();
  description.add('Expected ${signature} ').addDescriptionOf(matcher).
      add('\n     but: ');
  matcher.describeMismatch(actual, description, matchState, verbose).add('.');
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
  void failMatch(actual, Matcher matcher, String reason,
                 Map matchState, bool verbose) {
    proxy.fail(_mockingErrorFormatter(actual, matcher, reason,
        matchState, verbose));
  }
}

_MockFailureHandler _mockFailureHandler = null;

/** Sentinel value for representing no argument. */
class _Sentinel {
  const _Sentinel();
}
const _noArg = const _Sentinel();

/** The ways in which a call to a mock method can be handled. */
class Action {
  /** Do nothing (void method) */
  static const IGNORE = const Action._('IGNORE');

  /** Return a supplied value. */
  static const RETURN = const Action._('RETURN');

  /** Throw a supplied value. */
  static const THROW = const Action._('THROW');

  /** Call a supplied function. */
  static const PROXY = const Action._('PROXY');

  const Action._(this.name);

  final String name;

  String toString() => 'Action: $name';
}

/**
 * The behavior of a method call in the mock library is specified
 * with [Responder]s. A [Responder] has a [value] to throw
 * or return (depending on the type of [action]),
 * and can either be one-shot, multi-shot, or infinitely repeating,
 * depending on the value of [count (1, greater than 1, or 0 respectively).
 */
class Responder {
  final Object value;
  final Action action;
  int count;
  Responder(this.value, [this.count = 1, this.action = Action.RETURN]);
}

/**
 * A [CallMatcher] is a special matcher used to match method calls (i.e.
 * a method name and set of arguments). It is not a [Matcher] like the
 * unit test [Matcher], but instead represents a method name and a
 * collection of [Matcher]s, one per argument, that will be applied
 * to the parameters to decide if the method call is a match.
 */
class CallMatcher {
  Matcher nameFilter;
  List<Matcher> argMatchers;

  /**
   * Constructor for [CallMatcher]. [name] can be null to
   * match anything, or a literal [String], a predicate [Function],
   * or a [Matcher]. The various arguments can be scalar values or
   * [Matcher]s.
   */
  CallMatcher([name,
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
    if (name == null) {
      nameFilter = anything;
    } else {
      nameFilter = wrapMatcher(name);
    }
    argMatchers = new List<Matcher>();
    if (identical(arg0, _noArg)) return;
    argMatchers.add(wrapMatcher(arg0));
    if (identical(arg1, _noArg)) return;
    argMatchers.add(wrapMatcher(arg1));
    if (identical(arg2, _noArg)) return;
    argMatchers.add(wrapMatcher(arg2));
    if (identical(arg3, _noArg)) return;
    argMatchers.add(wrapMatcher(arg3));
    if (identical(arg4, _noArg)) return;
    argMatchers.add(wrapMatcher(arg4));
    if (identical(arg5, _noArg)) return;
    argMatchers.add(wrapMatcher(arg5));
    if (identical(arg6, _noArg)) return;
    argMatchers.add(wrapMatcher(arg6));
    if (identical(arg7, _noArg)) return;
    argMatchers.add(wrapMatcher(arg7));
    if (identical(arg8, _noArg)) return;
    argMatchers.add(wrapMatcher(arg8));
    if (identical(arg9, _noArg)) return;
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
    d.addDescriptionOf(nameFilter);
    // If the nameFilter was a simple string - i.e. just a method name -
    // strip the quotes to make this more natural in appearance.
    if (d.toString()[0] == "'") {
      d.replace(d.toString().substring(1, d.toString().length - 1));
    }
    d.add('(');
    for (var i = 0; i < argMatchers.length; i++) {
      if (i > 0) d.add(', ');
      d.addDescriptionOf(argMatchers[i]);
    }
    d.add(')');
    return d.toString();
  }

  /**
   * Given a [method] name and list of [arguments], return true
   * if it matches this [CallMatcher.
   */
  bool matches(String method, List arguments) {
    var matchState = {};
    if (!nameFilter.matches(method, matchState)) {
      return false;
    }
    var numArgs = (arguments == null) ? 0 : arguments.length;
    if (numArgs < argMatchers.length) {
      throw new Exception("Less arguments than matchers for $method.");
    }
    for (var i = 0; i < argMatchers.length; i++) {
      if (!argMatchers[i].matches(arguments[i], matchState)) {
        return false;
      }
    }
    return true;
  }
}

/**
 * Returns a [CallMatcher] for the specified signature. [method] can be
 * null to match anything, or a literal [String], a predicate [Function],
 * or a [Matcher]. The various arguments can be scalar values or [Matcher]s.
 * To match getters and setters, use "get " and "set " prefixes on the names.
 * For example, for a property "foo", you could use "get foo" and "set foo"
 * as literal string arguments to callsTo to match the getter and setter
 * of "foo".
 */
CallMatcher callsTo([method,
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
  bool logging = true;

  Behavior (this.matcher) {
    actions = new List<Responder>();
  }

  /**
   * Adds a [Responder] that returns a [value] for [count] calls
   * (1 by default).
   */
  Behavior thenReturn(value, [count = 1]) {
    actions.add(new Responder(value, count, Action.RETURN));
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
    actions.add(new Responder(value, count, Action.THROW));
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
    actions.add(new Responder(value, count, Action.PROXY));
    return this; // For chaining calls.
  }

  /** Creates a repeating proxy call. */
  Behavior alwaysCall(value) {
    return thenCall(value, 0);
  }

  /** Returns true if a method call matches the [Behavior]. */
  bool matches(String method, List args) => matcher.matches(method, args);

  /** Returns the [matcher]'s representation. */
  String toString() => matcher.toString();
}

/**
 * Every call to a [Mock] object method is logged. The logs are
 * kept in instances of [LogEntry].
 */
class LogEntry {
  /** The time of the event. */
  DateTime time;

  /** The mock object name, if any. */
  final String mockName;

  /** The method name. */
  final String methodName;

  /** The parameters. */
  final List args;

  /** The behavior that resulted. */
  final Action action;

  /** The value that was returned (if no throw). */
  final value;

  LogEntry(this.mockName, this.methodName,
      this.args, this.action, [this.value]) {
    time = new DateTime.now();
  }

  String _pad2(int val) => (val >= 10 ? '$val' : '0$val');

  String toString([DateTime baseTime]) {
    Description d = new StringDescription();
    if (baseTime == null) {
      // Show absolute time.
      d.add('${time.hour}:${_pad2(time.minute)}:'
          '${_pad2(time.second)}.${time.millisecond}>  ');
    } else {
      // Show relative time.
      int delta = time.millisecondsSinceEpoch - baseTime.millisecondsSinceEpoch;
      int secs = delta ~/ 1000;
      int msecs = delta % 1000;
      d.add('$secs.$msecs>  ');
    }
    d.add('${_qualifiedName(mockName, methodName)}(');
    if (args != null) {
      for (var i = 0; i < args.length; i++) {
        if (i != 0) d.add(', ');
        d.addDescriptionOf(args[i]);
      }
    }
    d.add(') ${action == Action.THROW ? "threw" : "returned"} ');
    d.addDescriptionOf(value);
    return d.toString();
  }
}

/** Utility function for optionally qualified method names */
String _qualifiedName(owner, String method) {
  if (owner == null || identical(owner, anything)) {
    return method;
  } else if (owner is Matcher) {
    Description d = new StringDescription();
    d.addDescriptionOf(owner);
    d.add('.');
    d.add(method);
    return d.toString();
  } else {
    return '$owner.$method';
  }
}

/**
* [StepValidator]s are used by [stepwiseValidate] in [LogEntryList], which
* iterates through the list and call the [StepValidator] function with the
* log [List] and position. The [StepValidator] should return the number of
* positions to advance upon success, or zero upon failure. When zero is
* returned an error is reported.
*/
typedef int StepValidator(List<LogEntry> logs, int pos);

/**
 * We do verification on a list of [LogEntry]s. To allow chaining
 * of calls to verify, we encapsulate such a list in the [LogEntryList]
 * class.
 */
class LogEntryList {
  String filter;
  List<LogEntry> logs;
  LogEntryList([this.filter]) {
    logs = new List<LogEntry>();
  }

  /** Add a [LogEntry] to the log. */
  add(LogEntry entry) => logs.add(entry);

  /** Get the first entry, or null if no entries. */
  get first => (logs == null || logs.length == 0) ? null : logs[0];

  /** Get the last entry, or null if no entries. */
  get last => (logs == null || logs.length == 0) ? null : logs.last;

  /** Creates a LogEntry predicate function from the argument. */
  Function _makePredicate(arg) {
    if (arg == null) {
      return (e) => true;
    } else if (arg is CallMatcher) {
      return (e) => arg.matches(e.methodName, e.args);
    } else if (arg is Function) {
      return arg;
    } else {
      throw new Exception("Invalid argument to _makePredicate.");
    }
  }

  /**
   * Create a new [LogEntryList] consisting of [LogEntry]s from
   * this list that match the specified [mockNameFilter] and [logFilter].
   * [mockNameFilter] can be null, a [String], a predicate [Function],
   * or a [Matcher]. If [mockNameFilter] is null, this is the same as
   * [anything].
   * If [logFilter] is null, all entries in the log will be returned.
   * Otherwise [logFilter] should be a [CallMatcher] or  predicate function
   * that takes a [LogEntry] and returns a bool.
   * If [destructive] is true, the log entries are removed from the
   * original list.
   */
  LogEntryList getMatches([mockNameFilter,
                          logFilter,
                          Matcher actionMatcher,
                          bool destructive = false]) {
    if (mockNameFilter == null) {
      mockNameFilter = anything;
    } else {
      mockNameFilter = wrapMatcher(mockNameFilter);
    }
    Function entryFilter = _makePredicate(logFilter);
    String filterName = _qualifiedName(mockNameFilter, logFilter.toString());
    LogEntryList rtn = new LogEntryList(filterName);
    var matchState = {};
    for (var i = 0; i < logs.length; i++) {
      LogEntry entry = logs[i];
      if (mockNameFilter.matches(entry.mockName, matchState) &&
          entryFilter(entry)) {
        if (actionMatcher == null ||
            actionMatcher.matches(entry, matchState)) {
          rtn.add(entry);
          if (destructive) {
            int startIndex = i--;
            logs.removeRange(startIndex, startIndex + 1);
          }
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
    expect(logs, matcher, reason:filter, failureHandler: _mockFailureHandler);
    return this;
  }

  /**
   * Iterate through the list and call the [validator] function with the
   * log [List] and position. The [validator] should return the number of
   * positions to advance upon success, or zero upon failure. When zero is
   * returned an error is reported. [reason] can be used to provide a
   * more descriptive failure message. If a failure occurred false will be
   * returned (unless the failure handler itself threw an exception);
   * otherwise true is returned.
   * The use case here is to perform more complex validations; for example
   * we may want to assert that the return value from some function is
   * later used as a parameter to a following function. If we filter the logs
   * to include just these two functions we can write a simple validator to
   * do this check.
   */
  bool stepwiseValidate(StepValidator validator, [String reason = '']) {
    if (_mockFailureHandler == null) {
      _mockFailureHandler =
          new _MockFailureHandler(getOrCreateExpectFailureHandler());
    }
    var i = 0;
    while (i < logs.length) {
      var n = validator(logs, i);
      if (n == 0) {
        if (reason.length > 0) {
          reason = ': $reason';
        }
        _mockFailureHandler.fail("Stepwise validation failed at $filter "
                                 "position $i$reason");
        return false;
      } else {
        i += n;
      }
    }
    return true;
  }

  /**
   * Turn the logs into human-readable text. If [baseTime] is specified
   * then each entry is prefixed with the offset from that time in
   * milliseconds; otherwise the time of day is used.
   */
  String toString([DateTime baseTime]) {
    String s = '';
    for (var e in logs) {
      s = '$s${e.toString(baseTime)}\n';
    }
    return s;
  }

  /**
   *  Find the first log entry that satisfies [logFilter] and
   *  return its position. A search [start] position can be provided
   *  to allow for repeated searches. [logFilter] can be a [CallMatcher],
   *  or a predicate function that takes a [LogEntry] argument and returns
   *  a bool. If [logFilter] is null, it will match any [LogEntry].
   *  If no entry is found, then [failureReturnValue] is returned.
   *  After each check the position is updated by [skip], so using
   *  [skip] of -1 allows backward searches, using a [skip] of 2 can
   *  be used to check pairs of adjacent entries, and so on.
   */
  int findLogEntry(logFilter, [int start = 0, int failureReturnValue = -1,
      skip = 1]) {
    logFilter = _makePredicate(logFilter);
    int pos = start;
    while (pos >= 0 && pos < logs.length) {
      if (logFilter(logs[pos])) {
        return pos;
      }
      pos += skip;
    }
    return failureReturnValue;
  }

  /**
   * Returns log events that happened up to the first one that
   * satisfies [logFilter]. If [inPlace] is true, then returns
   * this LogEntryList after removing the from the first satisfier;
   * onwards otherwise a new list is created. [description]
   * is used to create a new name for the resulting list.
   * [defaultPosition] is used as the index of the matching item in
   * the case that no match is found.
   */
  LogEntryList _head(logFilter, bool inPlace,
                     String description, int defaultPosition) {
    if (filter != null) {
      description = '$filter $description';
    }
    int pos = findLogEntry(logFilter, 0, defaultPosition);
    if (inPlace) {
      if (pos < logs.length) {
        logs.removeRange(pos, logs.length);
      }
      filter = description;
      return this;
    } else {
      LogEntryList newList = new LogEntryList(description);
      for (var i = 0; i < pos; i++) {
        newList.logs.add(logs[i]);
      }
      return newList;
    }
  }

  /**
   * Returns log events that happened from the first one that
   * satisfies [logFilter]. If [inPlace] is true, then returns
   * this LogEntryList after removing the entries up to the first
   * satisfier; otherwise a new list is created. [description]
   * is used to create a new name for the resulting list.
   * [defaultPosition] is used as the index of the matching item in
   * the case that no match is found.
   */
  LogEntryList _tail(logFilter, bool inPlace,
                     String description, int defaultPosition) {
    if (filter != null) {
      description = '$filter $description';
    }
    int pos = findLogEntry(logFilter, 0, defaultPosition);
    if (inPlace) {
      if (pos > 0) {
        logs.removeRange(0, pos);
      }
      filter = description;
      return this;
    } else {
      LogEntryList newList = new LogEntryList(description);
      while (pos < logs.length) {
        newList.logs.add(logs[pos++]);
      }
      return newList;
    }
  }

  /**
   * Returns log events that happened after [when]. If [inPlace]
   * is true, then it returns this LogEntryList after removing
   * the entries that happened up to [when]; otherwise a new
   * list is created.
   */
  LogEntryList after(DateTime when, [bool inPlace = false]) =>
      _tail((e) => e.time.isAfter(when), inPlace, 'after $when', logs.length);

  /**
   * Returns log events that happened from [when] onwards. If
   * [inPlace] is true, then it returns this LogEntryList after
   * removing the entries that happened before [when]; otherwise
   * a new list is created.
   */
  LogEntryList from(DateTime when, [bool inPlace = false]) =>
      _tail((e) => !e.time.isBefore(when), inPlace, 'from $when', logs.length);

  /**
   * Returns log events that happened until [when]. If [inPlace]
   * is true, then it returns this LogEntryList after removing
   * the entries that happened after [when]; otherwise a new
   * list is created.
   */
  LogEntryList until(DateTime when, [bool inPlace = false]) =>
      _head((e) => e.time.isAfter(when), inPlace, 'until $when', logs.length);

  /**
   * Returns log events that happened before [when]. If [inPlace]
   * is true, then it returns this LogEntryList after removing
   * the entries that happened from [when] onwards; otherwise a new
   * list is created.
   */
  LogEntryList before(DateTime when, [bool inPlace = false]) =>
      _head((e) => !e.time.isBefore(when),
            inPlace,
            'before $when',
            logs.length);

  /**
   * Returns log events that happened after [logEntry]'s time.
   * If [inPlace] is true, then it returns this LogEntryList after
   * removing the entries that happened up to [when]; otherwise a new
   * list is created. If [logEntry] is null the current time is used.
   */
  LogEntryList afterEntry(LogEntry logEntry, [bool inPlace = false]) =>
      after(logEntry == null ? new DateTime.now() : logEntry.time);

  /**
   * Returns log events that happened from [logEntry]'s time onwards.
   * If [inPlace] is true, then it returns this LogEntryList after
   * removing the entries that happened before [when]; otherwise
   * a new list is created. If [logEntry] is null the current time is used.
   */
  LogEntryList fromEntry(LogEntry logEntry, [bool inPlace = false]) =>
      from(logEntry == null ? new DateTime.now() : logEntry.time);

  /**
   * Returns log events that happened until [logEntry]'s time. If
   * [inPlace] is true, then it returns this LogEntryList after removing
   * the entries that happened after [when]; otherwise a new
   * list is created. If [logEntry] is null the epoch time is used.
   */
  LogEntryList untilEntry(LogEntry logEntry, [bool inPlace = false]) =>
      until(logEntry == null ?
          new DateTime.fromMillisecondsSinceEpoch(0) : logEntry.time);

  /**
   * Returns log events that happened before [logEntry]'s time. If
   * [inPlace] is true, then it returns this LogEntryList after removing
   * the entries that happened from [when] onwards; otherwise a new
   * list is created. If [logEntry] is null the epoch time is used.
   */
  LogEntryList beforeEntry(LogEntry logEntry, [bool inPlace = false]) =>
      before(logEntry == null ?
          new DateTime.fromMillisecondsSinceEpoch(0) : logEntry.time);

  /**
   * Returns log events that happened after the first event in [segment].
   * If [inPlace] is true, then it returns this LogEntryList after removing
   * the entries that happened earlier; otherwise a new list is created.
   */
  LogEntryList afterFirst(LogEntryList segment, [bool inPlace = false]) =>
      afterEntry(segment.first, inPlace);

  /**
   * Returns log events that happened after the last event in [segment].
   * If [inPlace] is true, then it returns this LogEntryList after removing
   * the entries that happened earlier; otherwise a new list is created.
   */
  LogEntryList afterLast(LogEntryList segment, [bool inPlace = false]) =>
      afterEntry(segment.last, inPlace);

  /**
   * Returns log events that happened from the time of the first event in
   * [segment] onwards. If [inPlace] is true, then it returns this
   * LogEntryList after removing the earlier entries; otherwise a new list
   * is created.
   */
  LogEntryList fromFirst(LogEntryList segment, [bool inPlace = false]) =>
      fromEntry(segment.first, inPlace);

  /**
   * Returns log events that happened from the time of the last event in
   * [segment] onwards. If [inPlace] is true, then it returns this
   * LogEntryList after removing the earlier entries; otherwise a new list
   * is created.
   */
  LogEntryList fromLast(LogEntryList segment, [bool inPlace = false]) =>
      fromEntry(segment.last, inPlace);

  /**
   * Returns log events that happened until the first event in [segment].
   * If [inPlace] is true, then it returns this LogEntryList after removing
   * the entries that happened later; otherwise a new list is created.
   */
  LogEntryList untilFirst(LogEntryList segment, [bool inPlace = false]) =>
      untilEntry(segment.first, inPlace);

  /**
   * Returns log events that happened until the last event in [segment].
   * If [inPlace] is true, then it returns this LogEntryList after removing
   * the entries that happened later; otherwise a new list is created.
   */
  LogEntryList untilLast(LogEntryList segment, [bool inPlace = false]) =>
      untilEntry(segment.last, inPlace);

  /**
   * Returns log events that happened before the first event in [segment].
   * If [inPlace] is true, then it returns this LogEntryList after removing
   * the entries that happened later; otherwise a new list is created.
   */
  LogEntryList beforeFirst(LogEntryList segment, [bool inPlace = false]) =>
      beforeEntry(segment.first, inPlace);

  /**
   * Returns log events that happened before the last event in [segment].
   * If [inPlace] is true, then it returns this LogEntryList after removing
   * the entries that happened later; otherwise a new list is created.
   */
  LogEntryList beforeLast(LogEntryList segment, [bool inPlace = false]) =>
      beforeEntry(segment.last, inPlace);

  /**
   * Iterate through the LogEntryList looking for matches to the entries
   * in [keys]; for each match found the closest [distance] neighboring log
   * entries that match [mockNameFilter] and [logFilter] will be included in
   * the result. If [isPreceding] is true we use the neighbors that precede
   * the matched entry; else we use the neighbors that followed.
   * If [includeKeys] is true then the entries in [keys] that resulted in
   * entries in the output list are themselves included in the output list. If
   * [distance] is zero then all matches are included.
   */
  LogEntryList _neighboring(bool isPreceding,
                            LogEntryList keys,
                            mockNameFilter,
                            logFilter,
                            int distance,
                            bool includeKeys) {
    String filterName = 'Calls to '
        '${_qualifiedName(mockNameFilter, logFilter.toString())} '
        '${isPreceding?"preceding":"following"} ${keys.filter}';

    LogEntryList rtn = new LogEntryList(filterName);

    // Deal with the trivial case.
    if (logs.length == 0 || keys.logs.length == 0) {
      return rtn;
    }

    // Normalize the mockNameFilter and logFilter values.
    if (mockNameFilter == null) {
      mockNameFilter = anything;
    } else {
      mockNameFilter = wrapMatcher(mockNameFilter);
    }
    logFilter = _makePredicate(logFilter);

    // The scratch list is used to hold matching entries when we
    // are doing preceding neighbors. The remainingCount is used to
    // keep track of how many matching entries we can still add in the
    // current segment (0 if we are doing doing following neighbors, until
    // we get our first key match).
    List scratch = null;
    int remainingCount = 0;
    if (isPreceding) {
      scratch = new List();
      remainingCount = logs.length;
    }

    var keyIterator = keys.logs.iterator;
    keyIterator.moveNext();
    LogEntry keyEntry = keyIterator.current;
    Map matchState = {};

    for (LogEntry logEntry in logs) {
      // If we have a log entry match, copy the saved matches from the
      // scratch buffer into the return list, as well as the matching entry,
      // if appropriate, and reset the scratch buffer. Continue processing
      // from the next key entry.
      if (keyEntry == logEntry) {
        if (scratch != null) {
          int numToCopy = scratch.length;
          if (distance > 0 && distance < numToCopy) {
            numToCopy = distance;
          }
          for (var i = scratch.length - numToCopy; i < scratch.length; i++) {
            rtn.logs.add(scratch[i]);
          }
          scratch.clear();
        } else {
          remainingCount = distance > 0 ? distance : logs.length;
        }
        if (includeKeys) {
          rtn.logs.add(keyEntry);
        }
        if (keyIterator.moveNext()) {
          keyEntry = keyIterator.current;
        } else if (isPreceding) { // We're done.
          break;
        }
      } else if (remainingCount > 0 &&
                 mockNameFilter.matches(logEntry.mockName, matchState) &&
                 logFilter(logEntry)) {
        if (scratch != null) {
          scratch.add(logEntry);
        } else {
          rtn.logs.add(logEntry);
          --remainingCount;
        }
      }
    }
    return rtn;
  }

  /**
   * Iterate through the LogEntryList looking for matches to the entries
   * in [keys]; for each match found the closest [distance] prior log entries
   * that match [mocknameFilter] and [logFilter] will be included in the result.
   * If [includeKeys] is true then the entries in [keys] that resulted in
   * entries in the output list are themselves included in the output list. If
   * [distance] is zero then all matches are included.
   *
   * The idea here is that you could find log entries that are related to
   * other logs entries in some temporal sense. For example, say we have a
   * method commit() that returns -1 on failure. Before commit() gets called
   * the value being committed is created by process(). We may want to find
   * the calls to process() that preceded calls to commit() that failed.
   * We could do this with:
   *
   *      print(log.preceding(log.getLogs(callsTo('commit'), returning(-1)),
   *          logFilter: callsTo('process')).toString());
   *
   * We might want to include the details of the failing calls to commit()
   * to see what parameters were passed in, in which case we would set
   * [includeKeys].
   *
   * As another simple example, say we wanted to know the three method
   * calls that immediately preceded each failing call to commit():
   *
   *     print(log.preceding(log.getLogs(callsTo('commit'), returning(-1)),
   *         distance: 3).toString());
   */
  LogEntryList preceding(LogEntryList keys,
                         {mockNameFilter: null,
                         logFilter: null,
                         int distance: 1,
                         bool includeKeys: false}) =>
      _neighboring(true, keys, mockNameFilter, logFilter,
          distance, includeKeys);

  /**
   * Iterate through the LogEntryList looking for matches to the entries
   * in [keys]; for each match found the closest [distance] subsequent log
   * entries that match [mocknameFilter] and [logFilter] will be included in
   * the result. If [includeKeys] is true then the entries in [keys] that
   * resulted in entries in the output list are themselves included in the
   * output list. If [distance] is zero then all matches are included.
   * See [preceding] for a usage example.
   */
  LogEntryList following(LogEntryList keys,
                         {mockNameFilter: null,
                         logFilter: null,
                         int distance: 1,
                         bool includeKeys: false}) =>
      _neighboring(false, keys, mockNameFilter, logFilter,
          distance, includeKeys);
}

/**
 * [_TimesMatcher]s are used to make assertions about the number of
 * times a method was called.
 */
class _TimesMatcher extends Matcher {
  final int min, max;

  const _TimesMatcher(this.min, [this.max = -1]);

  bool matches(logList, Map matchState) => logList.length >= min &&
      (max < 0 || logList.length <= max);

  Description describe(Description description) {
    description.add('to be called ');
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

  Description describeMismatch(logList, Description mismatchDescription,
                               Map matchState, bool verbose) =>
      mismatchDescription.add('was called ${logList.length} times');
}

/** [happenedExactly] matches an exact number of calls. */
Matcher happenedExactly(count) {
  return new _TimesMatcher(count, count);
}

/** [happenedAtLeast] matches a minimum number of calls. */
Matcher happenedAtLeast(count) {
  return new _TimesMatcher(count);
}

/** [happenedAtMost] matches a maximum number of calls. */
Matcher happenedAtMost(count) {
  return new _TimesMatcher(0, count);
}

/** [neverHappened] matches zero calls. */
const Matcher neverHappened = const _TimesMatcher(0, 0);

/** [happenedOnce] matches exactly one call. */
const Matcher happenedOnce = const _TimesMatcher(1, 1);

/** [happenedAtLeastOnce] matches one or more calls. */
const Matcher happenedAtLeastOnce = const _TimesMatcher(1);

/** [happenedAtMostOnce] matches zero or one call. */
const Matcher happenedAtMostOnce = const _TimesMatcher(0, 1);

/**
 * [_ResultMatcher]s are used to make assertions about the results
 * of method calls. These can be used as optional parameters to [getLogs].
 */
class _ResultMatcher extends Matcher {
  final Action action;
  final Matcher value;

  const _ResultMatcher(this.action, this.value);

  bool matches(item, Map matchState) {
    if (item is! LogEntry) {
     return false;
    }
    // normalize the action; _PROXY is like _RETURN.
    Action eaction = item.action;
    if (eaction == Action.PROXY) {
      eaction = Action.RETURN;
    }
    return (eaction == action && value.matches(item.value, matchState));
  }

  Description describe(Description description) {
    description.add(' to ');
    if (action == Action.RETURN || action == Action.PROXY)
      description.add('return ');
    else
      description.add('throw ');
    return description.addDescriptionOf(value);
  }

  Description describeMismatch(item, Description mismatchDescription,
                               Map matchState, bool verbose) {
    if (item.action == Action.RETURN || item.action == Action.PROXY) {
      mismatchDescription.add('returned ');
    } else {
      mismatchDescription.add('threw ');
    }
    mismatchDescription.add(item.value);
    return mismatchDescription;
  }
}

/**
 *[returning] matches log entries where the call to a method returned
 * a value that matched [value].
 */
Matcher returning(value) =>
    new _ResultMatcher(Action.RETURN, wrapMatcher(value));

/**
 *[throwing] matches log entrues where the call to a method threw
 * a value that matched [value].
 */
Matcher throwing(value) =>
    new _ResultMatcher(Action.THROW, wrapMatcher(value));

/** Special values for use with [_ResultSetMatcher] [frequency]. */
class _Frequency {
  /** Every call/throw must match */
  static const ALL = const _Frequency._('ALL');

  /** At least one call/throw must match. */
  static const SOME = const _Frequency._('SOME');

  /** No calls/throws should match. */
  static const NONE = const _Frequency._('NONE');

  const _Frequency._(this.name);

  final String name;
}

/**
 * [_ResultSetMatcher]s are used to make assertions about the results
 * of method calls. When filtering an execution log by calling
 * [getLogs], a [LogEntrySet] of matching call logs is returned;
 * [_ResultSetMatcher]s can then assert various things about this
 * (sub)set of logs.
 *
 * We could make this class use _ResultMatcher but it doesn't buy that
 * match and adds some perf hit, so there is some duplication here.
 */
class _ResultSetMatcher extends Matcher {
  final Action action;
  final Matcher value;
  final _Frequency frequency; // ALL, SOME, or NONE.

  const _ResultSetMatcher(this.action, this.value, this.frequency);

  bool matches(logList, Map matchState) {
    for (LogEntry entry in logList) {
      // normalize the action; PROXY is like RETURN.
      Action eaction = entry.action;
      if (eaction == Action.PROXY) {
        eaction = Action.RETURN;
      }
      if (eaction == action && value.matches(entry.value, matchState)) {
        if (frequency == _Frequency.NONE) {
          addStateInfo(matchState, {'entry': entry});
          return false;
        } else if (frequency == _Frequency.SOME) {
          return true;
        }
      } else {
        // Mismatch.
        if (frequency == _Frequency.ALL) { // We need just one mismatch to fail.
          addStateInfo(matchState, {'entry': entry});
          return false;
        }
      }
    }
    // If we get here, then if count is _ALL we got all matches and
    // this is success; otherwise we got all mismatched which is
    // success for count == _NONE and failure for count == _SOME.
    return (frequency != _Frequency.SOME);
  }

  Description describe(Description description) {
    description.add(' to ');
    description.add(frequency == _Frequency.ALL ? 'alway ' :
        (frequency == _Frequency.NONE ? 'never ' : 'sometimes '));
    if (action == Action.RETURN || action == Action.PROXY)
      description.add('return ');
    else
      description.add('throw ');
    return description.addDescriptionOf(value);
  }

  Description describeMismatch(logList, Description mismatchDescription,
                               Map matchState, bool verbose) {
    if (frequency != _Frequency.SOME) {
      LogEntry entry = matchState['entry'];
      if (entry.action == Action.RETURN || entry.action == Action.PROXY) {
        mismatchDescription.add('returned');
      } else {
        mismatchDescription.add('threw');
      }
      mismatchDescription.add(' value that ');
      value.describeMismatch(entry.value, mismatchDescription,
        matchState['state'], verbose);
      mismatchDescription.add(' at least once');
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
    new _ResultSetMatcher(Action.RETURN, wrapMatcher(value), _Frequency.ALL);

/**
 *[sometimeReturned] asserts that at least one matching call to a method
 * returned a value that matched [value].
 */
Matcher sometimeReturned(value) =>
    new _ResultSetMatcher(Action.RETURN, wrapMatcher(value), _Frequency.SOME);

/**
 *[neverReturned] asserts that no matching calls to a method returned
 * a value that matched [value].
 */
Matcher neverReturned(value) =>
    new _ResultSetMatcher(Action.RETURN, wrapMatcher(value), _Frequency.NONE);

/**
 *[alwaysThrew] asserts that all matching calls to a method threw
 * a value that matched [value].
 */
Matcher alwaysThrew(value) =>
    new _ResultSetMatcher(Action.THROW, wrapMatcher(value), _Frequency.ALL);

/**
 *[sometimeThrew] asserts that at least one matching call to a method threw
 * a value that matched [value].
 */
Matcher sometimeThrew(value) =>
  new _ResultSetMatcher(Action.THROW, wrapMatcher(value), _Frequency.SOME);

/**
 *[neverThrew] asserts that no matching call to a method threw
 * a value that matched [value].
 */
Matcher neverThrew(value) =>
  new _ResultSetMatcher(Action.THROW, wrapMatcher(value), _Frequency.NONE);

/** The shared log used for named mocks. */
LogEntryList sharedLog = null;

/** The base class for all mocked objects. */
@proxy
class Mock {
  /** The mock name. Needed if the log is shared; optional otherwise. */
  final String name;

  /** The set of [Behavior]s supported. */
  final LinkedHashMap<String,Behavior> _behaviors;

  /** How to handle unknown method calls - swallow or throw. */
  final bool _throwIfNoBehavior;

  /** For spys, the real object that we are spying on. */
  final Object _realObject;

  /** The [log] of calls made. Only used if [name] is null. */
  LogEntryList log;

  /** Whether to create an audit log or not. */
  bool _logging;

  bool get logging => _logging;
  set logging(bool value) {
    if (value && log == null) {
      log = new LogEntryList();
    }
    _logging = value;
  }

  /**
   * Default constructor. Unknown method calls are allowed and logged,
   * the mock has no name, and has its own log.
   */
  Mock() :
    _throwIfNoBehavior = false, log = null, name = null, _realObject = null,
    _behaviors = new LinkedHashMap<String,Behavior>() {
    logging = true;
  }

  /**
   * This constructor makes a mock that has a [name] and possibly uses
   * a shared [log]. If [throwIfNoBehavior] is true, any calls to methods
   * that have no defined behaviors will throw an exception; otherwise they
   * will be allowed and logged (but will not do anything).
   * If [enableLogging] is false, no logging will be done initially (whether
   * or not a [log] is supplied), but [logging] can be set to true later.
   */
  Mock.custom({this.name,
               this.log,
               throwIfNoBehavior: false,
               enableLogging: true})
      : _throwIfNoBehavior = throwIfNoBehavior, _realObject = null,
        _behaviors = new LinkedHashMap<String,Behavior>() {
    if (log != null && name == null) {
      throw new Exception("Mocks with shared logs must have a name.");
    }
    logging = enableLogging;
  }

  /**
   * This constructor creates a spy with no user-defined behavior.
   * This is simply a proxy for a real object that passes calls
   * through to that real object but captures an audit trail of
   * calls made to the object that can be queried and validated
   * later.
   */
  Mock.spy(this._realObject, {this.name, this.log})
    : _behaviors = null,
     _throwIfNoBehavior = true {
    logging = true;
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
    if (!_behaviors.containsKey(key)) {
      Behavior b = new Behavior(logFilter);
      _behaviors[key] = b;
      return b;
    } else {
      return _behaviors[key];
    }
  }

  /**
   * This is the handler for method calls. We loop through the list
   * of [Behavior]s, and find the first match that still has return
   * values available, and then do the action specified by that
   * return value. If we find no [Behavior] to apply an exception is
   * thrown.
   */
  noSuchMethod(Invocation invocation) {
    var method = MirrorSystem.getName(invocation.memberName);
    var args = invocation.positionalArguments;
    if (invocation.isGetter) {
      method = 'get $method';
    } else if (invocation.isSetter) {
      method = 'set $method';
      // Remove the trailing '='.
      if (method[method.length-1] == '=') {
        method = method.substring(0, method.length - 1);
      }
    }
    if (_behaviors == null) { // Spy.
      var mirror = reflect(_realObject);
      try {
        var result = mirror.delegate(invocation);
        log.add(new LogEntry(name, method, args, Action.PROXY, result));
        return result;
      } catch (e) {
        log.add(new LogEntry(name, method, args, Action.THROW, e));
        throw e;
      }
    }
    bool matchedMethodName = false;
    Map matchState = {};
    for (String k in _behaviors.keys) {
      Behavior b = _behaviors[k];
      if (b.matcher.nameFilter.matches(method, matchState)) {
        matchedMethodName = true;
      }
      if (b.matches(method, args)) {
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
        }
        // Do the response.
        Action action = response.action;
        var value = response.value;
        if (action == Action.RETURN) {
          if (_logging && b.logging) {
            log.add(new LogEntry(name, method, args, action, value));
          }
          return value;
        } else if (action == Action.THROW) {
          if (_logging && b.logging) {
            log.add(new LogEntry(name, method, args, action, value));
          }
          throw value;
        } else if (action == Action.PROXY) {
          // TODO(gram): Replace all this with:
          //     var rtn = reflect(value).apply(invocation.positionalArguments,
          //         invocation.namedArguments);
          // once that is supported.
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
                  "Cannot proxy calls with more than 10 parameters.");
          }
          if (_logging && b.logging) {
            log.add(new LogEntry(name, method, args, action, rtn));
          }
          return rtn;
        }
      }
    }
    if (matchedMethodName) {
      // User did specify behavior for this method, but all the
      // actions are exhausted. This is considered an error.
      throw new Exception('No more actions for method '
          '${_qualifiedName(name, method)}.');
    } else if (_throwIfNoBehavior) {
      throw new Exception('No behavior specified for method '
          '${_qualifiedName(name, method)}.');
    }
    // Otherwise user hasn't specified behavior for this method; we don't throw
    // so we can underspecify.
    if (_logging) {
      log.add(new LogEntry(name, method, args, Action.IGNORE));
    }
  }

  /** [verifyZeroInteractions] returns true if no calls were made */
  bool verifyZeroInteractions() {
    if (log == null) {
      // This means we created the mock with logging off and have never turned
      // it on, so it doesn't make sense to verify behavior on such a mock.
      throw new
          Exception("Can't verify behavior when logging was never enabled.");
    }
    return log.logs.length == 0;
  }

  /**
   * [getLogs] extracts all calls from the call log that match the
   * [logFilter], and returns the matching list of [LogEntry]s. If
   * [destructive] is false (the default) the matching calls are left
   * in the log, else they are removed. Removal allows us to verify a
   * set of interactions and then verify that there are no other
   * interactions left. [actionMatcher] can be used to further
   * restrict the returned logs based on the action the mock performed.
   * [logFilter] can be a [CallMatcher] or a predicate function that
   * takes a [LogEntry] and returns a bool.
   *
   * Typical usage:
   *
   *     getLogs(callsTo(...)).verify(...);
   */
  LogEntryList getLogs([CallMatcher logFilter,
                        Matcher actionMatcher,
                        bool destructive = false]) {
    if (log == null) {
      // This means we created the mock with logging off and have never turned
      // it on, so it doesn't make sense to get logs from such a mock.
      throw new
          Exception("Can't retrieve logs when logging was never enabled.");
    } else {
      return log.getMatches(name, logFilter, actionMatcher, destructive);
    }
  }

  /**
   * Useful shorthand method that creates a [CallMatcher] from its arguments
   * and then calls [getLogs].
   */
  LogEntryList calls(method,
                      [arg0 = _noArg,
                       arg1 = _noArg,
                       arg2 = _noArg,
                       arg3 = _noArg,
                       arg4 = _noArg,
                       arg5 = _noArg,
                       arg6 = _noArg,
                       arg7 = _noArg,
                       arg8 = _noArg,
                       arg9 = _noArg]) =>
      getLogs(callsTo(method, arg0, arg1, arg2, arg3, arg4,
          arg5, arg6, arg7, arg8, arg9));

  /** Clear the behaviors for the Mock. */
  void resetBehavior() => _behaviors.clear();

  /** Clear the logs for the Mock. */
  void clearLogs() {
    if (log != null) {
      if (name == null) { // This log is not shared.
        log.logs.clear();
      } else { // This log may be shared.
        log.logs = log.logs.where((e) => e.mockName != name).toList();
      }
    }
  }

  /** Clear both logs and behavior. */
  void reset() {
    resetBehavior();
    clearLogs();
  }
}
