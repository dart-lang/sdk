// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test exercises a corner case of override checking that is safe from a
// soundness perspective, but which we haven't decided whether or not to allow
// from a usability perspective.

class A {
  void foo() {}
}

abstract class B extends A {
  // If this class were concrete, there would be a problem, since `new
  // B().foo(42)` would be statically allowed, but would lead to invalid
  // arguments being passed to A.foo.  But since the class is abstract, there is
  // no problem.
  void foo([x]);
}

class C extends B {
  void foo([x]) {
    super.foo();
  }
}

void f(B b) {
  b.foo(42);
}

main() {
  f(new C());
}
