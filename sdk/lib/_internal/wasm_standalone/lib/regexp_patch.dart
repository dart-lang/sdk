// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_embedder';
import 'dart:_error_utils';
import 'dart:_internal' show patch;
import 'dart:_js_helper';
import 'dart:_string';
import 'dart:_wasm';

@patch
class RegExp {
  @patch
  factory RegExp(
    String source, {
    bool multiLine = false,
    bool caseSensitive = true,
    bool unicode = false,
    bool dotAll = false,
  }) {
    return _EmbedderRegExp(source, multiLine, caseSensitive, unicode, dotAll);
  }

  @patch
  static String escape(String text) {
    return JSStringImpl.fromRefUnchecked(
      regexpEscape(jsStringFromDartString(text).wrappedExternRef),
    );
  }
}

final class _EmbedderRegExp implements RegExp {
  WasmExternRef? _regexp = WasmExternRef.nullRef;

  @override
  final String pattern;
  @override
  final bool isMultiLine;
  @override
  final bool isCaseSensitive;
  @override
  final bool isUnicode;
  @override
  final bool isDotAll;

  _EmbedderRegExp(
    this.pattern,
    this.isMultiLine,
    this.isCaseSensitive,
    this.isUnicode,
    this.isDotAll,
  ) {
    final compiled = regexpCreateOrFailWithString(
      jsStringFromDartString(pattern).wrappedExternRef,
      WasmI32.fromBool(isMultiLine),
      WasmI32.fromBool(isCaseSensitive),
      WasmI32.fromBool(isUnicode),
      WasmI32.fromBool(isDotAll),
    );
    if (!regexpIsRegexp(compiled).toBool()) {
      // The returned value is the stringified JavaScript exception. Turn it
      // into a Dart exception.
      final errorMessage = JSStringImpl.fromRefUnchecked(compiled);
      throw FormatException('Illegal RegExp pattern ($errorMessage)', pattern);
    }

    this._regexp = compiled;
  }

  @override
  String toString() {
    final buffer = StringBuffer('RegExp/');
    buffer.write(pattern);
    buffer.write('/');

    if (isMultiLine) buffer.write('m');
    if (!isCaseSensitive) buffer.write('i');
    if (isUnicode) buffer.write('u');
    if (isDotAll) buffer.write('s');
    return buffer.toString();
  }

  @override
  Iterable<RegExpMatch> allMatches(String input, [int start = 0]) {
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(start, input.length);
    return Iterable.withIterator(
      () => _EmbedderMatchesIterator(this, input, start),
    );
  }

  @override
  RegExpMatch? firstMatch(String input) {
    return _search(input, 0, false);
  }

  @override
  bool hasMatch(String input) {
    return firstMatch(input) != null;
  }

  @override
  Match? matchAsPrefix(String string, [int start = 0]) {
    return _search(string, start, true);
  }

  _EmbedderMatch? _search(String string, int start, bool exactStartIndex) {
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(start, string.length);
    final match = regexpMatch(
      _regexp,
      jsStringFromDartString(string).wrappedExternRef,
      WasmI32.fromInt(start),
      WasmI32.fromBool(exactStartIndex),
    );
    if (match.isNull) {
      return null;
    }

    return _EmbedderMatch(this, string).._match = match;
  }

  @override
  String? stringMatch(String input) {
    var match = firstMatch(input);
    if (match != null) return match[0];
    return null;
  }
}

final class _EmbedderMatch implements RegExpMatch {
  @override
  final _EmbedderRegExp pattern;
  @override
  final String input;

  WasmExternRef? _match = WasmExternRef.nullRef;

  _EmbedderMatch(this.pattern, this.input);

  @override
  String? operator [](int group) {
    return this.group(group);
  }

  @override
  int get start => regexpMatchGetStart(_match).toIntUnsigned();

  @override
  int get end => regexpMatchGetEnd(_match).toIntUnsigned();

  @override
  int get groupCount => regexpMatchGetGroupCount(_match).toIntUnsigned();

  @override
  String? group(int group) {
    IndexErrorUtils.checkIndex(group, groupCount + 1);
    final contents = regexpMatchGetGroup(_match, WasmI32.fromInt(group));
    return contents.isNull ? null : JSStringImpl.fromRefUnchecked(contents);
  }

  @override
  List<String?> groups(List<int> groupIndices) {
    return [for (final index in groupIndices) group(index)];
  }

  @override
  late final List<String> groupNames = List.generate(
    regexpMatchGetNamedGroups(_match).toIntUnsigned(),
    (i) {
      return JSStringImpl.fromRefUnchecked(
        regexpMatchGetGroupName(_match, WasmI32.fromInt(i)),
      );
    },
  );

  @override
  String? namedGroup(String name) {
    final groupIndex = groupNames.indexOf(name);
    if (groupIndex < 0) {
      throw ArgumentError.value(name, "name", "Not a capture group name");
    }

    final contents = regexpMatchGetGroupByName(
      _match,
      WasmI32.fromInt(groupIndex),
    );
    return contents.isNull ? null : JSStringImpl.fromRefUnchecked(contents);
  }
}

class _EmbedderMatchesIterator implements Iterator<RegExpMatch> {
  final _EmbedderRegExp _regExp;
  String? _string;
  int _nextIndex;
  RegExpMatch? _current;

  _EmbedderMatchesIterator(this._regExp, this._string, this._nextIndex);

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
      final match = _regExp._search(_string!, _nextIndex, false);
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
