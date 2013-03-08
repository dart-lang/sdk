// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library scheduled_future_matchers;

import 'dart:async';

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
Matcher completes = const _ScheduledCompletes(null);

/// Matches a [Future] that completes succesfully with a value that matches
/// [matcher]. Note that this creates an asynchronous expectation. The call to
/// `expect()` that includes this will return immediately and execution will
/// continue. Later, when the future completes, the actual expectation will run.
///
/// To test that a Future completes with an exception, you can use [throws] and
/// [throwsA].
///
/// This differs from the `completion` matcher in `unittest` in that it pipes
/// any errors in the Future to [currentSchedule], rather than reporting them in
/// the [expect]'s error message.
Matcher completion(matcher) => new _ScheduledCompletes(wrapMatcher(matcher));

class _ScheduledCompletes extends BaseMatcher {
  final Matcher _matcher;

  const _ScheduledCompletes(this._matcher);

  bool matches(item, MatchState matchState) {
    if (item is! Future) return false;

    wrapFuture(item.then((value) {
      if (_matcher != null) expect(value, _matcher);
    }));

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
