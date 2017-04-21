// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js that used to crash on this code.

class A {
  operator []=(index, value) {
    switch (value) {
      case 42:
        break;
      case 43:
        break;
    }
  }
}

main() {
  // Make [a] a phi.
  var a;
  if (true) {
    a = new A();
  } else {
    a = new A();
  }
  // `A[]=` being inlined, the compiler was confused when merging the
  // phis after the switch.
  a[0] = 42;

  // Use [a] to provoke the crash.
  print(a);
}
