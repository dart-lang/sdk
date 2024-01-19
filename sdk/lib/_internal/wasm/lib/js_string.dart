// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._js_types;

final class JSStringImpl implements String {
  final WasmExternRef? _ref;

  JSStringImpl(this._ref);

  @pragma("wasm:prefer-inline")
  static String? box(WasmExternRef? ref) =>
      js.isDartNull(ref) ? null : JSStringImpl(ref);

  @pragma("wasm:prefer-inline")
  WasmExternRef? get toExternRef => _ref;

  @override
  @pragma("wasm:prefer-inline")
  int get length => _jsLength(toExternRef);

  @override
  @pragma("wasm:prefer-inline")
  bool get isEmpty => length == 0;

  @override
  @pragma("wasm:prefer-inline")
  bool get isNotEmpty => !isEmpty;

  @pragma("wasm:entry-point")
  static String interpolate(List<Object?> values) {
    final valuesLength = values.length;
    final array = JSArrayImpl.fromLength(valuesLength);
    for (int i = 0; i < valuesLength; i++) {
      final o = values[i];
      final s = o.toString();
      final jsString =
          s is JSStringImpl ? js.JSValue.boxT<JSAny?>(s.toExternRef) : s.toJS;
      array._setUnchecked(i, jsString);
    }
    return JSStringImpl(
        js.JS<WasmExternRef?>("a => a.join('')", array.toExternRef));
  }

  @override
  @pragma("wasm:prefer-inline")
  int codeUnitAt(int index) {
    final length = this.length;
    IndexErrorUtils.checkAssumePositiveLength(index, length);
    return _codeUnitAtUnchecked(index);
  }

  @pragma("wasm:prefer-inline")
  int _codeUnitAtUnchecked(int index) {
    return _jsCharCodeAt(toExternRef, index);
  }

  @override
  Iterable<Match> allMatches(String string, [int start = 0]) {
    final stringLength = string.length;
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(start, stringLength);
    return StringAllMatchesIterable(string, this, start);
  }

  @override
  Match? matchAsPrefix(String string, [int start = 0]) {
    final stringLength = string.length;
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(start, stringLength);
    final length = this.length;
    if (start + length > stringLength) return null;
    // TODO(lrn): See if this can be optimized.
    for (int i = 0; i < length; i++) {
      if (string.codeUnitAt(start + i) != codeUnitAt(i)) {
        return null;
      }
    }
    return StringMatch(start, string, this);
  }

  @override
  String operator +(String other) {
    if (other is JSStringImpl) {
      return JSStringImpl(_jsConcat(toExternRef, other.toExternRef));
    }

    // TODO(joshualitt): Refactor `string_patch.dart` so we can directly
    // allocate a string of the right size.
    return js.jsStringToDartString(toExternRef) + other;
  }

  @override
  bool endsWith(String other) {
    final otherLength = other.length;
    final length = this.length;
    if (otherLength > length) return false;
    return other == substring(length - otherLength);
  }

  String _replaceJS(js.JSNativeRegExp jsRegExp, String replacement) =>
      JSStringImpl(js.JS<WasmExternRef?>(
          '(o, a, b) => o.replace(a, b)',
          toExternRef,
          (jsRegExp as js.JSValue).toExternRef,
          replacement.toExternRef));

  @override
  String replaceAll(Pattern from, String to) {
    if (from is String) {
      if (from.isEmpty) {
        if (isEmpty) {
          return to;
        } else {
          StringBuffer result = StringBuffer();
          result.write(to);
          final length = this.length;
          for (int i = 0; i < length; i++) {
            result.write(this[i]);
            result.write(to);
          }
          return result.toString();
        }
      } else if (from is JSStringImpl && to is JSStringImpl) {
        return JSStringImpl(js.JS<WasmExternRef?>(
            '(o, p, r) => o.split(p).join(r)',
            toExternRef,
            from.toExternRef,
            to.toExternRef));
      } else {
        return split(from).join(to);
      }
    } else if (from is js.JSSyntaxRegExp) {
      return _replaceJS(js.regExpGetGlobalNative(from), to);
    } else {
      int startIndex = 0;
      StringBuffer result = StringBuffer();
      for (Match match in from.allMatches(this)) {
        result.write(substring(startIndex, match.start));
        result.write(to);
        startIndex = match.end;
      }
      result.write(substring(startIndex));
      return result.toString();
    }
  }

  @override
  String replaceAllMapped(Pattern from, String Function(Match) convert) {
    return splitMapJoin(from, onMatch: convert);
  }

  @override
  String splitMapJoin(Pattern from,
      {String Function(Match)? onMatch, String Function(String)? onNonMatch}) {
    if (onMatch == null) onMatch = _matchString;
    if (onNonMatch == null) onNonMatch = _stringIdentity;
    if (from is String) {
      final patternLength = from.length;
      if (patternLength == 0) {
        // Pattern is the empty string.
        StringBuffer buffer = StringBuffer();
        int i = 0;
        buffer.write(onNonMatch(""));
        final length = this.length;
        while (i < length) {
          buffer.write(onMatch(StringMatch(i, this, "")));
          // Special case to avoid splitting a surrogate pair.
          int code = codeUnitAt(i);
          if ((code & ~0x3FF) == 0xD800 && length > i + 1) {
            // Leading surrogate;
            code = codeUnitAt(i + 1);
            if ((code & ~0x3FF) == 0xDC00) {
              // Matching trailing surrogate.
              buffer.write(onNonMatch(substring(i, i + 2)));
              i += 2;
              continue;
            }
          }
          buffer.write(onNonMatch(this[i]));
          i++;
        }
        buffer.write(onMatch(StringMatch(i, this, "")));
        buffer.write(onNonMatch(""));
        return buffer.toString();
      }
      StringBuffer buffer = StringBuffer();
      int startIndex = 0;
      final length = this.length;
      while (startIndex < length) {
        int position = indexOf(from, startIndex);
        if (position == -1) {
          break;
        }
        buffer.write(onNonMatch(substring(startIndex, position)));
        buffer.write(onMatch(StringMatch(position, this, from)));
        startIndex = position + patternLength;
      }
      buffer.write(onNonMatch(substring(startIndex)));
      return buffer.toString();
    }
    StringBuffer buffer = StringBuffer();
    int startIndex = 0;
    for (Match match in from.allMatches(this)) {
      buffer.write(onNonMatch(substring(startIndex, match.start)));
      buffer.write(onMatch(match));
      startIndex = match.end;
    }
    buffer.write(onNonMatch(substring(startIndex)));
    return buffer.toString();
  }

  String _replaceRange(int start, int end, String replacement) {
    String prefix = substring(0, start);
    String suffix = substring(end);
    return "$prefix$replacement$suffix";
  }

  String _replaceFirstRE(
      js.JSSyntaxRegExp regexp, String replacement, int startIndex) {
    final match = js.regExpExecGlobal(regexp, this, startIndex);
    if (match == null) return this;
    final start = match.start;
    final end = match.end;
    return _replaceRange(start, end, replacement);
  }

  @override
  String replaceFirst(Pattern from, String to, [int startIndex = 0]) {
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(startIndex, length);
    if (from is String) {
      int index = indexOf(from, startIndex);
      if (index < 0) return this;
      int end = index + from.length;
      return _replaceRange(index, end, to);
    }
    if (from is js.JSSyntaxRegExp) {
      return startIndex == 0
          ? _replaceJS(js.regExpGetNative(from), to)
          : _replaceFirstRE(from, to, startIndex);
    }
    Iterator<Match> matches = from.allMatches(this, startIndex).iterator;
    if (!matches.moveNext()) return this;
    Match match = matches.current;
    return replaceRange(match.start, match.end, to);
  }

  @override
  String replaceFirstMapped(Pattern from, String replace(Match match),
      [int startIndex = 0]) {
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(startIndex, length);
    Iterator<Match> matches = from.allMatches(this, startIndex).iterator;
    if (!matches.moveNext()) return this;
    Match match = matches.current;
    String replacement = "${replace(match)}";
    return replaceRange(match.start, match.end, replacement);
  }

  // TODO(joshualitt): Create a subtype of `JSArrayImpl` that can support lazily
  // converting arguments `toDart` and return that here.
  List<String> _jsSplit(WasmExternRef? token) => (js.JSValue(
              js.JS<WasmExternRef?>('(s, t) => s.split(t)', toExternRef, token))
          as JSArray)
      .toDart
      .map((JSAny? a) => (a as JSString).toDart)
      .toList();

  @override
  List<String> split(Pattern pattern) {
    if (pattern is JSStringImpl) {
      return _jsSplit(pattern.toExternRef);
    } else if (pattern is String) {
      return _jsSplit(pattern.toJS.toExternRef);
    } else if (pattern is js.JSSyntaxRegExp &&
        js.regExpCaptureCount(pattern) == 0) {
      final re = js.regExpGetNative(pattern);
      return _jsSplit((re as js.JSValue).toExternRef);
    } else {
      final result = <String>[];
      // End of most recent match. That is, start of next part to add to result.
      int start = 0;
      // Length of most recent match.
      // Set >0, so no match on the empty string causes the result to be [""].
      int length = 1;
      for (var match in pattern.allMatches(this)) {
        int matchStart = match.start;
        int matchEnd = match.end;
        length = matchEnd - matchStart;
        if (length == 0 && start == matchStart) {
          // An empty match right after another match is ignored.
          // This includes an empty match at the start of the string.
          continue;
        }
        int end = matchStart;
        result.add(substring(start, end));
        start = matchEnd;
      }
      if (start < this.length || length > 0) {
        // An empty match at the end of the string does not cause a "" at the
        // end.  A non-empty match ending at the end of the string does add a
        // "".
        result.add(substring(start));
      }
      return result;
    }
  }

  @override
  String replaceRange(int start, int? end, String replacement) {
    end ??= length;
    RangeErrorUtils.checkValidRangePositiveLength(start, end, length);
    return _replaceRange(start, end, replacement);
  }

  @override
  bool startsWith(Pattern pattern, [int index = 0]) {
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(index, length);
    if (pattern is String) {
      final patternLength = pattern.length;
      final endIndex = index + patternLength;
      if (endIndex > length) return false;
      return pattern == substring(index, endIndex);
    }
    return pattern.matchAsPrefix(this, index) != null;
  }

  @override
  String substring(int start, [int? end]) {
    end ??= length;
    RangeErrorUtils.checkValidRangePositiveLength(start, end, length);
    return JSStringImpl(_jsSubstring(toExternRef, start, end));
  }

  @override
  String toLowerCase() {
    final thisRef = toExternRef;
    final lowerCaseRef = js.JS<WasmExternRef?>('s => s.toLowerCase()', thisRef);
    return _jsIdentical(thisRef, lowerCaseRef)
        ? this
        : JSStringImpl(lowerCaseRef);
  }

  @override
  String toUpperCase() {
    final thisRef = toExternRef;
    final upperCaseRef = js.JS<WasmExternRef?>('s => s.toUpperCase()', thisRef);
    return _jsIdentical(thisRef, upperCaseRef)
        ? this
        : JSStringImpl(upperCaseRef);
  }

  // Characters with Whitespace property (Unicode 6.3).
  // 0009..000D    ; White_Space # Cc       <control-0009>..<control-000D>
  // 0020          ; White_Space # Zs       SPACE
  // 0085          ; White_Space # Cc       <control-0085>
  // 00A0          ; White_Space # Zs       NO-BREAK SPACE
  // 1680          ; White_Space # Zs       OGHAM SPACE MARK
  // 2000..200A    ; White_Space # Zs       EN QUAD..HAIR SPACE
  // 2028          ; White_Space # Zl       LINE SEPARATOR
  // 2029          ; White_Space # Zp       PARAGRAPH SEPARATOR
  // 202F          ; White_Space # Zs       NARROW NO-BREAK SPACE
  // 205F          ; White_Space # Zs       MEDIUM MATHEMATICAL SPACE
  // 3000          ; White_Space # Zs       IDEOGRAPHIC SPACE
  //
  // BOM: 0xFEFF
  static bool _isWhitespace(int codeUnit) {
    // Most codeUnits should be less than 256. Special case with a smaller
    // switch.
    if (codeUnit < 256) {
      switch (codeUnit) {
        case 0x09:
        case 0x0A:
        case 0x0B:
        case 0x0C:
        case 0x0D:
        case 0x20:
        case 0x85:
        case 0xA0:
          return true;
        default:
          return false;
      }
    }
    switch (codeUnit) {
      case 0x1680:
      case 0x2000:
      case 0x2001:
      case 0x2002:
      case 0x2003:
      case 0x2004:
      case 0x2005:
      case 0x2006:
      case 0x2007:
      case 0x2008:
      case 0x2009:
      case 0x200A:
      case 0x2028:
      case 0x2029:
      case 0x202F:
      case 0x205F:
      case 0x3000:
      case 0xFEFF:
        return true;
      default:
        return false;
    }
  }

  static const int spaceCodeUnit = 0x20;
  static const int carriageReturnCodeUnit = 0x0D;
  static const int nelCodeUnit = 0x85;

  /// Finds the index of the first non-whitespace character, or the
  /// end of the string. Start looking at position [index].
  static int _skipLeadingWhitespace(JSStringImpl string, int index) {
    final stringLength = string.length;
    while (index < stringLength) {
      int codeUnit = string._codeUnitAtUnchecked(index);
      if (codeUnit != spaceCodeUnit &&
          codeUnit != carriageReturnCodeUnit &&
          !_isWhitespace(codeUnit)) {
        break;
      }
      index++;
    }
    return index;
  }

  /// Finds the index after the last non-whitespace character, or 0.
  /// Start looking at position [index - 1].
  static int _skipTrailingWhitespace(JSStringImpl string, int index) {
    while (index > 0) {
      int codeUnit = string._codeUnitAtUnchecked(index - 1);
      if (codeUnit != spaceCodeUnit &&
          codeUnit != carriageReturnCodeUnit &&
          !_isWhitespace(codeUnit)) {
        break;
      }
      index--;
    }
    return index;
  }

  // dart2wasm can't use JavaScript trim directly,
  // because JavaScript does not trim
  // the NEXT LINE (NEL) character (0x85).
  @override
  String trim() {
    // Start by doing JS trim. Then check if it leaves a NEL at
    // either end of the string.
    final result =
        JSStringImpl(js.JS<WasmExternRef?>('s => s.trim()', toExternRef));
    final resultLength = result.length;
    if (resultLength == 0) return result;
    int firstCode = result._codeUnitAtUnchecked(0);
    int startIndex = 0;
    if (firstCode == nelCodeUnit) {
      startIndex = _skipLeadingWhitespace(result, 1);
      if (startIndex == resultLength) return "";
    }

    int endIndex = resultLength;
    // We know that there is at least one character that is non-whitespace.
    // Therefore we don't need to verify that endIndex > startIndex.
    int lastCode = result.codeUnitAt(endIndex - 1);
    if (lastCode == nelCodeUnit) {
      endIndex = _skipTrailingWhitespace(result, endIndex - 1);
    }
    if (startIndex == 0 && endIndex == resultLength) return result;
    return substring(startIndex, endIndex);
  }

  // dart2wasm can't use JavaScript trimLeft directly because it does not trim
  // the NEXT LINE character (0x85).
  @override
  String trimLeft() {
    // Start by doing JS trim. Then check if it leaves a NEL at
    // the beginning of the string.
    int startIndex = 0;
    final result =
        JSStringImpl(js.JS<WasmExternRef?>('s => s.trimLeft()', toExternRef));
    final resultLength = result.length;
    if (resultLength == 0) return result;
    int firstCode = result._codeUnitAtUnchecked(0);
    if (firstCode == nelCodeUnit) {
      startIndex = _skipLeadingWhitespace(result, 1);
    }
    if (startIndex == 0) return result;
    if (startIndex == resultLength) return "";
    return result.substring(startIndex);
  }

  // dart2wasm can't use JavaScript trimRight directly because it does not trim
  // the NEXT LINE character (0x85).
  @override
  String trimRight() {
    // Start by doing JS trim. Then check if it leaves a NEL at the end of the
    // string.
    final result =
        JSStringImpl(js.JS<WasmExternRef?>('s => s.trimRight()', toExternRef));
    final resultLength = result.length;
    int endIndex = resultLength;
    if (endIndex == 0) return result;
    int lastCode = result.codeUnitAt(endIndex - 1);
    if (lastCode == nelCodeUnit) {
      endIndex = _skipTrailingWhitespace(result, endIndex - 1);
    }

    if (endIndex == resultLength) return result;
    if (endIndex == 0) return "";
    return result.substring(0, endIndex);
  }

  @override
  String operator *(int times) {
    if (0 >= times) return '';
    if (times == 1 || length == 0) return this;
    return JSStringImpl(js.JS<WasmExternRef?>(
        '(s, n) => s.repeat(n)', toExternRef, times.toDouble().toExternRef));
  }

  @override
  String padLeft(int width, [String padding = ' ']) {
    int delta = width - length;
    if (delta <= 0) return this;
    return (padding * delta) + this;
  }

  @override
  String padRight(int width, [String padding = ' ']) {
    int delta = width - length;
    if (delta <= 0) return this;
    return this + (padding * delta);
  }

  @override
  List<int> get codeUnits => CodeUnits(this);

  @override
  Runes get runes => Runes(this);

  int _jsIndexOf(WasmExternRef? pattern, int start) => js
      .JS<double>('(s, p, i) => s.indexOf(p, i)', toExternRef, pattern,
          start.toDouble())
      .toInt();

  @override
  int indexOf(Pattern pattern, [int start = 0]) {
    final length = this.length;
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(start, length);
    if (pattern is JSStringImpl) {
      return _jsIndexOf(pattern.toExternRef, start);
    } else if (pattern is String) {
      return _jsIndexOf(pattern.toExternRef, start);
    } else if (pattern is js.JSSyntaxRegExp) {
      Match? match = js.firstMatchAfter(pattern, this, start);
      return (match == null) ? -1 : match.start;
    } else {
      for (int i = start; i <= length; i++) {
        if (pattern.matchAsPrefix(this, i) != null) return i;
      }
      return -1;
    }
  }

  int _jsLastIndexOf(WasmExternRef? pattern, int start) => js
      .JS<double>('(s, p, i) => s.lastIndexOf(p, i)', toExternRef, pattern,
          start.toDouble())
      .toInt();

  @override
  int lastIndexOf(Pattern pattern, [int? start]) {
    final length = this.length;
    if (start == null) {
      start = length;
    } else {
      RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(start, length);
    }
    if (pattern is JSStringImpl) {
      if (start + pattern.length > length) {
        start = length - pattern.length;
      }
      return _jsLastIndexOf(pattern.toExternRef, start);
    } else if (pattern is String) {
      if (start + pattern.length > length) {
        start = length - pattern.length;
      }
      return _jsLastIndexOf(pattern.toExternRef, start);
    }
    for (int i = start; i >= 0; i--) {
      if (pattern.matchAsPrefix(this, i) != null) return i;
    }
    return -1;
  }

  @override
  bool contains(Pattern other, [int startIndex = 0]) {
    final length = this.length;
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(startIndex, length);
    if (other is String) {
      return indexOf(other, startIndex) >= 0;
    } else if (other is js.JSSyntaxRegExp) {
      return other.hasMatch(substring(startIndex));
    } else {
      return other.allMatches(substring(startIndex)).isNotEmpty;
    }
  }

  /// This must be kept in sync with `StringBase.hashCode` in string_patch.dart.
  /// TODO(joshualitt): Find some way to cache the hash code.
  @override
  int get hashCode {
    int hash = 0;
    final length = this.length;
    for (int i = 0; i < length; i++) {
      hash = stringCombineHashes(hash, _codeUnitAtUnchecked(i));
    }
    return stringFinalizeHash(hash);
  }

  @override
  @pragma("wasm:prefer-inline")
  String operator [](int index) {
    final length = this.length;
    IndexErrorUtils.checkAssumePositiveLength(index, length);
    return JSStringImpl(_jsFromCharCode(_codeUnitAtUnchecked(index)));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is JSStringImpl) {
      return _jsEquals(toExternRef, other.toExternRef);
    }

    final length = this.length;
    if (other is String && length == other.length) {
      for (int i = 0; i < length; i++) {
        if (_codeUnitAtUnchecked(i) != other.codeUnitAt(i)) {
          return false;
        }
      }
      return true;
    }

    return false;
  }

  @override
  int compareTo(String other) {
    if (other is JSStringImpl) {
      return _jsCompare(toExternRef, other.toExternRef);
    }
    final otherLength = other.length;
    final length = this.length;
    final len = (length < otherLength) ? length : otherLength;
    for (int i = 0; i < len; i++) {
      int thisCodeUnit = _codeUnitAtUnchecked(i);
      int otherCodeUnit = other.codeUnitAt(i);
      if (thisCodeUnit < otherCodeUnit) {
        return -1;
      }
      if (thisCodeUnit > otherCodeUnit) {
        return 1;
      }
    }
    if (length < otherLength) return -1;
    if (length > otherLength) return 1;
    return 0;
  }

  @override
  String toString() => js.stringify(toExternRef);

  int firstNonWhitespace() {
    final length = this.length;
    int first = 0;
    for (; first < length; first++) {
      if (!_isWhitespace(_codeUnitAtUnchecked(first))) {
        break;
      }
    }
    return first;
  }

  int lastNonWhitespace() {
    int last = length - 1;
    for (; last >= 0; last--) {
      if (!_isWhitespace(_codeUnitAtUnchecked(last))) {
        break;
      }
    }
    return last;
  }
}

String _matchString(Match match) => match[0]!;

String _stringIdentity(String string) => string;

@pragma("wasm:export", "\$jsStringToJSStringImpl")
JSStringImpl _jsStringToJSStringImpl(WasmExternRef? string) =>
    JSStringImpl(string);

@pragma("wasm:export", "\$jsStringFromJSStringImpl")
WasmExternRef? _jsStringFromJSStringImpl(JSStringImpl string) =>
    string.toExternRef;

bool _jsIdentical(WasmExternRef? ref1, WasmExternRef? ref2) =>
    js.JS<bool>('Object.is', ref1, ref2);

@pragma("wasm:prefer-inline")
int _jsCharCodeAt(WasmExternRef? stringRef, int index) => js
    .JS<WasmI32>(
        'WebAssembly.String.charCodeAt', stringRef, WasmI32.fromInt(index))
    .toIntUnsigned();

WasmExternRef _jsConcat(WasmExternRef? s1, WasmExternRef? s2) =>
    js.JS<WasmExternRef>('WebAssembly.String.concat', s1, s2);

@pragma("wasm:prefer-inline")
WasmExternRef _jsSubstring(
        WasmExternRef? stringRef, int startIndex, int endIndex) =>
    js.JS<WasmExternRef>('WebAssembly.String.substring', stringRef,
        WasmI32.fromInt(startIndex), WasmI32.fromInt(endIndex));

@pragma("wasm:prefer-inline")
int _jsLength(WasmExternRef? stringRef) =>
    js.JS<WasmI32>('WebAssembly.String.length', stringRef).toIntUnsigned();

@pragma("wasm:prefer-inline")
bool _jsEquals(WasmExternRef? s1, WasmExternRef? s2) =>
    js.JS<WasmI32>('WebAssembly.String.equals', s1, s2).toBool();

@pragma("wasm:prefer-inline")
int _jsCompare(WasmExternRef? s1, WasmExternRef? s2) =>
    js.JS<WasmI32>('WebAssembly.String.compare', s1, s2).toIntSigned();

@pragma("wasm:prefer-inline")
WasmExternRef _jsFromCharCode(int charCode) => js.JS<WasmExternRef>(
    'WebAssembly.String.fromCharCode', WasmI32.fromInt(charCode));
