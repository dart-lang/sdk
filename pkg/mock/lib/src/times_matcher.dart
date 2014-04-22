// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock.times_matcher;

import 'package:matcher/matcher.dart';

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
