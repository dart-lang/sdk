// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/57213.
// Verifies that TFA doesn't crash if @pragma("vm:entry-point") is used
// on redirecting factory constructors.

@pragma("vm:entry-point")
class A {
  A();

  @pragma("vm:entry-point")
  factory A.foo() = B;
}

class B extends A {
  B(); // Should be retained.
}

class C {
  C();

  @pragma("vm:entry-point")
  factory C.bar() = D.baz;
}

class D extends C {
  D();
  factory D.baz() = E;
}

class E extends D {
  E(); // Should be retained.
}

void main() {}
