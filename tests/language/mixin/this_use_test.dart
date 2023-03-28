// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(51557): Decide if the mixins being applied in this test should be
// "mixin", "mixin class" or the test should be left at 2.19.
// @dart=2.19

// Test that [:this:] in a class A used as a mixin in class D knows it can be an
// instance of D.

import "package:expect/expect.dart";

class A {
  foo() => bar(); // Implicit use of [:this:]
  bar() => 42;
}

class B {}

class C = B with A;

class D extends C {
  bar() => 54;
}

class E extends A {
  bar() => 68;
}

main() {
  Expect.equals(54, new D().foo());
  Expect.equals(68, new E().foo());
}
