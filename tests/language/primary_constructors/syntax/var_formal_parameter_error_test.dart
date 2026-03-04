// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It's a compile-time error to write a formal non-declaring parameter with a
// `var` keyword and no type annotation.

// SharedOptions=--enable-experiment=primary-constructors

typedef void Logger(var message);
//                  ^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'var' here.

void fn(var x, var y) {}
//      ^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'var' here.
//             ^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'var' here.

class C {
  C.ctor(var x) {}
  //     ^^^
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  // [cfe] Can't have modifier 'var' here.

  void method1(var x) {}
  //           ^^^
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  // [cfe] Can't have modifier 'var' here.

  void method2([var y = 1]) {}
  //            ^^^
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  // [cfe] Can't have modifier 'var' here.
}

enum E(final int x) {
  e(1);
  void method1(var x) {}
  //           ^^^
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  // [cfe] Can't have modifier 'var' here.

  void method2({required var y}) {}
  //                     ^^^
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  // [cfe] Can't have modifier 'var' here.
}

extension type ET(final int x) {
  void method1(var x) {}
  //           ^^^
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  // [cfe] Can't have modifier 'var' here.

  void method2({var y = 1}) {}
  //            ^^^
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  // [cfe] Can't have modifier 'var' here.
}

class FieldFunctionType {
  final void Function(int) f;
  FieldFunctionType(void this.f(var p));
  //                            ^^^
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  // [cfe] Can't have modifier 'var' here.
}

class A {
  A(void f(int p));
}
class SuperFunctionType extends A {
  SuperFunctionType(void super.f(var p));
  //                             ^^^
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  // [cfe] Can't have modifier 'var' here.
}

void f(void g(var p)) {}
//            ^^^
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'var' here.

void main() {
  [1, 4, 6, 8].forEach((var value) => print(value + 2));
  //                    ^^^
  // [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
  // [cfe] Can't have modifier 'var' here.
}
