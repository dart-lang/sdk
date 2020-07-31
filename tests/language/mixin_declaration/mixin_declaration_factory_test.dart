// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A mixin declaration cannot declare any (factory) constructors.

class A {}

class B implements A {
  const B();
}

mixin M on A {
  factory M.foo() => throw "uncalled"; //# 01: compile-time error
  const factory M.bar() = B; //# 02: compile-time error
  M.baz(); //# 03: compile-time error
}

class MA extends A with M {}

class N {
  // It's OK for a mixin derived from a class to have factory constructors.
  factory N.quux() => throw "uncalled"; //# none: ok
  N.bar(); //# 04: compile-time error
}

class NA extends A with N {}

main() {
  new MA();
  new NA();
}
