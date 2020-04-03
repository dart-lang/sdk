// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for the "is" type test operator.

import "package:expect/expect.dart";

abstract class I {}

abstract class AI implements I {}

class A implements AI {
  const A();
}

class B implements I {
  const B();
}

class C extends A {
  const C() : super();
}

class IsOperatorTest {
  static testMain() {
    var a = new A();
    var b = new B();
    var c = new C();
    var n = null;
    Expect.equals(true, a is A);
    Expect.equals(false, a is! A);
    Expect.equals(true, b is B);
    Expect.equals(false, b is! B);
    Expect.equals(true, c is C);
    Expect.equals(false, c is! C);
    Expect.equals(true, c is A);
    Expect.equals(false, c is! A);

    Expect.equals(true, a is AI);
    Expect.equals(false, a is! AI);
    Expect.equals(true, a is I);
    Expect.equals(false, a is! I);
    Expect.equals(false, b is AI);
    Expect.equals(true, b is! AI);
    Expect.equals(true, b is I);
    Expect.equals(false, b is! I);
    Expect.equals(true, c is AI);
    Expect.equals(false, c is! AI);
    Expect.equals(true, c is I);
    Expect.equals(false, c is! I);
    Expect.equals(false, n is AI);
    Expect.equals(true, n is! AI);
    Expect.equals(false, n is I);
    Expect.equals(true, n is! I);

    Expect.equals(false, a is B);
    Expect.equals(true, a is! B);
    Expect.equals(false, a is C);
    Expect.equals(true, a is! C);
    Expect.equals(false, b is A);
    Expect.equals(true, b is! A);
    Expect.equals(false, b is C);
    Expect.equals(true, b is! C);
    Expect.equals(false, c is B);
    Expect.equals(true, c is! B);
    Expect.equals(false, n is A);
    Expect.equals(true, n is! A);

    Expect.equals(false, null is A);
    Expect.equals(false, null is B);
    Expect.equals(false, null is C);
    Expect.equals(false, null is AI);
    Expect.equals(false, null is I);

    Expect.equals(true, null is! A);
    Expect.equals(true, null is! B);
    Expect.equals(true, null is! C);
    Expect.equals(true, null is! AI);
    Expect.equals(true, null is! I);
  }
}

main() {
  IsOperatorTest.testMain();
}
