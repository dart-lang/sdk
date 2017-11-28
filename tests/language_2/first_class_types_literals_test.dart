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
  Expect.equals(C, new C().runtimeType); // //# 01: ok
  Expect.equals(D, new D().runtimeType); // //# 02: ok

  // runtimeType on type is idempotent.
  Expect.equals((D).runtimeType, (D).runtimeType.runtimeType);

  // Test that operator calls on class literals go to Type.
  Expect.throwsNoSuchMethodError(() => C = 1); //# 03: compile-time error
  Expect.throwsNoSuchMethodError(() => C++); //# 04: compile-time error
  Expect.throwsNoSuchMethodError(() => C + 1); //# 05: compile-time error
  Expect.throwsNoSuchMethodError(() => C[2]); //# 06: compile-time error
  Expect.throwsNoSuchMethodError(() => C[2] = 'hest'); //# 07: compile-time error
  Expect.throwsNoSuchMethodError(() => dynamic = 1); //# 08: compile-time error
  Expect.throwsNoSuchMethodError(() => dynamic++); //# 09: compile-time error
  Expect.throwsNoSuchMethodError(() => dynamic + 1); //# 10: compile-time error
  Expect.throwsNoSuchMethodError(() => dynamic[2]); //# 11: compile-time error
  Expect.throwsNoSuchMethodError(() => dynamic[2] = 'hest'); //# 12: compile-time error

  Expect.equals((dynamic).toString(), 'dynamic');
}
