// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  void f(Object x) {}

  void g(Object x, String y) {}
}

class B {
  void f(String x) {}

  void g(String x, Object y) {}
}

class C extends A implements B {
  void f(x) {
    // Infers Object for x.
    Object y = x;
    String z = x;
    //         ^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    // [cfe] A value of type 'Object' can't be assigned to a variable of type 'String'.
  }

  // No combined signature.
  void g(x, y) {
    // ^
    // [analyzer] COMPILE_TIME_ERROR.NO_COMBINED_SUPER_SIGNATURE
    // [cfe] Can't infer types for 'g' as the overridden members don't have a combined signature.
  }
}

void main() {}
