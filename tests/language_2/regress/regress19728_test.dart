// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Regression test for issue 19728.

class C<T extends dynamic> {
  T field;

  test() {
    field = 0;
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    // [cfe] A value of type 'int' can't be assigned to a variable of type 'T'.
    int i = field;
    //      ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    // [cfe] A value of type 'T' can't be assigned to a variable of type 'int'.
  }
}

void main() {
  new C().test();
}
