// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.utf;

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
IterableUtf32Decoder decodeUtf32AsIterable(List<int> bytes, [
    int offset = 0, int length,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  return new IterableUtf32Decoder._(
      () => new Utf32BytesDecoder(bytes, offset, length, replacementCodepoint));
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
IterableUtf32Decoder decodeUtf32beAsIterable(List<int> bytes, [
    int offset = 0, int length, bool stripBom = true,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  return new IterableUtf32Decoder._(
      () => new Utf32beBytesDecoder(bytes, offset, length, stripBom,
          replacementCodepoint));
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
IterableUtf32Decoder decodeUtf32leAsIterable(List<int> bytes, [
    int offset = 0, int length, bool stripBom = true,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  return new IterableUtf32Decoder._(
      () => new Utf32leBytesDecoder(bytes, offset, length, stripBom,
          replacementCodepoint));
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
String decodeUtf32(List<int> bytes, [int offset = 0, int length,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  return new String.fromCharCodes((new Utf32BytesDecoder(bytes, offset, length,
      replacementCodepoint)).decodeRest());
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
String decodeUtf32be(
    List<int> bytes, [int offset = 0, int length, bool stripBom = true,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) =>
  new String.fromCharCodes((new Utf32beBytesDecoder(bytes, offset, length,
    stripBom, replacementCodepoint)).decodeRest());

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
String decodeUtf32le(
    List<int> bytes, [int offset = 0, int length, bool stripBom = true,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) =>
    new String.fromCharCodes((new Utf32leBytesDecoder(bytes, offset, length,
      stripBom, replacementCodepoint)).decodeRest());

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
List<int> encodeUtf32(String str) =>
    encodeUtf32be(str, true);

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
List<int> encodeUtf32be(String str, [bool writeBOM = false]) {
  List<int> utf32CodeUnits = stringToCodepoints(str);
  List<int> encoding = new List<int>(4 * utf32CodeUnits.length +
      (writeBOM ? 4 : 0));
  int i = 0;
  if (writeBOM) {
    encoding[i++] = 0;
    encoding[i++] = 0;
    encoding[i++] = UNICODE_UTF_BOM_HI;
    encoding[i++] = UNICODE_UTF_BOM_LO;
  }
  for (int unit in utf32CodeUnits) {
    encoding[i++] = (unit >> 24) & UNICODE_BYTE_ZERO_MASK;
    encoding[i++] = (unit >> 16) & UNICODE_BYTE_ZERO_MASK;
    encoding[i++] = (unit >> 8) & UNICODE_BYTE_ZERO_MASK;
    encoding[i++] = unit & UNICODE_BYTE_ZERO_MASK;
  }
  return encoding;
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
List<int> encodeUtf32le(String str, [bool writeBOM = false]) {
  List<int> utf32CodeUnits = stringToCodepoints(str);
  List<int> encoding = new List<int>(4 * utf32CodeUnits.length +
      (writeBOM ? 4 : 0));
  int i = 0;
  if (writeBOM) {
    encoding[i++] = UNICODE_UTF_BOM_LO;
    encoding[i++] = UNICODE_UTF_BOM_HI;
    encoding[i++] = 0;
    encoding[i++] = 0;
  }
  for (int unit in utf32CodeUnits) {
    encoding[i++] = unit & UNICODE_BYTE_ZERO_MASK;
    encoding[i++] = (unit >> 8) & UNICODE_BYTE_ZERO_MASK;
    encoding[i++] = (unit >> 16) & UNICODE_BYTE_ZERO_MASK;
    encoding[i++] = (unit >> 24) & UNICODE_BYTE_ZERO_MASK;
  }
  return encoding;
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
bool hasUtf32Bom(
    List<int> utf32EncodedBytes, [int offset = 0, int length]) {
  return hasUtf32beBom(utf32EncodedBytes, offset, length) ||
      hasUtf32leBom(utf32EncodedBytes, offset, length);
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
bool hasUtf32beBom(List<int> utf32EncodedBytes, [int offset = 0, int length]) {
  int end = length != null ? offset + length : utf32EncodedBytes.length;
  return (offset + 4) <= end &&
      utf32EncodedBytes[offset] == 0 && utf32EncodedBytes[offset + 1] == 0 &&
      utf32EncodedBytes[offset + 2] == UNICODE_UTF_BOM_HI &&
      utf32EncodedBytes[offset + 3] == UNICODE_UTF_BOM_LO;
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
bool hasUtf32leBom(List<int> utf32EncodedBytes, [int offset = 0, int length]) {
  int end = length != null ? offset + length : utf32EncodedBytes.length;
  return (offset + 4) <= end &&
      utf32EncodedBytes[offset] == UNICODE_UTF_BOM_LO &&
      utf32EncodedBytes[offset + 1] == UNICODE_UTF_BOM_HI &&
      utf32EncodedBytes[offset + 2] == 0 && utf32EncodedBytes[offset + 3] == 0;
}

typedef Utf32BytesDecoder Utf32BytesDecoderProvider();

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
class IterableUtf32Decoder extends IterableBase<int> {
  final Utf32BytesDecoderProvider codeunitsProvider;

  IterableUtf32Decoder._(this.codeunitsProvider);

  Utf32BytesDecoder get iterator => codeunitsProvider();
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
abstract class Utf32BytesDecoder implements _ListRangeIterator {
  final _ListRangeIterator utf32EncodedBytesIterator;
  final int replacementCodepoint;
  int _current = null;

  Utf32BytesDecoder._fromListRangeIterator(
      this.utf32EncodedBytesIterator, this.replacementCodepoint);

  factory Utf32BytesDecoder(List<int> utf32EncodedBytes, [
      int offset = 0, int length,
      int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
    if (length == null) {
      length = utf32EncodedBytes.length - offset;
    }
    if (hasUtf32beBom(utf32EncodedBytes, offset, length)) {
      return new Utf32beBytesDecoder(utf32EncodedBytes, offset + 4, length - 4,
          false, replacementCodepoint);
    } else if (hasUtf32leBom(utf32EncodedBytes, offset, length)) {
      return new Utf32leBytesDecoder(utf32EncodedBytes, offset + 4, length - 4,
          false, replacementCodepoint);
    } else {
      return new Utf32beBytesDecoder(utf32EncodedBytes, offset, length, false,
          replacementCodepoint);
    }
  }

  List<int> decodeRest() {
    List<int> codeunits = new List<int>(remaining);
    int i = 0;
    while (moveNext()) {
      codeunits[i++] = current;
    }
    return codeunits;
  }

  int get current => _current;

  bool moveNext() {
    _current = null;
    if (utf32EncodedBytesIterator.remaining < 4) {
      utf32EncodedBytesIterator.skip(utf32EncodedBytesIterator.remaining);
      if (replacementCodepoint != null) {
          _current = replacementCodepoint;
          return true;
      } else {
        throw new ArgumentError(
            "Invalid UTF32 at ${utf32EncodedBytesIterator.position}");
      }
    } else {
      int codepoint = decode();
      if (_validCodepoint(codepoint)) {
        _current = codepoint;
        return true;
      } else if (replacementCodepoint != null) {
        _current = replacementCodepoint;
        return true;
      } else {
        throw new ArgumentError(
            "Invalid UTF32 at ${utf32EncodedBytesIterator.position}");
      }
    }
  }

  int get position => utf32EncodedBytesIterator.position ~/ 4;

  void backup([int by = 1]) {
    utf32EncodedBytesIterator.backup(4 * by);
  }

  int get remaining => (utf32EncodedBytesIterator.remaining + 3) ~/ 4;

  void skip([int count = 1]) {
    utf32EncodedBytesIterator.skip(4 * count);
  }

  int decode();
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
class Utf32beBytesDecoder extends Utf32BytesDecoder {
  Utf32beBytesDecoder(List<int> utf32EncodedBytes, [int offset = 0,
      int length, bool stripBom = true,
      int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) :
      super._fromListRangeIterator(
          (new _ListRange(utf32EncodedBytes, offset, length)).iterator,
          replacementCodepoint) {
    if (stripBom && hasUtf32beBom(utf32EncodedBytes, offset, length)) {
      skip();
    }
  }

  int decode() {
    utf32EncodedBytesIterator.moveNext();
    int value = utf32EncodedBytesIterator.current;
    utf32EncodedBytesIterator.moveNext();
    value = (value << 8) + utf32EncodedBytesIterator.current;
    utf32EncodedBytesIterator.moveNext();
    value = (value << 8) + utf32EncodedBytesIterator.current;
    utf32EncodedBytesIterator.moveNext();
    value = (value << 8) + utf32EncodedBytesIterator.current;
    return value;
  }
}

/**
 * *DEPRECATED*: Use `package:utf/utf.dart` or, when applicable, `dart:convert`
 * instead.
 */
@deprecated
class Utf32leBytesDecoder extends Utf32BytesDecoder {
  Utf32leBytesDecoder(List<int> utf32EncodedBytes, [int offset = 0,
      int length, bool stripBom = true,
      int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) :
      super._fromListRangeIterator(
          (new _ListRange(utf32EncodedBytes, offset, length)).iterator,
          replacementCodepoint) {
    if (stripBom && hasUtf32leBom(utf32EncodedBytes, offset, length)) {
      skip();
    }
  }

  int decode() {
    utf32EncodedBytesIterator.moveNext();
    int value = utf32EncodedBytesIterator.current;
    utf32EncodedBytesIterator.moveNext();
    value += (utf32EncodedBytesIterator.current << 8);
    utf32EncodedBytesIterator.moveNext();
    value += (utf32EncodedBytesIterator.current << 16);
    utf32EncodedBytesIterator.moveNext();
    value += (utf32EncodedBytesIterator.current << 24);
    return value;
  }
}

bool _validCodepoint(int codepoint) {
  return (codepoint >= 0 && codepoint < UNICODE_UTF16_RESERVED_LO) ||
      (codepoint > UNICODE_UTF16_RESERVED_HI &&
      codepoint < UNICODE_VALID_RANGE_MAX);
}
