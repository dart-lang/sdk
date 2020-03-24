// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

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

void postPlusPlusTest() {
  var x = zero();
  var y = x++;
  Expect.equals(0, y);
  Expect.equals(1, x);
  Expect.equals(1, x++);
  Expect.equals(2, x);
}

void prePlusPlusTest() {
  var x = zero();
  var y = ++x;
  Expect.equals(1, x);
  Expect.equals(1, y);
  Expect.equals(2, ++x);
  Expect.equals(2, ++y);
}

void postMinusMinusTest() {
  var x = four99();
  var y = x--;
  Expect.equals(499, y);
  Expect.equals(498, x);
  Expect.equals(498, x--);
  Expect.equals(497, x);
}

void preMinusMinusTest() {
  var x = four99();
  var y = --x;
  Expect.equals(498, y);
  Expect.equals(498, x);
  Expect.equals(497, --x);
  Expect.equals(497, x);
}

void main() {
  postPlusPlusTest();
  prePlusPlusTest();
  postMinusMinusTest();
  preMinusMinusTest();
}
