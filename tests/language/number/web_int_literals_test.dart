// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Integer literals that lose precision when represented as a JavaScript double
// are compile errors in the web compilers.

main() {
  check(0x8000000000000000);

  check(0x7FFF00001111F000);
  check(0x7FFF00001111FC00);
  check(0x7FFF00001111FE00);
  //    ^
  // [web] The integer literal 0x7FFF00001111FE00 can't be represented exactly in JavaScript.
  check(0x7FFF00001111FF00);
  //    ^
  // [web] The integer literal 0x7FFF00001111FF00 can't be represented exactly in JavaScript.
  check(0x7FFF00001111FFFF);
  //    ^
  // [web] The integer literal 0x7FFF00001111FFFF can't be represented exactly in JavaScript.

  check(0xFFFF00001111F000);
  check(0xFFFF00001111F800);
  check(0xFFFF00001111FC00);
  //    ^
  // [web] The integer literal 0xFFFF00001111FC00 can't be represented exactly in JavaScript.
  check(0xFFFF00001111FE00);
  //    ^
  // [web] The integer literal 0xFFFF00001111FE00 can't be represented exactly in JavaScript.
  check(0xFFFF00001111FF00);
  //    ^
  // [web] The integer literal 0xFFFF00001111FF00 can't be represented exactly in JavaScript.
  check(0xFFFF00001111FFFF);
  //    ^
  // [web] The integer literal 0xFFFF00001111FFFF can't be represented exactly in JavaScript.

  // Test all runs of 53 and 54 bits.
  check(0x000FFFFFFFFFFFFF);
  check(0x001FFFFFFFFFFFFF);
  check(0x003FFFFFFFFFFFFF);
  //    ^
  // [web] The integer literal 0x003FFFFFFFFFFFFF can't be represented exactly in JavaScript.
  check(0x003FFFFFFFFFFFFE);
  check(0x007FFFFFFFFFFFFE);
  //    ^
  // [web] The integer literal 0x007FFFFFFFFFFFFE can't be represented exactly in JavaScript.
  check(0x007FFFFFFFFFFFFC);
  check(0x00FFFFFFFFFFFFFC);
  //    ^
  // [web] The integer literal 0x00FFFFFFFFFFFFFC can't be represented exactly in JavaScript.
  check(0x00FFFFFFFFFFFFF8);
  check(0x01FFFFFFFFFFFFF8);
  //    ^
  // [web] The integer literal 0x01FFFFFFFFFFFFF8 can't be represented exactly in JavaScript.
  check(0x01FFFFFFFFFFFFF0);
  check(0x03FFFFFFFFFFFFF0);
  //    ^
  // [web] The integer literal 0x03FFFFFFFFFFFFF0 can't be represented exactly in JavaScript.
  check(0x03FFFFFFFFFFFFE0);
  check(0x07FFFFFFFFFFFFE0);
  //    ^
  // [web] The integer literal 0x07FFFFFFFFFFFFE0 can't be represented exactly in JavaScript.
  check(0x07FFFFFFFFFFFFC0);
  check(0x0FFFFFFFFFFFFFC0);
  //    ^
  // [web] The integer literal 0x0FFFFFFFFFFFFFC0 can't be represented exactly in JavaScript.
  check(0x0FFFFFFFFFFFFF80);
  check(0x1FFFFFFFFFFFFF80);
  //    ^
  // [web] The integer literal 0x1FFFFFFFFFFFFF80 can't be represented exactly in JavaScript.
  check(0x1FFFFFFFFFFFFF00);
  check(0x3FFFFFFFFFFFFF00);
  //    ^
  // [web] The integer literal 0x3FFFFFFFFFFFFF00 can't be represented exactly in JavaScript.
  check(0x3FFFFFFFFFFFFE00);
  check(0x7FFFFFFFFFFFFE00);
  //    ^
  // [web] The integer literal 0x7FFFFFFFFFFFFE00 can't be represented exactly in JavaScript.
  check(0x7FFFFFFFFFFFFC00);
  check(0xFFFFFFFFFFFFFC00);
  //    ^
  // [web] The integer literal 0xFFFFFFFFFFFFFC00 can't be represented exactly in JavaScript.
  check(0xFFFFFFFFFFFFF800);

  // Too big, even on VM.
  check(9223372036854775808);
  //    ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INTEGER_LITERAL_OUT_OF_RANGE
  // [cfe] The integer literal 9223372036854775808 can't be represented in 64 bits.
  // [web] The integer literal 9223372036854775808 can't be represented in 64 bits.
  check(9223372036854775807);
  //    ^
  // [web] The integer literal 9223372036854775807 can't be represented exactly in JavaScript.
  check(9223372036854775806);
  //    ^
  // [web] The integer literal 9223372036854775806 can't be represented exactly in JavaScript.

  // 9223372036854775808 - 512 is rounded.
  check(9223372036854775296);
  //    ^
  // [web] The integer literal 9223372036854775296 can't be represented exactly in JavaScript.

  // 9223372036854775808 - 1024 is exact.
  check(9223372036854774784);

  check(-9223372036854775808);
  check(-9223372036854775807);
  //     ^
  // [web] The integer literal 9223372036854775807 can't be represented exactly in JavaScript.
  check(-9223372036854775296);
  //     ^
  // [web] The integer literal 9223372036854775296 can't be represented exactly in JavaScript.
  check(-9223372036854774784);

  check(1000000000000000001);
  //    ^
  // [web] The integer literal 1000000000000000001 can't be represented exactly in JavaScript.
}

check(int n) {}
