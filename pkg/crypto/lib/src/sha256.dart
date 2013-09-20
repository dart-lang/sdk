// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of crypto;

/**
 * SHA256 hash function implementation.
 */
class SHA256 extends _HashBase {
  // Construct a SHA256 hasher object.
  SHA256() : _w = new List(64), super(16, 8, true) {
    // Initial value of the hash parts. First 32 bits of the fractional parts
    // of the square roots of the first 8 prime numbers.
    _h[0] = 0x6a09e667;
    _h[1] = 0xbb67ae85;
    _h[2] = 0x3c6ef372;
    _h[3] = 0xa54ff53a;
    _h[4] = 0x510e527f;
    _h[5] = 0x9b05688c;
    _h[6] = 0x1f83d9ab;
    _h[7] = 0x5be0cd19;
  }

  // Returns a new instance of this Hash.
  SHA256 newInstance() {
    return new SHA256();
  }

  // Table of round constants. First 32 bits of the fractional
  // parts of the cube roots of the first 64 prime numbers.
  static const List<int> _K =
      const [ 0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b,
              0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01,
              0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7,
              0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
              0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152,
              0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
              0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc,
              0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
              0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819,
              0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116, 0x1e376c08,
              0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f,
              0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
              0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2 ];

  // Helper functions as defined in http://tools.ietf.org/html/rfc6234
  _rotr32(n, x) => (x >> n) | ((x << (32 - n)) & _MASK_32);
  _ch(x, y, z) => (x & y) ^ ((~x & _MASK_32) & z);
  _maj(x, y, z) => (x & y) ^ (x & z) ^ (y & z);
  _bsig0(x) => _rotr32(2, x) ^ _rotr32(13, x) ^ _rotr32(22, x);
  _bsig1(x) => _rotr32(6, x) ^ _rotr32(11, x) ^ _rotr32(25, x);
  _ssig0(x) => _rotr32(7, x) ^ _rotr32(18, x) ^ (x >> 3);
  _ssig1(x) => _rotr32(17, x) ^ _rotr32(19, x) ^ (x >> 10);

  // Compute one iteration of the SHA256 algorithm with a chunk of
  // 16 32-bit pieces.
  void _updateHash(List<int> M) {
    assert(M.length == 16);

    // Prepare message schedule.
    var i = 0;
    for (; i < 16; i++) {
      _w[i] = M[i];
    }
    for (; i < 64; i++) {
      _w[i] = _add32(_add32(_ssig1(_w[i - 2]), _w[i - 7]),
                     _add32(_ssig0(_w[i - 15]), _w[i - 16]));
    }

    // Shuffle around the bits.
    var a = _h[0];
    var b = _h[1];
    var c = _h[2];
    var d = _h[3];
    var e = _h[4];
    var f = _h[5];
    var g = _h[6];
    var h = _h[7];

    for (var t = 0; t < 64; t++) {
      var t1 = _add32(_add32(h, _bsig1(e)),
                      _add32(_ch(e, f, g), _add32(_K[t], _w[t])));
      var t2 = _add32(_bsig0(a), _maj(a, b, c));
      h = g;
      g = f;
      f = e;
      e = _add32(d, t1);
      d = c;
      c = b;
      b = a;
      a = _add32(t1, t2);
    }

    // Update hash values after iteration.
    _h[0] = _add32(a, _h[0]);
    _h[1] = _add32(b, _h[1]);
    _h[2] = _add32(c, _h[2]);
    _h[3] = _add32(d, _h[3]);
    _h[4] = _add32(e, _h[4]);
    _h[5] = _add32(f, _h[5]);
    _h[6] = _add32(g, _h[6]);
    _h[7] = _add32(h, _h[7]);
  }

  final List<int> _w;
}
