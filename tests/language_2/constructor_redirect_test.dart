// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for redirection constructors.

import "package:expect/expect.dart";

class A {
  var x;
  A(this.x) {}
  A.named(x, int y) : this(x + y);
  A.named2(int x, int y, z) : this.named(staticFun(x, y), z);

  // The following is a bit tricky. It is a compile-time error to
  // refer to this (implicitly or explicitly) from an initializer.
  // When we remove the line with moreStaticFun, staticFun is really a
  // static function and it is legal to call it. This is what will
  // happen in the /none version of this test. However, in /01,
  // staticFun isn't really a static function and should cause a
  // compile-time error.
  static
  moreStaticFun() {} //# 01: compile-time error
      int staticFun(int v1, int v2) {
    return v1 * v2;
  }
}

class B extends A {
  B(y) : super(y + 1) {}
  B.named(y) : super.named(y, y + 1) {}
}

class C {
  final x;
  const C(this.x);
  const C.named(x, int y) : this(x + y);
}

class D extends C {
  const D(y) : super(y + 1);
  const D.named(y) : super.named(y, y + 1);
}

class ConstructorRedirectTest {
  static testMain() {
    var a = new A(499);
    Expect.equals(499, a.x);
    a = new A.named(349, 499);
    Expect.equals(349 + 499, a.x);
    a = new A.named2(11, 42, 99);
    Expect.equals(11 * 42 + 99, a.x);

    var b = new B(498);
    Expect.equals(499, b.x);
    b = new B.named(249);
    Expect.equals(499, b.x);

    C c = const C(499);
    Expect.equals(499, c.x);
    c = const C.named(249, 250);
    Expect.equals(499, c.x);

    D d = const D(498);
    Expect.equals(499, d.x);
    d = const D.named(249);
    Expect.equals(499, d.x);
  }
}

main() {
  ConstructorRedirectTest.testMain();
}
