// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of crypto;

abstract class _CryptoUtils {
  static String bytesToHex(List<int> bytes) {
    var result = new StringBuffer();
    for (var part in bytes) {
      result.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
    }
    return result.toString();
  }

  static const int PAD = 61; // '='
  static const int CR = 13;  // '\r'
  static const int LF = 10;  // '\n'
  static const int LINE_LENGTH = 76;

  static const String _encodeTable =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  static const String _encodeTableUrlSafe =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

  // Lookup table used for finding Base 64 alphabet index of a given byte.
  // -2 : Outside Base 64 alphabet.
  // -1 : '\r' or '\n'
  //  0 : = (Padding character).
  // >0 : Base 64 alphabet index of given byte.
  static const List<int> _decodeTable =
      const [ -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -2, -2, -1, -2, -2,
              -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
              -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 62, -2, 62, -2, 63,
              52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -2, -2, -2,  0, -2, -2,
              -2,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14,
              15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -2, -2, -2, -2, 63,
              -2, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
              41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -2, -2, -2, -2, -2,
              -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
              -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
              -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
              -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
              -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
              -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
              -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
              -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2 ];

  static String bytesToBase64(List<int> bytes,
                              [bool urlSafe = false,
                               bool addLineSeparator = false]) {
    int len = bytes.length;
    if (len == 0) {
      return "";
    }
    final String lookup = urlSafe ? _encodeTableUrlSafe : _encodeTable;
    // Size of 24 bit chunks.
    final int remainderLength = len.remainder(3);
    final int chunkLength = len - remainderLength;
    // Size of base output.
    int outputLen = ((len ~/ 3) * 4) + ((remainderLength > 0) ? 4 : 0);
    // Add extra for line separators.
    if (addLineSeparator) {
      outputLen += ((outputLen - 1) ~/ LINE_LENGTH) << 1;
    }
    List<int> out = new List<int>(outputLen);

    // Encode 24 bit chunks.
    int j = 0, i = 0, c = 0;
    while (i < chunkLength) {
      int x = ((bytes[i++] << 16) & 0xFFFFFF) |
              ((bytes[i++] << 8) & 0xFFFFFF) |
                bytes[i++];
      out[j++] = lookup.codeUnitAt(x >> 18);
      out[j++] = lookup.codeUnitAt((x >> 12) & 0x3F);
      out[j++] = lookup.codeUnitAt((x >> 6)  & 0x3F);
      out[j++] = lookup.codeUnitAt(x & 0x3f);
      // Add optional line separator for each 76 char output.
      if (addLineSeparator && ++c == 19 && j < outputLen - 2) {
          out[j++] = CR;
          out[j++] = LF;
          c = 0;
      }
    }

    // If input length if not a multiple of 3, encode remaining bytes and
    // add padding.
    if (remainderLength == 1) {
      int x = bytes[i];
      out[j++] = lookup.codeUnitAt(x >> 2);
      out[j++] = lookup.codeUnitAt((x << 4) & 0x3F);
      out[j++] = PAD;
      out[j++] = PAD;
    } else if (remainderLength == 2) {
      int x = bytes[i];
      int y = bytes[i + 1];
      out[j++] = lookup.codeUnitAt(x >> 2);
      out[j++] = lookup.codeUnitAt(((x << 4) | (y >> 4)) & 0x3F);
      out[j++] = lookup.codeUnitAt((y << 2) & 0x3F);
      out[j++] = PAD;
    }

    return new String.fromCharCodes(out);
  }

  static List<int> base64StringToBytes(String input) {
    int len = input.length;
    if (len == 0) {
      return new List<int>(0);
    }

    // Count '\r', '\n' and illegal characters, For illegal characters,
    // throw an exception.
    int extrasLen = 0;
    for (int i = 0; i < len; i++) {
      int c = _decodeTable[input.codeUnitAt(i)];
      if (c < 0) {
        extrasLen++;
        if(c == -2) {
          throw new FormatException('Invalid character: ${input[i]}');
        }
      }
    }

    if ((len - extrasLen) % 4 != 0) {
      throw new FormatException('''Size of Base 64 characters in Input
          must be a multiple of 4. Input: $input''');
    }

    // Count pad characters.
    int padLength = 0;
    for (int i = len - 1; i >= 0; i--) {
      int currentCodeUnit = input.codeUnitAt(i);
      if (_decodeTable[currentCodeUnit] > 0) break;
      if (currentCodeUnit == PAD) padLength++;
    }
    int outputLen = (((len - extrasLen) * 6) >> 3) - padLength;
    List<int> out = new List<int>(outputLen);

    for (int i = 0, o = 0; o < outputLen;) {
      // Accumulate 4 valid 6 bit Base 64 characters into an int.
      int x = 0;
      for (int j = 4; j > 0;) {
        int c = _decodeTable[input.codeUnitAt(i++)];
        if (c >= 0) {
          x = ((x << 6) & 0xFFFFFF) | c;
          j--;
        }
      }
      out[o++] = x >> 16;
      if (o < outputLen) {
        out[o++] = (x >> 8) & 0xFF;
        if (o < outputLen) out[o++] = x & 0xFF;
      }
    }
    return out;
  }

}
