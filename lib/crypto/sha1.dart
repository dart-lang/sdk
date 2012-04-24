// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class SHA1 {
  static List<int> digest(List<int> input,
                          [int offset = 0,
                           int len = null]) {
    var input_len = input.length;
    if ((offset < 0) || (offset > input_len)) {
      throw new IllegalArgumentException("Invalid offset ($offset).");
    }
    if (len == null) {
      len = input_len - offset;
    }
    if ((len < 0) || ((offset + len) > input_len)) {
      throw new IllegalArgumentException("Invalid length ($len) for "
          "offset ($offset) and input length (input_len).");
    }

    // Round up to 512 bit size.
    var m_len = _roundUp((len * _BITS_PER_BYTE) + 65, _BITS_PER_CHUNK);
    m_len = m_len ~/ _BITS_PER_WORD;
    var m = new List<int>(m_len);

    _bytesToWords(input, offset, len, m, 0, m_len);

    var l = len * 8;
    var w = new List<int>(80);
    var H0 = 0x67452301;
    var H1 = 0xEFCDAB89;
    var H2 = 0x98BADCFE;
    var H3 = 0x10325476;
    var H4 = 0xC3D2E1F0;

    // TODO(iposva): Deal with lengths longer than 32-bits once arrays can
    // grow to this size.
    m[l >> 5] |= 0x80 << (24 - l % 32);
    m[(((l + 64) >> 9) << 4) + 15] = l;

    for (var i = 0; i < m_len; i += 16) {
      var a = H0;
      var b = H1;
      var c = H2;
      var d = H3;
      var e = H4;

      for (var j = 0; j < 80; j++) {
        if (j < 16) {
          w[j] = m[i + j];
        } else {
          var n = w[j - 3] ^ w[j - 8] ^ w[j - 14] ^ w[j - 16];
          w[j] = _rotl32(n, 1);
        }

        var t = _rotl32(a, 5) + e + w[j];
        if (j < 20) {
          t += (((b & c) | (~b & d)) + 0x5A827999);
        } else if (j < 40) {
          t += ((b ^ c ^ d) + 0x6ED9EBA1);
        } else if (j < 60) {
          t += (((b & c) | (b & d) | (c & d)) + 0x8F1BBCDC);
        } else {
          t += ((b ^ c ^ d) + 0xCA62C1D6);
        }

        e = d;
        d = c;
        c = _rotl32(b, 30);
        b = a;
        a = t & _MASK_32;
      }
      H0 = _add32(H0, a);
      H1 = _add32(H1, b);
      H2 = _add32(H2, c);
      H3 = _add32(H3, d);
      H4 = _add32(H4, e);
    }
    return _wordsToBytes([H0, H1, H2, H3, H4]);
  }

  static final int _BITS_PER_CHUNK = 512;
}

