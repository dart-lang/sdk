// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous subtyping for the `inout` variance modifier.

// SharedOptions=--enable-experiment=variance

class Invariant<inout T> {}

class A {
  Invariant<num> method1() {
    return Invariant<num>();
  }

  void method2(Invariant<num> x) {}
}

class B extends A {
  @override
  Invariant<Object> method1() {
  //                ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
  // [cfe] The return type of the method 'B.method1' is 'Invariant<Object>', which does not match the return type, 'Invariant<num>', of the overridden method, 'A.method1'.
    return new Invariant<Object>();
  }

  @override
  void method2(Invariant<int> x) {}
  //   ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
  //                          ^
  // [cfe] The parameter 'x' of the method 'B.method2' has type 'Invariant<int>', which does not match the corresponding type, 'Invariant<num>', in the overridden method, 'A.method2'.
}

class C extends A {
  @override
  Invariant<int> method1() {
  //             ^
  // [analyzer] unspecified
  // [cfe] The return type of the method 'C.method1' is 'Invariant<int>', which does not match the return type, 'Invariant<num>', of the overridden method, 'A.method1'.
    return new Invariant<int>();
  }

  @override
  void method2(Invariant<Object> x) {}
  //                             ^
  // [analyzer] unspecified
  // [cfe] The parameter 'x' of the method 'C.method2' has type 'Invariant<Object>', which does not match the corresponding type, 'Invariant<num>', in the overridden method, 'A.method2'.
}
