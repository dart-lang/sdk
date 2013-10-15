// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test type promotion of functions.

class A {}
class B extends A {}
class C {}

// We have the following more specific (<<) relations between these typedefs:
//
//  FuncDynToDyn << FuncAtoDyn
//  FuncDynToDyn << FuncDynToA << FuncDynToVoid

typedef FuncAtoDyn(A a);
typedef FuncDynToDyn(x);
typedef void FuncDynToVoid(x);
typedef A FuncDynToA(x);

func(x) => x;

A a;
B b;
C c;

main() {
  testFuncAtoDyn();
  testFuncDynToDyn();
  testFuncDynToVoid();
  testFuncDynToA();
}

testFuncAtoDyn() {
  FuncAtoDyn funcAtoDyn = func;
  a = funcAtoDyn(new A());
  b = funcAtoDyn(new B());
  c = funcAtoDyn(new C()); /// 01: static type warning

  if (funcAtoDyn is FuncDynToDyn) { // Promotion: FuncDynToDyn << FuncAtoDyn.
    a = funcAtoDyn(new A());
    b = funcAtoDyn(new B());
    c = funcAtoDyn(new C());
  }
}

testFuncDynToDyn() {
  FuncDynToDyn funcDynToDyn = func;
  a = funcDynToDyn(new A());
  b = funcDynToDyn(new B());
  c = funcDynToDyn(new C());

  if (funcDynToDyn is FuncAtoDyn) {
    // No promotion: FuncAtoDyn !<< FuncDynToDyn.
    a = funcDynToDyn(new A());
    b = funcDynToDyn(new B());
    c = funcDynToDyn(new C());
  }

  if (funcDynToDyn is FuncDynToVoid) {
    // No promotion: FuncDynToVoid !<< FuncDynToDyn.
    a = funcDynToDyn(new A());
    b = funcDynToDyn(new B());
    c = funcDynToDyn(new C());
  }

  if (funcDynToDyn is FuncDynToA) {
    // No promotion: FuncDynToA !<< FuncDynToDyn.
    a = funcDynToDyn(new A());
    b = funcDynToDyn(new B());
    c = funcDynToDyn(new C());
  }
}

testFuncDynToVoid() {
  FuncDynToVoid funcDynToVoid = func;
  a = funcDynToVoid(new A()); /// 02: static type warning
  b = funcDynToVoid(new B()); /// 03: static type warning
  c = funcDynToVoid(new C()); /// 04: static type warning

  if (funcDynToVoid is FuncDynToDyn) {
    // Promotion: FuncDynToDyn << FuncDynToVoid.
    a = funcDynToVoid(new A());
    b = funcDynToVoid(new B());
    c = funcDynToVoid(new C());
  }

  if (funcDynToVoid is FuncDynToA) { // Promotion: FuncDynToA << FuncDynToVoid.
    a = funcDynToVoid(new A());
    b = funcDynToVoid(new B());
    c = funcDynToVoid(new C()); /// 05: static type warning
  }
}

testFuncDynToA() {
  FuncDynToA funcDynToA = func;
  a = funcDynToA(new A());
  b = funcDynToA(new B());
  c = funcDynToA(new C()); /// 06: static type warning

  if (funcDynToA is FuncDynToDyn) { // Promotion: FuncDynToDyn << FuncDynToA.
    a = funcDynToA(new A());
    b = funcDynToA(new B());
    c = funcDynToA(new C());
  }

  if (funcDynToA is FuncDynToVoid) {
    // No promotion: FuncDynToVoid !<< FuncDynToA.
    a = funcDynToA(new A());
    b = funcDynToA(new B());
    c = funcDynToA(new C()); /// 07: static type warning
  }
}