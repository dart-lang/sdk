// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test program to test type-based optimization on fields.

class A {
  var a = 0;
  var b = 0;
  foo() {
    var c = b + 27;
    for (var i = 0; i < 1; i++) {
      for (var j = 0; j < 1; j++) {
        Expect.equals(50, c + 23);
      }
    }
    return a > 0.2;
  }

  setA(value) {
    a = value;
  }

  setB(value) {
    b = value;
  }

  operator >(other) => other == 0.2;
}

main() {
  var a = new A();
  Expect.isFalse(a.foo());
  a.setA(new A());
  a.setB(0);
  Expect.isTrue(a.foo());
}
