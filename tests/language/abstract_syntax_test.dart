// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  var b = new B();
  Expect.equals(42, b.foo());
}

class A {
  foo(); // //# 00: static type warning
  static bar(); // //# 01: compile-time error
}

class B extends A {
  foo() => 42;
  bar() => 87;
}
