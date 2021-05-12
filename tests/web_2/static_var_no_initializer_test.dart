// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

int one;
int x;

void testOne() {
  Expect.equals(1, one);
}

void testX(var expected) {
  Expect.equals(expected, x);
}

void increaseX() {
  x = x + 1;
}

void main() {
  one = 1;
  x = 5;
  Expect.equals(1, one);
  testOne();
  Expect.equals(5, x);
  testX(5);
  x = x + 1;
  Expect.equals(6, x);
  testX(6);
  increaseX();
  Expect.equals(7, x);
  testX(7);
}
