// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {}

class C {
  B b;
  C(A a) : b = a;
  //           ^
  // [analyzer] COMPILE_TIME_ERROR.FIELD_INITIALIZER_NOT_ASSIGNABLE
  // [cfe] A value of type 'A' can't be assigned to a variable of type 'B'.
}

void main() {
  A a = new B();
  new C(a);
}
