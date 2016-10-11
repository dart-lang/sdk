// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

abstract class Mixin1 {
  var mixin1Field = 1;
}

abstract class Mixin2 {
  var mixin2Field = 2;
}

class A {
  var superField;
  A() : superField = 3;
}

class B extends A with Mixin1, Mixin2 {
  var field = 4;
}

main() {
  var b = new B();
  Expect.equals(1, b.mixin1Field);
  Expect.equals(2, b.mixin2Field);
  Expect.equals(3, b.superField);
  Expect.equals(4, b.field);
}
