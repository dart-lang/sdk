// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  num x;
  int y;
  // x has type int in the initialization list, but num inside the constructor
  // body.
  A(int this.x) : y = x { // OK.
    int z = x;
    //      ^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    // [cfe] A value of type 'num' can't be assigned to a variable of type 'int'.
  }
}

main() {
  A(0);
}
