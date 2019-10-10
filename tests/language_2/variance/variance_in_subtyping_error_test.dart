// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous subtyping for the `in` variance modifier.

// SharedOptions=--enable-experiment=variance

class Contravariant<in T> {}

class A {
  Contravariant<num> method1() {
    return new Contravariant<num>();
  }

  void method2(Contravariant<num> x) {}
}

class B extends A {
  @override
  Contravariant<int> method1() {
  //                 ^
  // [analyzer] unspecified
  // [cfe] The return type of the method 'B.method1' is 'Contravariant<int>', which does not match the return type, 'Contravariant<num>', of the overridden method, 'A.method1'.
    return new Contravariant<int>();
  }

  @override
  void method2(Contravariant<Object> x) {}
  //                                 ^
  // [analyzer] unspecified
  // [cfe] The parameter 'x' of the method 'B.method2' has type 'Contravariant<Object>', which does not match the corresponding type, 'Contravariant<num>', in the overridden method, 'A.method2'.
}
