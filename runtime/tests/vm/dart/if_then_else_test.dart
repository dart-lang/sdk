// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-counter-threshold=50 --no-background-compilation

import "package:expect/expect.dart";

@pragma("vm:never-inline")
dynamic eq(dynamic x, dynamic y) => x == y ? 3 : 7;
@pragma("vm:never-inline")
dynamic ne(dynamic x, dynamic y) => x != y ? 3 : 7;
@pragma("vm:never-inline")
dynamic lt(dynamic x, dynamic y) => x < y ? 3 : 7;
@pragma("vm:never-inline")
dynamic le(dynamic x, dynamic y) => x <= y ? 3 : 7;
@pragma("vm:never-inline")
dynamic gt(dynamic x, dynamic y) => x > y ? 3 : 7;
@pragma("vm:never-inline")
dynamic ge(dynamic x, dynamic y) => x >= y ? 3 : 7;

testCompareReg() {
  Expect.equals(7, eq(3, 2));
  Expect.equals(3, eq(3, 3));
  Expect.equals(7, eq(3, 4));

  Expect.equals(3, ne(3, 2));
  Expect.equals(7, ne(3, 3));
  Expect.equals(3, ne(3, 4));

  Expect.equals(7, lt(3, 2));
  Expect.equals(7, lt(3, 3));
  Expect.equals(3, lt(3, 4));

  Expect.equals(7, le(3, 2));
  Expect.equals(3, le(3, 3));
  Expect.equals(3, le(3, 4));

  Expect.equals(3, gt(3, 2));
  Expect.equals(7, gt(3, 3));
  Expect.equals(7, gt(3, 4));

  Expect.equals(3, ge(3, 2));
  Expect.equals(3, ge(3, 3));
  Expect.equals(7, ge(3, 4));
}

@pragma("vm:never-inline")
dynamic eq0(dynamic x, dynamic y) => x == y ? 1 : 0;
@pragma("vm:never-inline")
dynamic ne0(dynamic x, dynamic y) => x != y ? 1 : 0;
@pragma("vm:never-inline")
dynamic lt0(dynamic x, dynamic y) => x < y ? 1 : 0;
@pragma("vm:never-inline")
dynamic le0(dynamic x, dynamic y) => x <= y ? 1 : 0;
@pragma("vm:never-inline")
dynamic gt0(dynamic x, dynamic y) => x > y ? 1 : 0;
@pragma("vm:never-inline")
dynamic ge0(dynamic x, dynamic y) => x >= y ? 1 : 0;

testCompareReg0() {
  Expect.equals(0, eq0(3, 2));
  Expect.equals(1, eq0(3, 3));
  Expect.equals(0, eq0(3, 4));

  Expect.equals(1, ne0(3, 2));
  Expect.equals(0, ne0(3, 3));
  Expect.equals(1, ne0(3, 4));

  Expect.equals(0, lt0(3, 2));
  Expect.equals(0, lt0(3, 3));
  Expect.equals(1, lt0(3, 4));

  Expect.equals(0, le0(3, 2));
  Expect.equals(1, le0(3, 3));
  Expect.equals(1, le0(3, 4));

  Expect.equals(1, gt0(3, 2));
  Expect.equals(0, gt0(3, 3));
  Expect.equals(0, gt0(3, 4));

  Expect.equals(1, ge0(3, 2));
  Expect.equals(1, ge0(3, 3));
  Expect.equals(0, ge0(3, 4));
}

@pragma("vm:never-inline")
dynamic eqN(dynamic x, dynamic y) => x == y ? 1 : 4;
@pragma("vm:never-inline")
dynamic neN(dynamic x, dynamic y) => x != y ? 1 : 4;
@pragma("vm:never-inline")
dynamic ltN(dynamic x, dynamic y) => x < y ? 1 : 4;
@pragma("vm:never-inline")
dynamic leN(dynamic x, dynamic y) => x <= y ? 1 : 4;
@pragma("vm:never-inline")
dynamic gtN(dynamic x, dynamic y) => x > y ? 1 : 4;
@pragma("vm:never-inline")
dynamic geN(dynamic x, dynamic y) => x >= y ? 1 : 4;

testCompareRegN() {
  Expect.equals(4, eqN(3, 2));
  Expect.equals(1, eqN(3, 3));
  Expect.equals(4, eqN(3, 4));

  Expect.equals(1, neN(3, 2));
  Expect.equals(4, neN(3, 3));
  Expect.equals(1, neN(3, 4));

  Expect.equals(4, ltN(3, 2));
  Expect.equals(4, ltN(3, 3));
  Expect.equals(1, ltN(3, 4));

  Expect.equals(4, leN(3, 2));
  Expect.equals(1, leN(3, 3));
  Expect.equals(1, leN(3, 4));

  Expect.equals(1, gtN(3, 2));
  Expect.equals(4, gtN(3, 3));
  Expect.equals(4, gtN(3, 4));

  Expect.equals(1, geN(3, 2));
  Expect.equals(1, geN(3, 3));
  Expect.equals(4, geN(3, 4));
}

@pragma("vm:never-inline")
dynamic eqimm(dynamic x) => x == 4 ? 3 : 7;
@pragma("vm:never-inline")
dynamic neimm(dynamic x) => x != 4 ? 3 : 7;
@pragma("vm:never-inline")
dynamic ltimm(dynamic x) => x < 4 ? 3 : 7;
@pragma("vm:never-inline")
dynamic leimm(dynamic x) => x <= 4 ? 3 : 7;
@pragma("vm:never-inline")
dynamic gtimm(dynamic x) => x > 4 ? 3 : 7;
@pragma("vm:never-inline")
dynamic geimm(dynamic x) => x >= 4 ? 3 : 7;

testCompareImm() {
  Expect.equals(7, eqimm(3));
  Expect.equals(3, eqimm(4));
  Expect.equals(7, eqimm(5));

  Expect.equals(3, neimm(3));
  Expect.equals(7, neimm(4));
  Expect.equals(3, neimm(5));

  Expect.equals(3, ltimm(3));
  Expect.equals(7, ltimm(4));
  Expect.equals(7, ltimm(5));

  Expect.equals(3, leimm(3));
  Expect.equals(3, leimm(4));
  Expect.equals(7, leimm(5));

  Expect.equals(7, gtimm(3));
  Expect.equals(7, gtimm(4));
  Expect.equals(3, gtimm(5));

  Expect.equals(7, geimm(3));
  Expect.equals(3, geimm(4));
  Expect.equals(3, geimm(5));
}

@pragma("vm:never-inline")
dynamic eqimm0(dynamic x) => x == 4 ? 1 : 0;
@pragma("vm:never-inline")
dynamic neimm0(dynamic x) => x != 4 ? 1 : 0;
@pragma("vm:never-inline")
dynamic ltimm0(dynamic x) => x < 4 ? 1 : 0;
@pragma("vm:never-inline")
dynamic leimm0(dynamic x) => x <= 4 ? 1 : 0;
@pragma("vm:never-inline")
dynamic gtimm0(dynamic x) => x > 4 ? 1 : 0;
@pragma("vm:never-inline")
dynamic geimm0(dynamic x) => x >= 4 ? 1 : 0;

testCompareImm0() {
  Expect.equals(0, eqimm0(3));
  Expect.equals(1, eqimm0(4));
  Expect.equals(0, eqimm0(5));

  Expect.equals(1, neimm0(3));
  Expect.equals(0, neimm0(4));
  Expect.equals(1, neimm0(5));

  Expect.equals(1, ltimm0(3));
  Expect.equals(0, ltimm0(4));
  Expect.equals(0, ltimm0(5));

  Expect.equals(1, leimm0(3));
  Expect.equals(1, leimm0(4));
  Expect.equals(0, leimm0(5));

  Expect.equals(0, gtimm0(3));
  Expect.equals(0, gtimm0(4));
  Expect.equals(1, gtimm0(5));

  Expect.equals(0, geimm0(3));
  Expect.equals(1, geimm0(4));
  Expect.equals(1, geimm0(5));
}

@pragma("vm:never-inline")
dynamic eqimmN(dynamic x) => x == 4 ? 1 : 4;
@pragma("vm:never-inline")
dynamic neimmN(dynamic x) => x != 4 ? 1 : 4;
@pragma("vm:never-inline")
dynamic ltimmN(dynamic x) => x < 4 ? 1 : 4;
@pragma("vm:never-inline")
dynamic leimmN(dynamic x) => x <= 4 ? 1 : 4;
@pragma("vm:never-inline")
dynamic gtimmN(dynamic x) => x > 4 ? 1 : 4;
@pragma("vm:never-inline")
dynamic geimmN(dynamic x) => x >= 4 ? 1 : 4;

testCompareImmN() {
  Expect.equals(4, eqimmN(3));
  Expect.equals(1, eqimmN(4));
  Expect.equals(4, eqimmN(5));

  Expect.equals(1, neimmN(3));
  Expect.equals(4, neimmN(4));
  Expect.equals(1, neimmN(5));

  Expect.equals(1, ltimmN(3));
  Expect.equals(4, ltimmN(4));
  Expect.equals(4, ltimmN(5));

  Expect.equals(1, leimmN(3));
  Expect.equals(1, leimmN(4));
  Expect.equals(4, leimmN(5));

  Expect.equals(4, gtimmN(3));
  Expect.equals(4, gtimmN(4));
  Expect.equals(1, gtimmN(5));

  Expect.equals(4, geimmN(3));
  Expect.equals(1, geimmN(4));
  Expect.equals(1, geimmN(5));
}

@pragma("vm:never-inline")
dynamic zr(dynamic x, dynamic y) => x & y == 0 ? 3 : 7;
@pragma("vm:never-inline")
dynamic nz(dynamic x, dynamic y) => x & y != 0 ? 3 : 7;

testTestReg() {
  Expect.equals(7, zr(3, 2));
  Expect.equals(7, zr(3, 3));
  Expect.equals(3, zr(3, 4));
  Expect.equals(3, zr(3, 8));

  Expect.equals(3, nz(3, 2));
  Expect.equals(3, nz(3, 3));
  Expect.equals(7, nz(3, 4));
  Expect.equals(7, nz(3, 8));
}

@pragma("vm:never-inline")
dynamic zr0(dynamic x, dynamic y) => x & y == 0 ? 1 : 0;
@pragma("vm:never-inline")
dynamic nz0(dynamic x, dynamic y) => x & y != 0 ? 1 : 0;

testTestReg0() {
  Expect.equals(0, zr0(3, 2));
  Expect.equals(0, zr0(3, 3));
  Expect.equals(1, zr0(3, 4));
  Expect.equals(1, zr0(3, 8));

  Expect.equals(1, nz0(3, 2));
  Expect.equals(1, nz0(3, 3));
  Expect.equals(0, nz0(3, 4));
  Expect.equals(0, nz0(3, 8));
}

@pragma("vm:never-inline")
dynamic zrN(dynamic x, dynamic y) => x & y == 0 ? 1 : 4;
@pragma("vm:never-inline")
dynamic nzN(dynamic x, dynamic y) => x & y != 0 ? 1 : 4;

testTestRegN() {
  Expect.equals(4, zrN(3, 2));
  Expect.equals(4, zrN(3, 3));
  Expect.equals(1, zrN(3, 4));
  Expect.equals(1, zrN(3, 8));

  Expect.equals(1, nzN(3, 2));
  Expect.equals(1, nzN(3, 3));
  Expect.equals(4, nzN(3, 4));
  Expect.equals(4, nzN(3, 8));
}

@pragma("vm:never-inline")
dynamic zrimm(dynamic x) => x & 4 == 0 ? 3 : 7;
@pragma("vm:never-inline")
dynamic nzimm(dynamic x) => x & 4 != 0 ? 3 : 7;

testTestImm() {
  Expect.equals(3, zrimm(3));
  Expect.equals(7, zrimm(4));
  Expect.equals(7, zrimm(5));

  Expect.equals(7, nzimm(3));
  Expect.equals(3, nzimm(4));
  Expect.equals(3, nzimm(5));
}

@pragma("vm:never-inline")
dynamic zrimm0(dynamic x) => x & 4 == 0 ? 1 : 0;
@pragma("vm:never-inline")
dynamic nzimm0(dynamic x) => x & 4 != 0 ? 1 : 0;

testTestImm0() {
  Expect.equals(1, zrimm0(3));
  Expect.equals(0, zrimm0(4));
  Expect.equals(0, zrimm0(5));

  Expect.equals(0, nzimm0(3));
  Expect.equals(1, nzimm0(4));
  Expect.equals(1, nzimm0(5));
}

@pragma("vm:never-inline")
dynamic zrimmN(dynamic x) => x & 4 == 0 ? 1 : 4;
@pragma("vm:never-inline")
dynamic nzimmN(dynamic x) => x & 4 != 0 ? 1 : 4;

testTestImmN() {
  Expect.equals(1, zrimmN(3));
  Expect.equals(4, zrimmN(4));
  Expect.equals(4, zrimmN(5));

  Expect.equals(4, nzimmN(3));
  Expect.equals(1, nzimmN(4));
  Expect.equals(1, nzimmN(5));
}

@pragma("vm:never-inline")
dynamic testN(dynamic x) => identical(x, null) ? 1 : 4;
@pragma("vm:never-inline")
dynamic testF(dynamic x) => identical(x, false) ? 1 : 4;
@pragma("vm:never-inline")
dynamic testT(dynamic x) => identical(x, true) ? 1 : 4;
@pragma("vm:never-inline")
dynamic testO(dynamic x) => identical(x, const Object()) ? 1 : 4;

testTempConflicts() {
  Expect.equals(1, testN(null));
  Expect.equals(4, testN(false));
  Expect.equals(4, testN(true));
  Expect.equals(4, testN(const Object()));

  Expect.equals(4, testF(null));
  Expect.equals(1, testF(false));
  Expect.equals(4, testF(true));
  Expect.equals(4, testF(const Object()));

  Expect.equals(4, testT(null));
  Expect.equals(4, testT(false));
  Expect.equals(1, testT(true));
  Expect.equals(4, testT(const Object()));

  Expect.equals(4, testO(null));
  Expect.equals(4, testO(false));
  Expect.equals(4, testO(true));
  Expect.equals(1, testO(const Object()));
}

main() {
  for (int i = 0; i < 200; i++) {
    testCompareReg();
    testCompareReg0();
    testCompareRegN();
    testCompareImm();
    testCompareImm0();
    testCompareImmN();
    testTestReg();
    testTestReg0();
    testTestRegN();
    testTestImm();
    testTestImm0();
    testTestImmN();
    testTempConflicts();
  }
}
