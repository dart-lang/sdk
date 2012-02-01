// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("unicode_core");

/*
 * Test for presence of bug related to the use of UTF-16 code units for
 * Dart compiled to JS.
 */
bool _test16BitCodeUnit = null;
// TODO is16BitCodeUnit() is used to work around a bug with frog/dartc
// (http://code.google.com/p/dart/issues/detail?id=1357). Consider
// removing after this issue is resolved.
bool is16BitCodeUnit() {
  if (_test16BitCodeUnit == null) {
    _test16BitCodeUnit = (new String.fromCharCodes([0x1D11E])) ==
        (new String.fromCharCodes([0xD11E]));
  }
  return _test16BitCodeUnit;
}

/**
 * Invalid codepoints or encodings may be substituted with the value U+fffd.
 */
final int UNICODE_REPLACEMENT_CHARACTER_CODEPOINT = 0xfffd;
final int UNICODE_BOM = 0xfeff;
final int UNICODE_UTF_BOM_LO = 0xff;
final int UNICODE_UTF_BOM_HI = 0xfe;

final int UNICODE_BYTE_ZERO_MASK = 0xff;
final int UNICODE_BYTE_ONE_MASK = 0xff00;
final int UNICODE_VALID_RANGE_MAX = 0x10ffff;
final int UNICODE_PLANE_ONE_MAX = 0xffff;
final int UNICODE_UTF16_RESERVED_LO = 0xd800;
final int UNICODE_UTF16_RESERVED_HI = 0xdfff;
final int UNICODE_UTF16_OFFSET = 0x10000;
final int UNICODE_UTF16_SURROGATE_UNIT_0_BASE = 0xd800;
final int UNICODE_UTF16_SURROGATE_UNIT_1_BASE = 0xdc00;
final int UNICODE_UTF16_HI_MASK = 0xffc00;
final int UNICODE_UTF16_LO_MASK = 0x3ff;

/**
 * Encode code points as UTF16 code units.
 */
List<int> codepointsToUtf16CodeUnits(
    List<int> codepoints, [int offset = 0, int length,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  if (!(offset >= 0)) {
    throw new IllegalArgumentException("offset");
  }

  if (!(length == null || length >= 0)) {
    throw new IllegalArgumentException("length");
  }

  int end = length != null ?
      Math.min(codepoints.length, offset + length) :
      codepoints.length;

  int encodedLength = 0;
  for (int i = offset; i < end; i++) {
    int value = codepoints[i];
    if ((value >= 0 && value < UNICODE_UTF16_RESERVED_LO) || 
        (value > UNICODE_UTF16_RESERVED_HI && value <= UNICODE_PLANE_ONE_MAX)) {
      encodedLength++;
    } else if (value > UNICODE_PLANE_ONE_MAX && 
        value <= UNICODE_VALID_RANGE_MAX) {
      encodedLength += 2;
    } else {
      encodedLength++;
    }
  }
  
  void addReplacementCodepoint(List<int> codepointBuffer, int offset,
      int replacementCodepoint) {
    if(replacementCodepoint != null) {
      codepointBuffer[offset] = replacementCodepoint;
    } else {
      throw new IllegalArgumentException("Invalid encoding");
    }
  }
  List<int> codeUnitsBuffer = new List<int>(encodedLength);
  int j = 0;
  for (int i = offset; i < end; i++) {
    int value = codepoints[i];
    if ((value >= 0 && value < UNICODE_UTF16_RESERVED_LO) || 
        (value > UNICODE_UTF16_RESERVED_HI && value <= UNICODE_PLANE_ONE_MAX)) {
      codeUnitsBuffer[j++] = value;
    } else if (value > UNICODE_PLANE_ONE_MAX && 
        value <= UNICODE_VALID_RANGE_MAX) {
      int base = value - UNICODE_UTF16_OFFSET;
      codeUnitsBuffer[j++] = UNICODE_UTF16_SURROGATE_UNIT_0_BASE +
          ((base & UNICODE_UTF16_HI_MASK) >> 10);
      codeUnitsBuffer[j++] = UNICODE_UTF16_SURROGATE_UNIT_1_BASE +
          (base & UNICODE_UTF16_LO_MASK);
    } else {
      addReplacementCodepoint(codeUnitsBuffer, j++, replacementCodepoint);
    }
  }
  return codeUnitsBuffer;
}

/**
 * Decodes the utf16 codeunits to codepoints.
 */
List<int> utf16CodeUnitsToCodepoints(
    List<int> utf16CodeUnits, [int offset = 0, int length,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  if (!(offset >= 0)) {
    throw new IllegalArgumentException("offset");
  }

  if (!(length == null || length >= 0)) {
    throw new IllegalArgumentException("length");
  }

  int end = length != null ?
      Math.min(utf16CodeUnits.length, offset + length) :
      utf16CodeUnits.length;

  void addReplacementCodepoint(void f(int v), int replacementCodepoint) {
    if(replacementCodepoint != null) {
      f(replacementCodepoint);
    } else {
      throw new IllegalArgumentException("Invalid encoding");
    }
  }

  void apply(void f(int v)) {
    int i = offset;
    // skip the first entry if it is a BOM.
    if (end > 0 && utf16CodeUnits[0] == UNICODE_BOM) {
      i++;
    }
    while (i < end) {
      int value = utf16CodeUnits[i++];
      if (value < 0) {
        addReplacementCodepoint(f, replacementCodepoint);
        continue;
      }
      if (value < UNICODE_UTF16_RESERVED_LO || 
          (value > UNICODE_UTF16_RESERVED_HI &&
          value <= UNICODE_PLANE_ONE_MAX)) {
        // transfer directly
        f(value);
      } else if (value < UNICODE_UTF16_SURROGATE_UNIT_1_BASE && i < end) {
        // merge surrogate pair
        int nextValue = utf16CodeUnits[i++];
        if (nextValue >= UNICODE_UTF16_SURROGATE_UNIT_1_BASE && 
            nextValue <= UNICODE_UTF16_RESERVED_HI) {
          value = (value - UNICODE_UTF16_SURROGATE_UNIT_0_BASE) << 10;
          value += UNICODE_UTF16_OFFSET +
              (nextValue - UNICODE_UTF16_SURROGATE_UNIT_1_BASE);
          f(value);
        } else {
          if (nextValue >= UNICODE_UTF16_SURROGATE_UNIT_0_BASE &&
             nextValue < UNICODE_UTF16_SURROGATE_UNIT_1_BASE) {
            i--;
          }
          addReplacementCodepoint(f, replacementCodepoint);
          continue;
        }
      } else {
        addReplacementCodepoint(f, replacementCodepoint);
        continue;
      }
    }
  }
  int codepointBufferLength = 0;
  apply(void _(int value) {
      codepointBufferLength++;
  });

  List<int> codepointBuffer = new List<int>(codepointBufferLength);
  int i = 0;
  apply(void _(int value) {
      codepointBuffer[i++] = value;
  });
  return codepointBuffer;
}
