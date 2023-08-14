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
//    ^
// [analyzer] COMPILE_TIME_ERROR.INVALID_IMPLEMENTATION_OVERRIDE
// [cfe] The implementation of 'foo' in the non-abstract class 'C' does not conform to its interface.

  // However, there is a problem here because this class is concrete and doesn't
  // override foo.
}

void f(B b) {
  b.foo();
}

main() {
  f(new C());
}
