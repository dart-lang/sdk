// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {}

class Base {
  void g(B b) {}
}

class C extends Base {
  void f(A a) {
    g(a);
    //^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] The argument type 'A' can't be assigned to the parameter type 'B'.
  }
}

main() {
  C c = new C();
  A a = new B();
  c.f(a);
}
