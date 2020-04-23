// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B extends A {}

class C {
  void f(B x, B y) {}
}

abstract class I1 {
  void f(covariant A x, B y);
}

// D contains a forwarding stub for f which ensures that `x` is type checked.
class D extends C implements I1 {}

abstract class I2 {
  void f(B x, covariant A y);
}

// E contains a forwarding stub for f which ensures that `y` is type checked.
class E extends D implements I2 {
  void f(B x, B y);
}

main() {
  E e = new E();
  C c = e;
  I1 i1 = e;
  D d = e;
  I2 i2 = e;
  A a = new A();
  B b = new B();
  c.f(b, b); // No error
  i1.f(b, b); // No error
  d.f(b, b); // No error
  i2.f(b, b); // No error
  e.f(b, b); // No error
  Expect.throwsTypeError(() {
    i1.f(a, b);
  });
  Expect.throwsTypeError(() {
    d.f(a, b);
  });
  Expect.throwsTypeError(() {
    i2.f(b, a);
  });
  Expect.throwsTypeError(() {
    e.f(a, b);
  });
  Expect.throwsTypeError(() {
    e.f(b, a);
  });
}
