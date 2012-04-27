// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing named parameters.


interface I {
  // Expect a compile-time error below: no default values allowed.
  int F31(int a, [int b = 20, int c = 30]);
}

class C implements I {
  int F31(int a, [int b = 20, int c = 30]) {
    return 100 * (100 * a + b) + c;
  }
}

main() {
  var c = new C();
  var i = c.F31(10, c:35);
  Expect.equals(true, false);
}
