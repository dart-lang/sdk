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
  c = funcAtoDyn(new C());
  //             ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  //                 ^
  // [cfe] The argument type 'C' can't be assigned to the parameter type 'A'.

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
    Object o = funcDynToDyn(null);
    //         ^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
    //                     ^
    // [cfe] This expression has type 'void' and can't be used.
  }

  if (funcDynToDyn is FuncDynToA) {
    // Promotion: FuncDynToA <: FuncDynToDyn.
    a = funcDynToDyn(new A());
    b = funcDynToDyn(new B());
    c = funcDynToDyn(new C());
    //  ^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //              ^
    // [cfe] A value of type 'A' can't be assigned to a variable of type 'C'.
  }
}

testFuncDynToVoid() {
  FuncDynToVoid funcDynToVoid = func;
  a = funcDynToVoid(new A());
  //  ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //               ^
  // [cfe] This expression has type 'void' and can't be used.
  b = funcDynToVoid(new B());
  //  ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //               ^
  // [cfe] This expression has type 'void' and can't be used.
  c = funcDynToVoid(new C());
  //  ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.USE_OF_VOID_RESULT
  //               ^
  // [cfe] This expression has type 'void' and can't be used.

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
    c = funcDynToVoid(new C());
    //  ^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //               ^
    // [cfe] A value of type 'A' can't be assigned to a variable of type 'C'.
  }
}

testFuncDynToA() {
  FuncDynToA funcDynToA = func;
  a = funcDynToA(new A());
  b = funcDynToA(new B());
  c = funcDynToA(new C());
  //  ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //            ^
  // [cfe] A value of type 'A' can't be assigned to a variable of type 'C'.

  if (funcDynToA is FuncDynToDyn) {
    // No promotion: FuncDynToDyn <\: FuncDynToA.
    a = funcDynToA(new A());
    b = funcDynToA(new B());
    c = funcDynToA(new C());
    //  ^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //            ^
    // [cfe] A value of type 'A' can't be assigned to a variable of type 'C'.
  }

  if (funcDynToA is FuncDynToVoid) {
    // No promotion: FuncDynToVoid <\: FuncDynToA.
    a = funcDynToA(new A());
    b = funcDynToA(new B());
    c = funcDynToA(new C());
    //  ^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //            ^
    // [cfe] A value of type 'A' can't be assigned to a variable of type 'C'.
  }
}
