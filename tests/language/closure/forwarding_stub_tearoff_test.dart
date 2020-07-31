// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B extends A {}

class C {
  void f(B x) {}
}

abstract class I {
  void f(covariant A x);
}

// D contains a forwarding stub for f which ensures that `x` is type checked.
class D extends C implements I {}

void checkStubTearoff(dynamic tearoff) {
  // Since the stub's parameter is covariant, its type should be reified as
  // Object.
  Expect.isTrue(tearoff is void Function(Object));

  // Verify that the appropriate runtime check occurs.
  tearoff(new B()); // No error
  Expect.throwsTypeError(() {
    tearoff(new A());
  });
}

main() {
  // The same forwarding stub should be torn off from D regardless of what
  // interface is used to tear it off.
  D d = new D();
  C c = d;
  I i = d;
  checkStubTearoff(d.f);
  checkStubTearoff(c.f);
  checkStubTearoff(i.f);
}
