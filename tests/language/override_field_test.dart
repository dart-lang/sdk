// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test checking that static/instance field shadowing do not conflict.

class A {
  A() {}  // DartC has no implicit constructors yet.

  int instanceFieldInA;
  static int staticFieldInA;
}

class B extends A {
  B() : super() {}  // DartC has no implicit constructors yet.

  static int instanceFieldInA; /// 01: compile-time error
  int staticFieldInA; /// 02: static type warning
  static int staticFieldInA; /// 03: static type warning
  int instanceFieldInA; /// 04: compile-time error
}

main() {
  var x  = new B();
}
