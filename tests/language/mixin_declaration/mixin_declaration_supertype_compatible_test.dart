// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test various invalid super-constraints for mixin declarations.

abstract class BinaryNumInt {
  num foo(num x, int y);
}

abstract class BinaryIntNum {
  num foo(int x, num y);
}

abstract class GetterNumNum {
  num Function(num) get foo;
}

abstract class GetterIntInt {
  int Function(int) get foo;
}

abstract class UnaryInt {
  num foo(int x);
}

abstract class UnaryNum {
  num foo(num x);
}

abstract class UnaryString {
  num foo(String x);
}

// The super-interfaces must be *compatible*.
// Any member declared by more than one super-interface must have at
// least one most-specific signature among the super-interfaces.

// Incompatible member kinds, one is a getter, the other a method.
mixin _ on UnaryNum, GetterNumNum {} //# 01: compile-time error

// Incompatible signature structure, unary vs binary.
mixin _ on UnaryNum, BinaryNumInt {} //# 02: compile-time error

// Incompatible method parameter type, neither is more specific.
mixin _ on UnaryNum, UnaryString {} //# 03: compile-time error

// Compatible types for each parameter, but still no most specific signature.
mixin _ on BinaryNumInt, BinaryIntNum {} //# 04: compile-time error

// Incompatible return type for getter.
mixin _ on GetterNumNum, GetterIntInt {} //# 05: compile-time error


// Mixin is valid when one signature is more specific.
mixin M1 on UnaryNum, UnaryInt {
  // May call the method in a super-invocation, at the most specific type.
  num bar() {
    return super.foo(42.0);
  }
}

class C1 implements UnaryNum, UnaryInt {
  num foo(num x) => x;
}

class A1 = C1 with M1;

main() {
  Expect.equals(42.0, A1().bar());
}