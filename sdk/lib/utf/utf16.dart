// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.utf;

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
IterableUtf16Decoder decodeUtf16AsIterable(List<int> bytes, [int offset = 0,
    int length, int replacementCodepoint =
    UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  return new IterableUtf16Decoder._(
      () => new Utf16BytesToCodeUnitsDecoder(bytes, offset, length,
      replacementCodepoint), replacementCodepoint);
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
IterableUtf16Decoder decodeUtf16beAsIterable(List<int> bytes, [int offset = 0,
    int length, bool stripBom = true, int replacementCodepoint =
    UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  return new IterableUtf16Decoder._(
      () => new Utf16beBytesToCodeUnitsDecoder(bytes, offset, length, stripBom,
      replacementCodepoint), replacementCodepoint);
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
IterableUtf16Decoder decodeUtf16leAsIterable(List<int> bytes, [int offset = 0,
    int length, bool stripBom = true, int replacementCodepoint =
    UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  return new IterableUtf16Decoder._(
      () => new Utf16leBytesToCodeUnitsDecoder(bytes, offset, length, stripBom,
      replacementCodepoint), replacementCodepoint);
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
String decodeUtf16(List<int> bytes, [int offset = 0, int length,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  Utf16BytesToCodeUnitsDecoder decoder = new Utf16BytesToCodeUnitsDecoder(bytes,
      offset, length, replacementCodepoint);
  List<int> codeunits = decoder.decodeRest();
  return new String.fromCharCodes(
      _utf16CodeUnitsToCodepoints(codeunits, 0, null, replacementCodepoint));
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
String decodeUtf16be(List<int> bytes, [int offset = 0, int length,
    bool stripBom = true,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  List<int> codeunits = (new Utf16beBytesToCodeUnitsDecoder(bytes, offset,
      length, stripBom, replacementCodepoint)).decodeRest();
  return new String.fromCharCodes(
      _utf16CodeUnitsToCodepoints(codeunits, 0, null, replacementCodepoint));
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
String decodeUtf16le(List<int> bytes, [int offset = 0, int length,
    bool stripBom = true,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  List<int> codeunits = (new Utf16leBytesToCodeUnitsDecoder(bytes, offset,
      length, stripBom, replacementCodepoint)).decodeRest();
  return new String.fromCharCodes(
      _utf16CodeUnitsToCodepoints(codeunits, 0, null, replacementCodepoint));
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
List<int> encodeUtf16(String str) =>
    encodeUtf16be(str, true);

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
List<int> encodeUtf16be(String str, [bool writeBOM = false]) {
  List<int> utf16CodeUnits = _stringToUtf16CodeUnits(str);
  List<int> encoding =
      new List<int>(2 * utf16CodeUnits.length + (writeBOM ? 2 : 0));
  int i = 0;
  if (writeBOM) {
    encoding[i++] = UNICODE_UTF_BOM_HI;
    encoding[i++] = UNICODE_UTF_BOM_LO;
  }
  for (int unit in utf16CodeUnits) {
    encoding[i++] = (unit & UNICODE_BYTE_ONE_MASK) >> 8;
    encoding[i++] = unit & UNICODE_BYTE_ZERO_MASK;
  }
  return encoding;
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
List<int> encodeUtf16le(String str, [bool writeBOM = false]) {
  List<int> utf16CodeUnits = _stringToUtf16CodeUnits(str);
  List<int> encoding =
      new List<int>(2 * utf16CodeUnits.length + (writeBOM ? 2 : 0));
  int i = 0;
  if (writeBOM) {
    encoding[i++] = UNICODE_UTF_BOM_LO;
    encoding[i++] = UNICODE_UTF_BOM_HI;
  }
  for (int unit in utf16CodeUnits) {
    encoding[i++] = unit & UNICODE_BYTE_ZERO_MASK;
    encoding[i++] = (unit & UNICODE_BYTE_ONE_MASK) >> 8;
  }
  return encoding;
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
bool hasUtf16Bom(List<int> utf32EncodedBytes, [int offset = 0, int length]) {
  return hasUtf16beBom(utf32EncodedBytes, offset, length) ||
      hasUtf16leBom(utf32EncodedBytes, offset, length);
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
bool hasUtf16beBom(List<int> utf16EncodedBytes, [int offset = 0, int length]) {
  int end = length != null ? offset + length : utf16EncodedBytes.length;
  return (offset + 2) <= end &&
      utf16EncodedBytes[offset] == UNICODE_UTF_BOM_HI &&
      utf16EncodedBytes[offset + 1] == UNICODE_UTF_BOM_LO;
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
bool hasUtf16leBom(List<int> utf16EncodedBytes, [int offset = 0, int length]) {
  int end = length != null ? offset + length : utf16EncodedBytes.length;
  return (offset + 2) <= end &&
      utf16EncodedBytes[offset] == UNICODE_UTF_BOM_LO &&
      utf16EncodedBytes[offset + 1] == UNICODE_UTF_BOM_HI;
}

List<int> _stringToUtf16CodeUnits(String str) {
  return _codepointsToUtf16CodeUnits(str.codeUnits);
}

typedef _ListRangeIterator _CodeUnitsProvider();

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
class IterableUtf16Decoder extends IterableBase<int> {
  final _CodeUnitsProvider codeunitsProvider;
  final int replacementCodepoint;

  IterableUtf16Decoder._(this.codeunitsProvider, this.replacementCodepoint);

  Utf16CodeUnitDecoder get iterator =>
      new Utf16CodeUnitDecoder.fromListRangeIterator(codeunitsProvider(),
          replacementCodepoint);
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
abstract class Utf16BytesToCodeUnitsDecoder implements _ListRangeIterator {
  final _ListRangeIterator utf16EncodedBytesIterator;
  final int replacementCodepoint;
  int _current = null;

  Utf16BytesToCodeUnitsDecoder._fromListRangeIterator(
      this.utf16EncodedBytesIterator, this.replacementCodepoint);

  factory Utf16BytesToCodeUnitsDecoder(List<int> utf16EncodedBytes, [
      int offset = 0, int length,
      int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
    if (length == null) {
      length = utf16EncodedBytes.length - offset;
    }
    if (hasUtf16beBom(utf16EncodedBytes, offset, length)) {
      return new Utf16beBytesToCodeUnitsDecoder(utf16EncodedBytes, offset + 2,
          length - 2, false, replacementCodepoint);
    } else if (hasUtf16leBom(utf16EncodedBytes, offset, length)) {
      return new Utf16leBytesToCodeUnitsDecoder(utf16EncodedBytes, offset + 2,
          length - 2, false, replacementCodepoint);
    } else {
      return new Utf16beBytesToCodeUnitsDecoder(utf16EncodedBytes, offset,
          length, false, replacementCodepoint);
    }
  }

  /**
   * Provides a fast way to decode the rest of the source bytes in a single
   * call. This method trades memory for improved speed in that it potentially
   * over-allocates the List containing results.
   */
  List<int> decodeRest() {
    List<int> codeunits = new List<int>(remaining);
    int i = 0;
    while (moveNext()) {
      codeunits[i++] = current;
    }
    if (i == codeunits.length) {
      return codeunits;
    } else {
      List<int> truncCodeunits = new List<int>(i);
      truncCodeunits.setRange(0, i, codeunits);
      return truncCodeunits;
    }
  }

  int get current => _current;

  bool moveNext() {
    _current = null;
    if (utf16EncodedBytesIterator.remaining < 2) {
      utf16EncodedBytesIterator.moveNext();
      if (replacementCodepoint != null) {
        _current = replacementCodepoint;
        return true;
      } else {
        throw new ArgumentError(
            "Invalid UTF16 at ${utf16EncodedBytesIterator.position}");
      }
    } else {
      _current = decode();
      return true;
    }
  }

  int get position => utf16EncodedBytesIterator.position ~/ 2;

  void backup([int by = 1]) {
    utf16EncodedBytesIterator.backup(2 * by);
  }

  int get remaining => (utf16EncodedBytesIterator.remaining + 1) ~/ 2;

  void skip([int count = 1]) {
    utf16EncodedBytesIterator.skip(2 * count);
  }

  int decode();
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
class Utf16beBytesToCodeUnitsDecoder extends Utf16BytesToCodeUnitsDecoder {
  Utf16beBytesToCodeUnitsDecoder(List<int> utf16EncodedBytes, [
      int offset = 0, int length, bool stripBom = true,
      int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) :
      super._fromListRangeIterator(
          (new _ListRange(utf16EncodedBytes, offset, length)).iterator,
          replacementCodepoint) {
    if (stripBom && hasUtf16beBom(utf16EncodedBytes, offset, length)) {
      skip();
    }
  }

  int decode() {
    utf16EncodedBytesIterator.moveNext();
    int hi = utf16EncodedBytesIterator.current;
    utf16EncodedBytesIterator.moveNext();
    int lo = utf16EncodedBytesIterator.current;
    return (hi << 8) + lo;
  }
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
class Utf16leBytesToCodeUnitsDecoder extends Utf16BytesToCodeUnitsDecoder {
  Utf16leBytesToCodeUnitsDecoder(List<int> utf16EncodedBytes, [
      int offset = 0, int length, bool stripBom = true,
      int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) :
      super._fromListRangeIterator(
          (new _ListRange(utf16EncodedBytes, offset, length)).iterator,
          replacementCodepoint) {
    if (stripBom && hasUtf16leBom(utf16EncodedBytes, offset, length)) {
      skip();
    }
  }

  int decode() {
    utf16EncodedBytesIterator.moveNext();
    int lo = utf16EncodedBytesIterator.current;
    utf16EncodedBytesIterator.moveNext();
    int hi = utf16EncodedBytesIterator.current;
    return (hi << 8) + lo;
  }
}
