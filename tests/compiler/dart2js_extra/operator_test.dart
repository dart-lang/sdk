// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int zero() { return 0; }
int one() { return 1; }
int minus1() { return 0 - 1; }
int two() { return 2; }
int three() { return 3; }
int five() { return 5; }
int minus5() { return 0 - 5; }
int ninetyNine() { return 99; }
int four99() { return 499; }
int four99times99() { return 499 * 99; }
int four99times99plus1() { return 499 * 99 + 1; }

void addTest() {
  var m1 = 0 - 1;
  Expect.equals(0, 0 + 0);
  Expect.equals(m1, m1 + 0);
  Expect.equals(0, m1 + 1);
  Expect.equals(499, 400 + 99);
  Expect.equals(1, 0 + one());
  Expect.equals(1, one() + 0);
  Expect.equals(2, one() + one());
}

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

void divTest() {
  var m1 = 0.0 - 1.0;
  var m2 = 0 - 2;
  Expect.equals(1.0, 2 / 2);
  Expect.equals(m1, m2 / 2);
  Expect.equals(0.5, 1 / 2);
  Expect.equals(499.0, 49401 / 99);

  Expect.equals(1.0, two() / 2);
  Expect.equals(1.0, 2 / two());
  Expect.equals(m1, m2 / two());
  Expect.equals(m1, two() / m2);
  Expect.equals(0.5, 1 / two());
  Expect.equals(0.5, one() / 2);
  Expect.equals(499.0, four99times99() / 99);
}

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
}

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

void shlTest() {
  Expect.equals(2, 1 << 1);
  Expect.equals(8, 1 << 3);
  Expect.equals(6, 3 << 1);

  Expect.equals(10, five() << 1);
  Expect.equals(24, 3 << three());
}

void shrTest() {
  Expect.equals(1, 2 >> 1);
  Expect.equals(1, 8 >> 3);
  Expect.equals(3, 6 >> 1);

  var x = 0 - ninetyNine();
  Expect.equals(6, ninetyNine() >> 4);
}

void andTest() {
  Expect.equals(2, 10 & 3);
  Expect.equals(7, 15 & 7);
  Expect.equals(10, 10 & 10);

  Expect.equals(99, ninetyNine() & ninetyNine());
  Expect.equals(34, four99() & 42);
  Expect.equals(3, minus5() & 7);
}

void orTest() {
  Expect.equals(11, 10 | 3);
  Expect.equals(15, 15 | 7);
  Expect.equals(10, 10 | 10);

  Expect.equals(99, ninetyNine() | ninetyNine());
  Expect.equals(507, four99() | 42);
}

void xorTest() {
  Expect.equals(9, 10 ^ 3);
  Expect.equals(8, 15 ^ 7);
  Expect.equals(0, 10 ^ 10);

  Expect.equals(0, ninetyNine() ^ ninetyNine());
  Expect.equals(473, four99() ^ 42);
  Expect.equals(0, minus5() ^ -5);
  Expect.equals(6, minus5() ^ -3);
}

void notTest() {
  Expect.equals(4, ~minus5());
}

void negateTest() {
  Expect.equals(minus5(), -5);
  Expect.equals(-5, -five());
  Expect.equals(5, -minus5());
  var x = 3;
  if (false) x = 5;
  Expect.equals(-3, -x);
  var y = -5;
  Expect.equals(8, x - y);
}

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
}

void lessEqualTest() {
  var m1 = minus1();
  Expect.equals(true, 1 <= 2);
  Expect.equals(false, 2 <= 1);
  Expect.equals(true, 1 <= 1);

  Expect.equals(true, 0 <= 1);
  Expect.equals(false, 1 <= 0);
  Expect.equals(true, 0 <= 0);

  Expect.equals(true, one() <= 2);
  Expect.equals(false, 2 <= one());
  Expect.equals(true, 1 <= one());

  Expect.equals(true, 0 <= one());
  Expect.equals(false, one() <= 0);
  Expect.equals(true, 0 <= 0);

  Expect.equals(true, m1 <= 0);
  Expect.equals(false, 0 <= m1);
  Expect.equals(true, m1 <= m1);
}

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
}

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
}

void main() {
  addTest();
  subTest();
  mulTest();
  divTest();
  tdivTest();
  modTest();
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
