// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for dart2js, where the optimizer was too aggressive
// about parameter types of closures.

class A {
  Function f;
  A(this.f);
  _do() => f(1);
}

main() {
  int invokeCount = 0;
  closure(a) {
    if (invokeCount++ == 1) {
      Expect.isTrue(a is int);
    }
  }

  closure('s');
  new A(closure)._do();
  Expect.equals(2, invokeCount);
}
