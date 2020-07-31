// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test checking that static/instance field shadowing do not conflict.

class A {
  int instanceFieldInA = 0;
  static int staticFieldInA = 0;
}

class B extends A {
  static int instanceFieldInA = 0; //  //# 01: compile-time error
  int staticFieldInA = 0; //           //# 02: ok
  static int staticFieldInA = 0; //    //# 03: ok
}

main() {
  var x = new B();
}
