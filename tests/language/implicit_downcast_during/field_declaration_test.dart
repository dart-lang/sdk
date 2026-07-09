// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {}

A a1 = new B();
B b1 = a1;
//     ^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
// [cfe] A value of type 'A' can't be assigned to a variable of type 'B'.

class C {
  static B b3 = a1;
  //            ^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'A' can't be assigned to a variable of type 'B'.

  B b5 = a1;
  //     ^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'A' can't be assigned to a variable of type 'B'.
}

void main() {
  b1;
  C.b3;
  new C();
}
