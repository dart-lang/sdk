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

expectSum(aString, bString, expectedString) {
  BigInt a = BigInt.parse(aString, radix: 16);
  BigInt b = BigInt.parse(bString, radix: 16);
  BigInt expected = BigInt.parse(expectedString, radix: 16);
  BigInt actual = a + b;
  String actualString = actual.toRadixString(16);
  print("$aString + $bString");
  print(" = $actualString (expected $expectedString)");
  Expect.equals(expected, actual);
}

main() {
  expectSum(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "1ad478de9e340aba6cb25ae8dbb531d2bc0105fa0");
  expectSum(
      "d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "1ad478de9e340aba6cb25ae8dbb531d2bc0105fa0");
  expectSum(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "a13fac3ee22b996ff6856c27c1f6d88aef0e",
      "d87c8de9e340aba6cb25ae8dbb531d2bc0105fa0");
  expectSum(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "3fac3ee22b996ff6856c27c1f6d88aef0e",
      "d87bece9e340aba6cb25ae8dbb531d2bc0105fa0");
  expectSum(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "ac3ee22b996ff6856c27c1f6d88aef0e",
      "d87becaae340aba6cb25ae8dbb531d2bc0105fa0");
  expectSum(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "3ee22b996ff6856c27c1f6d88aef0e",
      "d87becaa3740aba6cb25ae8dbb531d2bc0105fa0");
  expectSum("d87becaa3701c97b31b5b8084f2b5b34e7857092", "1",
      "d87becaa3701c97b31b5b8084f2b5b34e7857093");
  expectSum("d87becaa3701c97b31b5b8084f2b5b34e7857092", "0",
      "d87becaa3701c97b31b5b8084f2b5b34e7857092");

  expectSum(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "-3b04b6a8ac2e74f9845c182e303993e0efa8184");
  expectSum(
      "-d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "3b04b6a8ac2e74f9845c182e303993e0efa8184");
  expectSum(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "a13fac3ee22b996ff6856c27c1f6d88aef0e",
      "-d87b4b6a8ac2e74f9845c182e303993e0efa8184");
  expectSum(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "3fac3ee22b996ff6856c27c1f6d88aef0e",
      "-d87bec6a8ac2e74f9845c182e303993e0efa8184");
  expectSum(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "ac3ee22b996ff6856c27c1f6d88aef0e",
      "-d87beca98ac2e74f9845c182e303993e0efa8184");
  expectSum(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "3ee22b996ff6856c27c1f6d88aef0e",
      "-d87becaa36c2e74f9845c182e303993e0efa8184");
  expectSum("-d87becaa3701c97b31b5b8084f2b5b34e7857092", "1",
      "-d87becaa3701c97b31b5b8084f2b5b34e7857091");
  expectSum("-d87becaa3701c97b31b5b8084f2b5b34e7857092", "0",
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092");

  expectSum(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "3b04b6a8ac2e74f9845c182e303993e0efa8184");
  expectSum(
      "d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-3b04b6a8ac2e74f9845c182e303993e0efa8184");
  expectSum(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-a13fac3ee22b996ff6856c27c1f6d88aef0e",
      "d87b4b6a8ac2e74f9845c182e303993e0efa8184");
  expectSum(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-3fac3ee22b996ff6856c27c1f6d88aef0e",
      "d87bec6a8ac2e74f9845c182e303993e0efa8184");
  expectSum(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-ac3ee22b996ff6856c27c1f6d88aef0e",
      "d87beca98ac2e74f9845c182e303993e0efa8184");
  expectSum(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-3ee22b996ff6856c27c1f6d88aef0e",
      "d87becaa36c2e74f9845c182e303993e0efa8184");
  expectSum("d87becaa3701c97b31b5b8084f2b5b34e7857092", "-1",
      "d87becaa3701c97b31b5b8084f2b5b34e7857091");
  expectSum("d87becaa3701c97b31b5b8084f2b5b34e7857092", "-0",
      "d87becaa3701c97b31b5b8084f2b5b34e7857092");

  expectSum(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "-1ad478de9e340aba6cb25ae8dbb531d2bc0105fa0");
  expectSum(
      "-d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-1ad478de9e340aba6cb25ae8dbb531d2bc0105fa0");
  expectSum(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-a13fac3ee22b996ff6856c27c1f6d88aef0e",
      "-d87c8de9e340aba6cb25ae8dbb531d2bc0105fa0");
  expectSum(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-3fac3ee22b996ff6856c27c1f6d88aef0e",
      "-d87bece9e340aba6cb25ae8dbb531d2bc0105fa0");
  expectSum(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-ac3ee22b996ff6856c27c1f6d88aef0e",
      "-d87becaae340aba6cb25ae8dbb531d2bc0105fa0");
  expectSum(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-3ee22b996ff6856c27c1f6d88aef0e",
      "-d87becaa3740aba6cb25ae8dbb531d2bc0105fa0");
  expectSum("-d87becaa3701c97b31b5b8084f2b5b34e7857092", "-1",
      "-d87becaa3701c97b31b5b8084f2b5b34e7857093");
  expectSum("-d87becaa3701c97b31b5b8084f2b5b34e7857092", "-0",
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092");
}
