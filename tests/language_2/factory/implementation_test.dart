// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

abstract class A {
  factory A(int x, int y) = B;
}

class B implements A {
  final int x;
  final int y;

  B(this.x, this.y);

  // This factory should never be invoked.
  factory B.A(int a, int b) {
    return new B(0, 0);
  }

  factory B.X(int a, int b) {
    return new B(a * 10, b * 10);
  }
}

main() {
  var a = new B(1, 2);
  // Check that constructor B is invoked and not factory B.A.
  Expect.equals(1, a.x);
  Expect.equals(2, a.y);

  var x = new B.X(11, 22);
  // Check that factory is invoked.
  Expect.equals(110, x.x);
  Expect.equals(220, x.y);
}
