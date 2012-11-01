// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Returns a matcher which matches [Collection]s in which all elements
 * match the given [matcher].
 */

part of matcher;

Matcher everyElement(matcher) => new _EveryElement(wrapMatcher(matcher));

class _EveryElement extends _CollectionMatcher {
  Matcher _matcher;

  _EveryElement(Matcher this._matcher);

  bool matches(item, MatchState matchState) {
    if (item is! Iterable) {
      return false;
    }
    var i = 0;
    for (var element in item) {
      if (!_matcher.matches(element, matchState)) {
        matchState.state = {
            'index': i,
            'element': element,
            'state': matchState.state
        };
        return false;
      }
      ++i;
    }
    return true;
  }

  Description describe(Description description) =>
      description.add('every element ').addDescriptionOf(_matcher);

  Description describeMismatch(item, Description mismatchDescription,
                               MatchState matchState, bool verbose) {
    if (matchState.state != null) {
      var index = matchState.state['index'];
      var element = matchState.state['element'];
      return _matcher.describeMismatch(element, mismatchDescription,
            matchState.state['state'], verbose).add(' at position $index');
    }
    return super.describeMismatch(item, mismatchDescription,
          matchState, verbose);
  }
}

/**
 * Returns a matcher which matches [Collection]s in which at least one
 * element matches the given [matcher].
 */
Matcher someElement(matcher) => new _SomeElement(wrapMatcher(matcher));

class _SomeElement extends _CollectionMatcher {
  Matcher _matcher;

  _SomeElement(this._matcher);

  bool matches(item, MatchState matchState) {
    return item.some( (e) => _matcher.matches(e, matchState) );
  }

  Description describe(Description description) =>
      description.add('some element ').addDescriptionOf(_matcher);
}

/**
 * Returns a matcher which matches [Iterable]s that have the same
 * length and the same elements as [expected], and in the same order.
 * This is equivalent to equals but does not recurse.
 */

Matcher orderedEquals(Iterable expected) => new _OrderedEquals(expected);

class _OrderedEquals extends BaseMatcher {
  final Iterable _expected;
  Matcher _matcher;

  _OrderedEquals(this._expected) {
    _matcher = equals(_expected, 1);
  }

  bool matches(item, MatchState matchState) =>
      (item is Iterable) && _matcher.matches(item, matchState);

  Description describe(Description description) =>
      description.add('equals ').addDescriptionOf(_expected).add(' ordered');

  Description describeMismatch(item, Description mismatchDescription,
                               MatchState matchState, bool verbose) {
    if (item is !Iterable) {
      return mismatchDescription.add('not an Iterable');
    } else {
      return _matcher.describeMismatch(item, mismatchDescription,
          matchState, verbose);
    }
  }
}
/**
 * Returns a matcher which matches [Iterable]s that have the same
 * length and the same elements as [expected], but not necessarily in
 * the same order. Note that this is O(n^2) so should only be used on
 * small objects.
 */
Matcher unorderedEquals(Iterable expected) =>
    new _UnorderedEquals(expected);

class _UnorderedEquals extends BaseMatcher {
  Iterable _expected;

  _UnorderedEquals(Iterable this._expected);

  String _test(item) {
    if (item is !Iterable) {
      return 'not iterable';
    }
    // Check the lengths are the same.
    var expectedLength = 0;
    if (_expected is Collection) {
      Collection cast = _expected; // "_expected as Collection"
      expectedLength = cast.length;
    } else {
      for (var element in _expected) {
        ++expectedLength;
      }
    }
    var actualLength = 0;
    if (item is Collection) {
      actualLength = item.length;
    } else {
      for (var element in item) {
        ++actualLength;
      }
    }
    if (expectedLength > actualLength) {
      return 'has too few elements (${actualLength} < ${expectedLength})';
    } else if (expectedLength < actualLength) {
      return 'has too many elements (${actualLength} > ${expectedLength})';
    }
    List<bool> matched = new List<bool>(actualLength);
    for (var i = 0; i < actualLength; i++) {
      matched[i] = false;
    }
    var expectedPosition = 0;
    for (var expectedElement in _expected) {
      var actualPosition = 0;
      var gotMatch = false;
      for (var actualElement in item) {
        if (!matched[actualPosition]) {
          if (expectedElement == actualElement) {
            matched[actualPosition] = gotMatch = true;
            break;
          }
        }
        ++actualPosition;
      }
      if (!gotMatch) {
        Description reason = new StringDescription();
        reason.add('has no match for element ').
            addDescriptionOf(expectedElement).
            add(' at position ${expectedPosition}');
        return reason.toString();
      }
      ++expectedPosition;
    }
    return null;
  }

  bool matches(item, MatchState mismatchState) => (_test(item) == null);

  Description describe(Description description) =>
      description.add('equals ').addDescriptionOf(_expected).add(' unordered');

  Description describeMismatch(item, Description mismatchDescription,
                               MatchState matchState, bool verbose) =>
      mismatchDescription.add(_test(item));
}

/**
 * Collection matchers match against [Collection]s. We add this intermediate
 * class to give better mismatch error messages than the base Matcher class.
 */
abstract class _CollectionMatcher extends BaseMatcher {
  const _CollectionMatcher();
  Description describeMismatch(item, Description mismatchDescription,
                               MatchState matchState, bool verbose) {
    if (item is !Collection) {
      return mismatchDescription.
          addDescriptionOf(item).
          add(' not a collection');
    } else {
      return super.describeMismatch(item, mismatchDescription, matchState,
        verbose);
    }
  }
}
