// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a cycle in redirecting factories leads to a compile-time error.

class A {
  factory A.foo() = B;
}

class B implements A {
  factory B() = C.bar;
}

class C implements B {
  factory C.bar() = C.foo;
  factory C.foo() = C
    .bar //# 01: compile-time error
  ;
  C();
}

main() {
  new A.foo();
}
