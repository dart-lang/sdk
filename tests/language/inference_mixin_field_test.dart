// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Mixin {
  var field;
  createIt() {
    if (field == null) field = 42;
  }
}

class A {
  A(foo);
}

class B extends A with Mixin {
  // Because [super] references a synthesized constructor, dart2js
  // used to not see the null assignment to it.
  B(foo) : super(foo);
}

main() {
  var a = new B(42);
  a.createIt();
  Expect.equals(42, a.field);
}
