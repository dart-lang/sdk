// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class JSSyntaxRegExp implements RegExp {
  const JSSyntaxRegExp(String pattern, String flags)
    : this.pattern = pattern, this.flags = flags;

  final String pattern;
  final String flags;

  Iterable<Match> allMatches(String str) {
    return new _LazyAllMatches(this, str);
  }

  Match firstMatch(String str) native;
  bool hasMatch(String str) native;
  String stringMatch(String str) native;

  static String _pattern(JSSyntaxRegExp regexp) native {
    return regexp.pattern;
  }
  static String _flags(JSSyntaxRegExp regexp) native {
    return regexp.flags;
  }
}

class JSSyntaxMatch implements Match {
  const JSSyntaxMatch(RegExp regexp, String str)
    : this.pattern = regexp, this.str = str;

  final String str;
  final Pattern pattern;

  String operator[](int group) {
    return this.group(group);
  }

  Array<String> groups(Array<int> groups) {
    Array<String> strings = new Array<String>();
    groups.forEach((int group) {
      strings.add(this.group(group));
    });
    return strings;
  }

  String group(int nb) native;

  int start() native;

  int end() native;

  groupCount() native;

  static _new(RegExp regexp, String str) native {
    return new JSSyntaxMatch(regexp, str);
  }
}

class _LazyAllMatches implements Collection<Match> {
  JSSyntaxRegExp _regexp;
  String _str;

  const _LazyAllMatches(this._regexp, this._str);

  void forEach(void f(Match match)) {
    for (Match match in this) {
      f(match);
    }
  }

  Collection<Match> filter(bool f(Match match)) {
    Array<Match> result = new Array<Match>();
    for (Match match in this) {
      if (f(match)) result.add(match);
    }
    return result;
  }

  bool every(bool f(Match match)) {
    for (Match match in this) {
      if (!f(match)) return false;
    }
    return true;
  }

  bool some(bool f(Match match)) {
    for (Match match in this) {
      if (f(match)) return true;
    }
    return false;
  }

  bool isEmpty() {
    return _regexp.firstMatch(_str) == null;
  }

  int get length() {
    int result = 0;
    for (Match match in this) {
      result++;
    }
    return result;
  }

  Iterator<Match> iterator() {
    return new _LazyAllMatchesIterator(_regexp, _str);
  }
}

class _LazyAllMatchesIterator implements Iterator<Match> {
  JSSyntaxRegExp _regexp;
  String _str;
  Match _nextMatch;

  _LazyAllMatchesIterator(this._regexp, this._str) {
    _jsInit(_regexp);
  }

  Match next() {
    if (!hasNext()) throw const NoMoreElementsException();
    Match result = _nextMatch;
    _nextMatch = null;
    return result;
  }

  bool hasNext() {
    if (_nextMatch != null) return true;
    _nextMatch = _computeNextMatch(_regexp, _str);
    return (_nextMatch != null);
  }

  void _jsInit(JSSyntaxRegExp regexp) native;
  Match _computeNextMatch(JSSyntaxRegExp regexp, String str) native;
}
