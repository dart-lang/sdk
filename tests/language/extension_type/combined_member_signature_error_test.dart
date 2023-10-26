// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

import 'package:expect/expect.dart';

abstract class A {
  (Object?, dynamic) method();
  (Object?, dynamic) get getter;
  void set setter((int, int) Function(Object?, dynamic) f);
}

abstract class B {
  (dynamic, Object?) method();
  (dynamic, Object?) get getter;
  void set setter((int, int) Function(dynamic, Object?) f);
}

class C implements A, B {
  (int, int) method() => (42, 87);
  (int, int) get getter => (42, 87);
  void set setter((int, int) Function(dynamic, dynamic) f) {}
}

extension type E(C c) implements A, B {}

(Object?, Object?) testMethod0(E e) => e.method();

(int, Object?) testMethod1(E e) => e.method();
//                                 ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
//                                   ^
// [cfe] A value of type '(Object?, Object?)' can't be returned from a function with return type '(int, Object?)'.

(Object?, int) testMethod2(E e) => e.method();
//                                 ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
//                                   ^
// [cfe] A value of type '(Object?, Object?)' can't be returned from a function with return type '(Object?, int)'.

testMethod3(E e) => e.method().$1.unresolved();
//                                ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe] The method 'unresolved' isn't defined for the class 'Object?'.

testMethod4(E e) => e.method().$2.unresolved();
//                                ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe] The method 'unresolved' isn't defined for the class 'Object?'.

(Object?, Object?) testGetter0(E e) => e.getter;

(int, Object?) testGetter1(E e) => e.getter;
//                                 ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
//                                   ^
// [cfe] A value of type '(Object?, Object?)' can't be returned from a function with return type '(int, Object?)'.

(Object?, int) testGetter2(E e) => e.getter;
//                                 ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
//                                   ^
// [cfe] A value of type '(Object?, Object?)' can't be returned from a function with return type '(Object?, int)'.

void testSetter(E e) {
  e.setter = (a, b) => (a as int, b as int);

  e.setter = (a, b) => (a, b as int);
  //                   ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE_FROM_CLOSURE
  // [cfe] A value of type '(Object?, int)' can't be returned from a function with return type '(int, int)'.

  e.setter = (a, b) => (a as int, b);
  //                   ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE_FROM_CLOSURE
  // [cfe] A value of type '(int, Object?)' can't be returned from a function with return type '(int, int)'.
}

main() {}
