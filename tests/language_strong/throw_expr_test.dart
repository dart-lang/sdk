// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program for testing throw expressions.

void test1() {
  var x = 6;
  try {
    throw x = 10;
    x = 0;
  } catch (e) {
    Expect.equals(10, e);
    Expect.equals(10, x);
    x = 15;
  }
  Expect.equals(15, x);
  x = 100;
  try {
    throw x++;
    x = 0;
  } catch (e) {
    Expect.equals(100, e);
    Expect.equals(101, x);
    x = 150;
  }
  Expect.equals(150, x);
}

void test2() {
  var x = 6;
  try {
    throw x + 4;
  } catch (e) {
    Expect.equals(10, e);
    Expect.equals(6, x);
    x = 15;
  }
  Expect.equals(15, x);
}

foo(x, y) => throw "foo" "$x";

bar(x, y) => throw "foo" "${throw x}";

class Q {
  var qqq;
  f(x) {
    qqq = x;
  }

  Q get nono => throw "nono";
}

void test3() {
  try {
    throw throw throw "up";
  } catch (e) {
    Expect.equals("up", e);
  }

  var x = 10;
  try {
    foo(x = 12, throw 7);
  } catch (e) {
    Expect.equals(7, e);
    Expect.equals(12, x);
  }

  x = 10;
  try {
    foo(x++, 10);
  } catch (e) {
    Expect.equals("foo10", e);
    Expect.equals(11, x);
  }

  x = 100;
  try {
    bar(++x, 10);
  } catch (e) {
    Expect.equals(101, e);
    Expect.equals(101, x);
  }

  x = null;
  try {
    x = new Q();
    x
      ..f(11)
      ..qqq = throw 77
      ..f(22);
  } catch (e) {
    Expect.equals(77, e);
    Expect.equals(11, x.qqq);
  }
}

void test4() {
  var q = new Q();
  Expect.throws(() => q.nono, (e) => e == "nono");
}

main() {
  test1();
  test2();
  test3();
  test4();
}
