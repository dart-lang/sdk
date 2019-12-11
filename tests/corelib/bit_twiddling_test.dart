// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Testing int.bitLength, int.toUnsigned and int.toSigned.

library bit_twiddling_test;

import "package:expect/expect.dart";

testBitLength() {
  check(int i, width) {
    Expect.equals(width, i.bitLength, '$i.bitLength ==  $width');
    // (~i) written as (-i-1) to avoid issues with limited range of dart2js ops.
    Expect.equals(width, (-i - 1).bitLength, '(~$i).bitLength == $width');
  }

  check(0, 0);
  check(1, 1);
  check(2, 2);
  check(3, 2);
  check(4, 3);
  check(5, 3);
  check(6, 3);
  check(7, 3);
  check(8, 4);
  check(127, 7);
  check(128, 8);
  check(129, 8);
  check(2147483646, 31);
  check(2147483647, 31);
  check(2147483648, 32);
  check(2147483649, 32);
  check(4294967295, 32);
  check(4294967296, 33);
  check(0xffffffffff, 40);
  check(0xfffffffffff, 44);
  check(0xffffffffffff, 48);
  check(0x1000000000000, 49);
  check(0x1000000000001, 49);
  check(0x1ffffffffffff, 49);
  check(0x2000000000000, 50);
  check(0x2000000000001, 50);

  check(0xffffffffffffff, 56); //   //# int64: ok
  check(0x7fffffffffffffff, 63); // //# int64: continued
  check(0xffffffffffffffff, 0); //  //# int64: continued
}

testToUnsigned() {
  checkU(src, width, expected) {
    Expect.equals(expected, src.toUnsigned(width));
  }

  checkU(1, 8, 1);
  checkU(0xff, 8, 0xff);
  checkU(0xffff, 8, 0xff);
  checkU(-1, 8, 0xff);
  checkU(0xffffffff, 32, 0xffffffff);

  checkU(0x7fffffff, 30, 0x3fffffff);
  checkU(0x7fffffff, 31, 0x7fffffff);
  checkU(0x7fffffff, 32, 0x7fffffff);
  checkU(0x80000000, 30, 0);
  checkU(0x80000000, 31, 0);
  checkU(0x80000000, 32, 0x80000000);
  checkU(0xffffffff, 30, 0x3fffffff);
  checkU(0xffffffff, 31, 0x7fffffff);
  checkU(0xffffffff, 32, 0xffffffff);
  checkU(0x100000000, 30, 0);
  checkU(0x100000000, 31, 0);
  checkU(0x100000000, 32, 0);
  checkU(0x1ffffffff, 30, 0x3fffffff);
  checkU(0x1ffffffff, 31, 0x7fffffff);
  checkU(0x1ffffffff, 32, 0xffffffff);

  checkU(-1, 0, 0);
  checkU(0, 0, 0);
  checkU(1, 0, 0);
  checkU(2, 0, 0);
  checkU(3, 0, 0);

  checkU(-1, 1, 1);
  checkU(0, 1, 0);
  checkU(1, 1, 1);
  checkU(2, 1, 0);
  checkU(3, 1, 1);
  checkU(4, 1, 0);

  checkU(-1, 2, 3);
  checkU(0, 2, 0);
  checkU(1, 2, 1);
  checkU(2, 2, 2);
  checkU(3, 2, 3);
  checkU(4, 2, 0);

  checkU(-1, 3, 7);
  checkU(0, 3, 0);
  checkU(1, 3, 1);
  checkU(2, 3, 2);
  checkU(3, 3, 3);
  checkU(4, 3, 4);

  checkU(0x0100000000000001, 2, 1); //                   //# int64: continued
  checkU(0x0200000000000001, 60, 0x200000000000001); //  //# int64: continued
  checkU(0x0200000000000001, 59, 0x200000000000001); //  //# int64: continued
  checkU(0x0200000000000001, 58, 0x200000000000001); //  //# int64: continued
  checkU(0x0200000000000001, 57, 1); //                  //# int64: continued

  checkU(0x8100000000000001, 2, 1); //                   //# int64: continued
  checkU(0x8200000000000001, 60, 0x200000000000001); //  //# int64: continued
  checkU(0x8200000000000001, 59, 0x200000000000001); //  //# int64: continued
  checkU(0x8200000000000001, 58, 0x200000000000001); //  //# int64: continued
  checkU(0x8200000000000001, 57, 1); //                  //# int64: continued
}

testToSigned() {
  checkS(src, width, expected) {
    Expect.equals(
        expected, src.toSigned(width), '$src.toSigned($width) == $expected');
  }

  checkS(1, 8, 1);
  checkS(0xff, 8, -1);
  checkS(0xffff, 8, -1);
  checkS(-1, 8, -1);
  checkS(128, 8, -128);
  checkS(0xffffffff, 32, -1);

  checkS(0x7fffffff, 30, -1);
  checkS(0x7fffffff, 31, -1);
  checkS(0x7fffffff, 32, 0x7fffffff);
  checkS(0x80000000, 30, 0);
  checkS(0x80000000, 31, 0);
  checkS(0x80000000, 32, -2147483648);
  checkS(0xffffffff, 30, -1);
  checkS(0xffffffff, 31, -1);
  checkS(0xffffffff, 32, -1);

  checkS(0x100000000, 30, 0);
  checkS(0x100000000, 31, 0);
  checkS(0x100000000, 32, 0);
  checkS(0x1ffffffff, 30, -1);
  checkS(0x1ffffffff, 31, -1);
  checkS(0x1ffffffff, 32, -1);

  checkS(-1, 1, -1);
  checkS(0, 1, 0);
  checkS(1, 1, -1); // The only bit is the sign bit.
  checkS(2, 1, 0);
  checkS(3, 1, -1);
  checkS(4, 1, 0);

  checkS(-1, 2, -1);
  checkS(0, 2, 0);
  checkS(1, 2, 1);
  checkS(2, 2, -2);
  checkS(3, 2, -1);
  checkS(4, 2, 0);

  checkS(-1, 3, -1);
  checkS(0, 3, 0);
  checkS(1, 3, 1);
  checkS(2, 3, 2);
  checkS(3, 3, 3);
  checkS(4, 3, -4);

  checkS(0x0100000000000001, 2, 1); //                       //# int64: continued
  checkS(0x0200000000000001, 60, 0x200000000000001); //      //# int64: continued
  checkS(0x0200000000000001, 59, 0x200000000000001); //      //# int64: continued
  checkS(0x0200000000000001, 58, -0x200000000000000 + 1); // //# int64: continued
  checkS(0x0200000000000001, 57, 1); //                      //# int64: continued

  checkS(0x8100000000000001, 2, 1); //                       //# int64: continued
  checkS(0x8200000000000001, 60, 0x200000000000001); //      //# int64: continued
  checkS(0x8200000000000001, 59, 0x200000000000001); //      //# int64: continued
  checkS(0x8200000000000001, 58, -0x200000000000000 + 1); // //# int64: continued
  checkS(0x8200000000000001, 57, 1); //                      //# int64: continued
}

main() {
  testBitLength();
  testToUnsigned();
  testToSigned();
}
