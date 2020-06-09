// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dartbug.com/29846: check that range-based
// CheckClassId is generated correctly.

// VMOptions=--optimization_counter_threshold=10 --no-background-compilation

import "package:expect/expect.dart";

class B {
  int x;
  B(this.x) {}
}

abstract class A0 {
  int foo() => bar.x;
  B get bar;
}

class A1 extends A0 {
  B get bar => _bfield;
  B _bfield = new B(1);
}

class A2 extends A1 {
  B get bar => new B(2);
}

// Several classes with subsequent Cids

class A3 extends A1 {}

class A4 extends A1 {}

// This one does not have _bfield

class A5 extends A0 {
  B get bar => new B(5);
}

main() {
  var b = new B(0);
  var a1 = new A1();
  var a2 = new A2();
  var a3 = new A3();
  var a4 = new A4();
  var a5 = new A5();

  for (var i = 0; i < 5; i++) {
    a1.foo();
    a2.foo();
    a3.foo();
    a4.foo();
  }

  // CheckClassId should trigger deoptimization
  Expect.equals(a5.foo(), 5);
}
