// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we emit errors for unresolved indexing operations on super.

class A {
  operator []=(a, b) {}
}

class B extends A {
  foo() {
    super[4] = 42;
    super[4] += 5; //# 01: compile-time error
    return super[2]; //# 02: compile-time error
  }
}

class C {
  operator [](a) {}
}

class D extends C {
  foo() {
    super[4] = 42; //# 03: compile-time error
    super[4] += 5; //# 04: compile-time error
    return super[2];
  }
}

class E {
  foo() {
    super[4] = 42; //# 05: compile-time error
    super[4] += 5; //# 06: compile-time error
    return super[2]; //# 07: compile-time error
  }
}

main() {
  new B().foo();
  new D().foo();
  new E().foo();
}
