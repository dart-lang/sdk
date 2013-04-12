// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that a call to a bailout method in dart2js resolves to the
// right method.

var reachedAfoo = new C();

class A {
  foo() {
    // Using '++' makes sure there is a type guard.
    reachedAfoo++;
  }
}

class B extends A {
  foo() {
    reachedAfoo++;
    // Call the Expect method after the type guard.
    Expect.fail('Should never reach B.foo');
  }

  bar() {
    super.foo();
  }
}

class C {
  int value = 0;
  operator +(val) {
    value += val;
    return this;
  }
}

main() {
  // Using a loop makes sure the 'foo' methods will have an optimized
  // version.
  while (reachedAfoo.value != 0) {
    new A().foo();
    new B().foo();
  }
  new B().bar();
  Expect.equals(1, reachedAfoo.value);
}
