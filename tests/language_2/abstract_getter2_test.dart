// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  int get x => 100;
}

abstract class B extends A {
  int _x;

  int get x;
  set x(int v) {
    _x = v;
  }
}

class C extends B {
  int get x => super.x;
}

void main() {
  B b = new C();
  b.x = 42;
  Expect.equals(b._x, 42);
  Expect.equals(b.x, 100);
}
