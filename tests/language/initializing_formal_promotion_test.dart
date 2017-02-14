// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class B {}

class A {
  B x, y;
  // Promotion occurs for the initializing formal because C <: B.
  A(this.x) : y = (x is C) ? x.x : x;
}

class C extends A implements B {
  C(B x) : super(x);
}

main() {
  C c = new C(null);
  C cc = new C(c);
  Expect.equals(c.y, null);
  Expect.equals(cc.y, null);
}
