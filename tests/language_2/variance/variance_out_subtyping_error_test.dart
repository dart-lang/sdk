// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous subtyping for the `out` variance modifier.

// SharedOptions=--enable-experiment=variance

class Covariant<out T> {}

class A {
  Covariant<num> method1() {
    return Covariant<num>();
  }

  void method2(Covariant<num> x) {}
}

class B extends A {
  @override
  Covariant<Object> method1() {
  //                ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
  // [cfe] The return type of the method 'B.method1' is 'Covariant<Object>', which does not match the return type, 'Covariant<num>', of the overridden method, 'A.method1'.
    return new Covariant<Object>();
  }

  @override
  void method2(Covariant<int> x) {}
  //   ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
  //                          ^
  // [cfe] The parameter 'x' of the method 'B.method2' has type 'Covariant<int>', which does not match the corresponding type, 'Covariant<num>', in the overridden method, 'A.method2'.
}
