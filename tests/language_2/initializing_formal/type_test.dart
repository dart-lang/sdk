// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "package:expect/expect.dart";

class A {
  num x;
  double y;
  // Finding the type of an initializing formal: should cause an error
  // in the initializer but not the body, because the former has type
  // `int` and the latter has type `num`.
  A(int this.x) : y = x {
    //                ^
    // [analyzer] COMPILE_TIME_ERROR.FIELD_INITIALIZER_NOT_ASSIGNABLE
    // [cfe] A value of type 'int' can't be assigned to a variable of type 'double'.
    y = x;
  }
}

main() {
  A a = new A(null);
  Expect.equals(a.x, null);
  Expect.equals(a.y, null);
}
