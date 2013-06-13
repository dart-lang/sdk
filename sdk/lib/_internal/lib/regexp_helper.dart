// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _js_helper;

// Helper method used by internal libraries.
regExpGetNative(JSSyntaxRegExp regexp) => regexp._nativeRegExp;

class JSSyntaxRegExp implements RegExp {
  final String _pattern;
  final bool _isMultiLine;
  final bool _isCaseSensitive;
  var _nativeRegExp;

  JSSyntaxRegExp._internal(String pattern,
                           bool multiLine,
                           bool caseSensitive,
                           bool global)
      : _nativeRegExp = makeNative(pattern, multiLine, caseSensitive, global),
        this._pattern = pattern,
        this._isMultiLine = multiLine,
        this._isCaseSensitive = caseSensitive;

  JSSyntaxRegExp(String pattern,
                 {bool multiLine: false,
                  bool caseSensitive: true})
      : this._internal(pattern, multiLine, caseSensitive, false);

  JSSyntaxRegExp._globalVersionOf(JSSyntaxRegExp other)
      : this._internal(other.pattern,
                       other.isMultiLine,
                       other.isCaseSensitive,
                       true);

  JSSyntaxRegExp._anchoredVersionOf(JSSyntaxRegExp other)
      : this._internal(other.pattern + "|()",
                       other.isMultiLine,
                       other.isCaseSensitive,
                       true);

  static makeNative(
      String pattern, bool multiLine, bool caseSensitive, bool global) {
    checkString(pattern);
    String m = multiLine ? 'm' : '';
    String i = caseSensitive ? '' : 'i';
    String g = global ? 'g' : '';
    // We're using the JavaScript's try catch instead of the Dart one
    // to avoid dragging in Dart runtime support just because of using
    // RegExp.
    var regexp = JS('',
        '(function() {'
         'try {'
          'return new RegExp(#, # + # + #);'
         '} catch (e) {'
           'return e;'
         '}'
        '})()', pattern, m, i, g);
    if (JS('bool', '# instanceof RegExp', regexp)) return regexp;
    // The returned value is the JavaScript exception. Turn it into a
    // Dart exception.
    String errorMessage = JS('String', r'String(#)', regexp);
    throw new FormatException(
        "Illegal RegExp pattern: $pattern, $errorMessage");
  }

  Match firstMatch(String str) {
    List<String> m =
        JS('=List|Null', r'#.exec(#)', _nativeRegExp, checkString(str));
    if (m == null) return null;
    var matchStart = JS('int', r'#.index', m);
    // m.lastIndex only works with flag 'g'.
    var matchEnd = matchStart + m[0].length;
    return new _MatchImplementation(pattern, str, matchStart, matchEnd, m);
  }

  bool hasMatch(String str) {
    return JS('bool', r'#.test(#)', _nativeRegExp, checkString(str));
  }

  String stringMatch(String str) {
    var match = firstMatch(str);
    return match == null ? null : match.group(0);
  }

  Iterable<Match> allMatches(String str) {
    checkString(str);
    return new _AllMatchesIterable(this, str);
  }

  Match matchAsPrefix(String string, [int start = 0]) {
    if (start < 0 || start > string.length) {
      throw new RangeError.range(start, 0, string.length);
    }
    // An "anchored version" of a regexp is created by adding "|()" to the
    // source. This means that the regexp always matches at the first position
    // that it tries, and you can see if the original regexp matched, or it
    // was the added zero-width match that matched, by looking at the last
    // capture. If it is a String, the match participated, otherwise it didn't.
    JSSyntaxRegExp regexp = new JSSyntaxRegExp._anchoredVersionOf(this);
    if (start > 0) {
      JS("void", "#.lastIndex = #", regExpGetNative(regexp), start);
    }
    _MatchImplementation match = regexp.firstMatch(string);
    if (match == null) return null;
    if (match._groups[match._groups.length - 1] != null) return null;
    match._groups.length -= 1;
    return match;
  }

  String get pattern => _pattern;
  bool get isMultiLine => _isMultiLine;
  bool get isCaseSensitive => _isCaseSensitive;
}

class _MatchImplementation implements Match {
  final Pattern pattern;
  final String str;
  final int start;
  final int end;
  final List<String> _groups;

  const _MatchImplementation(
      this.pattern,
      this.str,
      int this.start,
      int this.end,
      List<String> this._groups);

  String group(int index) => _groups[index];
  String operator [](int index) => group(index);
  int get groupCount => _groups.length - 1;

  List<String> groups(List<int> groups) {
    List<String> out = [];
    for (int i in groups) {
      out.add(group(i));
    }
    return out;
  }
}

class _AllMatchesIterable extends IterableBase<Match> {
  final JSSyntaxRegExp _re;
  final String _str;

  const _AllMatchesIterable(this._re, this._str);

  Iterator<Match> get iterator => new _AllMatchesIterator(_re, _str);
}

class _AllMatchesIterator implements Iterator<Match> {
  final RegExp _regExp;
  final RegExp _globalRegExp;
  String _str;
  Match _current;

  _AllMatchesIterator(JSSyntaxRegExp re, String this._str)
    : _regExp = re,
      _globalRegExp = new JSSyntaxRegExp._globalVersionOf(re);

  Match get current => _current;

  bool moveNext() {
    if (_str == null) return false;
    // firstMatch actually acts as nextMatch because of
    // hidden global flag.
    if (_current != null && _current.start == _current.end) {
      // Advance implicit start-position if last match was empty.
      JS("void", "#.lastIndex++", regExpGetNative(_globalRegExp));
    }
    List<String> m =
        JS('=List|Null', r'#.exec(#)', regExpGetNative(_globalRegExp), _str);
    if (m == null) {
      _current = null;
      _str = null;  // Marks iteration as ended.
      return false;
    }
    var matchStart = JS('int', r'#.index', m);
    var matchEnd = matchStart + m[0].length;
    _current = new _MatchImplementation(_regExp, _str, matchStart, matchEnd, m);
    return true;
  }
}

Match firstMatchAfter(JSSyntaxRegExp re, String str, int start) {
  JSSyntaxRegExp global = new JSSyntaxRegExp._globalVersionOf(re);
  JS("void", "#.lastIndex = #", regExpGetNative(global), start);
  List<String> m =
      JS('=List|Null', r'#.exec(#)', regExpGetNative(global), checkString(str));
  if (m == null) return null;
  var matchStart = JS('int', r'#.index', m);
  var matchEnd = matchStart + m[0].length;
  return new _MatchImplementation(re, str, matchStart, matchEnd, m);
}
