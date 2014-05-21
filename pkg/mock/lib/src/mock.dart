// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock.mock;

// TOOD(kevmoo): just use `Map`
import 'dart:collection' show LinkedHashMap;
import 'dart:mirrors';

import 'package:matcher/matcher.dart';

import 'action.dart';
import 'behavior.dart';
import 'call_matcher.dart';
import 'log_entry.dart';
import 'log_entry_list.dart';
import 'responder.dart';
import 'util.dart';

/** The base class for all mocked objects. */
@proxy
class Mock {
  /** The mock name. Needed if the log is shared; optional otherwise. */
  final String name;

  /** The set of [Behavior]s supported. */
  final LinkedHashMap<String, Behavior> _behaviors;

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
      if (method[method.length - 1] == '=') {
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
          var mir = reflect(value) as ClosureMirror;
          var rtn = mir.invoke(#call, invocation.positionalArguments,
              invocation.namedArguments).reflectee;
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
          '${qualifiedName(name, method)}.');
    } else if (_throwIfNoBehavior) {
      throw new Exception('No behavior specified for method '
          '${qualifiedName(name, method)}.');
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
                      [arg0 = NO_ARG,
                       arg1 = NO_ARG,
                       arg2 = NO_ARG,
                       arg3 = NO_ARG,
                       arg4 = NO_ARG,
                       arg5 = NO_ARG,
                       arg6 = NO_ARG,
                       arg7 = NO_ARG,
                       arg8 = NO_ARG,
                       arg9 = NO_ARG]) =>
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
