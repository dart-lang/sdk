// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('utf8');

class Utf8Decoder implements Iterable<int>, Iterator<int> {
  final List<int> bytes;
  int offset;
  final int end;

  Utf8Decoder(List<int> this.bytes, int offset, int length)
      : this.offset = offset, end = offset + length;

  /** Decode the remaininder of the characters in this decoder
    * into a [List<int>].
    */
  List<int> decodeRest() {
    List<int> result = <int>[];
    for (int char in this) result.add(char);
    return result;
  }

  Iterator<int> iterator() => this;

  bool hasNext() => offset < end;

  int next() {
    assert(hasNext());
    int byte = bytes[offset++];
    if (byte < 0x80) {
      return byte;
    }
    if (byte < 0xC2) {
      throw new Exception('Cannot decode UTF-8 @ $offset');
    }
    if (byte < 0xE0) {
      int char = (byte & 0x1F) << 6;
      char += decodeTrailing(bytes[offset++]);
      if (char < 0x80) {
        throw new Exception('Cannot decode UTF-8 @ ${offset-1}');
      }
      return char;
    }
    if (byte < 0xF0) {
      int char = (byte & 0x0F) << 6;
      char += decodeTrailing(bytes[offset++]);
      char <<= 6;
      char += decodeTrailing(bytes[offset++]);
      if (char < 0x800 || (0xD800 <= char && char <= 0xDFFF)) {
        throw new Exception('Cannot decode UTF-8 @ ${offset-2}');
      }
      return char;
    }
    if (byte < 0xF8) {
      int char = (byte & 0x07) << 6;
      char += decodeTrailing(bytes[offset++]);
      char <<= 6;
      char += decodeTrailing(bytes[offset++]);
      char <<= 6;
      char += decodeTrailing(bytes[offset++]);
      if (char < 0x10000) {
        throw new Exception('Cannot decode UTF-8 @ ${offset-3}');
      }
      return char;
    }
    throw new Exception('Cannot decode UTF-8 @ ${offset}');
  }

  static int decodeTrailing(int byte) {
    if (byte < 0x80 || 0xBF < byte) {
      throw new Exception('Cannot decode UTF-8 $byte');
    } else {
      return byte & 0x3F;
    }
  }

  static List<int> decodeUtf8(List<int> bytes) {
    return new Utf8Decoder(bytes, 0, bytes.length).decodeRest();
  }
}
