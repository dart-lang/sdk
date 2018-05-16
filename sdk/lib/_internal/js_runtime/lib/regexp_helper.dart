// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of _js_helper;

// Helper method used by internal libraries.
regExpGetNative(JSSyntaxRegExp regexp) => regexp._nativeRegExp;

/**
 * Returns a native version of the RegExp with the global flag set.
 *
 * The RegExp's `lastIndex` property is zero when it is returned.
 *
 * The returned regexp is shared, and its `lastIndex` property may be
 * modified by other uses, so the returned regexp must be used immediately
 * when it's returned, with no user-provided code run in between.
 */
regExpGetGlobalNative(JSSyntaxRegExp regexp) {
  var nativeRegexp = regexp._nativeGlobalVersion;
  JS('void', '#.lastIndex = 0', nativeRegexp);
  return nativeRegexp;
}

/**
 * Computes the number of captures in a regexp.
 *
 * This currently involves creating a new RegExp object with a different
 * source and running it against the empty string (the last part is usually
 * fast).
 *
 * The JSSyntaxRegExp could cache the result, and set the cache any time
 * it finds a match.
 */
int regExpCaptureCount(JSSyntaxRegExp regexp) {
  var nativeAnchoredRegExp = regexp._nativeAnchoredVersion;
  var match = JS('JSExtendableArray', '#.exec("")', nativeAnchoredRegExp);
  // The native-anchored regexp always have one capture more than the original,
  // and always matches the empty string.
  return match.length - 2;
}

class JSSyntaxRegExp implements RegExp {
  final String pattern;
  final _nativeRegExp;
  var _nativeGlobalRegExp;
  var _nativeAnchoredRegExp;

  String toString() => 'RegExp/$pattern/';

  JSSyntaxRegExp(String source,
      {bool multiLine: false, bool caseSensitive: true})
      : this.pattern = source,
        this._nativeRegExp =
            makeNative(source, multiLine, caseSensitive, false);

  get _nativeGlobalVersion {
    if (_nativeGlobalRegExp != null) return _nativeGlobalRegExp;
    return _nativeGlobalRegExp =
        makeNative(pattern, _isMultiLine, _isCaseSensitive, true);
  }

  get _nativeAnchoredVersion {
    if (_nativeAnchoredRegExp != null) return _nativeAnchoredRegExp;
    // An "anchored version" of a regexp is created by adding "|()" to the
    // source. This means that the regexp always matches at the first position
    // that it tries, and you can see if the original regexp matched, or it
    // was the added zero-width match that matched, by looking at the last
    // capture. If it is a String, the match participated, otherwise it didn't.
    return _nativeAnchoredRegExp =
        makeNative('$pattern|()', _isMultiLine, _isCaseSensitive, true);
  }

  bool get _isMultiLine => JS('bool', '#.multiline', _nativeRegExp);
  bool get _isCaseSensitive => JS('bool', '!#.ignoreCase', _nativeRegExp);

  static makeNative(
      String source, bool multiLine, bool caseSensitive, bool global) {
    checkString(source);
    String m = multiLine == true ? 'm' : '';
    String i = caseSensitive == true ? '' : 'i';
    String g = global ? 'g' : '';
    // We're using the JavaScript's try catch instead of the Dart one to avoid
    // dragging in Dart runtime support just because of using RegExp.
    var regexp = JS(
        '',
        r'''
          (function(source, modifiers) {
            try {
              return new RegExp(source, modifiers);
            } catch (e) {
              return e;
            }
          })(#, # + # + #)''',
        source,
        m,
        i,
        g);
    if (JS('bool', '# instanceof RegExp', regexp)) return regexp;
    // The returned value is the JavaScript exception. Turn it into a
    // Dart exception.
    String errorMessage = JS('String', r'String(#)', regexp);
    throw new FormatException('Illegal RegExp pattern ($errorMessage)', source);
  }

  Match firstMatch(String string) {
    List m = JS('JSExtendableArray|Null', r'#.exec(#)', _nativeRegExp,
        checkString(string));
    if (m == null) return null;
    return new _MatchImplementation(this, m);
  }

  bool hasMatch(String string) {
    return JS('bool', r'#.test(#)', _nativeRegExp, checkString(string));
  }

  String stringMatch(String string) {
    var match = firstMatch(string);
    if (match != null) return match.group(0);
    return null;
  }

  Iterable<Match> allMatches(String string, [int start = 0]) {
    checkString(string);
    checkInt(start);
    if (start < 0 || start > string.length) {
      throw new RangeError.range(start, 0, string.length);
    }
    return new _AllMatchesIterable(this, string, start);
  }

  Match _execGlobal(String string, int start) {
    Object regexp = _nativeGlobalVersion;
    JS('void', '#.lastIndex = #', regexp, start);
    List match = JS('JSExtendableArray|Null', '#.exec(#)', regexp, string);
    if (match == null) return null;
    return new _MatchImplementation(this, match);
  }

  Match _execAnchored(String string, int start) {
    Object regexp = _nativeAnchoredVersion;
    JS('void', '#.lastIndex = #', regexp, start);
    List match = JS('JSExtendableArray|Null', '#.exec(#)', regexp, string);
    if (match == null) return null;
    // If the last capture group participated, the original regexp did not
    // match at the start position.
    if (match.removeLast() != null) return null;
    return new _MatchImplementation(this, match);
  }

  Match matchAsPrefix(String string, [int start = 0]) {
    if (start < 0 || start > string.length) {
      throw new RangeError.range(start, 0, string.length);
    }
    return _execAnchored(string, start);
  }

  bool get isMultiLine => _isMultiLine;
  bool get isCaseSensitive => _isCaseSensitive;
}

class _MatchImplementation implements Match {
  final Pattern pattern;
  // Contains a JS RegExp match object.
  // It is an Array of String values with extra 'index' and 'input' properties.
  // We didn't force it to be JSArray<String>, so it is JSArray<dynamic>, but
  // containing String or `undefined` values.
  final JSArray _match;

  _MatchImplementation(this.pattern, this._match) {
    assert(JS('var', '#.input', _match) is String);
    assert(JS('var', '#.index', _match) is int);
  }

  String get input => JS('String', '#.input', _match);

  int get start =>
      JS('returns:int;depends:none;effects:none;gvn:true', '#.index', _match);

  int get end =>
      start +
      JS('returns:int;depends:none;effects:none;gvn:true', '#[0].length',
          _match);

  // The JS below changes the static type to avoid an implicit cast.
  // TODO(sra): Find a nicer way to do this, e.g. unsafeCast.
  String group(int index) => JS('String|Null', '#', _match[index]);

  String operator [](int index) => group(index);

  int get groupCount => _match.length - 1;

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
  final String _string;
  final int _start;

  _AllMatchesIterable(this._re, this._string, this._start);

  Iterator<Match> get iterator => new _AllMatchesIterator(_re, _string, _start);
}

class _AllMatchesIterator implements Iterator<Match> {
  final JSSyntaxRegExp _regExp;
  String _string;
  int _nextIndex;
  Match _current;

  _AllMatchesIterator(this._regExp, this._string, this._nextIndex);

  Match get current => _current;

  bool moveNext() {
    if (_string == null) return false;
    if (_nextIndex <= _string.length) {
      var match = _regExp._execGlobal(_string, _nextIndex);
      if (match != null) {
        _current = match;
        int nextIndex = match.end;
        if (match.start == nextIndex) {
          nextIndex++;
        }
        _nextIndex = nextIndex;
        return true;
      }
    }
    _current = null;
    _string = null; // Marks iteration as ended.
    return false;
  }
}

/** Find the first match of [regExp] in [string] at or after [start]. */
Match firstMatchAfter(JSSyntaxRegExp regExp, String string, int start) {
  return regExp._execGlobal(string, start);
}
