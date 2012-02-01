// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("utf32");
#import("unicode_core.dart");
#import("unicode.dart");

/**
 * Produce a String from a sequence of UTF-32 encoded bytes. The parameters
 * allow an offset into a list of bytes (as int), limiting the length of the
 * values be decoded and the ability of override the default Unicode
 * replacement character. Set the replacementCharacter to null to throw an
 * IllegalArgumentException rather than replace the bad value.
 */
String decodeFromUtf32(List<int> bytes, [int offset = 0, int length,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) =>
    codepointsToString(_utf32ToCodePoints(bytes, offset, length,
        replacementCodepoint));

/**
 * Produce a String from a sequence of UTF-32BE encoded bytes. The parameters
 * allow an offset into a list of bytes (as int), limiting the length of the
 * values be decoded and the ability of override the default Unicode
 * replacement character. Set the replacementCharacter to null to throw an
 * IllegalArgumentException rather than replace the bad value.
 */
String decodeFromUtf32be(
    List<int> bytes, [int offset = 0, int length, bool stripBom = true,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) =>
    codepointsToString(_utf32beToCodePoints(bytes, offset, length, stripBom,
        replacementCodepoint));

/**
 * Produce a String from a sequence of UTF-32LE encoded bytes. The parameters
 * allow an offset into a list of bytes (as int), limiting the length of the
 * values be decoded and the ability of override the default Unicode
 * replacement character. Set the replacementCharacter to null to throw an
 * IllegalArgumentException rather than replace the bad value.
 */
String decodeFromUtf32le(
    List<int> bytes, [int offset = 0, int length, bool stripBom = true,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) =>
    codepointsToString(_utf32leToCodePoints(bytes, offset, length, stripBom,
        replacementCodepoint));

/**
 * Produce a sequence of UTF-32 encoded bytes.
 */
List<int> encodeAsUtf32(String str) =>
    encodeAsUtf32be(str, true);

/**
 * Produce a sequence of UTF-32BE encoded bytes.
 */
List<int> encodeAsUtf32be(String str, [bool writeBOM = false]) {
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
 * Produce a sequence of UTF-32LE encoded bytes.
 */
List<int> encodeAsUtf32le(String str, [bool writeBOM = false]) {
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

bool hasUtf32Bom(
    List<int> utf32EncodedBytes, [int offset = 0, int length]) {
  return hasUtf32beBom(utf32EncodedBytes, offset, length) ||
      hasUtf32leBom(utf32EncodedBytes, offset, length);
}

bool hasUtf32beBom(List<int> utf32EncodedBytes, [int offset = 0, int length]) {
  if (!(offset >= 0)) {
    throw new IllegalArgumentException("offset");
  }

  if (!(length == null || length >= 0)) {
    throw new IllegalArgumentException("length");
  }

  int end = length != null ?
      Math.min(utf32EncodedBytes.length, offset + length) :
      utf32EncodedBytes.length;

  return (offset + 4) <= end &&
      utf32EncodedBytes[offset] == 0 &&
      utf32EncodedBytes[offset + 1] == 0 &&
      utf32EncodedBytes[offset + 2] == UNICODE_UTF_BOM_HI &&
      utf32EncodedBytes[offset + 3] == UNICODE_UTF_BOM_LO;
}

bool hasUtf32leBom(List<int> utf32EncodedBytes, [int offset = 0, int length]) {
  if (!(offset >= 0)) {
    throw new IllegalArgumentException("offset");
  }

  if (!(length == null || length >= 0)) {
    throw new IllegalArgumentException("length");
  }

  int end = length != null ?
      Math.min(utf32EncodedBytes.length, offset + length) :
      utf32EncodedBytes.length;

  return (offset + 4) <= end &&
      utf32EncodedBytes[offset] == UNICODE_UTF_BOM_LO &&
      utf32EncodedBytes[offset + 1] == UNICODE_UTF_BOM_HI &&
      utf32EncodedBytes[offset + 2] == 0 &&
      utf32EncodedBytes[offset + 3] == 0;
}

void _addReplacementCodepoint(List<int> codepointBuffer, int offset,
    int replacementCodepoint) {
  if(replacementCodepoint != null) {
    codepointBuffer[offset] = replacementCodepoint;
  } else {
    throw new IllegalArgumentException("Invalid encoding");
  }
}

int _sizeCodepoints(int utf32BytesLength) =>
    ((utf32BytesLength)/4).ceil().toInt();

/**
 * Joins groups of 4 bytes (0-255) UTF-32BE to produce single code points.
 */
List<int> _utf32beToCodePoints(
    List<int> utf32beEncodedBytes, [int offset = 0, int length,
    bool stripBom = true,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  if (!(offset >= 0)) {
    throw new IllegalArgumentException("offset");
  }

  if (!(length == null || length >= 0)) {
    throw new IllegalArgumentException("length");
  }

  int end = length != null ?
      Math.min(utf32beEncodedBytes.length, offset + length) :
      utf32beEncodedBytes.length;

  int i = (stripBom && hasUtf32beBom(utf32beEncodedBytes, offset, length)) ?
      offset + 4 : offset;
  int lastIndex = end - 3;
  List<int> codepoints = new List<int>(_sizeCodepoints(end - i));
  int j = 0;
  while (i < lastIndex) {
    int value = utf32beEncodedBytes[i++];
    value = (value << 8) + utf32beEncodedBytes[i++];
    value = (value << 8) + utf32beEncodedBytes[i++];
    value = (value << 8) + utf32beEncodedBytes[i++];
    if (_validCodepoint(value)) {
      codepoints[j++] = value;
    } else {
      _addReplacementCodepoint(codepoints, j++, replacementCodepoint);
    }
  }
  while (j < codepoints.length) {
    _addReplacementCodepoint(codepoints, j++, replacementCodepoint);
  }
  return codepoints;
}

/**
 * Joins groups of 4 bytes (0-255) UTF-32LE to produce single code points.
 */
List<int> _utf32leToCodePoints(
    List<int> utf32leEncodedBytes, [int offset = 0, int length,
    bool stripBom = true,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  if (!(offset >= 0)) {
    throw new IllegalArgumentException("offset");
  }

  if (!(length == null || length >= 0)) {
    throw new IllegalArgumentException("length");
  }

  int end = length != null ?
      Math.min(utf32leEncodedBytes.length, offset + length) :
      utf32leEncodedBytes.length;

  int i = (stripBom && hasUtf32leBom(utf32leEncodedBytes, offset, length)) ?
      offset + 4 : offset;
  int lastIndex = end - 3;
  List<int> codepoints = new List<int>(_sizeCodepoints(end - i));
  int j = 0;
  while (i < lastIndex) {
    int value = utf32leEncodedBytes[i+3];
    value = (value << 8) + utf32leEncodedBytes[i+2];
    value = (value << 8) + utf32leEncodedBytes[i+1];
    value = (value << 8) + utf32leEncodedBytes[i];
    i += 4;
    if (_validCodepoint(value)) {
      codepoints[j++] = value;
    } else {
      _addReplacementCodepoint(codepoints, j++, replacementCodepoint);
    }
  }
  while (j < codepoints.length) {
    _addReplacementCodepoint(codepoints, j++, replacementCodepoint);
  }
  return codepoints;
}

/**
 * Joins groups of 4 bytes (0-255) UTF-32 to produce single code points.
 */
List<int> _utf32ToCodePoints(List<int> utf32EncodedBytes, [int offset = 0,
    int length,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  if (!(offset >= 0)) {
    throw new IllegalArgumentException("offset");
  }

  if (!(length == null || length >= 0)) {
    throw new IllegalArgumentException("length");
  }

  int end = length != null ?
      Math.min(utf32EncodedBytes.length, offset + length) :
      utf32EncodedBytes.length;

  if (hasUtf32beBom(utf32EncodedBytes, offset, length)) {
    return _utf32beToCodePoints(utf32EncodedBytes, offset + 4,
        end - (offset + 4), false);
  } else if (hasUtf32leBom(utf32EncodedBytes, offset, length)) {
    return _utf32leToCodePoints(utf32EncodedBytes, offset + 4,
        end - (offset + 4), false);
  } else {
    return _utf32beToCodePoints(utf32EncodedBytes, offset, end - offset);
  }
}

bool _validCodepoint(int codepoint) {
  return (codepoint >= 0 && codepoint < UNICODE_UTF16_RESERVED_LO) ||
      (codepoint > UNICODE_UTF16_RESERVED_HI &&
      codepoint < UNICODE_VALID_RANGE_MAX);
}
