// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock.result_set_matcher;

import 'package:matcher/matcher.dart';

import 'action.dart';
import 'log_entry.dart';

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
