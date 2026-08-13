// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

int zero() {
  return 0;
}

int one() {
  return 1;
}

int minus1() {
  return 0 - 1;
}

int two() {
  return 2;
}

int three() {
  return 3;
}

int five() {
  return 5;
}

int minus5() {
  return 0 - 5;
}

int ninetyNine() {
  return 99;
}

int four99() {
  return 499;
}

int four99times99() {
  return 499 * 99;
}

int four99times99plus1() {
  return 499 * 99 + 1;
}

void addTest() {
  var m1 = 0 - 1;
  var x = 0;
  x += 0;
  Expect.equals(0, x);
  x += one();
  Expect.equals(1, x);
  x += m1;
  Expect.equals(0, x);
  x += 499;
  Expect.equals(499, x);
}

void subTest() {
  var m1 = 0 - 1;
  var x = 0;
  x -= 0;
  Expect.equals(0, x);
  x -= one();
  Expect.equals(m1, x);
  x -= m1;
  Expect.equals(0, x);
  x = 499;
  x -= one();
  x -= 98;
  Expect.equals(400, x);
}

void mulTest() {
  var m1 = 0 - 1;
  var x = 0;
  x *= 0;
  Expect.equals(0, x);
  x = one();
  x *= 1;
  Expect.equals(1, x);
  x *= four99();
  Expect.equals(499, x);
  x *= m1;
  Expect.equals(0 - 499, x);
}

void divTest() {
  var m1 = 0.0 - 1.0;
  var m2 = 0 - 2;
  num x = two();
  x /= 2;
  Expect.equals(1.0, x);
  x /= 2;
  Expect.equals(0.5, x);
  x = four99times99();
  x /= 99;
  Expect.equals(499.0, x);
}

void tdivTest() {
  var x = 3;
  x ~/= two();
  Expect.equals(1, x);
  x = 49402;
  x ~/= ninetyNine();
  Expect.equals(499, x);
}

void modTest() {
  var x = five();
  x %= 3;
  Expect.equals(2, x);
  x = 49402;
  x %= ninetyNine();
  Expect.equals(1, x);
}

void shlTest() {
  var x = five();
  x <<= 2;
  Expect.equals(20, x);
  x <<= 1;
  Expect.equals(40, x);
}

void shrTest() {
  var x = four99();
  x >>= 1;
  Expect.equals(249, x);
  x >>= 2;
  Expect.equals(62, x);
}

void andTest() {
  var x = five();
  x &= 3;
  Expect.equals(1, x);
  x &= 10;
  Expect.equals(0, x);
  x = four99();
  x &= 63;
  Expect.equals(51, x);
}

void orTest() {
  var x = five();
  x |= 2;
  Expect.equals(7, x);
  x |= 7;
  Expect.equals(7, x);
  x |= 10;
  Expect.equals(15, x);
  x |= 499;
  Expect.equals(511, x);
}

void xorTest() {
  var x = five();
  x ^= 2;
  Expect.equals(7, x);
  x ^= 7;
  Expect.equals(0, x);
  x ^= 10;
  Expect.equals(10, x);
  x ^= 499;
  Expect.equals(505, x);
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
}
