// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests basic expressions. Does not attempt to validate the details of arithmetic, coercion, and
// so forth.
class ExpressionTest {
  ExpressionTest() {}

  int foo;

  static testMain() {
    var test = new ExpressionTest();
    test.testBinary();
    test.testUnary();
    test.testShifts();
    test.testBitwise();
    test.testIncrement();
    test.testMangling();
  }

  testBinary() {
    int x = 4, y = 2;
    Expect.equals(6, x + y);
    Expect.equals(2, x - y);
    Expect.equals(8, x * y);
    Expect.equals(2, x / y);
    Expect.equals(0, x % y);
  }

  testUnary() {
    int x = 4, y = 2, z = -5;
    bool t = true, f = false;
    Expect.equals(-4, -x);
    Expect.equals(4, ~z);
    Expect.equals(f, !t);
  }

  testShifts() {
    int x = 4, y = 2;
    Expect.equals(y, x >> 1);
    Expect.equals(x, y << 1);
  }

  testBitwise() {
    int x = 4, y = 2;
    Expect.equals(6, (x | y));
    Expect.equals(0, (x & y));
    Expect.equals(6, (x ^ y));
  }

  operator [](int index) {
    return foo;
  }

  operator []=(int index, int value) {
    foo = value;
  }

  testIncrement() {
    int x = 4, a = x++;
    Expect.equals(4, a);
    Expect.equals(5, x);
    Expect.equals(6, ++x);
    Expect.equals(6, x++);
    Expect.equals(7, x);
    Expect.equals(6, --x);
    Expect.equals(6, x--);
    Expect.equals(5, x);

    this.foo = 0;
    Expect.equals(0, this.foo++);
    Expect.equals(1, this.foo);
    Expect.equals(2, ++this.foo);
    Expect.equals(2, this.foo);
    Expect.equals(2, this.foo--);
    Expect.equals(1, this.foo);
    Expect.equals(0, --this.foo);
    Expect.equals(0, this.foo);

    Expect.equals(0, this[0]++);
    Expect.equals(1, this[0]);
    Expect.equals(2, ++this[0]);
    Expect.equals(2, this[0]);
    Expect.equals(2, this[0]--);
    Expect.equals(1, this[0]);
    Expect.equals(0, --this[0]);
    Expect.equals(0, this[0]);

    int $0 = 42, $1 = 87, $2 = 117;
    Expect.equals(42, $0++);
    Expect.equals(43, $0);
    Expect.equals(44, ++$0);
    Expect.equals(88, $0 += $0);
    Expect.equals(87, $1++);
    Expect.equals(88, $1);
    Expect.equals(89, ++$1);
    Expect.equals(178, ($1 += $1));
    Expect.equals(117, $2++);
    Expect.equals(118, $2);
    Expect.equals(119, ++$2);
  }

  void testMangling() {
    int $0 = 42, $1 = 87, $2 = 117;
    this[0] = 0;
    Expect.equals(42, (this[0] += $0));
    Expect.equals(129, (this[0] += $1));
    Expect.equals(246, (this[0] += $2));
  }
}

main() {
  ExpressionTest.testMain();
}
