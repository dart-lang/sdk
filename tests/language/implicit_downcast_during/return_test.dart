// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {}

B f1(A a) {
  return a;
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  // [cfe] A value of type 'A' can't be returned from a function with return type 'B'.
}

B f2(A a) => a;
//           ^
// [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
// [cfe] A value of type 'A' can't be returned from a function with return type 'B'.

void main() {
  Object b;
  A a = new B();
  b = f1(a);
  b = f2(a);
}
