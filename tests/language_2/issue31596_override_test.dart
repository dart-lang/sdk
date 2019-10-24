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

abstract class I1<X> {
  void f(X x);
}

// This class contains a forwarding stub for f to allow it to satisfy the
// interface I<B>, while still ensuring that the x argument is type checked
// before C.f is executed.
class D extends C implements I1<B> {}

class Test extends D {
  void f(A x) {} //# 01: ok
  void f(covariant A x) {} //# 02: ok

  void f(B x) {} //# 03: ok
  void f(covariant B x) {} //# 04: ok

  void f(I0 x) {} //# 05: ok
  void f(covariant I0 x) {} //# 06: ok

  void f(B2 x) {} //# 07: compile-time error
  void f(covariant B2 x) {} //# 08: compile-time error
}

main() {
  // Make sure that Test is compiled.
  new Test();
}
