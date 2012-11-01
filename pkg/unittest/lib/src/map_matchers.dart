// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Returns a matcher which matches maps containing the given [value].
 */

part of matcher;

Matcher containsValue(value) => new _ContainsValue(value);

class _ContainsValue extends BaseMatcher {
  final _value;

  const _ContainsValue(this._value);

  bool matches(item, MatchState matchState) => item.containsValue(_value);
  Description describe(Description description) =>
      description.add('contains value ').addDescriptionOf(_value);
}

/**
 * Returns a matcher which matches maps containing the key-value pair
 * with [key] => [value].
 */
Matcher containsPair(key, value) =>
    new _ContainsMapping(key, wrapMatcher(value));

class _ContainsMapping extends BaseMatcher {
  final _key;
  final Matcher _valueMatcher;

  const _ContainsMapping(this._key, Matcher this._valueMatcher);

  bool matches(item, MatchState matchState) =>
      item.containsKey(_key) &&
      _valueMatcher.matches(item[_key], matchState);

  Description describe(Description description) {
    return description.add('contains pair ').addDescriptionOf(_key).
          add(' => ').addDescriptionOf(_valueMatcher);
  }

  Description describeMismatch(item, Description mismatchDescription,
                               MatchState matchState, bool verbose) {
    if (!item.containsKey(_key)) {
      return mismatchDescription.addDescriptionOf(item).
          add(" doesn't contain key ").addDescriptionOf(_key);
    } else {
      mismatchDescription.add(' contains key ').addDescriptionOf(_key).
          add(' but with value ');
      _valueMatcher.describeMismatch(item[_key], mismatchDescription,
          matchState, verbose);
      return mismatchDescription;
    }
  }
}
