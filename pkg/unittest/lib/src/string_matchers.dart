// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Returns a matcher which matches if the match argument is a string and
 * is equal to [value] when compared case-insensitively.
 */

part of matcher;

Matcher equalsIgnoringCase(String value) => new _IsEqualIgnoringCase(value);

class _IsEqualIgnoringCase extends _StringMatcher {
  final String _value;
  String _matchValue;

  _IsEqualIgnoringCase(this._value) {
    _matchValue = _value.toLowerCase();
  }

  bool matches(item, MatchState mismatchState) =>
      item is String && _matchValue == item.toLowerCase();

  Description describe(Description description) =>
      description.addDescriptionOf(_value).add(' ignoring case');
}

/**
 * Returns a matcher which matches if the match argument is a string and
 * is equal to [value] when compared with all runs of whitespace
 * collapsed to single spaces and leading and trailing whitespace removed.
 *
 * For example, `equalsIgnoringCase("hello world")` will match
 * "hello   world", "  hello world" and "hello world  ".
 */
Matcher equalsIgnoringWhitespace(_string) =>
    new _IsEqualIgnoringWhitespace(_string);

class _IsEqualIgnoringWhitespace extends _StringMatcher {
  final String _value;
  String _matchValue;

  _IsEqualIgnoringWhitespace(this._value) {
    _matchValue = collapseWhitespace(_value);
  }

  bool matches(item, MatchState matchState) =>
      item is String && _matchValue == collapseWhitespace(item);

  Description describe(Description description) =>
    description.addDescriptionOf(_matchValue).add(' ignoring whitespace');

  Description describeMismatch(item, Description mismatchDescription,
                               MatchState matchState, bool verbose) {
    if (item is String) {
      return mismatchDescription.add('was ').
          addDescriptionOf(collapseWhitespace(item));
    } else {
      return super.describeMismatch(item, mismatchDescription,
          matchState, verbose);
    }
  }
}

/**
 * Utility function to collapse whitespace runs to single spaces
 * and strip leading/trailing whitespace.
 */
String collapseWhitespace(_string) {
  bool isWhitespace(String ch) => (' \n\r\t'.indexOf(ch) >= 0);
  StringBuffer result = new StringBuffer();
  bool skipSpace = true;
  for (var i = 0; i < _string.length; i++) {
    var character = _string[i];
    if (isWhitespace(character)) {
      if (!skipSpace) {
        result.add(' ');
        skipSpace = true;
      }
    } else {
      result.add(character);
      skipSpace = false;
    }
  }
  return result.toString().trim();
}

/**
 * Returns a matcher that matches if the match argument is a string and
 * starts with [prefixString].
 */
Matcher startsWith(String prefixString) => new _StringStartsWith(prefixString);

class _StringStartsWith extends _StringMatcher {
  final String _prefix;

  const _StringStartsWith(this._prefix);

  bool matches(item, MatchState matchState) =>
      item is String && item.startsWith(_prefix);

  Description describe(Description description) =>
      description.add('a string starting with ').addDescriptionOf(_prefix);
}

/**
 * Returns a matcher that matches if the match argument is a string and
 * ends with [suffixString].
 */
Matcher endsWith(String suffixString) => new _StringEndsWith(suffixString);

class _StringEndsWith extends _StringMatcher {

  final String _suffix;

  const _StringEndsWith(this._suffix);

  bool matches(item, MatchState matchState) =>
      item is String && item.endsWith(_suffix);

  Description describe(Description description) =>
      description.add('a string ending with ').addDescriptionOf(_suffix);
}

/**
 * Returns a matcher that matches if the match argument is a string and
 * contains a given list of [substrings] in relative order.
 *
 * For example, `stringContainsInOrder(["a", "e", "i", "o", "u"])` will match
 * "abcdefghijklmnopqrstuvwxyz".
 */

Matcher stringContainsInOrder(substrings) =>
    new _StringContainsInOrder(substrings);

class _StringContainsInOrder extends _StringMatcher {

  final List<String> _substrings;

  const _StringContainsInOrder(this._substrings);

  bool matches(item, MatchState matchState) {
    if (!(item is String)) {
      return false;
    }
    var from_index = 0;
    for (var s in _substrings) {
      from_index = item.indexOf(s, from_index);
      if (from_index < 0)
        return false;
    }
    return true;
  }

  Description describe(Description description) =>
      description.addAll('a string containing ', ', ', ' in order',
                                                  _substrings);
}

/**
 * Returns a matcher that matches if the match argument is a string and
 * matches the regular expression given by [re]. [re] can be a RegExp
 * instance or a string; in the latter case it will be used to create
 * a RegExp instance.
 */
Matcher matches(re) => new _MatchesRegExp(re);

class _MatchesRegExp extends _StringMatcher {
  RegExp _regexp;

  _MatchesRegExp(re) {
    if (re is String) {
      _regexp = new RegExp(re);
    } else if (re is RegExp) {
      _regexp = re;
    } else {
      throw new ArgumentError('matches requires a regexp or string');
    }
  }

  bool matches(String item, MatchState matchState) =>
        _regexp.hasMatch(item);

  Description describe(Description description) =>
      description.add("match '${_regexp.pattern}'");
}

// String matchers match against a string. We add this intermediate
// class to give better mismatch error messages than the base Matcher class.
abstract class _StringMatcher extends BaseMatcher {
  const _StringMatcher();
  Description describeMismatch(item, Description mismatchDescription,
                               MatchState matchState, bool verbose) {
    if (!(item is String)) {
      return mismatchDescription.
          addDescriptionOf(item).
          add(' not a string');
    } else {
      return super.describeMismatch(item, mismatchDescription,
          matchState, verbose);
    }
  }
}
