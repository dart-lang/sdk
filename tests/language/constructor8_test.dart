// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for dart2js that used to crash on this program.

class A {
  var b;

  // The parameter check here used to confuse the SSA builder when it
  // created the call to the constructor body.
  A([Map a]) : b = ?a {
    Expect.isTrue(b);
  }

  // The closure in the constructor body used to confuse the SSA builder
  // when it created the call to the constructor body.
  A.withClosure(Map a) {
    var c;
    var f = () { return c = 42; };
    b = f();
    Expect.equals(42, b);
    Expect.equals(42, c);
  }
}

main() {
  new A(null);
  new A({});
  new A.withClosure(null);
  new A.withClosure({});
}
