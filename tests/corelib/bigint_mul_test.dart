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

expectProduct(aString, bString, expectedString) {
  BigInt a = BigInt.parse(aString, radix: 16);
  BigInt b = BigInt.parse(bString, radix: 16);
  BigInt expected = BigInt.parse(expectedString, radix: 16);
  BigInt actual = a * b;
  String actualString = actual.toRadixString(16);
  print("$aString * $bString");
  print(" = $actualString (expected $expectedString)");
  Expect.equals(expected, actual);
}

main() {
  expectProduct(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "b3f2d29d6885d40866b040adf8f545352154823b15fed8aa8c35c5c223fcf4bf6eb904401c1875fc");
  expectProduct(
      "d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "b3f2d29d6885d40866b040adf8f545352154823b15fed8aa8c35c5c223fcf4bf6eb904401c1875fc");
  expectProduct(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "a13fac3ee22b996ff6856c27c1f6d88aef0e",
      "885bc7febac39cd5592e28ce964bfea66a31ea38d8aa8c35c5c223fcf4bf6eb904401c1875fc");
  expectProduct(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "3fac3ee22b996ff6856c27c1f6d88aef0e",
      "35d827ae2b7d1edeeae0115c81ba4a2496fe6d06aa8c35c5c223fcf4bf6eb904401c1875fc");
  expectProduct(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "ac3ee22b996ff6856c27c1f6d88aef0e",
      "91a87047f3ae4999a45912763e9eb292049652bc8c35c5c223fcf4bf6eb904401c1875fc");
  expectProduct(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "3ee22b996ff6856c27c1f6d88aef0e",
      "352d4596b9163adef2fad0a96d914a7908ab1a7435c5c223fcf4bf6eb904401c1875fc");
  expectProduct("d87becaa3701c97b31b5b8084f2b5b34e7857092", "1",
      "d87becaa3701c97b31b5b8084f2b5b34e7857092");
  expectProduct("d87becaa3701c97b31b5b8084f2b5b34e7857092", "0", "0");

  expectProduct(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "-b3f2d29d6885d40866b040adf8f545352154823b15fed8aa8c35c5c223fcf4bf6eb904401c1875fc");
  expectProduct(
      "-d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-b3f2d29d6885d40866b040adf8f545352154823b15fed8aa8c35c5c223fcf4bf6eb904401c1875fc");
  expectProduct(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "a13fac3ee22b996ff6856c27c1f6d88aef0e",
      "-885bc7febac39cd5592e28ce964bfea66a31ea38d8aa8c35c5c223fcf4bf6eb904401c1875fc");
  expectProduct(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "3fac3ee22b996ff6856c27c1f6d88aef0e",
      "-35d827ae2b7d1edeeae0115c81ba4a2496fe6d06aa8c35c5c223fcf4bf6eb904401c1875fc");
  expectProduct(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "ac3ee22b996ff6856c27c1f6d88aef0e",
      "-91a87047f3ae4999a45912763e9eb292049652bc8c35c5c223fcf4bf6eb904401c1875fc");
  expectProduct(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "3ee22b996ff6856c27c1f6d88aef0e",
      "-352d4596b9163adef2fad0a96d914a7908ab1a7435c5c223fcf4bf6eb904401c1875fc");
  expectProduct("-d87becaa3701c97b31b5b8084f2b5b34e7857092", "1",
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092");
  expectProduct("-d87becaa3701c97b31b5b8084f2b5b34e7857092", "0", "0");

  expectProduct(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "-b3f2d29d6885d40866b040adf8f545352154823b15fed8aa8c35c5c223fcf4bf6eb904401c1875fc");
  expectProduct(
      "d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-b3f2d29d6885d40866b040adf8f545352154823b15fed8aa8c35c5c223fcf4bf6eb904401c1875fc");
  expectProduct(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-a13fac3ee22b996ff6856c27c1f6d88aef0e",
      "-885bc7febac39cd5592e28ce964bfea66a31ea38d8aa8c35c5c223fcf4bf6eb904401c1875fc");
  expectProduct(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-3fac3ee22b996ff6856c27c1f6d88aef0e",
      "-35d827ae2b7d1edeeae0115c81ba4a2496fe6d06aa8c35c5c223fcf4bf6eb904401c1875fc");
  expectProduct(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-ac3ee22b996ff6856c27c1f6d88aef0e",
      "-91a87047f3ae4999a45912763e9eb292049652bc8c35c5c223fcf4bf6eb904401c1875fc");
  expectProduct(
      "d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-3ee22b996ff6856c27c1f6d88aef0e",
      "-352d4596b9163adef2fad0a96d914a7908ab1a7435c5c223fcf4bf6eb904401c1875fc");
  expectProduct("d87becaa3701c97b31b5b8084f2b5b34e7857092", "-1",
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092");
  expectProduct("d87becaa3701c97b31b5b8084f2b5b34e7857092", "-0", "0");

  expectProduct(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "b3f2d29d6885d40866b040adf8f545352154823b15fed8aa8c35c5c223fcf4bf6eb904401c1875fc");
  expectProduct(
      "-d4cba13fac3ee22b996ff6856c27c1f6d88aef0e",
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "b3f2d29d6885d40866b040adf8f545352154823b15fed8aa8c35c5c223fcf4bf6eb904401c1875fc");
  expectProduct(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-a13fac3ee22b996ff6856c27c1f6d88aef0e",
      "885bc7febac39cd5592e28ce964bfea66a31ea38d8aa8c35c5c223fcf4bf6eb904401c1875fc");
  expectProduct(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-3fac3ee22b996ff6856c27c1f6d88aef0e",
      "35d827ae2b7d1edeeae0115c81ba4a2496fe6d06aa8c35c5c223fcf4bf6eb904401c1875fc");
  expectProduct(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-ac3ee22b996ff6856c27c1f6d88aef0e",
      "91a87047f3ae4999a45912763e9eb292049652bc8c35c5c223fcf4bf6eb904401c1875fc");
  expectProduct(
      "-d87becaa3701c97b31b5b8084f2b5b34e7857092",
      "-3ee22b996ff6856c27c1f6d88aef0e",
      "352d4596b9163adef2fad0a96d914a7908ab1a7435c5c223fcf4bf6eb904401c1875fc");
  expectProduct("-d87becaa3701c97b31b5b8084f2b5b34e7857092", "-1",
      "d87becaa3701c97b31b5b8084f2b5b34e7857092");
  expectProduct("-d87becaa3701c97b31b5b8084f2b5b34e7857092", "-0", "0");
}
