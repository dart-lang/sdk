// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  check(0x8000000000000000);

  check(0x7FFF00001111F000);
  check(0x7FFF00001111FC00);
  check(0x7FFF00001111FE00);
  check(0x7FFF00001111FF00);
  check(0x7FFF00001111FFFF);

  check(0xFFFF00001111F000);
  check(0xFFFF00001111F800);
  check(0xFFFF00001111FC00);
  check(0xFFFF00001111FE00);
  check(0xFFFF00001111FF00);
  check(0xFFFF00001111FFFF);

  // Test all runs of 53 and 54 bits.
  check(0x000FFFFFFFFFFFFF);
  check(0x001FFFFFFFFFFFFF);
  check(0x003FFFFFFFFFFFFF);
  check(0x003FFFFFFFFFFFFE);
  check(0x007FFFFFFFFFFFFE);
  check(0x007FFFFFFFFFFFFC);
  check(0x00FFFFFFFFFFFFFC);
  check(0x00FFFFFFFFFFFFF8);
  check(0x01FFFFFFFFFFFFF8);
  check(0x01FFFFFFFFFFFFF0);
  check(0x03FFFFFFFFFFFFF0);
  check(0x03FFFFFFFFFFFFE0);
  check(0x07FFFFFFFFFFFFE0);
  check(0x07FFFFFFFFFFFFC0);
  check(0x0FFFFFFFFFFFFFC0);
  check(0x0FFFFFFFFFFFFF80);
  check(0x1FFFFFFFFFFFFF80);
  check(0x1FFFFFFFFFFFFF00);
  check(0x3FFFFFFFFFFFFF00);
  check(0x3FFFFFFFFFFFFE00);
  check(0x7FFFFFFFFFFFFE00);
  check(0x7FFFFFFFFFFFFC00);
  check(0xFFFFFFFFFFFFFC00);
  check(0xFFFFFFFFFFFFF800);

  // Too big, even on VM.
  check(9223372036854775808);
  //    ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INTEGER_LITERAL_OUT_OF_RANGE
  // [cfe] The integer literal 9223372036854775808 can't be represented in 64 bits.
  check(9223372036854775807);
  check(9223372036854775806);
  // 9223372036854775808 - 512 is rounded.
  check(9223372036854775296);
  // 9223372036854775808 - 1024 is exact.
  check(9223372036854774784);

  check(-9223372036854775808);
  check(-9223372036854775807);
  check(-9223372036854775296);
  check(-9223372036854774784);

  check(1000000000000000001);
}

check(int n) {}
