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
  matcher.describeMismatch(actual, description).add('.');
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
class _Action {
  /** Do nothing (void method) */
  static final IGNORE = const _Action._('IGNORE');

  /** Return a supplied value. */
  static final RETURN = const _Action._('RETURN');

  /** Throw a supplied value. */
  static final THROW = const _Action._('THROW');

  /** Call a supplied function. */
  static final PROXY = const _Action._('PROXY');

  const _Action._(this.name);

  final String name;
}

/**
 * The behavior of a method call in the mock library is specified
 * with [Responder]s. A [Responder] has a [value] to throw
 * or return (depending on whether [isThrow] is true or not, respectively),
 * and can either be one-shot, multi-shot, or infinitely repeating,
 * depending on the value of [count (1, greater than 1, or 0 respectively).
 */
class Responder {
  var value;
  _Action action;
  int count;
  Responder(this.value, [this.count = 1, this.action = _Action.RETURN]);
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
    d.addDescriptionOf(nameFilter);
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
    if (!nameFilter.matches(method)) {
      return false;
    }
    if (arguments.length < argMatchers.length) {
      throw new Exception("Less arguments than matchers for $method.");
    }
    for (var i = 0; i < argMatchers.length; i++) {
      if (!argMatchers[i].matches(arguments[i])) {
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

  Behavior (this.matcher) {
    actions = new List<Responder>();
  }

  /**
   * Adds a [Responder] that returns a [value] for [count] calls
   * (1 by default).
   */
  Behavior thenReturn(value, [count = 1]) {
    actions.add(new Responder(value, count, _Action.RETURN));
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
    actions.add(new Responder(value, count, _Action.THROW));
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
    actions.add(new Responder(value, count, _Action.PROXY));
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
  Date time;

  /** The mock object name, if any. */
  final String mockName;

  /** The method name. */
  final String methodName;

  /** The parameters. */
  final List args;

  /** The behavior that resulted. */
  final _Action action;

  /** The value that was returned (if no throw). */
  final value;

  LogEntry(this.mockName, this.methodName,
      this.args, this.action, [this.value]) {
    time = new Date.now();
  }

  String _pad2(int val) => (val >= 10 ? '$val' : '0$val');

  String toString([Date baseTime]) {
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
    for (var i = 0; i < args.length; i++) {
      if (i != 0) d.add(', ');
      d.addDescriptionOf(args[i]);
    }
    d.add(') ${action == _Action.THROW ? "threw" : "returned"} ');
    d.addDescriptionOf(value);
    return d.toString();
  }
}

/** Utility function for optionally qualified method names */
String _qualifiedName(owner, String method) {
  if (owner == null) {
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
 * We do verification on a list of [LogEntry]s. To allow chaining
 * of calls to verify, we encapsulate such a list in the [LogEntryList]
 * class.
 */
class LogEntryList {
  final String filter;
  List<LogEntry> logs;
  LogEntryList([this.filter]) {
    logs = new List<LogEntry>();
  }

  /** Add a [LogEntry] to the log. */
  add(LogEntry entry) => logs.add(entry);

  /**
   * Create a new [LogEntryList] consisting of [LogEntry]s from
   * this list that match the specified [mockNameFilter] and [logFilter].
   * [mockNameFilter] can be null, a [String], a predicate [Function],
   * or a [Matcher]. If [mockNameFilter] is null, only Mocks with no name
   * will be checked.
   * If [logFilter] is null, all entries in the log will be returned.
   * If [destructive] is true, the log entries are removed from the
   * original list.
   */
  LogEntryList getMatches([mockNameFilter,
                          CallMatcher logFilter,
                          Matcher actionMatcher,
                          bool destructive = false]) {
    mockNameFilter = wrapMatcher(mockNameFilter);
    if (logFilter == null) {
      logFilter = new CallMatcher();
    }
    String filterName = _qualifiedName(mockNameFilter, logFilter.toString());
    LogEntryList rtn = new LogEntryList(filterName);
    for (var i = 0; i < logs.length; i++) {
      LogEntry entry = logs[i];
      if (!mockNameFilter.matches(entry.mockName)) {
        continue;
      }
      if (logFilter.matches(entry.methodName, entry.args)) {
        if (actionMatcher == null || actionMatcher.matches(entry)) {
          rtn.add(entry);
          if (destructive) {
            logs.removeRange(i--, 1);
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
    expect(logs, matcher, filter, _mockFailureHandler);
    return this;
  }

  String toString([Date baseTime]) {
    String s = '';
    for (var e in logs) {
      s = '$s${e.toString(baseTime)}\n';
    }
    return s;
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
final Matcher neverHappened = const _TimesMatcher(0, 0);

/** [happenedOnce] matches exactly one call. */
final Matcher happenedOnce = const _TimesMatcher(1, 1);

/** [happenedAtLeastOnce] matches one or more calls. */
final Matcher happenedAtLeastOnce = const _TimesMatcher(1);

/** [happenedAtMostOnce] matches zero or one call. */
final Matcher happenedAtMostOnce = const _TimesMatcher(0, 1);

/**
 * [_ResultMatcher]s are used to make assertions about the results
 * of method calls. These can be used as optional parameters to [getLogs].
 */
class _ResultMatcher extends BaseMatcher {
  final _Action action;
  final Matcher value;

  const _ResultMatcher(this.action, this.value);

  bool matches(item) {
    if (item is! LogEntry) {
     return false;
    }
    // normalize the action; _PROXY is like _RETURN.
    _Action eaction = item.action;
    if (eaction == _Action.PROXY) {
      eaction = _Action.RETURN;
    }
    return (eaction == action && value.matches(item.value));
  }

  Description describe(Description description) {
    description.add(' to ');
    if (action == _Action.RETURN || action == _Action.PROXY)
      description.add('return ');
    else
      description.add('throw ');
    return description.addDescriptionOf(value);
  }

  Description describeMismatch(item, Description mismatchDescription) {
    if (item.action == _Action.RETURN || item.action == _Action.PROXY) {
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
    new _ResultMatcher(_Action.RETURN, wrapMatcher(value));

/**
 *[throwing] matches log entrues where the call to a method threw
 * a value that matched [value].
 */
Matcher throwing(value) =>
    new _ResultMatcher(_Action.THROW, wrapMatcher(value));

/** Special values for use with [_ResultSetMatcher] [frequency]. */
class _Frequency {
  /** Every call/throw must match */
  static final ALL = const _Frequency._('ALL');

  /** At least one call/throw must match. */
  static final SOME = const _Frequency._('SOME');

  /** No calls/throws should match. */
  static final NONE = const _Frequency._('NONE');

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
class _ResultSetMatcher extends BaseMatcher {
  final _Action action;
  final Matcher value;
  final _Frequency frequency; // ALL, SOME, or NONE.

  const _ResultSetMatcher(this.action, this.value, this.frequency);

  bool matches(log) {
    for (LogEntry entry in log) {
      // normalize the action; _PROXY is like _RETURN.
      _Action eaction = entry.action;
      if (eaction == _Action.PROXY) {
        eaction = _Action.RETURN;
      }
      if (eaction == action && value.matches(entry.value)) {
        if (frequency == _Frequency.NONE) {
          return false;
        } else if (frequency == _Frequency.SOME) {
          return true;
        }
      } else {
        // Mismatch.
        if (frequency == _Frequency.ALL) { // We need just one mismatch to fail.
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
    if (action == _Action.RETURN || action == __Action.PROXY)
      description.add('return ');
    else
      description.add('throw ');
    return description.addDescriptionOf(value);
  }

  Description describeMismatch(log, Description mismatchDescription) {
    if (frequency != _Frequency.SOME) {
      for (LogEntry entry in log) {
        if (entry.action != action || !value.matches(entry.value)) {
          if (entry.action == _Action.RETURN || entry.action == _Action.PROXY)
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
    new _ResultSetMatcher(_Action.RETURN, wrapMatcher(value), _Frequency.ALL);

/**
 *[sometimeReturned] asserts that at least one matching call to a method
 * returned a value that matched [value].
 */
Matcher sometimeReturned(value) =>
    new _ResultSetMatcher(_Action.RETURN, wrapMatcher(value), _Frequency.SOME);

/**
 *[neverReturned] asserts that no matching calls to a method returned
 * a value that matched [value].
 */
Matcher neverReturned(value) =>
    new _ResultSetMatcher(_Action.RETURN, wrapMatcher(value), _Frequency.NONE);

/**
 *[alwaysThrew] asserts that all matching calls to a method threw
 * a value that matched [value].
 */
Matcher alwaysThrew(value) =>
    new _ResultSetMatcher(_Action.THROW, wrapMatcher(value), _Frequency.ALL);

/**
 *[sometimeThrew] asserts that at least one matching call to a method threw
 * a value that matched [value].
 */
Matcher sometimeThrew(value) =>
  new _ResultSetMatcher(_Action.THROW, wrapMatcher(value), _Frequency.SOME);

/**
 *[neverThrew] asserts that no matching call to a method threw
 * a value that matched [value].
 */
Matcher neverThrew(value) =>
  new _ResultSetMatcher(_Action.THROW, wrapMatcher(value), _Frequency.NONE);

/** The shared log used for named mocks. */
LogEntryList sharedLog = null;

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
 * behavior, use [getLogs] to extract a relevant subset of method call
 * logs and apply [Matchers] to these through calling [verify].
 *
 * A Mock can be given a name when constructed. In this case instead of
 * keeping its own log, it uses a shared log. This can be useful to get an
 * audit trail of interleaved behavior. It is the responsibility of the user
 * to ensure that mock names, if used, are unique.
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
 */
class Mock {
  /** The mock name. Needed if the log is shared; optional otherwise. */
  final String name;

  /** The set of [Behavior]s supported. */
  Map<String,Behavior> _behaviors;

  /** The [log] of calls made. Only used if [name] is null. */
  LogEntryList log;

  /** How to handle unknown method calls - swallow or throw. */
  final bool _throwIfNoBehavior;

  /** Whether to create an audit log or not. */
  bool _logging;

  bool get logging() => _logging;
  bool set logging(bool value) {
    if (value && log == null) {
      log = new LogEntryList();
    }
    _logging = value;
  }

  /**
   * Default constructor. Unknown method calls are allowed and logged,
   * the mock has no name, and has its own log.
   */
  Mock() : _throwIfNoBehavior = false, log = null, name = null {
    logging = true;
    _behaviors = new Map<String,Behavior>();
  }

  /**
   * This constructor makes a mock that has a [name] and possibly uses
   * a shared [log]. If [throwIfNoBehavior] is true, any calls to methods
   * that have no defined behaviors will throw an exception; otherwise they
   * will be allowed and logged (but will not do anything).
   * If [enableLogging] is false, no logging will be done initially (whether
   * or not a [log] is supplied), but [logging] can be set to true later.
   */
  Mock.custom([this.name,
               this.log,
               throwIfNoBehavior = false,
               enableLogging = true]) : _throwIfNoBehavior = throwIfNoBehavior {
    logging = enableLogging;
    _behaviors = new Map<String,Behavior>();
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
   * This is the handler for method calls. We loo through the list
   * of [Behavior]s, and find the first match that still has return
   * values available, and then do the action specified by that
   * return value. If we find no [Behavior] to apply an exception is
   * thrown.
   */
  noSuchMethod(String method, List args) {
    if (method.startsWith('get:')) {
      method = 'get ${method.substring(4)}';
    }
    bool matchedMethodName = false;
    for (String k in _behaviors.getKeys()) {
      Behavior b = _behaviors[k];
      if (b.matcher.nameFilter.matches(method)) {
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
        _Action action = response.action;
        var value = response.value;
        if (action == _Action.RETURN) {
          if (_logging) {
            log.add(new LogEntry(name, method, args, action, value));
          }
          return value;
        } else if (action == _Action.THROW) {
          if (_logging) {
            log.add(new LogEntry(name, method, args, action, value));
          }
          throw value;
        } else if (action == _Action.PROXY) {
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
          if (_logging) {
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
      log.add(new LogEntry(name, method, args, _Action.IGNORE));
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
   * [logFilter] [CallMatcher], and returns the matching list of
   * [LogEntry]s. If [destructive] is false (the default) the matching
   * calls are left in the log, else they are removed. Removal allows
   * us to verify a set of interactions and then verify that there are
   * no other interactions left. [actionMatcher] can be used to further
   * restrict the returned logs based on the action the mock performed.
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
}
