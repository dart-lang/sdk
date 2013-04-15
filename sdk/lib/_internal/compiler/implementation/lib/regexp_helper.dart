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

  String get pattern => _pattern;
  bool get isMultiLine => _isMultiLine;
  bool get isCaseSensitive => _isCaseSensitive;
}

class _MatchImplementation implements Match {
  final String pattern;
  final String str;
  final int start;
  final int end;
  final List<String> _groups;

  const _MatchImplementation(
      String this.pattern,
      String this.str,
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
  final RegExp _re;
  final String _str;
  Match _current;

  _AllMatchesIterator(JSSyntaxRegExp re, String this._str)
    : _re = new JSSyntaxRegExp._globalVersionOf(re);

  Match get current => _current;

  bool moveNext() {
    // firstMatch actually acts as nextMatch because of
    // hidden global flag.
    _current = _re.firstMatch(_str);
    return _current != null;
  }
}
