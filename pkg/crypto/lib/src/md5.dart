// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of crypto;

/**
 * MD5 hash function implementation.
 *
 * WARNING: MD5 has known collisions and should only be used when
 * required for backwards compatibility.
 */
class MD5 extends _HashBase {
  MD5() : super(16, 4, false) {
    _h[0] = 0x67452301;
    _h[1] = 0xefcdab89;
    _h[2] = 0x98badcfe;
    _h[3] = 0x10325476;
  }

  // Returns a new instance of this Hash.
  MD5 newInstance() {
    return new MD5();
  }

  static const _k = const [
    0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a,
    0xa8304613, 0xfd469501, 0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
    0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821, 0xf61e2562, 0xc040b340,
    0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
    0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8,
    0x676f02d9, 0x8d2a4c8a, 0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
    0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70, 0x289b7ec6, 0xeaa127fa,
    0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
    0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92,
    0xffeff47d, 0x85845dd1, 0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
    0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391 ];

  static const _r = const [
    7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 5,  9, 14,
    20, 5,  9, 14, 20, 5,  9, 14, 20, 5,  9, 14, 20, 4, 11, 16, 23, 4, 11,
    16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 6, 10, 15, 21, 6, 10, 15, 21, 6,
    10, 15, 21, 6, 10, 15, 21 ];

  // Compute one iteration of the MD5 algorithm with a chunk of
  // 16 32-bit pieces.
  void _updateHash(List<int> m) {
    assert(m.length == 16);

    var a = _h[0];
    var b = _h[1];
    var c = _h[2];
    var d = _h[3];

    var t0;
    var t1;

    for (var i = 0; i < 64; i++) {
      if (i < 16) {
        t0 = (b & c) | ((~b & _MASK_32) & d);
        t1 = i;
      } else if (i < 32) {
        t0 = (d & b) | ((~d & _MASK_32) & c);
        t1 = ((5 * i) + 1) % 16;
      } else if (i < 48) {
        t0 = b ^ c ^ d;
        t1 = ((3 * i) + 5) % 16;
      } else {
        t0 = c ^ (b | (~d & _MASK_32));
        t1 = (7 * i) % 16;
      }

      var temp = d;
      d = c;
      c = b;
      b = _add32(b, _rotl32(_add32(_add32(a, t0),
                                   _add32(_k[i], m[t1])),
                            _r[i]));
      a = temp;
    }

    _h[0] = _add32(a, _h[0]);
    _h[1] = _add32(b, _h[1]);
    _h[2] = _add32(c, _h[2]);
    _h[3] = _add32(d, _h[3]);
  }
}
