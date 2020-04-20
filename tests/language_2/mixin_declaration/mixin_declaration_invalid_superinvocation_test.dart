// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test various invalid super-invocations for mixin declarations.

abstract class UnaryInt {
  num foo(int x);
}

abstract class UnaryNum {
  num foo(num x);
}

abstract class UnaryOptionalNum {
  num foo([num x]);
}

// Mixins may contain super-invocations.
// The super-invocation must be valid against the combined super-interfaces
// (i.e., valid against the most specific of them for that method).

mixin M1 on UnaryNum {
  void bar() {
    super.foo(); //# 01: compile-time error
    super.foo(1, 2); //# 02: compile-time error
    super.foo("not num"); //# 03: compile-time error
    super.bar; //# 04: compile-time error
    super + 2; //# 05: compile-time error
  }
}

mixin M2 on UnaryNum, UnaryInt {
  void bar() {
    super.foo(4.2); // Allows most specific type.
    super.foo(1, 2); //# 06: compile-time error
    super.foo("not num"); //# 07: compile-time error
  }
}

mixin M3 on UnaryNum, UnaryOptionalNum {
  void bar() {
    super.foo(4.2);
    super.foo();     //# 10: ok
    super.foo(1, 2); //# 08: compile-time error
    super.foo("not num"); //# 09: compile-time error
  }
}

class C1 implements UnaryNum, UnaryInt, UnaryOptionalNum {
  num foo([num x]) => x ?? 37.0;
}

class A1 = C1 with M1;
class A2 = C1 with M2;
class A3 = C1 with M3;
main() {
  A1().bar();
  A2().bar();
  A3().bar();
}
