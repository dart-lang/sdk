// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Exercises issue 2282, factory constructors in abstract classes should
// not emit a static type warning

class B extends A1 {
  B() {}
  method() {}
}

abstract class A1 {
  A1() {}
  method(); // Abstract.
  factory A1.make() {
    return new B();
  }
}

class A2 {
  // Intentionally abstract method.
  method(); // //# 00: static type warning
  A2.make() {}
}

main() {
  new A1.make();
  new A2.make();              //# 00: continued
}
