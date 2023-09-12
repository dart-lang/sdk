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

expectRemainder(aString, bString, expectedString) {
  BigInt a = BigInt.parse(aString, radix: 16);
  BigInt b = BigInt.parse(bString, radix: 16);
  BigInt expected = BigInt.parse(expectedString, radix: 16);
  BigInt actual = a % b;
  String actualString = actual.toRadixString(16);
  print("$aString % $bString");
  print(" = $actualString (expected $expectedString)");
  Expect.equals(expected, actual);
}

main() {
  expectRemainder(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "3b04b6a8ac2e74f9845c182e303993e0efa8184");
  expectRemainder(
      "d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "d4cba13fac3ee22b996ff6856c27c1f6d88aef0e");
  expectRemainder(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "a13fac3ee22b996ff6856c27c1f6d88aef0e",
      "1fdbde7efec117ff81df42cc8367092a65e4");
  expectRemainder(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "3fac3ee22b996ff6856c27c1f6d88aef0e",
      "359d4ac0e4440150310acc0e96fdb973c");
  expectRemainder("d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "ac3ee22b996ff6856c27c1f6d88aef0e", "84c9b202365aef6ea4b442ff6897d72e");
  expectRemainder("d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "3ee22b996ff6856c27c1f6d88aef0e", "2c66626e41743605244c026579e4f0");
  expectRemainder("d87becaa3701c97b31b5b8084f2b5b34e7857092", "1", "0");

  expectRemainder(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "d11b55d5217bfadc012a3502892428b8c9906d8a");
  expectRemainder(
      "-d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "3b04b6a8ac2e74f9845c182e303993e0efa8184");
  expectRemainder(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "a13fac3ee22b996ff6856c27c1f6d88aef0e",
      "8163cdbfe36a817074a6295b3e8fcf60892a");
  expectRemainder(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "3fac3ee22b996ff6856c27c1f6d88aef0e",
      "3c526a361d552fe1825b7b010d68af57d2");
  expectRemainder("-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "ac3ee22b996ff6856c27c1f6d88aef0e", "2775302963150716c7737ef76ff317e0");
  expectRemainder("-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "3ee22b996ff6856c27c1f6d88aef0e", "127bc92b2e824f670375f473110a1e");
  expectRemainder("-d87becaa3701c97b31b5b8084f2b5b34e7857092", "1", "0");

  expectRemainder(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "3b04b6a8ac2e74f9845c182e303993e0efa8184");
  expectRemainder(
      "d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "d4cba13fac3ee22b996ff6856c27c1f6d88aef0e");
  expectRemainder(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-a13fac3ee22b996ff6856c27c1f6d88aef0e",
      "1fdbde7efec117ff81df42cc8367092a65e4");
  expectRemainder(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-3fac3ee22b996ff6856c27c1f6d88aef0e",
      "359d4ac0e4440150310acc0e96fdb973c");
  expectRemainder("d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-ac3ee22b996ff6856c27c1f6d88aef0e", "84c9b202365aef6ea4b442ff6897d72e");
  expectRemainder("d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-3ee22b996ff6856c27c1f6d88aef0e", "2c66626e41743605244c026579e4f0");
  expectRemainder("d87becaa3701c97b31b5b8084f2b5b34e7857092", "-1", "0");

  expectRemainder(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "d11b55d5217bfadc012a3502892428b8c9906d8a");
  expectRemainder(
      "-d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "3b04b6a8ac2e74f9845c182e303993e0efa8184");
  expectRemainder(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-a13fac3ee22b996ff6856c27c1f6d88aef0e",
      "8163cdbfe36a817074a6295b3e8fcf60892a");
  expectRemainder(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-3fac3ee22b996ff6856c27c1f6d88aef0e",
      "3c526a361d552fe1825b7b010d68af57d2");
  expectRemainder("-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-ac3ee22b996ff6856c27c1f6d88aef0e", "2775302963150716c7737ef76ff317e0");
  expectRemainder("-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-3ee22b996ff6856c27c1f6d88aef0e", "127bc92b2e824f670375f473110a1e");
  expectRemainder("-d87becaa3701c97b31b5b8084f2b5b34e7857092", "-1", "0");
}
