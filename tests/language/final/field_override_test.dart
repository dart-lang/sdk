// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  int _x = 42;
  void set x(int val) {
    _x = val;
  }

  int get x => _x;
}

class B extends A {
  final x = 3;
  // we can still get to the super property
  int get y => _x;
}

void main() {
  var b = new B();
  Expect.equals(3, b.x);

  b.x = 21;
  Expect.equals(3, b.x);
  Expect.equals(21, b.y);
}
