// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  // Constructor may not be static.
  static A(); // //# 00: compile-time error

  // Factory may not be static.
  static factory A() { return null; } // //# 01: syntax error

  // Named constructor may not conflict with names of methods and fields.
  var m;
  A.m() { m = 0; } // //# 04: compile-time error

  set q(var value) {
    m = 0;
  } // No name conflict with q=.
  A.q(); //  //# 05: ok
  A(); //    //# 05: ok

  A.foo() : m = 0; // //# 06: compile-time error
  int foo(int a, int b) => a + b * m;
}

main() {
  new A();
}
