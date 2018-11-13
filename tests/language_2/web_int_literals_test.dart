// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  check(0x8000000000000000);

  check(0x7FFF00001111F000);
  check(0x7FFF00001111FC00);
  check(0x7FFF00001111FE00); //         //# 01: compile-time error
  check(0x7FFF00001111FF00); //         //# 02: compile-time error
  check(0x7FFF00001111FFFF); //         //# 03: compile-time error

  check(0xFFFF00001111F000);
  check(0xFFFF00001111F800);
  check(0xFFFF00001111FC00); //         //# 10: compile-time error
  check(0xFFFF00001111FE00); //         //# 11: compile-time error
  check(0xFFFF00001111FF00); //         //# 12: compile-time error
  check(0xFFFF00001111FFFF); //         //# 13: compile-time error

  // Test all runs of 53 and 54 bits.
  check(0x000FFFFFFFFFFFFF);
  check(0x001FFFFFFFFFFFFF);
  check(0x003FFFFFFFFFFFFF); //         //# 20: compile-time error
  check(0x003FFFFFFFFFFFFE);
  check(0x007FFFFFFFFFFFFE); //         //# 21: compile-time error
  check(0x007FFFFFFFFFFFFC);
  check(0x00FFFFFFFFFFFFFC); //         //# 22: compile-time error
  check(0x00FFFFFFFFFFFFF8);
  check(0x01FFFFFFFFFFFFF8); //         //# 23: compile-time error
  check(0x01FFFFFFFFFFFFF0);
  check(0x03FFFFFFFFFFFFF0); //         //# 22: compile-time error
  check(0x03FFFFFFFFFFFFE0);
  check(0x07FFFFFFFFFFFFE0); //         //# 24: compile-time error
  check(0x07FFFFFFFFFFFFC0);
  check(0x0FFFFFFFFFFFFFC0); //         //# 25: compile-time error
  check(0x0FFFFFFFFFFFFF80);
  check(0x1FFFFFFFFFFFFF80); //         //# 26: compile-time error
  check(0x1FFFFFFFFFFFFF00);
  check(0x3FFFFFFFFFFFFF00); //         //# 27: compile-time error
  check(0x3FFFFFFFFFFFFE00);
  check(0x7FFFFFFFFFFFFE00); //         //# 28: compile-time error
  check(0x7FFFFFFFFFFFFC00);
  check(0xFFFFFFFFFFFFFC00); //         //# 29: compile-time error
  check(0xFFFFFFFFFFFFF800);

  // Too big, even on VM.
  check(9223372036854775808); //        //# 60: compile-time error
  check(9223372036854775807); //        //# 61: compile-time error
  check(9223372036854775806); //        //# 62: compile-time error
  // 9223372036854775808 - 512 is rounded.
  check(9223372036854775296); //        //# 63: compile-time error
  // 9223372036854775808 - 1024 is exact.
  check(9223372036854774784);

  check(-9223372036854775808);
  check(-9223372036854775807); //       //# 64: compile-time error
  check(-9223372036854775296); //       //# 65: compile-time error
  check(-9223372036854774784);

  check(1000000000000000001); //        //# 70: compile-time error
}

check(int n) {}
