// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing factory generic result types.

// @dart = 2.9

class A<T> {
  A() {}
  factory A.factory() {
    return new A<String>();
    //     ^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
    //         ^
    // [cfe] A value of type 'A<String>' can't be assigned to a variable of type 'A<T>'.
  }
}

class B<T> extends A<T> {
  B() {}
  factory B.factory() {
    return new B<String>();
    //     ^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
    //         ^
    // [cfe] A value of type 'B<String>' can't be assigned to a variable of type 'B<T>'.
  }
}

main() {
  new A<String>.factory();
  new A<int>.factory();
  new B<String>.factory();
  new B<int>.factory();
}
