// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

class A {
  static int b;

  setA(val) {
    b = val;
  }

  bar() {
    return b;
  }

  bar2() {
    return A.b;
  }
}

main() {
  A a = new A();
  a.setA(42);
  Expect.equals(42, a.bar());
  Expect.equals(42, a.bar2());
}
