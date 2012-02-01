// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("utf16");
#import("unicode_core.dart");
#import("unicode.dart");

/**
 * Produce a String from a sequence of UTF-16 encoded bytes. The parameters
 * allow an offset into a list of bytes (as int), limiting the length of the
 * values be decoded and the ability of override the default Unicode
 * replacement character. Set the replacementCharacter to null to throw an
 * IllegalArgumentException rather than replace the bad value.
 */
String decodeFromUtf16(List<int> bytes, [int offset = 0, int length,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  List<int> codeUnits =
      _utf16ToUtf16CodeUnits(bytes, offset, length);
  // TODO is16BitCodeUnit() is used to work around a bug with frog/dartc
  // (http://code.google.com/p/dart/issues/detail?id=1357). Consider
  // removing after this issue is resolved.
  if (is16BitCodeUnit()) {
    return new String.fromCharCodes(codeUnits);
  } else {
    return new String.fromCharCodes(
        utf16CodeUnitsToCodepoints(codeUnits, 0, null, replacementCodepoint));
  }
}

/**
 * Produce a String from a sequence of UTF-16BE encoded bytes. The parameters
 * allow an offset into a list of bytes (as int), limiting the length of the
 * values be decoded and the ability of override the default Unicode
 * replacement character. Set the replacementCharacter to null to throw an
 * IllegalArgumentException rather than replace the bad value.
 */
String decodeFromUtf16be(List<int> bytes, [int offset = 0, int length,
    bool stripBom = true,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  List<int> codeUnits =
      _utf16beToUtf16CodeUnits(bytes, offset, length, stripBom);
  // TODO is16BitCodeUnit() is used to work around a bug with frog/dartc
  // (http://code.google.com/p/dart/issues/detail?id=1357). Consider
  // removing after this issue is resolved.
  if (is16BitCodeUnit()) {
    return new String.fromCharCodes(codeUnits);
  } else {
    return new String.fromCharCodes(
        utf16CodeUnitsToCodepoints(codeUnits, 0, null, replacementCodepoint));
  }
}

/**
 * Produce a String from a sequence of UTF-16LE encoded bytes. The parameters
 * allow an offset into a list of bytes (as int), limiting the length of the
 * values be decoded and the ability of override the default Unicode
 * replacement character. Set the replacementCharacter to null to throw an
 * IllegalArgumentException rather than replace the bad value.
 */
String decodeFromUtf16le(List<int> bytes, [int offset = 0, int length,
    bool stripBom = true,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  List<int> codeUnits =
      _utf16leToUtf16CodeUnits(bytes, offset, length, stripBom);
  // TODO is16BitCodeUnit() is used to work around a bug with frog/dartc
  // (http://code.google.com/p/dart/issues/detail?id=1357). Consider
  // removing after this issue is resolved.
  if (is16BitCodeUnit()) {
    return new String.fromCharCodes(codeUnits);
  } else {
    return new String.fromCharCodes(
        utf16CodeUnitsToCodepoints(codeUnits, 0, null, replacementCodepoint));
  }
}

/**
 * Produce a sequence of UTF-16 encoded bytes.
 */
List<int> encodeAsUtf16(String str) =>
    encodeAsUtf16be(str, true);

/**
 * Produce a sequence of UTF-16BE encoded bytes.
 */
List<int> encodeAsUtf16be(String str, [bool writeBOM = false]) {
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
 * Produce a sequence of UTF-16LE encoded bytes.
 */
List<int> encodeAsUtf16le(String str, [bool writeBOM = false]) {
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

bool hasUtf16Bom(List<int> utf32EncodedBytes, [int offset = 0, int length]) {
  return hasUtf16beBom(utf32EncodedBytes, offset, length) ||
      hasUtf16leBom(utf32EncodedBytes, offset, length);
}

bool hasUtf16beBom(List<int> utf16EncodedBytes, [int offset = 0, int length]) {
  if (!(offset >= 0)) {
    throw new IllegalArgumentException("offset");
  }

  if (!(length == null || length >= 0)) {
    throw new IllegalArgumentException("length");
  }

  int end = length != null ?
      Math.min(utf16EncodedBytes.length, offset + length) :
      utf16EncodedBytes.length;

  return (offset + 2) <= end &&
      utf16EncodedBytes[offset] == UNICODE_UTF_BOM_HI &&
      utf16EncodedBytes[offset + 1] == UNICODE_UTF_BOM_LO;
}

bool hasUtf16leBom(List<int> utf16EncodedBytes, [int offset = 0, int length]) {
  if (!(offset >= 0)) {
    throw new IllegalArgumentException("offset");
  }

  if (!(length == null || length >= 0)) {
    throw new IllegalArgumentException("length");
  }

  int end = length != null ?
      Math.min(utf16EncodedBytes.length, offset + length) :
      utf16EncodedBytes.length;

  return (offset + 2) <= end &&
      utf16EncodedBytes[offset] == UNICODE_UTF_BOM_LO &&
      utf16EncodedBytes[offset + 1] == UNICODE_UTF_BOM_HI;
}

int _sizeCodeUnits(int utf16CodeUnitsLength) {
  int v = ((utf16CodeUnitsLength)/2).floor().toInt();
  return v;
}

List<int> _stringToUtf16CodeUnits(String str) {
  // TODO is16BitCodeUnit() is used to work around a bug with frog/dartc
  // (http://code.google.com/p/dart/issues/detail?id=1357). Consider
  // removing after this issue is resolved.
  if (is16BitCodeUnit()) {
    return str.charCodes();
  } else {
    return codepointsToUtf16CodeUnits(str.charCodes());
  }
}

/**
 * Convert UTF-16BE encoded bytes to utf16 code units by grouping 1-2 bytes
 * to produce the code unit (0-(2^16)-1).
 */
List<int> _utf16beToUtf16CodeUnits(
    List<int> utf16beEncodedBytes, [int offset = 0, int length,
    bool stripBom = true]) {
  if (!(offset >= 0)) {
    throw new IllegalArgumentException("offset");
  }

  if (!(length == null || length >= 0)) {
    throw new IllegalArgumentException("length");
  }

  int end = length != null ?
      Math.min(utf16beEncodedBytes.length, offset + length) :
      utf16beEncodedBytes.length;

  int i = (stripBom && hasUtf16beBom(utf16beEncodedBytes, offset, length)) ?
      offset + 2 : offset;
  List<int> codeUnits =
      new List<int>(_sizeCodeUnits(end - i));
  int lastIndex = end - 1;
  int j = 0;
  while (i < lastIndex) {
    int hi = utf16beEncodedBytes[i++];
    int lo = utf16beEncodedBytes[i++];
    codeUnits[j++] = (hi << 8) | lo;
  }
  return codeUnits;
}

/**
 * Convert UTF-16LE encoded bytes to utf16 code units by grouping 1-2 bytes
 * to produce the code unit (0-(2^16)-1).
 */
List<int> _utf16leToUtf16CodeUnits(
    List<int> utf16leEncodedBytes, [int offset = 0, int length,
    bool stripBom = true]) {
  if (!(offset >= 0)) {
    throw new IllegalArgumentException("offset");
  }

  if (!(length == null || length >= 0)) {
    throw new IllegalArgumentException("length");
  }

  int end = length != null ?
      Math.min(utf16leEncodedBytes.length, offset + length) :
      utf16leEncodedBytes.length;

  int i = (stripBom && hasUtf16leBom(utf16leEncodedBytes, offset, length)) ?
      offset + 2 : offset;
  List<int> codeUnits =
      new List<int>(_sizeCodeUnits(end - i));
  int lastIndex = end - 1;
  int j = 0;
  while (i < lastIndex) {
    int lo = utf16leEncodedBytes[i++];
    int hi = utf16leEncodedBytes[i++];
    codeUnits[j] = (hi << 8) | lo;
  }
  return codeUnits;
}

/**
 * Convert UTF-16 encoded bytes to utf16 code units by grouping 1-2 bytes
 * to produce the code unit (0-(2^16)-1). Relies on BOM to determine
 * endian-ness, and defaults to BE.
 */
List<int> _utf16ToUtf16CodeUnits(
    List<int> utf16EncodedBytes, [int offset = 0, int length]) {
  if (!(offset >= 0)) {
    throw new IllegalArgumentException("offset");
  }

  if (!(length == null || length >= 0)) {
    throw new IllegalArgumentException("length");
  }

  int end = length != null ?
      Math.min(utf16EncodedBytes.length, offset + length) :
      utf16EncodedBytes.length;

  if (hasUtf16beBom(utf16EncodedBytes, offset, length)) {
    return _utf16beToUtf16CodeUnits(utf16EncodedBytes, offset + 2,
        end - (offset + 2), false);
  } else if (hasUtf16leBom(utf16EncodedBytes, offset, length)) {
    return _utf16leToUtf16CodeUnits(utf16EncodedBytes, offset + 2,
        end - (offset + 2), false);
  } else {
    return _utf16beToUtf16CodeUnits(
        utf16EncodedBytes, offset, end - offset, false);
  }
}
