// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  Expect.equals("str", foo("str"));
}

foo(y) {
  dynamic x = 3;
  for (int i = 0; i < 2; i++) {
    // Make sure that we don't think that the type of x is necessarily
    // a number and optimize the x + y expression based on that. The
    // value of x changes later...
    if (i == 1) return bar(x + y);
    x = new A();
  }
}

bar(t) => t;

class A {
  A() {}
  operator +(x) => x;
}
