// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class I0 {}

class A {}

class B extends A implements I0 {}

class B2 extends A {}

class C {
  void f(B x) {}
}

abstract class I {
  void f(covariant A x);
}

// This class contains a forwarding stub for f to allow it to satisfy the
// interface I, while still ensuring that the x argument is type checked before
// C.f is executed.
//
// Super calls in a derived class resolve directly to C.f, and are type checked
// accordingly at compile time.
class D extends C implements I {}

class E extends D {
  void test() {
    I0 i0 = null;
    B2 b2 = null;

    // ok since I0 is assignable to B
    super.f(i0); //# 01: ok

    // not ok since B2 is not assignable to B
    super.f(b2); //# 02: compile-time error

    var superF = super.f; // Inferred type: (B) -> void

    // ok since I0 is assignable to B
    superF(i0); //# 03: ok

    // not ok since B2 is not assignable to B
    superF(b2); //# 04: compile-time error

    // Should pass since superF's runtime type is (B) -> void
    Expect.isTrue(superF is void Function(B)); //# 05: ok
    Expect.isTrue(superF is! void Function(I0)); //# 05: continued
    Expect.isTrue(superF is! void Function(A)); //# 05: continued
    Expect.isTrue(superF is! void Function(Object)); //# 05: continued
  }
}

main() {
  new E().test();
}
