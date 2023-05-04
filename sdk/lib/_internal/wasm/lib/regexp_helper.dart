// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._js_helper;

// TODO(joshualitt): This is a fork of the DDC RegExp class. In the longer term,
// with careful factoring we may be able to share this code.

/// Returns a string for a RegExp pattern that matches [string]. This is done by
/// escaping all RegExp metacharacters.
String quoteStringForRegExp(String string) =>
    // This method is optimized to test before replacement, which should be
    // much faster. This might be worth measuring in real world use cases
    // though.
    JS<String>(r"""s => {
      let jsString = stringFromDartString(s);
      if (/[[\]{}()*+?.\\^$|]/.test(jsString)) {
          jsString = jsString.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
      }
      return stringToDartString(jsString);
    }""", string);

@js.JS()
@js.staticInterop
class JSNativeMatch extends JSArray {
  // This constructor exists just to avoid the `no unnamed constructor` error.
  external factory JSNativeMatch();
}

extension JSNativeMatchExtension on JSNativeMatch {
  external JSString get input;
  external JSNumber get index;
  external JSObject? get groups;
}

@js.JS()
@js.staticInterop
class JSNativeRegExp {}

extension JSNativeRegExpExtension on JSNativeRegExp {
  external JSNativeMatch? exec(JSString string);
  external JSBoolean test(JSString string);
  external JSString get flags;
  external JSBoolean get multiline;
  external JSBoolean get ignoreCase;
  external JSBoolean get unicode;
  external JSBoolean get dotAll;
  external set lastIndex(JSNumber start);
}

class JSSyntaxRegExp implements RegExp {
  final String pattern;
  final JSNativeRegExp _nativeRegExp;
  JSNativeRegExp? _nativeGlobalRegExp;
  JSNativeRegExp? _nativeAnchoredRegExp;

  String toString() => 'RegExp/$pattern/' + _nativeRegExp.flags.toDart;

  JSSyntaxRegExp(String source,
      {bool multiLine = false,
      bool caseSensitive = true,
      bool unicode = false,
      bool dotAll = false})
      : this.pattern = source,
        this._nativeRegExp = makeNative(
            source, multiLine, caseSensitive, unicode, dotAll, false);

  JSNativeRegExp get _nativeGlobalVersion {
    if (_nativeGlobalRegExp != null) return _nativeGlobalRegExp!;
    return _nativeGlobalRegExp = makeNative(
        pattern, isMultiLine, isCaseSensitive, isUnicode, isDotAll, true);
  }

  JSNativeRegExp get _nativeAnchoredVersion {
    if (_nativeAnchoredRegExp != null) return _nativeAnchoredRegExp!;
    // An "anchored version" of a regexp is created by adding "|()" to the
    // source. This means that the regexp always matches at the first position
    // that it tries, and you can see if the original regexp matched, or it
    // was the added zero-width match that matched, by looking at the last
    // capture. If it is a String, the match participated, otherwise it didn't.
    return _nativeAnchoredRegExp = makeNative(
        '$pattern|()', isMultiLine, isCaseSensitive, isUnicode, isDotAll, true);
  }

  bool get isMultiLine => _nativeRegExp.multiline.toDart;
  bool get isCaseSensitive => !_nativeRegExp.ignoreCase.toDart;
  bool get isUnicode => _nativeRegExp.unicode.toDart;
  bool get isDotAll => _nativeRegExp.dotAll.toDart;

  static JSNativeRegExp makeNative(String source, bool multiLine,
      bool caseSensitive, bool unicode, bool dotAll, bool global) {
    String m = multiLine == true ? 'm' : '';
    String i = caseSensitive == true ? '' : 'i';
    String u = unicode ? 'u' : '';
    String s = dotAll ? 's' : '';
    String g = global ? 'g' : '';
    String modifiers = '$m$i$u$s$g';
    // The call to create the regexp is wrapped in a try catch so we can
    // reformat the exception if need be.
    WasmExternRef? result = JS<WasmExternRef?>("""(s, m) => {
          try {
            return new RegExp(s, m);
          } catch (e) {
            return String(e);
          }
        }""", source.toExternRef, modifiers.toExternRef);
    if (isJSRegExp(result)) return JSValue(result!) as JSNativeRegExp;
    // The returned value is the stringified JavaScript exception. Turn it into
    // a Dart exception.
    String errorMessage = jsStringToDartString(result);
    throw new FormatException('Illegal RegExp pattern ($errorMessage)', source);
  }

  RegExpMatch? firstMatch(String string) {
    JSNativeMatch? m = _nativeRegExp.exec(string.toJS);
    if (m.isUndefinedOrNull) return null;
    return new _MatchImplementation(this, m!);
  }

  bool hasMatch(String string) {
    return _nativeRegExp.test(string.toJS).toDart;
  }

  String? stringMatch(String string) {
    var match = firstMatch(string);
    if (match != null) return match.group(0);
    return null;
  }

  Iterable<RegExpMatch> allMatches(String string, [int start = 0]) {
    if (start < 0 || start > string.length) {
      throw new RangeError.range(start, 0, string.length);
    }
    return _AllMatchesIterable(this, string, start);
  }

  RegExpMatch? _execGlobal(String string, int start) {
    JSNativeRegExp regexp = _nativeGlobalVersion;
    regexp.lastIndex = start.toJS;
    JSNativeMatch? match = regexp.exec(string.toJS);
    if (match.isUndefinedOrNull) return null;
    return new _MatchImplementation(this, match!);
  }

  RegExpMatch? _execAnchored(String string, int start) {
    JSNativeRegExp regexp = _nativeAnchoredVersion;
    regexp.lastIndex = start.toJS;
    JSNativeMatch? match = regexp.exec(string.toJS);
    if (match.isUndefinedOrNull) return null;
    // If the last capture group participated, the original regexp did not
    // match at the start position.
    if (match!.pop() != null) return null;
    return new _MatchImplementation(this, match);
  }

  RegExpMatch? matchAsPrefix(String string, [int start = 0]) {
    if (start < 0 || start > string.length) {
      throw new RangeError.range(start, 0, string.length);
    }
    return _execAnchored(string, start);
  }
}

class _MatchImplementation implements RegExpMatch {
  final RegExp pattern;
  // Contains a JS RegExp match object.
  // It is an Array of String values with extra 'index' and 'input' properties.
  // If there were named capture groups, there will also be an extra 'groups'
  // property containing an object with capture group names as keys and
  // matched strings as values.
  final JSNativeMatch _match;

  _MatchImplementation(this.pattern, this._match);

  String get input => _match.input.toDart;

  int get start => _match.index.toDart.toInt();

  int get end => (start + (_match[0.toJS].toString()).length);

  String? group(int index) {
    if (index < 0 || index >= _match.length.toDart.toInt()) {
      throw RangeError("Index $index is out of range ${_match.length}");
    }
    return _match[index.toJS]?.toString();
  }

  String? operator [](int index) => group(index);

  int get groupCount => _match.length.toDart.toInt() - 1;

  List<String?> groups(List<int> groups) {
    List<String?> out = [];
    for (int i in groups) {
      out.add(group(i));
    }
    return out;
  }

  String? namedGroup(String name) {
    JSObject? groups = _match.groups;
    if (groups.isDefinedAndNotNull) {
      Object? result = dartifyRaw(groups![name.toJS]?.toExternRef);
      if (result != null ||
          hasPropertyRaw(groups.toExternRef, name.toExternRef)) {
        return result?.toString();
      }
    }
    throw ArgumentError.value(name, "name", "Not a capture group name");
  }

  Iterable<String> get groupNames {
    JSObject? groups = _match.groups;
    if (groups.isDefinedAndNotNull) {
      return JSArrayIterableAdapter<String>(objectKeys(groups!));
    }
    return Iterable.empty();
  }
}

class _AllMatchesIterable extends Iterable<RegExpMatch> {
  final JSSyntaxRegExp _re;
  final String _string;
  final int _start;

  _AllMatchesIterable(this._re, this._string, this._start);

  Iterator<RegExpMatch> get iterator =>
      new _AllMatchesIterator(_re, _string, _start);
}

class _AllMatchesIterator implements Iterator<RegExpMatch> {
  final JSSyntaxRegExp _regExp;
  String? _string;
  int _nextIndex;
  RegExpMatch? _current;

  _AllMatchesIterator(this._regExp, this._string, this._nextIndex);

  RegExpMatch get current => _current as RegExpMatch;

  static bool _isLeadSurrogate(int c) {
    return c >= 0xd800 && c <= 0xdbff;
  }

  static bool _isTrailSurrogate(int c) {
    return c >= 0xdc00 && c <= 0xdfff;
  }

  bool moveNext() {
    var string = _string;
    if (string == null) return false;
    if (_nextIndex <= string.length) {
      RegExpMatch? match = _regExp._execGlobal(string, _nextIndex);
      if (match != null) {
        _current = match;
        int nextIndex = match.end;
        if (match.start == nextIndex) {
          // Zero-width match. Advance by one more, unless the regexp
          // is in unicode mode and it would put us within a surrogate
          // pair. In that case, advance past the code point as a whole.
          if (_regExp.isUnicode &&
              _nextIndex + 1 < string.length &&
              _isLeadSurrogate(string.codeUnitAt(_nextIndex)) &&
              _isTrailSurrogate(string.codeUnitAt(_nextIndex + 1))) {
            nextIndex++;
          }
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
