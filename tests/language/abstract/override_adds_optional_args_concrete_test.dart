// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  void foo() {}
}

class B extends A {
//    ^
// [analyzer] COMPILE_TIME_ERROR.INVALID_IMPLEMENTATION_OVERRIDE
// [cfe] The implementation of 'foo' in the non-abstract class 'B' does not conform to its interface.

  // This class declaration violates soundness, since it allows `new
  // B().foo(42)`, which would lead to invalid arguments being passed to A.foo.
  void foo([x]);
}

void f(B b) {
  b.foo();
}

main() {
  f(new B());
}
