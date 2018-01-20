// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B extends A {}

class B2 extends A {}

class C {
  void f(covariant B x) {}
}

abstract class I {
  void f(A x);
}

// This class does not require a forwarding stub; the interface of D.f is (A) ->
// void and the implementation has signature (covariant B) -> void.  The
// implementation satisfies the interface thanks to the presence of the
// "covariant" keyword.
class D extends C implements I {}

main() {
  var d = new D();
  I i = d;
  A a = new A();
  B b = new B();
  B2 b2Null = null;

  // The following two lines are statically ok because the type B2 is assignable
  // to the type A.  There should be no runtime error because the actual value
  // at runtime is `null`, which may be assigned to A.
  d.f(b2Null);
  i.f(b2Null);

  void Function(Object) g = d.f; // Ok; D.f reified as (Object) -> void
  Expect.throwsTypeError(() {
    d.f(a);
  });
  Expect.throwsTypeError(() {
    i.f(a);
  });
}
