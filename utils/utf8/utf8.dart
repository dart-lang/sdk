// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('utf8');

class Utf8Decoder {
  final List<int> bytes;
  final int offset;
  final int length;

  Utf8Decoder(List<int> this.bytes, int this.offset, int this.length);

  String toString() {
    return new String.fromCharCodes(decodeUtf8(bytes.getRange(offset, length)));
  }

  static int decodeTrailing(int byte) {
    if (byte < 0x80 || 0xBF < byte) {
      throw new Exception('Cannot decode UTF-8 $byte');
    } else {
      return byte & 0x3F;
    }
  }

  static List<int> decodeUtf8(List<int> bytes) {
    List<int> result = new List<int>();
    for (int i = 0; i < bytes.length; i++) {
      if (bytes[i] < 0x80) {
        result.add(bytes[i]);
      } else if (bytes[i] < 0xC2) {
        throw new Exception('Cannot decode UTF-8 @ $i');
      } else if (bytes[i] < 0xE0) {
        int char = (bytes[i++] & 0x1F) << 6;
        char += decodeTrailing(bytes[i]);
        if (char < 0x80) {
          throw new Exception('Cannot decode UTF-8 @ ${i-1}');
        } else {
          result.add(char);
        }
      } else if (bytes[i] < 0xF0) {
        int char = (bytes[i++] & 0x0F) << 6;
        char += decodeTrailing(bytes[i++]);
        char <<= 6;
        char += decodeTrailing(bytes[i]);
        if (char < 0x800 || (0xD800 <= char && char <= 0xDFFF)) {
          throw new Exception('Cannot decode UTF-8 @ ${i-2}');
        } else {
          result.add(char);
        }
      } else if (bytes[i] < 0xF8) {
        int char = (bytes[i++] & 0x07) << 6;
        char += decodeTrailing(bytes[i++]);
        char <<= 6;
        char += decodeTrailing(bytes[i++]);
        char <<= 6;
        char += decodeTrailing(bytes[i]);
        if (char < 0x10000) {
          throw new Exception('Cannot decode UTF-8 @ ${i-3}');
        } else {
          result.add(char);
        }
      } else {
        throw new Exception('Cannot decode UTF-8 @ $i');
      }
    }
    return result;
  }
}
