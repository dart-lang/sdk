// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 21912.

class A {}

class B extends A {}

typedef T Function2<S, T>(S z);
typedef B AToB(A x);
typedef A BToA(B x);

void main() {
  test(
      Function2<Function2<A, B>, Function2<B, A>> t1,
      Function2<AToB, BToA> t2,
      Function2<Function2<int, double>, Function2<int, double>> left) {
    left = t1;
    //     ^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    // [cfe] A value of type 'A Function(B) Function(B Function(A))' can't be assigned to a variable of type 'double Function(int) Function(double Function(int))'.
    left = t2;
    //     ^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    // [cfe] A value of type 'A Function(B) Function(B Function(A))' can't be assigned to a variable of type 'double Function(int) Function(double Function(int))'.
  }
}
