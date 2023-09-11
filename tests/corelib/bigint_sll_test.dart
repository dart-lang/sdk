// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing Bigints with and without intrinsics.
// VMOptions=--intrinsify --no-enable-asserts
// VMOptions=--intrinsify --enable-asserts
// VMOptions=--no-intrinsify --enable-asserts
// VMOptions=--no-intrinsify --no-enable-asserts
// VMOptions=--runtime_allocate_old
// VMOptions=--runtime_allocate_spill_tlab

import "package:expect/expect.dart";

expectShifted(aString, n, expectedString) {
  BigInt a = BigInt.parse(aString, radix: 16);
  BigInt expected = BigInt.parse(expectedString, radix: 16);
  BigInt actual = a << n;
  String actualString = actual.toRadixString(16);
  print("$aString << $n");
  print(" = $actualString (expected $expectedString)");
  Expect.equals(expected, actual);
}

main() {
  expectShifted("d87becaa3701c97b31b5b8084f2b5b34e7857092", 0,
      "d87becaa3701c97b31b5b8084f2b5b34e7857092");
  expectShifted("d87becaa3701c97b31b5b8084f2b5b34e7857092", 1,
      "1b0f7d9546e0392f6636b70109e56b669cf0ae124");
  expectShifted("d87becaa3701c97b31b5b8084f2b5b34e7857092", 2,
      "361efb2a8dc0725ecc6d6e0213cad6cd39e15c248");
  expectShifted("d87becaa3701c97b31b5b8084f2b5b34e7857092", 31,
      "6c3df6551b80e4bd98dadc042795ad9a73c2b84900000000");
  expectShifted("d87becaa3701c97b31b5b8084f2b5b34e7857092", 32,
      "d87becaa3701c97b31b5b8084f2b5b34e785709200000000");
  expectShifted("d87becaa3701c97b31b5b8084f2b5b34e7857092", 33,
      "1b0f7d9546e0392f6636b70109e56b669cf0ae12400000000");
  expectShifted("d87becaa3701c97b31b5b8084f2b5b34e7857092", 63,
      "6c3df6551b80e4bd98dadc042795ad9a73c2b8490000000000000000");
  expectShifted("d87becaa3701c97b31b5b8084f2b5b34e7857092", 64,
      "d87becaa3701c97b31b5b8084f2b5b34e78570920000000000000000");
  expectShifted("d87becaa3701c97b31b5b8084f2b5b34e7857092", 65,
      "1b0f7d9546e0392f6636b70109e56b669cf0ae1240000000000000000");
  expectShifted("d87becaa3701c97b31b5b8084f2b5b34e7857092", 127,
      "6c3df6551b80e4bd98dadc042795ad9a73c2b84900000000000000000000000000000000");
  expectShifted("d87becaa3701c97b31b5b8084f2b5b34e7857092", 128,
      "d87becaa3701c97b31b5b8084f2b5b34e785709200000000000000000000000000000000");
  expectShifted("d87becaa3701c97b31b5b8084f2b5b34e7857092", 129,
      "1b0f7d9546e0392f6636b70109e56b669cf0ae12400000000000000000000000000000000");

  expectShifted("-d87becaa3701c97b31b5b8084f2b5b34e7857092", 0,
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092");
  expectShifted("-d87becaa3701c97b31b5b8084f2b5b34e7857092", 1,
      "-1b0f7d9546e0392f6636b70109e56b669cf0ae124");
  expectShifted("-d87becaa3701c97b31b5b8084f2b5b34e7857092", 2,
      "-361efb2a8dc0725ecc6d6e0213cad6cd39e15c248");
  expectShifted("-d87becaa3701c97b31b5b8084f2b5b34e7857092", 31,
      "-6c3df6551b80e4bd98dadc042795ad9a73c2b84900000000");
  expectShifted("-d87becaa3701c97b31b5b8084f2b5b34e7857092", 32,
      "-d87becaa3701c97b31b5b8084f2b5b34e785709200000000");
  expectShifted("-d87becaa3701c97b31b5b8084f2b5b34e7857092", 33,
      "-1b0f7d9546e0392f6636b70109e56b669cf0ae12400000000");
  expectShifted("-d87becaa3701c97b31b5b8084f2b5b34e7857092", 63,
      "-6c3df6551b80e4bd98dadc042795ad9a73c2b8490000000000000000");
  expectShifted("-d87becaa3701c97b31b5b8084f2b5b34e7857092", 64,
      "-d87becaa3701c97b31b5b8084f2b5b34e78570920000000000000000");
  expectShifted("-d87becaa3701c97b31b5b8084f2b5b34e7857092", 65,
      "-1b0f7d9546e0392f6636b70109e56b669cf0ae1240000000000000000");
  expectShifted("-d87becaa3701c97b31b5b8084f2b5b34e7857092", 127,
      "-6c3df6551b80e4bd98dadc042795ad9a73c2b84900000000000000000000000000000000");
  expectShifted("-d87becaa3701c97b31b5b8084f2b5b34e7857092", 128,
      "-d87becaa3701c97b31b5b8084f2b5b34e785709200000000000000000000000000000000");
  expectShifted("-d87becaa3701c97b31b5b8084f2b5b34e7857092", 129,
      "-1b0f7d9546e0392f6636b70109e56b669cf0ae12400000000000000000000000000000000");
}
