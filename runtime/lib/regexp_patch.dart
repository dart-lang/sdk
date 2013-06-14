// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patch class RegExp {
  /* patch */ factory RegExp(String pattern,
                             {bool multiLine: false,
                              bool caseSensitive: true}) {
    return new _JSSyntaxRegExp(pattern,
                               multiLine: multiLine,
                               caseSensitive: caseSensitive);
  }
}

class _JSRegExpMatch implements Match {
  _JSRegExpMatch(this._regexp, this.str, this._match);

  int get start => _start(0);
  int get end => _end(0);

  int _start(int groupIdx) {
    return _match[(groupIdx * _MATCH_PAIR)];
  }

  int _end(int groupIdx) {
    return _match[(groupIdx * _MATCH_PAIR) + 1];
  }

  String group(int groupIdx) {
    if (groupIdx < 0 || groupIdx > _regexp._groupCount) {
      throw new RangeError.value(groupIdx);
    }
    int startIndex = _start(groupIdx);
    int endIndex = _end(groupIdx);
    if (startIndex == -1) {
      assert(endIndex == -1);
      return null;
    }
    return str._substringUnchecked(startIndex, endIndex);
  }

  String operator [](int groupIdx) {
    return this.group(groupIdx);
  }

  List<String> groups(List<int> groupsSpec) {
    var groupsList = new List<String>(groupsSpec.length);
    for (int i = 0; i < groupsSpec.length; i++) {
      groupsList[i] = group(groupsSpec[i]);
    }
    return groupsList;
  }

  int get groupCount => _regexp._groupCount;

  Pattern get pattern => _regexp;

  final RegExp _regexp;
  final String str;
  final List<int> _match;
  static const int _MATCH_PAIR = 2;
}


class _JSSyntaxRegExp implements RegExp {
  factory _JSSyntaxRegExp(
      String pattern,
      {bool multiLine: false,
       bool caseSensitive: true}) native "JSSyntaxRegExp_factory";

  Match firstMatch(String str) {
    List match = _ExecuteMatch(str, 0);
    if (match == null) {
      return null;
    }
    return new _JSRegExpMatch(this, str, match);
  }

  Iterable<Match> allMatches(String str) {
    if (str is! String) throw new ArgumentError(str);
    return new _AllMatchesIterable(this, str);
  }

  Match matchAsPrefix(String string, [int start = 0]) {
    if (start < 0 || start > string.length) {
      throw new RangeError.range(start, 0, string.length);
    }
    // Inefficient check that searches for a later match too.
    // Change this when possible.
    List<int> list = _ExecuteMatch(string, start);
    if (list == null) return null;
    if (list[0] != start) return null;
    return new _JSRegExpMatch(this, string, list);
  }

  bool hasMatch(String str) {
    List match = _ExecuteMatch(str, 0);
    return (match == null) ? false : true;
  }

  String stringMatch(String str) {
    List match = _ExecuteMatch(str, 0);
    if (match == null) {
      return null;
    }
    return str._substringUnchecked(match[0], match[1]);
  }

  String get pattern native "JSSyntaxRegExp_getPattern";

  bool get isMultiLine native "JSSyntaxRegExp_getIsMultiLine";

  bool get isCaseSensitive native "JSSyntaxRegExp_getIsCaseSensitive";

  int get _groupCount native "JSSyntaxRegExp_getGroupCount";

  List _ExecuteMatch(String str, int start_index)
      native "JSSyntaxRegExp_ExecuteMatch";
}

class _AllMatchesIterable extends IterableBase<Match> {
  final _JSSyntaxRegExp _re;
  final String _str;

  const _AllMatchesIterable(this._re, this._str);

  Iterator<Match> get iterator => new _AllMatchesIterator(_re, _str);
}

class _AllMatchesIterator implements Iterator<Match> {
  final String _str;
  _JSSyntaxRegExp _re;
  Match _current;

  _AllMatchesIterator(this._re, this._str);

  Match get current => _current;

  bool moveNext() {
    if (_re == null) return false;  // Cleared after a failed match.
    int nextIndex = 0;
    if (_current != null) {
      nextIndex = _current.end;
      if (nextIndex == _current.start) {
        // Zero-width match. Advance by one more.
        nextIndex++;
        if (nextIndex > _str.length) {
          _re = null;
          _current = null;
          return false;
        }
      }
    }
    var match = _re._ExecuteMatch(_str, nextIndex);
    if (match == null) {
      _current = null;
      _re = null;
      return false;
    }
    _current = new _JSRegExpMatch(_re, _str, match);
    return true;
  }
}
