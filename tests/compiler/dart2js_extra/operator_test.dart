// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

@NoInline()
@AssumeDynamic()
confuse(x) => x;

@NoInline()
asNum(x) {
  var result = confuse(x);
  if (result is num) return result;
  throw new ArgumentError.value(x);
}

@NoInline()
uint31(x) {
  var result = confuse(x);
  if (x is int) {
    var masked = 0x7fffffff & x; // inferred uint31 type.
    if (masked == x) return masked;
  }
  throw new ArgumentError('Not uint31: $x');
}

@NoInline()
uint32(x) {
  var result = confuse(x);
  if (x is int) {
    var masked = 0xffffffff & x; // inferred uint32 type.
    if (masked == x) return masked;
  }
  throw new ArgumentError('Not uint32: $x');
}

@NoInline()
int zero() {
  return 0;
}

@NoInline()
int one() {
  return 1;
}

@NoInline()
int minus1() {
  return 0 - 1;
}

@NoInline()
int minus2() {
  return 0 - 2;
}

@NoInline()
int two() {
  return 2;
}

@NoInline()
int three() {
  return 3;
}

@NoInline()
int five() {
  return 5;
}

@NoInline()
int minus5() {
  return 0 - 5;
}

@NoInline()
int ninetyNine() {
  return 99;
}

@NoInline()
int four99() {
  return 499;
}

@NoInline()
int four99times99() {
  return 499 * 99;
}

@NoInline()
int four99times99plus1() {
  return 499 * 99 + 1;
}

@NoInline()
void addTest() {
  var m1 = 0 - 1;
  Expect.equals(0, 0 + 0);
  Expect.equals(0, confuse(0) + 0);
  Expect.equals(0, asNum(0) + 0);
  Expect.equals(0, uint31(0) + 0);

  Expect.equals(m1, m1 + 0);
  Expect.equals(0, m1 + 1);
  Expect.equals(499, 400 + 99);
  Expect.equals(1, 0 + one());
  Expect.equals(1, one() + 0);
  Expect.equals(2, one() + one());
}

@NoInline()
void subTest() {
  var m1 = 0 - 1;
  Expect.equals(0, 0 - 0);
  Expect.equals(m1, 0 - 1);
  Expect.equals(0, 1 - 1);
  Expect.equals(400, 499 - 99);
  Expect.equals(m1, 0 - one());
  Expect.equals(1, one() - 0);
  Expect.equals(0, one() - one());
}

@NoInline()
void mulTest() {
  var m1 = 0 - 1;
  Expect.equals(0, 0 * 0);
  Expect.equals(m1, m1 * 1);
  Expect.equals(1, 1 * 1);
  Expect.equals(49401, 499 * 99);
  Expect.equals(499, 499 * one());
  Expect.equals(499, one() * 499);
  Expect.equals(49401, four99() * 99);
}

@NoInline()
void divTest() {
  var m1 = 0.0 - 1.0;
  var m2 = 0 - 2;
  Expect.equals(1.0, 2 / 2);
  Expect.equals(m1, m2 / 2);
  Expect.equals(m1, minus2() / 2);
  Expect.equals(0.5, 1 / 2);
  Expect.equals(499.0, 49401 / 99);

  Expect.equals(1.0, two() / 2);
  Expect.equals(1.0, 2 / two());
  Expect.equals(m1, m2 / two());
  Expect.equals(m1, minus2() / two());
  Expect.equals(m1, two() / m2);
  Expect.equals(m1, two() / minus2());
  Expect.equals(0.5, 1 / two());
  Expect.equals(0.5, one() / 2);
  Expect.equals(499.0, four99times99() / 99);

  Expect.equals(1.5, confuse(150) / confuse(100));
}

@NoInline()
void tdivTest() {
  var m1 = 0 - 1;
  var m2 = 0 - 2;
  Expect.equals(1, 2 ~/ 2);
  Expect.equals(m1, m2 ~/ 2);
  Expect.equals(0, 1 ~/ 2);
  Expect.equals(0, m1 ~/ 2);
  Expect.equals(499, 49401 ~/ 99);
  Expect.equals(499, 49402 ~/ 99);

  Expect.equals(1, two() ~/ 2);
  Expect.equals(1, 2 ~/ two());
  Expect.equals(m1, m2 ~/ two());
  Expect.equals(m1, two() ~/ m2);
  Expect.equals(0, 1 ~/ two());
  Expect.equals(0, one() ~/ 2);
  Expect.equals(499, four99times99() ~/ 99);
  Expect.equals(499, four99times99plus1() ~/ 99);

  Expect.equals(-33, -100 ~/ 3);
  Expect.equals(-33, asNum(-100) ~/ 3);
  Expect.equals(33, -100 ~/ -3);
  Expect.equals(33, asNum(-100) ~/ -3);

  // Signed int32 boundary is involved in optimizations.

  Expect.equals(-0x80000000, -0x80000000 ~/ 1.0);
  Expect.equals(-0x80000000, -0x80000000 ~/ 1.0000000000000001);
  Expect.equals(-0x7fffffff, -0x80000000 ~/ 1.0000000000000002);

  Expect.equals(-0x80000000, asNum(-0x80000000) ~/ 1.0);
  Expect.equals(-0x80000000, asNum(-0x80000000) ~/ 1.0000000000000001);
  Expect.equals(-0x7fffffff, asNum(-0x80000000) ~/ 1.0000000000000002);

  Expect.equals(-0x80000000, asNum(0x80000000) ~/ -1.0);
  Expect.equals(-0x80000000, asNum(0x80000000) ~/ -1.0000000000000001);
  Expect.equals(-0x7fffffff, asNum(0x80000000) ~/ -1.0000000000000002);

  Expect.equals(0x7fffffff, 0x10000000 ~/ .12500000000000002);
  Expect.equals(0x80000000, 0x10000000 ~/ .125);
  Expect.equals(-0x7fffffff, 0x10000000 ~/ -.12500000000000002);
  Expect.equals(-0x80000000, 0x10000000 ~/ -.125);

  Expect.equals(0x7fffffff, uint31(0x10000000) ~/ .12500000000000002);
  Expect.equals(0x80000000, uint31(0x10000000) ~/ .125);
  Expect.equals(-0x7fffffff, uint31(0x10000000) ~/ -.12500000000000002);
  Expect.equals(-0x80000000, uint31(0x10000000) ~/ -.125);

  // These can be compiled to `(a / 2) | 0`.
  Expect.equals(100, uint31(200) ~/ 2);
  Expect.equals(100, uint32(200) ~/ 2);

  Expect.equals(100, asNum(200) ~/ 2);
  Expect.equals(100, confuse(200) ~/ 2);
  Expect.equals(-100, uint31(200) ~/ -2);
  Expect.equals(-100, uint32(200) ~/ -2);
  Expect.equals(-100, asNum(200) ~/ -2);
  Expect.equals(-100, confuse(200) ~/ -2);

  // These can be compiled to `((a + b) / 2) | 0`.
  Expect.equals(100, (uint31(100) + uint31(100)) ~/ 2);
  Expect.equals(0x7fffffff, (uint31(0x7fffffff) + uint31(0x7fffffff)) ~/ 2);

  // NaN and Infinity results are errors.
  Expect.throws(() => -1 ~/ 0);
  Expect.throws(() => 1.5 ~/ 0);
  Expect.throws(() => 1e200 ~/ 1e-200);
  Expect.throws(() => -1e200 ~/ 1e-200);
  Expect.throws(() => 1e200 ~/ -1e-200);
  Expect.throws(() => -1e200 ~/ -1e-200);
  Expect.throws(() => double.nan ~/ 2);
}

@NoInline()
void modTest() {
  var m5 = 0 - 5;
  var m3 = 0 - 3;
  Expect.equals(2, 5 % 3);
  Expect.equals(0, 49401 % 99);
  Expect.equals(1, 49402 % 99);
  Expect.equals(1, m5 % 3);
  Expect.equals(2, 5 % m3);

  Expect.equals(2, five() % 3);
  Expect.equals(2, 5 % three());
  Expect.equals(0, four99times99() % 99);
  Expect.equals(1, four99times99plus1() % 99);
  Expect.equals(1, minus5() % 3);
  Expect.equals(2, five() % m3);
}

@NoInline()
void remainderTest() {
  var m5 = 0 - 5;
  Expect.equals(2, confuse(5).remainder(3));
  Expect.equals(0, confuse(49401).remainder(99));
  Expect.equals(1, confuse(49402).remainder(99));
  Expect.equals(-2, confuse(m5).remainder(3));
  Expect.equals(2, confuse(5).remainder(-3));

  Expect.equals(2, uint32(5).remainder(3));
  Expect.equals(0, uint32(49401).remainder(99));
  Expect.equals(1, uint32(49402).remainder(99));
  Expect.equals(-2, (-5).remainder(uint32(3)));
  Expect.equals(2, uint32(5).remainder(-3));

  Expect.equals(2, 5.remainder(3));
  Expect.equals(0, 49401.remainder(99));
  Expect.equals(1, 49402.remainder(99));
  Expect.equals(-2, (-5).remainder(3));
  Expect.equals(2, 5.remainder(-3));

  Expect.equals(2, five().remainder(3));
  Expect.equals(2, 5.remainder(three()));
  Expect.equals(0, four99times99().remainder(99));
  Expect.equals(1, four99times99plus1().remainder(99));
  Expect.equals(-2, minus5().remainder(3));
  Expect.equals(2, five().remainder(-3));
}

@NoInline()
void shlTest() {
  Expect.equals(2, 1 << 1);
  Expect.equals(8, 1 << 3);
  Expect.equals(6, 3 << 1);

  Expect.equals(10, five() << 1);
  Expect.equals(24, 3 << three());

  Expect.equals(10, confuse(5) << 1);
  Expect.equals(24, 3 << confuse(3));

  Expect.equals(10, uint31(5) << 1);
  Expect.equals(24, 3 << uint31(3));

  Expect.equals(10, asNum(5) << 1);
  Expect.equals(24, 3 << asNum(3));
}

@NoInline()
void shrTest() {
  Expect.equals(1, 2 >> 1);
  Expect.equals(1, 8 >> 3);
  Expect.equals(3, 6 >> 1);

  Expect.equals(6, ninetyNine() >> 4);
  Expect.equals(6, confuse(99) >> 4);
  Expect.equals(6, asNum(99) >> 4);
  Expect.equals(6, uint31(99) >> 4);

  Expect.equals(6, 99 >> 4);
  Expect.equals(6, 99 >> confuse(4));
  Expect.equals(6, 99 >> asNum(4));
  Expect.equals(6, 99 >> uint31(4));

  Expect.equals(0, uint31(1) >> 31);
  Expect.equals(0, asNum(0xffffffff) >> 32);
}

@NoInline()
void andTest() {
  Expect.equals(2, 10 & 3);
  Expect.equals(7, 15 & 7);
  Expect.equals(10, 10 & 10);

  Expect.equals(99, ninetyNine() & ninetyNine());
  Expect.equals(34, four99() & 42);
  Expect.equals(3, minus5() & 7);

  Expect.equals(0, uint31(0x7ffffffe) & uint31(1));
  Expect.equals(0, asNum(0x7ffffffe) & asNum(1));
}

@NoInline()
void orTest() {
  Expect.equals(11, 10 | 3);
  Expect.equals(15, 15 | 7);
  Expect.equals(10, 10 | 10);

  Expect.equals(99, ninetyNine() | ninetyNine());
  Expect.equals(507, four99() | 42);

  Expect.equals(11, asNum(10) | 3);
  Expect.equals(15, asNum(15) | 7);
  Expect.equals(10, asNum(10) | 10);
}

@NoInline()
void xorTest() {
  Expect.equals(9, 10 ^ 3);
  Expect.equals(8, 15 ^ 7);
  Expect.equals(0, 10 ^ 10);

  Expect.equals(0, ninetyNine() ^ ninetyNine());
  Expect.equals(473, four99() ^ 42);
  Expect.equals(0, minus5() ^ -5);
  Expect.equals(6, minus5() ^ -3);
}

@NoInline()
void notTest() {
  Expect.equals(4, ~minus5());
}

@NoInline()
void negateTest() {
  Expect.equals(minus5(), -5);
  Expect.equals(-5, -five());
  Expect.equals(5, -minus5());

  Expect.equals(-3, -confuse(3));
  Expect.equals(-3, -asNum(3));
  Expect.equals(-3, -uint31(3));

  Expect.equals(3, -confuse(-3));
  Expect.equals(3, -asNum(-3));
}

@NoInline()
void equalsTest() {
  // Equality of normal numbers is already well tested with "Expect.equals".
  Expect.equals(true, true == true);
  Expect.equals(true, false == false);
  Expect.equals(true, 0 == 0);
  Expect.equals(true, null == null);

  Expect.equals(false, 1 == 2);
  Expect.equals(false, 1 == "foo");
  Expect.equals(false, 1 == true);
  Expect.equals(false, 1 == false);
  Expect.equals(false, false == "");
  Expect.equals(false, false == 0);
  Expect.equals(false, false == null);
  Expect.equals(false, "" == false);
  Expect.equals(false, 0 == false);
  Expect.equals(false, null == false);

  var falseValue = false;
  var trueValue = true;
  var nullValue = null;
  if (one() == 2) {
    falseValue = true;
    trueValue = false;
    nullValue = 5;
  }

  Expect.equals(true, true == trueValue);
  Expect.equals(true, false == falseValue);
  Expect.equals(true, 1 == one());
  Expect.equals(true, null == nullValue);
  Expect.equals(false, one() == 2);
  Expect.equals(false, one() == "foo");
  Expect.equals(false, one() == true);
  Expect.equals(false, one() == false);
  Expect.equals(false, falseValue == "");
  Expect.equals(false, falseValue == 0);
  Expect.equals(false, falseValue == null);
  Expect.equals(false, "" == falseValue);
  Expect.equals(false, 0 == falseValue);
  Expect.equals(false, null == falseValue);
}

@NoInline()
void lessTest() {
  var m1 = minus1();
  Expect.equals(true, 1 < 2);
  Expect.equals(false, 2 < 1);
  Expect.equals(false, 1 < 1);

  Expect.equals(true, 0 < 1);
  Expect.equals(false, 1 < 0);
  Expect.equals(false, 0 < 0);

  Expect.equals(true, one() < 2);
  Expect.equals(false, 2 < one());
  Expect.equals(false, 1 < one());

  Expect.equals(true, 0 < one());
  Expect.equals(false, one() < 0);
  Expect.equals(false, 0 < 0);

  Expect.equals(true, m1 < 0);
  Expect.equals(false, 0 < m1);
  Expect.equals(false, m1 < m1);

  Expect.equals(true, minus1() < 0);
  Expect.equals(false, 0 < minus1());
  Expect.equals(false, minus1() < minus1());
}

@NoInline()
void lessEqualTest() {
  var m1 = minus1();
  Expect.equals(true, 1 <= 2);
  Expect.equals(false, 2 <= 1);
  Expect.equals(true, 1 <= 1);

  Expect.equals(true, 0 <= 1);
  Expect.equals(false, 1 <= 0);
  Expect.equals(true, 0 <= 0);

  Expect.equals(true, confuse(1) <= 2);
  Expect.equals(false, confuse(2) <= 1);
  Expect.equals(true, confuse(1) <= 1);

  Expect.equals(true, confuse(0) <= 1);
  Expect.equals(false, confuse(1) <= 0);
  Expect.equals(true, confuse(0) <= 0);

  Expect.equals(true, one() <= 2);
  Expect.equals(false, 2 <= one());
  Expect.equals(true, 1 <= one());

  Expect.equals(true, 0 <= one());
  Expect.equals(false, one() <= 0);
  Expect.equals(true, 0 <= 0);

  Expect.equals(true, m1 <= 0);
  Expect.equals(false, 0 <= m1);
  Expect.equals(true, m1 <= m1);

  Expect.equals(true, minus1() <= 0);
  Expect.equals(false, 0 <= minus1());
  Expect.equals(true, minus1() <= minus1());
}

@NoInline()
void greaterTest() {
  var m1 = minus1();
  Expect.equals(false, 1 > 2);
  Expect.equals(true, 2 > 1);
  Expect.equals(false, 1 > 1);

  Expect.equals(false, 0 > 1);
  Expect.equals(true, 1 > 0);
  Expect.equals(false, 0 > 0);

  Expect.equals(false, one() > 2);
  Expect.equals(true, 2 > one());
  Expect.equals(false, 1 > one());

  Expect.equals(false, 0 > one());
  Expect.equals(true, one() > 0);
  Expect.equals(false, 0 > 0);

  Expect.equals(false, m1 > 0);
  Expect.equals(true, 0 > m1);
  Expect.equals(false, m1 > m1);

  Expect.equals(false, minus1() > 0);
  Expect.equals(true, 0 > minus1());
  Expect.equals(false, minus1() > minus1());
}

@NoInline()
void greaterEqualTest() {
  var m1 = minus1();
  Expect.equals(false, 1 >= 2);
  Expect.equals(true, 2 >= 1);
  Expect.equals(true, 1 >= 1);

  Expect.equals(false, 0 >= 1);
  Expect.equals(true, 1 >= 0);
  Expect.equals(true, 0 >= 0);

  Expect.equals(false, one() >= 2);
  Expect.equals(true, 2 >= one());
  Expect.equals(true, 1 >= one());

  Expect.equals(false, 0 >= one());
  Expect.equals(true, one() >= 0);
  Expect.equals(true, 0 >= 0);

  Expect.equals(false, m1 >= 0);
  Expect.equals(true, 0 >= m1);
  Expect.equals(true, m1 >= m1);

  Expect.equals(false, minus1() >= 0);
  Expect.equals(true, 0 >= minus1());
  Expect.equals(true, minus1() >= minus1());
}

void main() {
  addTest();
  subTest();
  mulTest();
  divTest();
  tdivTest();
  modTest();
  remainderTest();
  shlTest();
  shrTest();
  andTest();
  orTest();
  xorTest();
  notTest();
  negateTest();
  equalsTest();
  lessTest();
  lessEqualTest();
  greaterTest();
  greaterEqualTest();
}
