// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--assert_initializer
//
// Dart test program testing assert statements.

import "package:expect/expect.dart";

class C {
  static bool check(x, y) => x < y;
  static bool staticTrue() => true;
  final int x;
  const C(this.x);

  C.c01(this.x, y) : assert(x < y);
  C.c02(x, y) : x = x, assert(x < y);
  C.c03(x, y) : assert(x < y), x = x;
  C.c04(this.x, y) : super(), assert(x < y);
  C.c05(this.x, y) : assert(x < y), super();
  C.c06(x, y) : x = x, super(), assert(x < y);
  C.c07(x, y) : assert(x < y), super(), x = x;
  C.c08(x, y) : assert(x < y), super(), x = x, assert(y > x);
  C.c09(this.x, y) : assert(x < y, "$x < $y");
  C.c10(this.x, y) : assert(x < y,);
  C.c11(this.x, y) : assert(x < y, "$x < $y",);

  const C.cc01(this.x, y) : assert(x < y);
  const C.cc02(x, y) : x = x, assert(x < y);
  const C.cc03(x, y) : assert(x < y), x = x;
  const C.cc04(this.x, y) : super(), assert(x < y);
  const C.cc05(this.x, y) : assert(x < y), super();
  const C.cc06(x, y) : x = x, super(), assert(x < y);
  const C.cc07(x, y) : assert(x < y), super(), x = x;
  const C.cc08(x, y) : assert(x < y), super(), x = x, assert(y > x);
  const C.cc09(this.x, y) : assert(x < y, "$x < $y");
  const C.cc10(this.x, y) : assert(x < y,);
  const C.cc11(this.x, y) : assert(x < y, "$x < $y",);

  C.nc01(this.x, y) : assert(check(x, y));
  C.nc02(x, y) : x = x, assert(check(x, y));
  C.nc03(x, y) : assert(check(x, y)), x = x;
  C.nc04(this.x, y) : super(), assert(check(x, y));
  C.nc05(this.x, y) : assert(check(x, y)), super();
  C.nc06(x, y) : x = x, super(), assert(check(x, y));
  C.nc07(x, y) : assert(check(x, y)), super(), x = x;
  C.nc08(x, y) : assert(check(x, y)), super(), x = x, assert(y > x);
  C.nc09(this.x, y) : assert(check(x, y), "$x < $y");
  C.nc10(this.x, y) : assert(check(x, y),);
  C.nc11(this.x, y) : assert(check(x, y), "$x < $y",);

  C.fc01(this.x, y) : assert(() => x < y);
  C.fc02(x, y) : x = x, assert(() => x < y);
  C.fc03(x, y) : assert(() => x < y), x = x;
  C.fc04(this.x, y) : super(), assert(() => x < y);
  C.fc05(this.x, y) : assert(() => x < y), super();
  C.fc06(x, y) : x = x, super(), assert(() => x < y);
  C.fc07(x, y) : assert(() => x < y), super(), x = x;
  C.fc08(x, y) : assert(() => x < y), super(), x = x, assert(y > x);
  C.fc09(this.x, y) : assert(() => x < y, "$x < $y");
  C.fc10(this.x, y) : assert(() => x < y,);
  C.fc11(this.x, y) : assert(() => x < y, "$x < $y",);
}


main() {
  // Test all constructors with both succeeding and failing asserts.
  test(1, 2);
  test(2, 1);

  const c1 = const C(1);

  // Asserts do not affect canonization.
  Expect.identical(c1, const C.cc01(1, 2));
  Expect.identical(c1, const C.cc02(1, 2));
  Expect.identical(c1, const C.cc03(1, 2));
  Expect.identical(c1, const C.cc04(1, 2));
  Expect.identical(c1, const C.cc05(1, 2));
  Expect.identical(c1, const C.cc06(1, 2));
  Expect.identical(c1, const C.cc07(1, 2));
  Expect.identical(c1, const C.cc08(1, 2));
  Expect.identical(c1, const C.cc09(1, 2));
  Expect.identical(c1, const C.cc10(1, 2));
  Expect.identical(c1, const C.cc11(1, 2));
}

void test(int x, int y) {
  bool assertionsEnabled = false;
  assert(assertionsEnabled = true);

  bool Function(C Function()) doTest = (assertionsEnabled && x >= y)
    ? (f) { Expect.throwsAssertionError(f); }
    : (f) { Expect.equals(x, f().x); };

  doTest(() => new C.c01(x, y));
  doTest(() => new C.c02(x, y));
  doTest(() => new C.c03(x, y));
  doTest(() => new C.c04(x, y));
  doTest(() => new C.c05(x, y));
  doTest(() => new C.c06(x, y));
  doTest(() => new C.c07(x, y));
  doTest(() => new C.c08(x, y));
  doTest(() => new C.c09(x, y));
  doTest(() => new C.c10(x, y));
  doTest(() => new C.c11(x, y));
  doTest(() => new C.cc01(x, y));
  doTest(() => new C.cc02(x, y));
  doTest(() => new C.cc03(x, y));
  doTest(() => new C.cc04(x, y));
  doTest(() => new C.cc05(x, y));
  doTest(() => new C.cc06(x, y));
  doTest(() => new C.cc07(x, y));
  doTest(() => new C.cc08(x, y));
  doTest(() => new C.cc09(x, y));
  doTest(() => new C.cc10(x, y));
  doTest(() => new C.cc11(x, y));
  doTest(() => new C.nc01(x, y));
  doTest(() => new C.nc02(x, y));
  doTest(() => new C.nc03(x, y));
  doTest(() => new C.nc04(x, y));
  doTest(() => new C.nc05(x, y));
  doTest(() => new C.nc06(x, y));
  doTest(() => new C.nc07(x, y));
  doTest(() => new C.nc08(x, y));
  doTest(() => new C.nc09(x, y));
  doTest(() => new C.nc10(x, y));
  doTest(() => new C.nc11(x, y));
  doTest(() => new C.fc01(x, y));
  doTest(() => new C.fc02(x, y));
  doTest(() => new C.fc03(x, y));
  doTest(() => new C.fc04(x, y));
  doTest(() => new C.fc05(x, y));
  doTest(() => new C.fc06(x, y));
  doTest(() => new C.fc07(x, y));
  doTest(() => new C.fc08(x, y));
  doTest(() => new C.fc09(x, y));
  doTest(() => new C.fc10(x, y));
  doTest(() => new C.fc11(x, y));
}

