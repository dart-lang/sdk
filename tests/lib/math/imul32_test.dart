// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing imul32 in dart:math, including products exceeding 2^53 where float64
// multiplication loses low bits.

import "dart:math" show imul32;

import "package:expect/expect.dart";
import "package:expect/variations.dart" show jsNumbers;

void checkImul32(int a, int b, int expected) {
  Expect.equals(expected, imul32(a, b), 'imul32($a, $b)');
  Expect.equals(expected, imul32(b, a), 'imul32($b, $a)');
}

void testSmallValues() {
  checkImul32(0, 0, 0);
  checkImul32(0, 1, 0);
  checkImul32(0, -1, 0);
  checkImul32(1, 1, 1);
  checkImul32(1, -1, -1);
  checkImul32(-1, -1, 1);
  checkImul32(3, 4, 12);
  checkImul32(-3, 4, -12);
  checkImul32(-3, -4, 12);
  checkImul32(-1, 5, -5);
}

void testSigned32Boundaries() {
  // 2^31 - 1 = 0x7fffffff = 2147483647.
  checkImul32(0x7fffffff, 1, 0x7fffffff);
  checkImul32(0x7fffffff, 2, -2);
  checkImul32(0x7fffffff, -1, -0x7fffffff);

  // 0x80000000 in low 32 bits is -2^31 = -2147483648.
  checkImul32(0x80000000, 1, -0x80000000);
  checkImul32(-0x80000000, 1, -0x80000000);
  checkImul32(-0x80000000, -1, -0x80000000);
  checkImul32(-0x80000000, 2, 0);

  // 0xffffffff in low 32 bits is -1.
  checkImul32(0xffffffff, 1, -1);
  checkImul32(0xffffffff, 2, -2);
  checkImul32(0xffffffff, 0xffffffff, 1);
  checkImul32(0x80000001, 0x80000001, 1);
}

void testAbove53BitProducts() {
  // Products whose exact 64-bit value exceeds 2^53 (where JS float64 `a * b`
  // loses low bits before `.toSigned(32)` or `.toUnsigned(32)`).

  // FNV-1a 32-bit offset basis (0x811c9dc5) * prime (0x01000193):
  // Exact 56-bit product is 0x811d69050c5d1f -> low 32 bits = 0x050c5d1f.
  // (JS float64 rounds to 0x811d69050c5d20.)
  checkImul32(0x811c9dc5, 0x01000193, 0x050c5d1f);

  // 0xffffffff * 0x01000193:
  // Exact 57-bit product is 0x01000192fefffe6d -> signed low 32 bits =
  // -0x01000193 (-16777619), unsigned low 32 bits = 0xfefffe6d.
  checkImul32(0xffffffff, 0x01000193, -0x01000193);
  Expect.equals(0xfefffe6d, imul32(0xffffffff, 0x01000193).toUnsigned(32));

  // (2^31 - 1) * (2^31 - 1) = 2^62 - 2^32 + 1 -> low 32 bits = 1.
  checkImul32(0x7fffffff, 0x7fffffff, 1);

  // 0xdeadbeef * 0xcafebabe = 0xb092ab7b88cf5b62 -> signed low 32 bits =
  // -0x7730a49e (-1999676574), unsigned low 32 bits = 0x88cf5b62.
  checkImul32(0xdeadbeef, 0xcafebabe, -0x7730a49e);
  Expect.equals(0x88cf5b62, imul32(0xdeadbeef, 0xcafebabe).toUnsigned(32));

  // 0xeeb56442 * 0xd35a2d97 = 0xc51397ea54d1bcee (> 2^63) and
  // 0xaec3758b * 0xd35a2d97 = 0x9048a9b854d1c3fd (> 2^63):
  // JS float64 rounds both products to low 32 bits 0x54d1c000, whereas the
  // exact low 32 bits are 0x54d1bcee and 0x54d1c3fd.
  checkImul32(0xeeb56442, 0xd35a2d97, 0x54d1bcee);
  checkImul32(0xaec3758b, 0xd35a2d97, 0x54d1c3fd);

  // Multi-step FNV-1a 32-bit hash over representative bytes.
  const int fnvPrime = 0x01000193;
  int hash = 0x811c9dc5;
  for (final int byte in const [0x00, 0x01, 0x02, 0xff, 0x80, 0x2a]) {
    hash = imul32(hash ^ byte, fnvPrime);
  }
  Expect.equals(1869169759, hash);
  Expect.equals(0x6f69445f, hash.toUnsigned(32));
}

void testHighBitsIgnored() {
  // Bits above bit 31 are ignored (inputs are reduced modulo 2^32).
  checkImul32(0x1_0000_0003, 0x2_0000_0004, 12);
  checkImul32(0x10_0000_0001, 0x10_0000_0001, 1);
  checkImul32(0x1_0000_0000, 0x7fffffff, 0);

  if (!jsNumbers) {
    checkImul32((1 << 62) + 7, (1 << 61) + 9, 63);
    checkImul32((1 << 63) | 3, (1 << 63) | 5, 15);
  }
}

void testIdentities() {
  const values = <int>[
    0,
    1,
    -1,
    2,
    -2,
    42,
    -42,
    0x01000193,
    0x7fffffff,
    -0x80000000,
    0x811c9dc5,
    0xffffffff,
  ];
  for (final a in values) {
    for (final b in values) {
      final prod = imul32(a, b);
      // Result is always in signed 32-bit range [-2^31, 2^31 - 1].
      Expect.equals(prod, prod.toSigned(32));
      // Distributive over 32-bit addition: a * (b + 1) == a * b + a (mod 2^32).
      Expect.equals(imul32(a, b + 1), (prod + a).toSigned(32));
    }
  }
}

void main() {
  testSmallValues();
  testSigned32Boundaries();
  testAbove53BitProducts();
  testHighBitsIgnored();
  testIdentities();
}
