// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart_io;

class _Base64 {
  static const List<String> _encodingTable = const [
      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
      'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd',
      'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's',
      't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7',
      '8', '9', '+', '/'];

  /**
   * Base64 transfer encoding for MIME (RFC 2045)
   */
  static String _encode(List<int> data) {
    List<String> characters = new List<String>();
    int i;
    for (i = 0; i + 3 <= data.length; i += 3) {
      int value = 0;
      value |= data[i + 2];
      value |= data[i + 1] << 8;
      value |= data[i] << 16;
      for (int j = 0; j < 4; j++) {
        int index = (value >> ((3 - j) * 6)) & ((1 << 6) - 1);
        characters.add(_encodingTable[index]);
      }
    }
    // Remainders.
    if (i + 2 == data.length) {
      int value = 0;
      value |= data[i + 1] << 8;
      value |= data[i] << 16;
      for (int j = 0; j < 3; j++) {
        int index = (value >> ((3 - j) * 6)) & ((1 << 6) - 1);
        characters.add(_encodingTable[index]);
      }
      characters.add("=");
    } else if (i + 1 == data.length) {
      int value = 0;
      value |= data[i] << 16;
      for (int j = 0; j < 2; j++) {
        int index = (value >> ((3 - j) * 6)) & ((1 << 6) - 1);
        characters.add(_encodingTable[index]);
      }
      characters.add("=");
      characters.add("=");
    }
    StringBuffer output = new StringBuffer();
    for (i = 0; i < characters.length; i++) {
      if (i > 0 && i % 76 == 0) {
        output.add("\r\n");
      }
      output.add(characters[i]);
    }
    return output.toString();
  }


  /**
   * Base64 transfer decoding for MIME (RFC 2045).
   */
  static List<int> _decode(String data) {
    List<int> result = new List<int>();
    int padCount = 0;
    int charCount = 0;
    int value = 0;
    for (int i = 0; i < data.length; i++) {
      int char = data.charCodeAt(i);
      if (65 <= char && char <= 90) {  // "A" - "Z".
        value = (value << 6) | char - 65;
        charCount++;
      } else if (97 <= char && char <= 122) { // "a" - "z".
        value = (value << 6) | char - 97 + 26;
        charCount++;
      } else if (48 <= char && char <= 57) {  // "0" - "9".
        value = (value << 6) | char - 48 + 52;
        charCount++;
      } else if (char == 43) {  // "+".
        value = (value << 6) | 62;
        charCount++;
      } else if (char == 47) {  // "/".
        value = (value << 6) | 63;
        charCount++;
      } else if (char == 61) {  // "=".
        value = (value << 6);
        charCount++;
        padCount++;
      }
      if (charCount == 4) {
        result.add((value & 0xFF0000) >> 16);
        if (padCount < 2) {
          result.add((value & 0xFF00) >> 8);
        }
        if (padCount == 0) {
          result.add(value & 0xFF);
        }
        charCount = 0;
        value = 0;
      }
    }
    return result;
  }
}
