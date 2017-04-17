// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test for new function type alias.

import "package:expect/expect.dart";

class FunctionLiteralsTest {
  static void testMain() {
    f(x) {
      return x * 2;
    }

    f(42); // make sure it is parsed as a function call
    Expect.equals(20, f(10));

    int g(x) {
      return x * 2;
    }

    g(42); // make sure it is parsed as a function call
    Expect.equals(20, g(10));

    h(x) {
      return x * 2;
    }

    h(42); // make sure it is parsed as a function call
    Expect.equals(20, h(10));

    var a = (x) {
      return x + 2;
    };
    Expect.equals(7, a(5));

    Expect.equals(
        10,
        apply((k) {
          return k << 1;
        }, 5));
    Expect.equals(20, apply((k) => k << 1, 10));

    a = new A(3);
    Expect.equals(-1, a.f);
    Expect.equals(-3, a.f2);

    a = new A.n(5);
    Expect.equals(-2, a.f);
    Expect.equals(2, a.f2);

    Expect.equals(true, isOdd(5));
    Expect.equals(false, isOdd(8));

    var b = new B(10);
    Expect.equals(10, b.n);
    Expect.equals(100, (b.f)(10));

    b = new B.withZ(10);
    Expect.equals(10, b.n);
    Expect.equals(101, (b.f)(10));

    var c = new C(5);
    Expect.equals("2*x is 10", c.s);

    int x = 0;
    int y = 1;
    // make sure this isn't parsed as a generic type
    Expect.isTrue(x < y, "foo");
  }
}

apply(f, n) {
  return f(n);
}

bool isOdd(b) => b % 2 == 1;

class A {
  int f;
  int f2;
  A(p) : f = apply((j) => 2 - j, p) {
    /* constr. body */
    f2 = -p;
  }
  A.n(p) : f = 1 + apply((j) => 2 - j, p) {
    /* constr. body */
    f2 = -f;
  }
}

class B {
  var f;
  int n;
  B(z) : f = ((x) => x * x) {
    n = z;
  }
  B.withZ(z)
      : f = ((x) {
          return x * x + 1;
        }) {
    n = z;
  }
}

class C {
  String s;
  C(x) : s = "2*x is ${() { return 2*x; }()}";
}

main() {
  FunctionLiteralsTest.testMain();
}
