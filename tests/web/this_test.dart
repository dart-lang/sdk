// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  int? x;
  getX() => this.x;
  setX(val) {
    this.x = val;
  }
}

main() {
  A a = A();
  a.setX(42);
  Expect.equals(42, a.getX());
}
