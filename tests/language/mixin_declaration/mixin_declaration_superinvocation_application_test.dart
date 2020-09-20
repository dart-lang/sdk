// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test various invalid mixin applications due to insufficient super-invoked
// methods.

abstract class UnaryNum {
  num foo(num x);
}

abstract class UnaryOptionalNum {
  num foo([num x]);
}

// When a mixin is applied, the super-invoked methods must have
// a concrete implementation in the superclass which satisfies
// the signature in the super-interfaces.

mixin M1 on UnaryNum {
  num bar() {
    return super.foo(42.0);
  }
}

mixin M11 on UnaryNum {
  num bar() {
    return 0.0;
  }
  num foo(num x) {
    return super.foo(42.0);
  }
}

// The super-invoked method must be non-abstract.
class A1 extends UnaryNum //
    with M1 //# 04: compile-time error
    with M11 //# 05: compile-time error
    with M1, M11 //# 06: compile-time error
    with M11, M1 //# 07: compile-time error
{
  // M1.bar does super.foo and UnaryNum has no implementation.
  num foo(num x) => x;
}

// The super-invoked method must satisfy the most specific signature
// among super-interfaces of the mixin.
class C1 {
  num foo(num x) => x;
}

abstract class C2 extends C1 implements UnaryOptionalNum {
  num foo([num x]);
}

mixin M2 on UnaryOptionalNum {
  num bar() {
    // Allowed, super.foo has signature num Function([num]).
    return super.foo(42.0);
  }
}

class A2 extends C2 //
    with M2 //# 08: compile-time error
{
  // M2.bar does a super.foo, so C2.foo must satisfy the super-interface of M2.
  // It doesn't, even if the super-call would succeed against C1.foo.
  num foo([num x = 0]) => x;
}

main() {
  A1().bar(); //# 04: continued
  A1().bar(); //# 05: continued
  A1().bar(); //# 06: continued
  A1().bar(); //# 07: continued
  A2().bar(); //# 08: continued
}