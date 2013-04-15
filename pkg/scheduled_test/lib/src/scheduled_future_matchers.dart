// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library scheduled_future_matchers;

import 'dart:async';

import 'package:stack_trace/stack_trace.dart';

import '../scheduled_test.dart';

/// Matches a [Future] that completes successfully with a value. Note that this
/// creates an asynchronous expectation. The call to `expect()` that includes
/// this will return immediately and execution will continue. Later, when the
/// future completes, the actual expectation will run.
///
/// To test that a Future completes with an exception, you can use [throws] and
/// [throwsA].
///
/// This differs from the `completes` matcher in `unittest` in that it pipes any
/// errors in the Future to [currentSchedule], rather than reporting them in the
/// [expect]'s error message.
Matcher completes = const _ScheduledCompletes(null, null);

/// Matches a [Future] that completes succesfully with a value that matches
/// [matcher]. Note that this creates an asynchronous expectation. The call to
/// `expect()` that includes this will return immediately and execution will
/// continue. Later, when the future completes, the actual expectation will run.
///
/// To test that a Future completes with an exception, you can use [throws] and
/// [throwsA].
///
/// [description] is an optional tag that can be used to identify the completion
/// matcher in error messages.
///
/// This differs from the `completion` matcher in `unittest` in that it pipes
/// any errors in the Future to [currentSchedule], rather than reporting them in
/// the [expect]'s error message.
Matcher completion(matcher, [String description]) =>
    new _ScheduledCompletes(wrapMatcher(matcher), description);

class _ScheduledCompletes extends BaseMatcher {
  final Matcher _matcher;
  final String _description;

  const _ScheduledCompletes(this._matcher, this._description);

  bool matches(item, MatchState matchState) {
    if (item is! Future) return false;

    // TODO(nweiz): parse the stack, figure out on what line these were called,
    // and include that in their descriptions
    var description = _description;
    if (description == null) {
      if (_matcher == null) {
        description = 'expect(..., completes)';
      } else {
        var matcherDescription = new StringDescription();
        _matcher.describe(matcherDescription);
        description = 'expect(..., completion($matcherDescription))';
      }
    }

    var outerTrace = new Trace.current();
    currentSchedule.wrapFuture(item.then((value) {
      if (_matcher == null) return;

      // TODO(floitsch): we cannot switch traces anymore.
      // If expect throws we might want to be able to switch to the outer trace
      // instead.
      expect(value, _matcher);
    }), description);

    return true;
  }

  Description describe(Description description) {
    if (_matcher == null) {
      description.add('completes successfully');
    } else {
      description.add('completes to a value that ').addDescriptionOf(_matcher);
    }
    return description;
  }
}
