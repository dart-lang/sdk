// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of matcher;

/**
 * This returns a matcher that inverts [matcher] to its logical negation.
 */
Matcher isNot(matcher) => new _IsNot(wrapMatcher(matcher));

class _IsNot extends BaseMatcher {
  final Matcher _matcher;

  const _IsNot(Matcher this._matcher);

  bool matches(item, MatchState matchState) =>
      !_matcher.matches(item, matchState);

  Description describe(Description description) =>
    description.add('not ').addDescriptionOf(_matcher);
}

/**
 * This returns a matcher that matches if all of the matchers passed as
 * arguments (up to 7) match. Instead of passing the matchers separately
 * they can be passed as a single List argument.
 * Any argument that is not a matcher is implicitly wrapped in a
 * Matcher to check for equality.
*/
Matcher allOf(arg0,
             [arg1 = null,
              arg2 = null,
              arg3 = null,
              arg4 = null,
              arg5 = null,
              arg6 = null]) {
  if (arg0 is List) {
    expect(arg1, isNull);
    expect(arg2, isNull);
    expect(arg3, isNull);
    expect(arg4, isNull);
    expect(arg5, isNull);
    expect(arg6, isNull);
    for (int i = 0; i < arg0.length; i++) {
      arg0[i] = wrapMatcher(arg0[i]);
    }
    return new _AllOf(arg0);
  } else {
    List matchers = new List();
    if (arg0 != null) {
      matchers.add(wrapMatcher(arg0));
    }
    if (arg1 != null) {
      matchers.add(wrapMatcher(arg1));
    }
    if (arg2 != null) {
      matchers.add(wrapMatcher(arg2));
    }
    if (arg3 != null) {
      matchers.add(wrapMatcher(arg3));
    }
    if (arg4 != null) {
      matchers.add(wrapMatcher(arg4));
    }
    if (arg5 != null) {
      matchers.add(wrapMatcher(arg5));
    }
    if (arg6 != null) {
      matchers.add(wrapMatcher(arg6));
    }
    return new _AllOf(matchers);
  }
}

class _AllOf extends BaseMatcher {
  final Iterable<Matcher> _matchers;

  const _AllOf(this._matchers);

  bool matches(item, MatchState matchState) {
     for (var matcher in _matchers) {
       if (!matcher.matches(item, matchState)) {
         matchState.state = {
             'matcher': matcher,
             'state': matchState.state
         };
         return false;
       }
     }
     return true;
  }

  Description describeMismatch(item, Description mismatchDescription,
                               MatchState matchState, bool verbose) {
    var matcher = matchState.state['matcher'];
    mismatchDescription.addDescriptionOf(matcher).add(' ');
        matcher.describeMismatch(item, mismatchDescription,
            matchState.state['state'], verbose);
    return mismatchDescription;
  }

  Description describe(Description description) =>
      description.addAll('(', ' and ', ')', _matchers);
}

/**
 * Matches if any of the given matchers evaluate to true. The
 * arguments can be a set of matchers as separate parameters
 * (up to 7), or a List of matchers.
 *
 * The matchers are evaluated from left to right using short-circuit
 * evaluation, so evaluation stops as soon as a matcher returns true.
 *
 * Any argument that is not a matcher is implicitly wrapped in a
 * Matcher to check for equality.
*/

Matcher anyOf(arg0,
               [arg1 = null,
                arg2 = null,
                arg3 = null,
                arg4 = null,
                arg5 = null,
                arg6 = null]) {
  if (arg0 is List) {
    expect(arg1, isNull);
    expect(arg2, isNull);
    expect(arg3, isNull);
    expect(arg4, isNull);
    expect(arg5, isNull);
    expect(arg6, isNull);
    for (int i = 0; i < arg0.length; i++) {
      arg0[i] = wrapMatcher(arg0[i]);
    }
    return new _AnyOf(arg0);
  } else {
    List matchers = new List();
    if (arg0 != null) {
      matchers.add(wrapMatcher(arg0));
    }
    if (arg1 != null) {
      matchers.add(wrapMatcher(arg1));
    }
    if (arg2 != null) {
      matchers.add(wrapMatcher(arg2));
    }
    if (arg3 != null) {
      matchers.add(wrapMatcher(arg3));
    }
    if (arg4 != null) {
      matchers.add(wrapMatcher(arg4));
    }
    if (arg5 != null) {
      matchers.add(wrapMatcher(arg5));
    }
    if (arg6 != null) {
      matchers.add(wrapMatcher(arg6));
    }
    return new _AnyOf(matchers);
  }
}

class _AnyOf extends BaseMatcher {
  final Iterable<Matcher> _matchers;

  const _AnyOf(this._matchers);

  bool matches(item, MatchState matchState) {
     for (var matcher in _matchers) {
       if (matcher.matches(item, matchState)) {
         return true;
       }
     }
     return false;
  }

  Description describe(Description description) =>
    description.addAll('(', ' or ', ')', _matchers);
}

