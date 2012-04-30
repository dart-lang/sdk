// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class _Sha1 {
  static List<int> _bytesToWords(List<int> bytes) {
    int blocks = (((bytes.length + 1) * 8 + 64) + 511) ~/ 512;
    List<int> words = new List<int>(blocks * 64 ~/ 4);
    for (int i = 0; i < words.length; i++) words[i] = 0;
    for (int i = 0, b = 0; i < bytes.length; i++, b += 8) {
      words[b >> 5] |= (bytes[i] & 0xFF) << (24 - b % 32);
    }
    return words;
  }

  /**
   * Calculate SHA-1 hash from binary data. Based on pseudocode from
   * http://en.wikipedia.org/wiki/SHA-1.
   */
  static List<int> _hash(List<int> data) {
    List<int> m = _bytesToWords(data);
    int l = data.length * 8;

    // Initialize variables.
    int h0 = 0x67452301;
    int h1 = 0xEFCDAB89;
    int h2 = 0x98BADCFE;
    int h3 = 0x10325476;
    int h4 = 0xC3D2E1F0;

    // Pre-processing.
    m[l >> 5] |= 0x80 << (24 - l % 32);  // Append 0x80.
    m[((l + 64 >> 9) << 4) + 15] = l;  // Set length at the end.

    List<int> w = new List<int>(80);
    for (int chunk = 0; chunk < m.length; chunk += 16) {
      // Extend the sixteen 32-bit words into eighty 32-bit words
      for (int i = 0; i < 80; i++) {
        if (i < 16) {
          w[i] = m[chunk + i];
        } else {
          int n = w[i - 3] ^ w[i - 8] ^ w[i - 14] ^ w[i - 16];
          w[i] = ((n << 1) | (n >> 31)) & 0xFFFFFFFF;
        }
      }

      // Initialize hash value for this chunk.
      int a = h0;
      int b = h1;
      int c = h2;
      int d = h3;
      int e = h4;

      // Main loop.
      for (int i = 0; i < 80; i++) {
        int f;
        int k;
        if (i < 20) {
          f = b & c | ~b & d;
          k = 0x5A827999;
        } else if (i < 40) {
          f = b ^ c ^ d;
          k = 0x6ED9EBA1;
        } else if (i < 60) {
          f = b & c | b & d | c & d;
          k = 0x8F1BBCDC;
        } else {
          f = b ^ c ^ d;
          k = 0xCA62C1D6;
        }

        int temp = (((a << 5) | (a >> 27)) + f + e + k + w[i]) & 0xFFFFFFFF;
        e = d;
        d = c;
        c = ((b << 30) | (b >> 2)) & 0xFFFFFFFF;
        b = a;
        a = temp;
      }

      // Add this chunk's hash to result so far.
      h0 = (h0 + a) & 0xFFFFFFFF;
      h1 = (h1 + b) & 0xFFFFFFFF;
      h2 = (h2 + c) & 0xFFFFFFFF;
      h3 = (h3 + d) & 0xFFFFFFFF;
      h4 = (h4 + e) & 0xFFFFFFFF;
    }

    // Finally return the hash as an array of bytes.
    void intToBigEndianBytes(int value, List<int> bytes, int offset) {
      bytes[offset] = (value >> 24) & 0xFF;
      bytes[offset + 1] = (value >> 16) & 0xFF;
      bytes[offset + 2] = (value >> 8) & 0xFF;
      bytes[offset + 3] = value & 0xFF;
    }

    List<int> result = new List<int>(20);
    intToBigEndianBytes(h0, result, 0);
    intToBigEndianBytes(h1, result, 4);
    intToBigEndianBytes(h2, result, 8);
    intToBigEndianBytes(h3, result, 12);
    intToBigEndianBytes(h4, result, 16);
    return result;
  }
}
