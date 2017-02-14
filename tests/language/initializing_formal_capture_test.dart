// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  var x, y;
  A(this.x) : y = (() => x);
}

main() {
  A a = new A(2);
  a.x = 3;
  Expect.equals(a.x, 3);
  Expect.equals(a.y(), 2);
}
