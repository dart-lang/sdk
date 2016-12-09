// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// DartOptions=--initializing-formal-access
// VMOptions=--initializing-formal-access

import "package:expect/expect.dart";

class A {
  num x;
  double y;
  // Finding the type of an initializing formal: should cause a warning
  // in the initializer but not the body, because the former has type
  // `int` and the latter has type `num`.
  A(int this.x) : y = x {
    y = x;
  }
}

main() {
  A a = new A(null);
  Expect.equals(a.x, null);
  Expect.equals(a.y, null);
}
