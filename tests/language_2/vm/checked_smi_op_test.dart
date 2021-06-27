// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// VMOptions=
// VMOptions=--use_slow_path

import "package:expect/expect.dart";

@pragma("vm:never-inline")
dynamic hiddenSmi() {
  try {
    throw 42;
  } catch (e) {
    return e;
  }
  return 0;
}

@pragma("vm:never-inline")
dynamic hiddenMint() {
  try {
    throw 0x8000000000000000;
  } catch (e) {
    return e;
  }
  return 0;
}

@pragma("vm:never-inline")
dynamic hiddenDouble() {
  try {
    throw 3.0;
  } catch (e) {
    return e;
  }
  return 0;
}

@pragma("vm:never-inline")
dynamic hiddenCustom() {
  try {
    throw new Custom();
  } catch (e) {
    return e;
  }
  return 0;
}

class Custom {
  operator +(other) => "add";
  operator -(other) => "sub";
  operator *(other) => "mul";
  operator ~/(other) => "div";
  operator %(other) => "mod";
  operator &(other) => "and";
  operator |(other) => "or";
  operator ^(other) => "xor";
  operator <<(other) => "sll";
  operator >>(other) => "sra";
}

main() {
  Expect.equals(44, hiddenSmi() + 2);
  Expect.equals(40, hiddenSmi() - 2);
  Expect.equals(84, hiddenSmi() * 2);
  Expect.equals(21, hiddenSmi() ~/ 2);
  Expect.equals(0, hiddenSmi() % 2);
  Expect.equals(2, hiddenSmi() & 2);
  Expect.equals(42, hiddenSmi() | 2);
  Expect.equals(40, hiddenSmi() ^ 2);
  Expect.equals(168, hiddenSmi() << 2);
  Expect.equals(10, hiddenSmi() >> 2);

  Expect.equals(-9223372036854775806, hiddenMint() + 2);
  Expect.equals(9223372036854775806, hiddenMint() - 2);
  Expect.equals(0, hiddenMint() * 2);
  Expect.equals(-4611686018427387904, hiddenMint() ~/ 2);
  Expect.equals(0, hiddenMint() % 2);
  Expect.equals(0, hiddenMint() & 2);
  Expect.equals(-9223372036854775806, hiddenMint() | 2);
  Expect.equals(-9223372036854775806, hiddenMint() ^ 2);
  Expect.equals(0, hiddenMint() << 2);
  Expect.equals(-2305843009213693952, hiddenMint() >> 2);

  Expect.equals(5.0, hiddenDouble() + 2);
  Expect.equals(1.0, hiddenDouble() - 2);
  Expect.equals(6.0, hiddenDouble() * 2);
  Expect.equals(1, hiddenDouble() ~/ 2);
  Expect.equals(1.0, hiddenDouble() % 2);
  Expect.throws(() => hiddenDouble() & 2, (e) => e is NoSuchMethodError);
  Expect.throws(() => hiddenDouble() | 2, (e) => e is NoSuchMethodError);
  Expect.throws(() => hiddenDouble() ^ 2, (e) => e is NoSuchMethodError);
  Expect.throws(() => hiddenDouble() << 2, (e) => e is NoSuchMethodError);
  Expect.throws(() => hiddenDouble() >> 2, (e) => e is NoSuchMethodError);

  Expect.equals("add", hiddenCustom() + 2);
  Expect.equals("sub", hiddenCustom() - 2);
  Expect.equals("mul", hiddenCustom() * 2);
  Expect.equals("div", hiddenCustom() ~/ 2);
  Expect.equals("mod", hiddenCustom() % 2);
  Expect.equals("and", hiddenCustom() & 2);
  Expect.equals("or", hiddenCustom() | 2);
  Expect.equals("xor", hiddenCustom() ^ 2);
  Expect.equals("sll", hiddenCustom() << 2);
  Expect.equals("sra", hiddenCustom() >> 2);
}
