// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Testing Bigints.

library bit_twiddling_test;

import "package:expect/expect.dart";

// See bit_twiddling_test.dart first.  This file contains only the tests that
// need Bigint or would fail in dart2js compatibility mode.

testBitLength() {
  check(int i, width) {
    Expect.equals(width, i.bitLength, '$i.bitLength ==  $width');
    // (~i) written as (-i-1) to avoid issues with limited range of dart2js ops.
    Expect.equals(width, (-i - 1).bitLength, '(~$i).bitLength == $width');
  }

  check(0xffffffffffffff, 56);
  check(0xffffffffffffffff, 64);
  check(0xffffffffffffffffff, 72);
  check(0x1000000000000000000, 73);
  check(0x1000000000000000001, 73);

  check(0xfffffffffffffffffffffffffffffffffffffe, 152);
  check(0xffffffffffffffffffffffffffffffffffffff, 152);
  check(0x100000000000000000000000000000000000000, 153);
  check(0x100000000000000000000000000000000000001, 153);
}

testToUnsigned() {
  checkU(src, width, expected) {
    Expect.equals(expected, src.toUnsigned(width));
  }

  checkU(0x100000100000000000001, 2, 1);
  checkU(0x100000200000000000001, 60, 0x200000000000001);
  checkU(0x100000200000000000001, 59, 0x200000000000001);
  checkU(0x100000200000000000001, 58, 0x200000000000001);
  checkU(0x100000200000000000001, 57, 1);
}

testToSigned() {
  checkS(src, width, expected) {
    Expect.equals(
        expected, src.toSigned(width), '$src.toSigned($width) == $expected');
  }

  checkS(0x100000100000000000001, 2, 1);
  checkS(0x100000200000000000001, 60, 0x200000000000001);
  checkS(0x100000200000000000001, 59, 0x200000000000001);
  checkS(0x100000200000000000001, 58, -0x200000000000000 + 1);
  checkS(0x100000200000000000001, 57, 1);
}

main() {
  testBitLength();
  testToUnsigned();
  testToSigned();
}
