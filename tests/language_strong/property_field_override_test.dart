// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test overriding a getter property with a field.
class A {
  int get v; // Abstract.

  int a() {
    return v - 1;
  }
}

class B extends A {
  int v = 3;

  int b() {
    return ++v;
  }
}

main() {
  var x = new B();
  Expect.equals(3, x.v);
  Expect.equals(2, x.a());
  Expect.equals(4, x.b());
}
