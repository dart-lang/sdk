// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_embedder' as embedder;
import 'dart:_error_utils';
import 'dart:_internal';
import 'dart:_object_helper';
import 'dart:_string_helper';
import 'dart:_wasm';

part 'regexp.dart';

abstract class StringUncheckedOperationsBase {
  int _codeUnitAtUnchecked(int index);
  String _substringUnchecked(int start, int end);
}

extension StringUncheckedOperations on String {
  @pragma('wasm:prefer-inline')
  int codeUnitAtUnchecked(int index) =>
      unsafeCast<StringUncheckedOperationsBase>(this)
          ._codeUnitAtUnchecked(index);

  @pragma('wasm:prefer-inline')
  String substringUnchecked(int start, int end) =>
      unsafeCast<StringUncheckedOperationsBase>(this)
          ._substringUnchecked(start, end);
}

/// A string managed by the WebAssembly embedder.
final class EmbedderStringImpl
    implements String, StringUncheckedOperationsBase {
  WasmExternRef? _ref;

  EmbedderStringImpl.fromRefUnchecked(this._ref);

  WasmExternRef? get wrappedExternRef => _ref;

  @override
  @pragma("wasm:prefer-inline")
  int get length => embedder.stringLength(_ref).toIntUnsigned();

  @override
  @pragma("wasm:prefer-inline")
  bool get isEmpty => length == 0;

  @override
  @pragma("wasm:prefer-inline")
  bool get isNotEmpty => !isEmpty;

  @pragma("wasm:entry-point")
  static String _interpolate(WasmArray<Object?> values) {
    final valuesLength = values.length;
    final result = StringBuffer();
    for (int i = 0; i < valuesLength; i++) {
      result.write(values[i].toString());
    }
    return result.toString();
  }

  @pragma("wasm:entry-point", "call")
  static String _interpolate1(Object? value) {
    return value is String ? value : value.toString();
  }

  @pragma("wasm:entry-point", "call")
  static String _interpolate2(Object? value1, Object? value2) {
    return (StringBuffer(
      value1 is String ? value1 : value1.toString(),
    )..write(value2 is String ? value2 : value2.toString())).toString();
  }

  @pragma("wasm:entry-point", "call")
  static String _interpolate3(Object? value1, Object? value2, Object? value3) {
    return (StringBuffer(value1 is String ? value1 : value1.toString())
          ..write(value2 is String ? value2 : value2.toString())
          ..write(value3 is String ? value3 : value3.toString()))
        .toString();
  }

  @pragma("wasm:entry-point", "call")
  static String _interpolate4(
    Object? value1,
    Object? value2,
    Object? value3,
    Object? value4,
  ) {
    return (StringBuffer(value1 is String ? value1 : value1.toString())
          ..write(value2 is String ? value2 : value2.toString())
          ..write(value3 is String ? value3 : value3.toString())
          ..write(value4 is String ? value4 : value4.toString()))
        .toString();
  }

  static EmbedderStringImpl fromAsciiBytes(
    WasmArray<WasmI8> source,
    int start,
    int end,
  ) {
    final length = WasmI32.fromInt(end - start);
    return EmbedderStringImpl.fromRefUnchecked(
      embedder.stringFromAsciiBytes(source, WasmI32.fromInt(start), length),
    );
  }

  static EmbedderStringImpl fromCharCodeArray(
    WasmArray<WasmI16> source,
    int start,
    int end,
  ) {
    return EmbedderStringImpl.fromRefUnchecked(
      embedder.stringFromCharCodeArray(
        source,
        WasmI32.fromInt(start),
        WasmI32.fromInt(end - start),
      ),
    );
  }

  @pragma("wasm:initialize-at-startup")
  static final _stringFromCodePointBuffer = WasmArray<WasmI16>(2);

  static EmbedderStringImpl fromCharCode(int charCode) {
    final array = _stringFromCodePointBuffer;
    array.write(0, charCode);
    return EmbedderStringImpl.fromCharCodeArray(array, 0, 1);
  }

  static EmbedderStringImpl fromCodePoint(int codePoint) {
    final array = _stringFromCodePointBuffer;
    if (codePoint <= 0xffff) {
      array.write(0, codePoint);
      return EmbedderStringImpl.fromCharCodeArray(array, 0, 1);
    }
    final low = 0xDC00 | (codePoint & 0x3ff);
    final high = 0xD7C0 + (codePoint >> 10);
    array.write(0, high);
    array.write(1, low);
    return EmbedderStringImpl.fromCharCodeArray(array, 0, 2);
  }

  @override
  @pragma("wasm:prefer-inline")
  int codeUnitAt(int index) {
    final length = this.length;
    IndexErrorUtils.checkIndex(index, length);
    return _codeUnitAtUnchecked(index);
  }

  @override
  @pragma("wasm:prefer-inline")
  int _codeUnitAtUnchecked(int index) {
    return embedder
        .stringCodeUnitAt(wrappedExternRef, WasmI32.fromInt(index))
        .toIntUnsigned();
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
  @pragma('wasm:pure-function')
  String operator +(String other) {
    return EmbedderStringImpl.fromRefUnchecked(
      embedder.stringConcat(
        wrappedExternRef,
        unsafeCast<EmbedderStringImpl>(other).wrappedExternRef,
      ),
    );
  }

  @override
  bool endsWith(String other) {
    final otherLength = other.length;
    final length = this.length;
    if (otherLength > length) return false;
    return other == _substringUnchecked(length - otherLength, length);
  }

  @override
  String replaceAll(Pattern from, String to) {
    if (from is String) {
      if (from.isEmpty) {
        if (isEmpty) return to;
        StringBuffer result = StringBuffer();
        result.write(to);
        final length = this.length;
        for (int i = 0; i < length; i++) {
          result.write(this[i]);
          result.write(to);
        }
        return result.toString();
      }
      return EmbedderStringImpl.fromRefUnchecked(
        embedder.stringReplaceAllString(
          wrappedExternRef,
          unsafeCast<EmbedderStringImpl>(from).wrappedExternRef,
          unsafeCast<EmbedderStringImpl>(to).wrappedExternRef,
        ),
      );
    } else if (from is EmbedderRegExp) {
      return EmbedderStringImpl.fromRefUnchecked(
        embedder.stringReplaceAllRegExp(
          wrappedExternRef,
          from._regexp,
          unsafeCast<EmbedderStringImpl>(to).wrappedExternRef,
        ),
      );
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
  String splitMapJoin(
    Pattern from, {
    String Function(Match)? onMatch,
    String Function(String)? onNonMatch,
  }) {
    return splitMapJoinImpl(this, from, onMatch, onNonMatch);
  }

  String _replaceRange(int start, int end, String replacement) {
    return EmbedderStringImpl.fromRefUnchecked(
      embedder.stringReplaceRange(
        wrappedExternRef,
        WasmI32.fromInt(start),
        WasmI32.fromInt(end),
        unsafeCast<EmbedderStringImpl>(replacement).wrappedExternRef,
      ),
    );
  }

  @override
  String replaceFirst(Pattern from, String to, [int startIndex = 0]) {
    Iterator<Match> matches = from.allMatches(this, startIndex).iterator;
    if (!matches.moveNext()) return this;
    Match match = matches.current;
    return replaceRange(match.start, match.end, to);
  }

  @override
  String replaceFirstMapped(
    Pattern from,
    String replace(Match match), [
    int startIndex = 0,
  ]) {
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(startIndex, length);
    final Iterator<Match> matches = from.allMatches(this, startIndex).iterator;
    if (!matches.moveNext()) return this;
    final Match match = matches.current;
    return replaceRange(match.start, match.end, replace(match));
  }

  @override
  List<String> split(Pattern pattern) {
    return genericSplitImpl(this, pattern);
  }

  @override
  String replaceRange(int start, int? end, String replacement) {
    end ??= length;
    RangeErrorUtils.checkValidRange(start, end, length);
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
    RangeErrorUtils.checkValidRange(start, end, length);
    if (start == end) return "";
    return _substringUnchecked(start, end);
  }

  @override
  @pragma('wasm:prefer-inline')
  String _substringUnchecked(int start, int end) =>
      EmbedderStringImpl.fromRefUnchecked(
        embedder.stringSubstring(
          wrappedExternRef,
          WasmI32.fromInt(start),
          WasmI32.fromInt(end),
        ),
      );

  @override
  String toLowerCase() {
    final toLower = embedder.stringToLowerCase(wrappedExternRef);
    if (embedder.stringEquals(toLower, wrappedExternRef).toBool()) {
      return this;
    } else {
      return EmbedderStringImpl.fromRefUnchecked(toLower);
    }
  }

  @override
  String toUpperCase() {
    final toUpper = embedder.stringToUpperCase(wrappedExternRef);
    if (embedder.stringEquals(toUpper, wrappedExternRef).toBool()) {
      return this;
    } else {
      return EmbedderStringImpl.fromRefUnchecked(toUpper);
    }
  }

  String _trim(bool left, bool right) {
    if (isEmpty) return this;

    var start = 0, end = length;
    if (left) start = skipLeadingWhitespace(this, 0);
    if (right) end = skipTrailingWhitespace(this, length, start);
    if (start >= end) return '';
    if (start == 0 && end == length) return this;

    return _substringUnchecked(start, end);
  }

  @override
  String trim() {
    return _trim(true, true);
  }

  @override
  String trimLeft() {
    return _trim(true, false);
  }

  @override
  String trimRight() {
    return _trim(false, true);
  }

  @override
  String operator *(int times) {
    if (0 >= times) return '';
    if (times == 1 || length == 0) return this;
    if (times & 0x7fffffff != times) {
      throw Exception(
        'The implementation cannot handle very large operands (was: $times).',
      );
    }

    return EmbedderStringImpl.fromRefUnchecked(
      embedder.stringRepeat(wrappedExternRef, WasmI32.fromInt(times)),
    );
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

  @override
  int indexOf(Pattern pattern, [int start = 0]) {
    final length = this.length;
    RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(start, length);
    if (pattern is EmbedderStringImpl) {
      return embedder
          .stringIndexOfString(
            wrappedExternRef,
            pattern.wrappedExternRef,
            WasmI32.fromInt(start),
          )
          .toIntSigned();
    } else if (pattern is EmbedderRegExp) {
      final match = pattern._search(this, start, false);
      return match?.start ?? -1;
    } else {
      for (int i = start; i <= length; i++) {
        if (pattern.matchAsPrefix(this, i) != null) return i;
      }
      return -1;
    }
  }

  @override
  int lastIndexOf(Pattern pattern, [int? start]) {
    final length = this.length;
    if (start == null) {
      start = length;
    } else {
      RangeErrorUtils.checkValueBetweenZeroAndPositiveMax(start, length);
    }
    if (pattern is EmbedderStringImpl) {
      if (start + pattern.length > length) {
        start = length - pattern.length;
      }
      return embedder
          .stringLastIndexOfString(
            wrappedExternRef,
            pattern.wrappedExternRef,
            WasmI32.fromInt(start),
          )
          .toIntSigned();
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
    if (other is String || other is EmbedderRegExp) {
      return indexOf(other, startIndex) >= 0;
    } else {
      return other.allMatches(substring(startIndex)).isNotEmpty;
    }
  }

  @override
  int get hashCode {
    int hash = getIdentityHashField(this);
    if (hash != 0) return hash;
    hash = _computeHashCode();
    setIdentityHashField(this, hash);
    return hash;
  }

  /// This must be kept in sync with `StringBase.hashCode` in string_patch.dart.
  int _computeHashCode() {
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
    IndexErrorUtils.checkIndex(index, length);
    return EmbedderStringImpl.fromCharCode(_codeUnitAtUnchecked(index));
  }

  @override
  @pragma('wasm:prefer-inline')
  bool operator ==(Object other) =>
      other is EmbedderStringImpl &&
      embedder.stringEquals(_ref, other._ref).toBool();

  @override
  @pragma('wasm:prefer-inline')
  int compareTo(String other) => embedder
      .stringCompare(
        wrappedExternRef,
        unsafeCast<EmbedderStringImpl>(other).wrappedExternRef,
      )
      .toIntSigned();

  @override
  String toString() => this;
}

String _matchString(Match match) => match[0]!;

String _stringIdentity(String string) => string;

@patch
@pragma('wasm:prefer-inline')
EmbedderStringImpl embedderStringFromDartString(String s) {
  return unsafeCast<EmbedderStringImpl>(s);
}
