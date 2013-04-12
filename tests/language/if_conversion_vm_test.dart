// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test if-convertion pass in the optimizing compiler.

import "package:expect/expect.dart";

f1(i) => (i == 0) ? 0 : 1;
f2(i) => (i == 0) ? 2 : 3;
f3(i) => (i == null) ? 0 : 1;
f4(i) => (i == null) ? 2 : 3;

f5(i) => (i != 0) ? 0 : 1;
f6(i) => (i != 0) ? 2 : 3;
f7(i) => (i != null) ? 0 : 1;
f8(i) => (i != null) ? 2 : 3;

f9(i) => identical(i, 0) ? 0 : 1;
f10(i) => identical(i, 0) ? 2 : 3;
f11(i) => identical(i, null) ? 0 : 1;
f12(i) => identical(i, null) ? 2 : 3;

f13(i) => !identical(i, 0) ? 0 : 1;
f14(i) => !identical(i, 0) ? 2 : 3;
f15(i) => !identical(i, null) ? 0 : 1;
f16(i) => !identical(i, null) ? 2 : 3;

const POWER_OF_2 = 0x1000000000;

bigPower(i) => (i == 11) ? 0 : POWER_OF_2;

cse(i) {
  final a = i == 0 ? 0 : 1;
  final b = i == 0 ? 2 : 3;
  return a + b;
}

f17(b) => b ? 0 : 11;
f18(b) => b ? 2 : 0;

main() {
  for (var i = 0; i < 10000; i++) {
    f1(i);
    f2(i);
    f3(i);
    f4(i);
    f5(i);
    f6(i);
    f7(i);
    f8(i);
    f9(i);
    f10(i);
    f11(i);
    f12(i);
    f13(i);
    f14(i);
    f15(i);
    f16(i);
    cse(i);
    bigPower(i);
    f17(true);
    f18(true);
  }

  Expect.equals(0, f1(0));
  Expect.equals(1, f1(44));
  Expect.equals(2, f2(0));
  Expect.equals(3, f2(44));
  Expect.equals(0, f3(null));
  Expect.equals(1, f3(44));
  Expect.equals(2, f4(null));
  Expect.equals(3, f4(44));

  Expect.equals(1, f5(0));
  Expect.equals(0, f5(44));
  Expect.equals(3, f6(0));
  Expect.equals(2, f6(44));
  Expect.equals(1, f7(null));
  Expect.equals(0, f7(44));
  Expect.equals(3, f8(null));
  Expect.equals(2, f8(44));

  Expect.equals(0, f9(0));
  Expect.equals(1, f9(44));
  Expect.equals(2, f10(0));
  Expect.equals(3, f10(44));
  Expect.equals(0, f11(null));
  Expect.equals(1, f11(44));
  Expect.equals(2, f12(null));
  Expect.equals(3, f12(44));

  Expect.equals(1, f13(0));
  Expect.equals(0, f13(44));
  Expect.equals(3, f14(0));
  Expect.equals(2, f14(44));
  Expect.equals(1, f15(null));
  Expect.equals(0, f15(44));
  Expect.equals(3, f16(null));
  Expect.equals(2, f16(44));

  Expect.equals(0, bigPower(11));
  Expect.equals(POWER_OF_2, bigPower(12));

  Expect.equals(2, cse(0));
  Expect.equals(4, cse(1));

  Expect.equals(11, f17(false));
  Expect.equals(0, f17(true));

  Expect.equals(0, f18(false));
  Expect.equals(2, f18(true));
}