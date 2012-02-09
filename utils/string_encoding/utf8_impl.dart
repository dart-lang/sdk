// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final int _UTF8_ONE_BYTE_MAX = 0x7f;
final int _UTF8_TWO_BYTE_MAX = 0x7ff;
final int _UTF8_THREE_BYTE_MAX = 0xffff;

final int _UTF8_LO_SIX_BIT_MASK = 0x3f;

final int _UTF8_FIRST_BYTE_OF_TWO_BASE = 0xc0;
final int _UTF8_FIRST_BYTE_OF_THREE_BASE = 0xe0;
final int _UTF8_FIRST_BYTE_OF_FOUR_BASE = 0xf0;
final int _UTF8_FIRST_BYTE_OF_FIVE_BASE = 0xf8;
final int _UTF8_FIRST_BYTE_OF_SIX_BASE = 0xfc;

final int _UTF8_FIRST_BYTE_OF_TWO_MASK = 0x1f;
final int _UTF8_FIRST_BYTE_OF_THREE_MASK = 0xf;
final int _UTF8_FIRST_BYTE_OF_FOUR_MASK = 0x7;

final int _UTF8_FIRST_BYTE_BOUND_EXCL = 0xfe;
final int _UTF8_SUBSEQUENT_BYTE_BASE = 0x80;

/**
 * Produce a String from a sequence of UTF-8 encoded bytes. The parameters
 * allow an offset into a list of bytes (as int), limiting the length of the
 * values be decoded and the ability of override the default Unicode
 * replacement character. Set the replacementCharacter to null to throw an
 * IllegalArgumentException rather than replace the bad value.
 */
String decodeFromUtf8(List<int> bytes, [int offset = 0, int length,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) =>
    codepointsToString(_utf8ToCodepoints(
        bytes, offset, length, replacementCodepoint));

/**
 * Produce a sequence of UTF-8 encoded bytes from the provided string.
 */
List<int> encodeAsUtf8(String str) =>
  _codepointsToUtf8(stringToCodepoints(str));

int _addToEncoding(int offset, int bytes, int value, List<int> buffer) {
  while(bytes > 0) {
    buffer[offset + bytes] = _UTF8_SUBSEQUENT_BYTE_BASE |
        (value & _UTF8_LO_SIX_BIT_MASK);
    value = value >> 6;
    bytes--;
  }
  return value;
}

/**
 * Encode code points as UTF-8 code units.
 */
List<int> _codepointsToUtf8(
    List<int> codepoints, [int offset = 0, int length]) {
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
    if (value < 0 || value > UNICODE_VALID_RANGE_MAX) {
      encodedLength += 3;
    } else if (value <= _UTF8_ONE_BYTE_MAX) {
      encodedLength++;
    } else if (value <= _UTF8_TWO_BYTE_MAX) {
      encodedLength += 2;
    } else if (value <= _UTF8_THREE_BYTE_MAX) {
      encodedLength += 3;
    } else if (value <= UNICODE_VALID_RANGE_MAX) {
      encodedLength += 4;
    }
  }

  List<int> encoded = new List<int>(encodedLength);
  int insertAt = 0;
  for (int i = offset; i < end; i++) {
    int value = codepoints[i];
    if (value < 0 || value > UNICODE_VALID_RANGE_MAX) {
      encoded.setRange(insertAt, 3, [0xef, 0xbf, 0xbd]);
      insertAt += 3;
    } else if (value <= _UTF8_ONE_BYTE_MAX) {
      encoded[insertAt] = value;
      insertAt++;
    } else if (value <= _UTF8_TWO_BYTE_MAX) {
      encoded[insertAt] = _UTF8_FIRST_BYTE_OF_TWO_BASE | (
          _UTF8_FIRST_BYTE_OF_TWO_MASK &
          _addToEncoding(insertAt, 1, value, encoded));
      insertAt += 2;
    } else if (value <= _UTF8_THREE_BYTE_MAX) {
      encoded[insertAt] = _UTF8_FIRST_BYTE_OF_THREE_BASE | (
          _UTF8_FIRST_BYTE_OF_THREE_MASK &
          _addToEncoding(insertAt, 2, value, encoded));
      insertAt += 3;
    } else if (value <= UNICODE_VALID_RANGE_MAX) {
      encoded[insertAt] = _UTF8_FIRST_BYTE_OF_FOUR_BASE | (
          _UTF8_FIRST_BYTE_OF_FOUR_MASK &
          _addToEncoding(insertAt, 3, value, encoded));
      insertAt += 4;
    }
  }
  return encoded;
}


// Because UTF-8 specifies byte order, we do not have to follow the pattern
// used by UTF-16 & UTF-32 regarding byte order.
List<int> _utf8ToCodepoints(
    List<int> utf8EncodedBytes, [int offset = 0, int length,
    int replacementCodepoint = UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]) {
  if (!(offset >= 0)) {
    throw new IllegalArgumentException("offset");
  }

  if (!(length == null || length >= 0)) {
    throw new IllegalArgumentException("length");
  }

  int end = length != null ?
      Math.min(utf8EncodedBytes.length, offset + length) :
      utf8EncodedBytes.length;

  void decode(void f(int v)) {
    int i = offset;
    while (i < end) {
      int value = utf8EncodedBytes[i++];
      if (value < 0) {
        f(null);
        continue;
      }

      if (value <= _UTF8_ONE_BYTE_MAX) {
        f(value);
      } else if (value < _UTF8_FIRST_BYTE_OF_TWO_BASE) {
        f(null);
        continue;
      } else {
        int additionalBytes = 0;
        if (value < _UTF8_FIRST_BYTE_OF_THREE_BASE) {
          value -= _UTF8_FIRST_BYTE_OF_TWO_BASE;
          additionalBytes = 1;
        } else if (value < _UTF8_FIRST_BYTE_OF_FOUR_BASE) {
          value -= _UTF8_FIRST_BYTE_OF_THREE_BASE;
          additionalBytes = 2;
        } else if (value < _UTF8_FIRST_BYTE_OF_FIVE_BASE) {
          value -= _UTF8_FIRST_BYTE_OF_FOUR_BASE;
          additionalBytes = 3;
        } else if (value < _UTF8_FIRST_BYTE_OF_SIX_BASE) {
          value -= _UTF8_FIRST_BYTE_OF_FIVE_BASE;
          additionalBytes = 4;
        } else if (value < _UTF8_FIRST_BYTE_BOUND_EXCL) {
          value -= _UTF8_FIRST_BYTE_OF_SIX_BASE;
          additionalBytes = 5;
        } else {
          f(null);
          continue;
        }
        int j = 0;
        while (j < additionalBytes && i < end) {
          int nextValue = utf8EncodedBytes[i++];
          if (nextValue > _UTF8_ONE_BYTE_MAX &&
              nextValue < _UTF8_FIRST_BYTE_OF_TWO_BASE) {
            value = (value << 6) | (nextValue & _UTF8_LO_SIX_BIT_MASK);
          } else {
            // if sequence-starting code unit, reposition cursor to start here
            if (nextValue >= _UTF8_FIRST_BYTE_OF_TWO_BASE) {
              i--;
            }
            break;
          }
          j++;
        }
        if (j == additionalBytes && (
            value < UNICODE_UTF16_RESERVED_LO ||
            value > UNICODE_UTF16_RESERVED_HI)) {
          if ((additionalBytes == 1 && value > _UTF8_ONE_BYTE_MAX) ||
              (additionalBytes == 2 && value > _UTF8_TWO_BYTE_MAX) ||
              (additionalBytes == 3 && value > _UTF8_THREE_BYTE_MAX &&
                value <= UNICODE_VALID_RANGE_MAX)) {
            f(value);
          } else {
            f(null);
          }
        } else {
          f(null);
          continue;
        }
      }
    }
  }

  // First pass through data to 1) size the output buffer and 2) check for 
  // special case optimization where A) the length stays the same and B)
  // no special replacement characters are used. If these criteria are met
  // we can just copy input to the output.
  int codepointBufferLength = 0;
  bool hasReplacements = false;
  decode(void _(int value) {
      codepointBufferLength++;
      if (value == null) {
        hasReplacements = true;
      }
  });

  // If the string calls for replacements, but when the method is called
  // with replacementCodepoint explicitly set to null, then throw an exception.
  if (hasReplacements && replacementCodepoint == null) {
    throw new IllegalArgumentException("Invalid encoding");
  }

  int _length = end - offset;
  List<int> codepointBuffer = new List<int>(codepointBufferLength);
  if (_length == codepointBufferLength && !hasReplacements) {
    codepointBuffer.setRange(0, _length, utf8EncodedBytes, offset);
  } else {
    int i = 0;
    decode(
      void _(int value) {
        if (value != null) {
          codepointBuffer[i++] = value;
        } else {
          codepointBuffer[i++] = replacementCodepoint;
        }
      }
    );
  }
  return codepointBuffer;
}
