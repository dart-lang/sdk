// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// DartOptions=--initializing-formal-access
// VMOptions=--initializing-formal-access

import "package:expect/expect.dart";

class B {}

class A {
  B x, y;
  A(this.x) {
    // Promote to subtype.
    if (x is C) y = x.x;
    // Promotion fails, not a subtype.
    if (x is A) y = x;
  }
}

class C extends A implements B {
  C(B x) : super(x);
}

main() {
  C c2 = new C(null);
  C cc = new C(c2);
  Expect.equals(c2.y, null);
  Expect.equals(cc.y, c2);
}
