// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock.result_matcher;

import 'package:matcher/matcher.dart';

import 'action.dart';
import 'log_entry.dart';

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
    if (action == Action.RETURN || action == Action.PROXY) {
      description.add('return ');
    } else {
      description.add('throw ');
    }
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
