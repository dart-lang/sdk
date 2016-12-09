// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that we emit warnings for unresolved indexing operations on super.

class A {
  operator[]=(a, b) {}
}

class B extends A {
  foo() {
    super[4] = 42;
    super[4] += 5; /// 01: static type warning, runtime error
    return super[2]; /// 02: static type warning, runtime error
  }
}

class C {
  operator[](a) {}
}

class D extends C {
  foo() {
    super[4] = 42; /// 03: static type warning, runtime error
    super[4] += 5; /// 04: static type warning, runtime error
    return super[2];
  }
}

class E {
  foo() {
    super[4] = 42; /// 05: static type warning, runtime error
    super[4] += 5; /// 06: static type warning, runtime error
    return super[2]; /// 07: static type warning, runtime error
  }
}

main() {
  new B().foo();
  new D().foo();
  new E().foo();
}
