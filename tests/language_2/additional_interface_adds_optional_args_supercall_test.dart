// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  void foo() {}
}

abstract class I {
  void foo([x]);
}

abstract class B extends A implements I {
  // If this class were concrete, there would be a problem, since `new
  // B().foo(42)` would be statically allowed, but would lead to invalid
  // arguments being passed to A.foo.  But since the class is abstract, there is
  // no problem.
}

class C extends B {
  void foo([x]) {
    // But it is a problem to try to pass `x` along to super, since the super
    // method is A.foo.
    super.foo(/*@compile-error=unspecified*/ x);
  }
}

void f(B b) {
  b.foo(42);
}

main() {
  f(new C());
}
