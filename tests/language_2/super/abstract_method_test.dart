// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that a method overridden by an abstract method is called at
// runtime.

import "package:expect/expect.dart";

class Base {
  foo() => 42;
}

abstract class A extends Base {
  foo();
}

class B extends A {
  testSuperCall() => super.foo();
  foo() =>
      42; // required since if is removed, then a warning is introduced on 'B' above
}

main() {
  Expect.equals(42, new B().foo());
  Expect.equals(42, new B().testSuperCall());
}
