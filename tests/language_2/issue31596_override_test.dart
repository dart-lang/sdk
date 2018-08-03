// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class I0 {}

class A {}

class B extends A implements I0 {}

class B2 extends A {}

class C {
  void f(B x) {}
}

abstract class I1 {
  void f(covariant A x);
}

// This class contains a forwarding stub for f to allow it to satisfy the
// interface I, while still ensuring that the x argument is type checked before
// C.f is executed.
//
// For purposes of override checking, the forwarding stub is ignored.
class D extends C implements I1 {}

class Test extends D {
  // Valid override - A assignable to A and B
  void f(A x) {} //# 01: ok
  void f(covariant A x) {} //# 02: ok

  // Valid override - B assignable to A and B
  void f(B x) {} //# 03: ok
  void f(covariant B x) {} //# 04: ok

  // Invalid override - I0 not assignable to A
  void f(I0 x) {} //# 05: compile-time error
  void f(covariant I0 x) {} //# 06: compile-time error

  // Invalid override - B2 not assignable to B
  void f(B2 x) {} //# 07: compile-time error
  void f(covariant B2 x) {} //# 08: compile-time error
}

main() {
  // Make sure that Test is compiled.
  new Test();
}
