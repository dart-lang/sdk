// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {
  Object operator +(Object x) => x;
}

void main() {
  B b = B();

  b += 2;
  //^
  // [cfe] A value of type 'Object' can't be assigned to a variable of type 'B'.
  //   ^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT

  ++b;
//^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
// [cfe] A value of type 'Object' can't be assigned to a variable of type 'B'.

  b++;
//^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
// ^
// [cfe] A value of type 'Object' can't be assigned to a variable of type 'B'.
}
