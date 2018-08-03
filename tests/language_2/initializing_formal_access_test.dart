// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class C {
  final int x;
  final int y;

  const C.constant(this.x) : y = x + 1;

  C(this.x) : y = x + 1 {
    int z = x + 2;
    assert(z == y + 1);
  }
}

main() {
  C c = new C(2);
  Expect.equals(c.x, 2);
  Expect.equals(c.y, 3);
  const C cc = const C.constant(4);
  Expect.equals(cc.x, 4);
  Expect.equals(cc.y, 5);
}
