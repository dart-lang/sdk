// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that a super call to access a field in a super class is just a normal
// field access.

import "package:expect/expect.dart";

class A {
  int y;
}

class B extends A {
  int get x => super.y;
  void set x(val) {
    super.y = val;
  }
}

void main() {
  var b = new B();
  b.x = 42;
  Expect.equals(42, b.x);
}
