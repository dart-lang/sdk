// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test type promotion of functions.

class A {}

class B extends A {}

class C {}

// Subtype relations:
//
//   FuncDynToA    == A       Function(dynamic) <:
//   FuncDynToDyn  == dynamic Function(dynamic) <:> // "void == dynamic"
//   FuncDynToVoid == void    Function(dynamic) <:
//   FuncAtoDyn    == dynamic Function(A).
//
// Declarations ordered by "super before sub", as is common for classes:

typedef FuncAtoDyn(A a);
typedef void FuncDynToVoid(x);
typedef FuncDynToDyn(x);
typedef A FuncDynToA(x);

A func(x) => null;

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
  c = funcAtoDyn(new C()); //# 01: compile-time error

  if (funcAtoDyn is FuncDynToDyn) {
    // Promotion: FuncDynToDyn <: FuncAtoDyn.
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
    // No promotion: FuncAtoDyn <\: FuncDynToDyn.
    a = funcDynToDyn(new A());
    b = funcDynToDyn(new B());
    c = funcDynToDyn(new C());
  }

  if (funcDynToDyn is FuncDynToVoid) {
    // Promotion: FuncDynToVoid <: FuncDynToDyn.
    funcDynToDyn(new A());
    funcDynToDyn(new B());
    funcDynToDyn(new C());
    // Returned value has type `void`, usage is restricted.
    Object o = funcDynToDyn(null); //# 12: compile-time error
  }

  if (funcDynToDyn is FuncDynToA) {
    // Promotion: FuncDynToA <: FuncDynToDyn.
    a = funcDynToDyn(new A());
    b = funcDynToDyn(new B());
    c = funcDynToDyn(new C()); //# 10: compile-time error
  }
}

testFuncDynToVoid() {
  FuncDynToVoid funcDynToVoid = func;
  a = funcDynToVoid(new A()); //# 02: compile-time error
  b = funcDynToVoid(new B()); //# 03: compile-time error
  c = funcDynToVoid(new C()); //# 04: compile-time error

  if (funcDynToVoid is FuncDynToDyn) {
    // Promotion: FuncDynToDyn <:> FuncDynToVoid.
    a = funcDynToVoid(new A());
    b = funcDynToVoid(new B());
    c = funcDynToVoid(new C());
  }

  if (funcDynToVoid is FuncDynToA) {
    // Promotion: FuncDynToA <: FuncDynToVoid.
    a = funcDynToVoid(new A());
    b = funcDynToVoid(new B());
    c = funcDynToVoid(new C()); //# 05: compile-time error
  }
}

testFuncDynToA() {
  FuncDynToA funcDynToA = func;
  a = funcDynToA(new A());
  b = funcDynToA(new B());
  c = funcDynToA(new C()); //# 06: compile-time error

  if (funcDynToA is FuncDynToDyn) {
    // No promotion: FuncDynToDyn <\: FuncDynToA.
    a = funcDynToA(new A());
    b = funcDynToA(new B());
    c = funcDynToA(new C()); //# 08: compile-time error
  }

  if (funcDynToA is FuncDynToVoid) {
    // No promotion: FuncDynToVoid <\: FuncDynToA.
    a = funcDynToA(new A());
    b = funcDynToA(new B());
    c = funcDynToA(new C()); //# 07: compile-time error
  }
}
