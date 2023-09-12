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

expectQuotient(aString, bString, expectedString) {
  BigInt a = BigInt.parse(aString, radix: 16);
  BigInt b = BigInt.parse(bString, radix: 16);
  BigInt expected = BigInt.parse(expectedString, radix: 16);
  BigInt actual = a ~/ b;
  String actualString = actual.toRadixString(16);
  print("$aString ~/ $bString");
  print(" = $actualString (expected $expectedString)");
  Expect.equals(expected, actual);
}

main() {
  expectQuotient("d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "d4cba13fac3ee22b996ff6856c27c1f6d88aef0e", "1");
  expectQuotient("d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "d87becaa3701c97b31b5b8084f2b5b34e7857092", "0");
  expectQuotient("d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "a13fac3ee22b996ff6856c27c1f6d88aef0e", "157b1");
  expectQuotient("d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "3fac3ee22b996ff6856c27c1f6d88aef0e", "36662bd");
  expectQuotient("d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "ac3ee22b996ff6856c27c1f6d88aef0e", "141bfd63e");
  expectQuotient("d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "3ee22b996ff6856c27c1f6d88aef0e", "3714fb67de7");
  expectQuotient("d87becaa3701c97b31b5b8084f2b5b34e7857092", "1",
      "d87becaa3701c97b31b5b8084f2b5b34e7857092");

  expectQuotient("-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "d4cba13fac3ee22b996ff6856c27c1f6d88aef0e", "-1");
  expectQuotient("-d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "d87becaa3701c97b31b5b8084f2b5b34e7857092", "0");
  expectQuotient("-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "a13fac3ee22b996ff6856c27c1f6d88aef0e", "-157b1");
  expectQuotient("-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "3fac3ee22b996ff6856c27c1f6d88aef0e", "-36662bd");
  expectQuotient("-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "ac3ee22b996ff6856c27c1f6d88aef0e", "-141bfd63e");
  expectQuotient("-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "3ee22b996ff6856c27c1f6d88aef0e", "-3714fb67de7");
  expectQuotient("-d87becaa3701c97b31b5b8084f2b5b34e7857092", "1",
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092");

  expectQuotient("d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-d4cba13fac3ee22b996ff6856c27c1f6d88aef0e", "-1");
  expectQuotient("d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092", "0");
  expectQuotient("d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-a13fac3ee22b996ff6856c27c1f6d88aef0e", "-157b1");
  expectQuotient("d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-3fac3ee22b996ff6856c27c1f6d88aef0e", "-36662bd");
  expectQuotient("d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-ac3ee22b996ff6856c27c1f6d88aef0e", "-141bfd63e");
  expectQuotient("d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-3ee22b996ff6856c27c1f6d88aef0e", "-3714fb67de7");
  expectQuotient("d87becaa3701c97b31b5b8084f2b5b34e7857092", "-1",
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092");

  expectQuotient("-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-d4cba13fac3ee22b996ff6856c27c1f6d88aef0e", "1");
  expectQuotient("-d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092", "0");
  expectQuotient("-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-a13fac3ee22b996ff6856c27c1f6d88aef0e", "157b1");
  expectQuotient("-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-3fac3ee22b996ff6856c27c1f6d88aef0e", "36662bd");
  expectQuotient("-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-ac3ee22b996ff6856c27c1f6d88aef0e", "141bfd63e");
  expectQuotient("-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-3ee22b996ff6856c27c1f6d88aef0e", "3714fb67de7");
  expectQuotient("-d87becaa3701c97b31b5b8084f2b5b34e7857092", "-1",
      "d87becaa3701c97b31b5b8084f2b5b34e7857092");
}
