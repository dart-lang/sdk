// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {}

class C {
  int operator [](A a) => 0;
  void operator []=(B b, int o) {}
}

class D {
  int operator [](B b) => 0;
  void operator []=(A a, int o) {}
}

void main() {
  A a = new B();
  C c = new C();
  D d = new D();
  c[a] += 1;
  //^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'A' can't be assigned to a variable of type 'B'.
  d[a] += 1;
  //^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'A' can't be assigned to a variable of type 'B'.
}
