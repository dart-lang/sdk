// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class C<T, U, V> {}

class D {}

typedef int Foo(bool b);

sameType(a, b) {
  Expect.equals(a.runtimeType, b.runtimeType);
}

main() {
  void foo(a) {}

  // Test that literals can be used in different contexts.
  [int];
  ([int]);
  foo([int]);
  [int].length;
  ({1: int});
  foo({1: int});
  ({1: int}).keys;

  // Test type literals.
  Expect.equals(int, int);
  Expect.notEquals(int, num);
  Expect.equals(Foo, Foo);
  Expect.equals(dynamic, dynamic);

  // Test that class literals return instances of Type.
  Expect.isTrue((D).runtimeType is Type);
  Expect.isTrue((dynamic).runtimeType is Type);

  // Test that types from runtimeType and literals agree.
  Expect.equals(int, 1.runtimeType);
  Expect.equals(String, 'hest'.runtimeType);
  Expect.equals(double, (0.5).runtimeType);
  Expect.equals(bool, true.runtimeType);
  Expect.equals(Object, Object().runtimeType);
  Expect.equals(C, new C().runtimeType);
  Expect.equals(D, new D().runtimeType);

  // runtimeType on type is idempotent.
  Expect.equals((D).runtimeType, (D).runtimeType.runtimeType);

  // Test that operator calls on class literals go to Type.
  Expect.throwsNoSuchMethodError(() => C = 1);
  //                                   ^
  // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_TYPE
  // [cfe] Can't assign to a type literal.
  Expect.throwsNoSuchMethodError(() => C++);
  //                                   ^
  // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_TYPE
  // [cfe] Can't assign to a type literal.
  Expect.throwsNoSuchMethodError(() => C + 1);
  //                                     ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '+' isn't defined for the class 'Type'.
  Expect.throwsNoSuchMethodError(() => C[2]);
  //                                    ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '[]' isn't defined for the class 'Type'.
  Expect.throwsNoSuchMethodError(() => C[2] = 'hest');
  //                                    ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '[]=' isn't defined for the class 'Type'.
  Expect.throwsNoSuchMethodError(() => dynamic = 1);
  //                                   ^
  // [cfe] Can't assign to a type literal.
  //                                   ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_TYPE
  Expect.throwsNoSuchMethodError(() => dynamic++);
  //                                   ^
  // [cfe] Can't assign to a type literal.
  //                                   ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_TYPE
  Expect.throwsNoSuchMethodError(() => dynamic + 1);
  //                                           ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '+' isn't defined for the class 'Type'.
  Expect.throwsNoSuchMethodError(() => dynamic[2]);
  //                                          ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '[]' isn't defined for the class 'Type'.
  Expect.throwsNoSuchMethodError(() => dynamic[2] = 'hest');
  //                                          ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '[]=' isn't defined for the class 'Type'.

  Expect.equals((dynamic).toString(), 'dynamic');
}
