// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that inferred types of parameters are valid *before*
// applying strong mode argument type checks.

abstract class T0 {
  void foo();
}

class T1 extends T0 {
  void foo() {}
}

class T2 extends T0 {
  void foo() {}
}

// Called directly with incompatible argument.
// In such case, CFE inserts implicit cast into the caller and function is
// invoked with correct argument type, so parameter type is inferred.
void func1(T0 t0) {
  t0.foo();
}

// Tear-off is taken. Arguments could be arbitrary.
void func2(T0 t0) {
  t0.foo(); // Devirtualization should still happen.
}

class A {
  // Tear-off is taken.
  void method1(T0 t0) {
    t0.foo();
  }
}

abstract class B {
  void method2(covariant arg);
}

class C implements B {
  // Called through interface with incompatible/unknown argument.
  void method2(T0 t0) {
    t0.foo();
  }
}

class D {
  // Potential dynamic call.
  void method3(T0 t0) {
    t0.foo();
  }
}

Function unknown;

getDynamic() => unknown.call();
use(x) => unknown.call(x);

main(List<String> args) {
  func1(getDynamic());

  use(func2);

  use(new A().method1);

  B bb = getDynamic();
  bb.method2(getDynamic());

  getDynamic().method3(getDynamic());

  new T2();
  new A();
  new C();
  new D();
}
