// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test various invalid syntax combinations.

// You cannot prefix "mixin" with anything.
abstract //# 01: compile-time error
static //# 02: compile-time error
const //# 03: compile-time error
mixin M0 {}

// Cannot use "extends".
mixin M1 //
  extends A //# 04: compile-time error
{}

// On-clause must be before implements clause.
mixin M2
  implements B //# 05: compile-time error
  on A
{}

// Cannot use "on" on class declarations.
class C0 //
  on A //# 06: compile-time error
{}

// Type parameters must not be empty.
mixin M3 //
  <> //# 07: compile-time error
{}

// Super-class restrictions and implements must be well-formed.
mixin M4 on List
  <UndeclaredType> //# 08: compile-time error
{}
mixin M5 implements List
  <UndeclaredType> //# 09: compile-time error
{}

mixin M6 {
  // Mixins cannot have constructors (or members with same name as mixin).
  factory M6() {} //# 10: compile-time error
  M6() {} //# 11: compile-time error
  M6.foo(); //# 12: compile-time error
  get M6 => 42; //# 13: compile-time error
}

// Cannot declare local mixins.
class C {
  static mixin M {}; //# 14: compile-time error
  mixin M {} //# 15: compile-time error
}

// Just to have some types.
class A {}
class B {}

main() {
  new C();
}