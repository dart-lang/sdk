// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to produce a non-valid SSA
// graph when inlining within a loop.

class X {
  void x(a, b) {
    do {
      if (identical(a, b)) {
        break;
      }
    } while (p(a, b));
  }

  bool p(a, b) {
    return identical(a, b);
  }
}

main() {
  var x = new X();
  x.x(1, 2);
}
