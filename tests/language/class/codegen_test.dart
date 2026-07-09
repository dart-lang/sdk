// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  A() : x = 3;
  foo() => x;
  var x;
}

class B extends A {
  bar() => 499;
}

class C extends A {
  bar() => 42;
}

main() {
  // We don't instantiate A, but the codegen still needs to emit (parts of) it
  // for inheritance purposes.
  var b = new B();
  var c = new C();
  Expect.equals(3, b.foo());
  Expect.equals(3, c.foo());
  Expect.equals(499, b.bar());
  Expect.equals(42, c.bar());
}
