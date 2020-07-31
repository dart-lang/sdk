// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test operation precedence.

library precedence_test;

import "package:expect/expect.dart";

main() {
  testBang();
  testIndexWithPrefixAdd();
  testIndexWithPostfixAdd();
  testTilde();
  testUnaryPrefixWithAdd();
  testUnaryPostfixWithAdd();
  testUnaryPrefixWithMultiply();
  testUnaryPostfixWithMultiply();
}

void testBang() {
  int x = 3;

  Expect.equals(!true == false, true);
  Expect.equals(!x.isEven, true);
  Expect.equals(!(++x).isEven, false);
  Expect.equals(x, 4);
  Expect.equals(!(x++).isEven, false);
  Expect.equals(x, 5);
}

void testIndexWithPrefixAdd() {
  var x = <int>[3];

  Expect.equals(++x[0] + 3, 7);
  Expect.equals(x[0], 4);
  Expect.equals(++x[0] - 3, 2);
  Expect.equals(x[0], 5);
  Expect.equals(--x[0] + 4, 8);
  Expect.equals(x[0], 4);
  Expect.equals(--x[0] - 4, -1);
  Expect.equals(x[0], 3);

  Expect.equals(3 + ++x[0], 7);
  Expect.equals(x[0], 4);
  Expect.equals(3 - ++x[0], -2);
  Expect.equals(x[0], 5);
  Expect.equals(4 + --x[0], 8);
  Expect.equals(x[0], 4);
  Expect.equals(4 - --x[0], 1);
  Expect.equals(x[0], 3);
}

void testIndexWithPostfixAdd() {
  var x = <int>[3];

  Expect.equals(x[0]++ + 3, 6);
  Expect.equals(x[0], 4);
  Expect.equals(x[0]++ - 3, 1);
  Expect.equals(x[0], 5);
  Expect.equals(x[0]-- + 4, 9);
  Expect.equals(x[0], 4);
  Expect.equals(x[0]-- - 4, 0);
  Expect.equals(x[0], 3);

  Expect.equals(3 + x[0]++, 6);
  Expect.equals(x[0], 4);
  Expect.equals(3 - x[0]++, -1);
  Expect.equals(x[0], 5);
  Expect.equals(4 + x[0]--, 9);
  Expect.equals(x[0], 4);
  Expect.equals(4 - x[0]--, 0);
  Expect.equals(x[0], 3);
}

void testTilde() {
  int x = 3;

  Expect.equals(~x.sign, ~(x.sign));
  Expect.equals(~x + 7, (~3) + 7);

  Expect.equals(~++x + 7, (~4) + 7);
  Expect.equals(x, 4);
  Expect.equals(~x++ + 7, (~4) + 7);
  Expect.equals(x, 5);

  Expect.equals(~ --x + 7, (~4) + 7);
  Expect.equals(x, 4);
  Expect.equals(~x-- + 7, (~4) + 7);
  Expect.equals(x, 3);
}

void testUnaryPrefixWithAdd() {
  int x = 3;

  Expect.equals(++x + 3, 7);
  Expect.equals(x, 4);
  Expect.equals(++x - 3, 2);
  Expect.equals(x, 5);
  Expect.equals(--x + 4, 8);
  Expect.equals(x, 4);
  Expect.equals(--x - 4, -1);
  Expect.equals(x, 3);

  Expect.equals(3 + ++x, 7);
  Expect.equals(x, 4);
  Expect.equals(3 - ++x, -2);
  Expect.equals(x, 5);
  Expect.equals(4 + --x, 8);
  Expect.equals(x, 4);
  Expect.equals(4 - --x, 1);
  Expect.equals(x, 3);
}

void testUnaryPostfixWithAdd() {
  int x = 3;

  Expect.equals(x++ + 3, 6);
  Expect.equals(x, 4);
  Expect.equals(x++ - 3, 1);
  Expect.equals(x, 5);
  Expect.equals(x-- + 4, 9);
  Expect.equals(x, 4);
  Expect.equals(x-- - 4, 0);
  Expect.equals(x, 3);

  Expect.equals(3 + x++, 6);
  Expect.equals(x, 4);
  Expect.equals(3 - x++, -1);
  Expect.equals(x, 5);
  Expect.equals(4 + x--, 9);
  Expect.equals(x, 4);
  Expect.equals(4 - x--, 0);
  Expect.equals(x, 3);
}

void testUnaryPrefixWithMultiply() {
  int x = 3;

  Expect.equals(++x * 3, 12);
  Expect.equals(x, 4);
  Expect.equals(++x / 5, 1.0);
  Expect.equals(x, 5);
  Expect.equals(--x * 3, 12);
  Expect.equals(x, 4);
  Expect.equals(--x / 4, 0.75);
  Expect.equals(x, 3);

  Expect.equals(3 * ++x, 12);
  Expect.equals(x, 4);
  Expect.equals(5 / ++x, 1.0);
  Expect.equals(x, 5);
  Expect.equals(3 * --x, 12);
  Expect.equals(x, 4);
  Expect.equals(6 / --x, 2.0);
  Expect.equals(x, 3);
}

void testUnaryPostfixWithMultiply() {
  int x = 3;

  Expect.equals(x++ * 3, 9);
  Expect.equals(x, 4);
  Expect.equals(x++ / 4, 1.0);
  Expect.equals(x, 5);
  Expect.equals(x-- * 3, 15);
  Expect.equals(x, 4);
  Expect.equals(x-- / 4, 1.0);
  Expect.equals(x, 3);

  Expect.equals(3 * x++, 9);
  Expect.equals(x, 4);
  Expect.equals(3 / x++, 0.75);
  Expect.equals(x, 5);
  Expect.equals(4 * x--, 20);
  Expect.equals(x, 4);
  Expect.equals(4 / x--, 1.0);
  Expect.equals(x, 3);
}
