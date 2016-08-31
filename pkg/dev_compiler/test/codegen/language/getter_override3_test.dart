// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that a getter in a subclass does not shadow the setter in the
// superclass.
import "package:expect/expect.dart";

class A {
  int _x = 42;
  void set x(int val) {
    _x = val;
  }
}

class B extends A {
  int get x => _x;
}

void main() {
  var b = new B();
  Expect.equals(42, b.x);

  b.x = 21;
  Expect.equals(21, b.x);
}
