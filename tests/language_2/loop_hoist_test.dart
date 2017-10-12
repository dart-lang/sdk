// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  num x;
  A() : this.x = 0;

  void bar() {
    // dart2js hoisted the this.x out of the loop, and missed that setX would
    // change the value.
    for (int i = 1; i < 3; i++) {
      setX(499);
      foo(x);
      break;
    }
  }

  setX(x) => this.x = x;
}

var saved;
foo(x) => saved = x;

main() {
  A a = new A();
  for (int i = 0; i < 1; i++) {
    a.bar();
  }
  Expect.equals(499, saved);
}
