// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code as governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

@pragma('vm:never-inline')
Object getType1(Object obj) => obj.runtimeType;

@pragma('vm:never-inline')
Object getType2<T>() => T;

@pragma('vm:never-inline')
void testRuntimeTypeEquality(bool expected, Object a, Object b) {
  bool result1 = getType1(a) == getType1(b);
  Expect.equals(expected, result1);
  // Test optimized 'a.runtimeType == b.runtimeType' pattern.
  bool result2 = a.runtimeType == b.runtimeType;
  Expect.equals(expected, result2);
}

class Base {}

class A extends Base {}

class B extends Base {}

final Base a1 = A();
final Base a2 = A();
final Base a3 = A();
final Base a4 = A();
final Base a5 = A();

final Base b1 = B();
final Base b2 = B();

main() {
  Expect.equals(B, getType1(b1));
  Expect.equals(getType2<B>(), getType1(b2));
  Expect.equals(getType2<A>(), getType1(a1));
  Expect.equals(getType2<(B, A)>(), getType1((b1, a3)));
  Expect.equals(getType2<({A bar, B foo})>(), getType1((foo: b1, bar: a2)));
  Expect.equals(
      getType2<(A, B, {A bar, B foo})>(), getType1((a1, foo: b1, b2, bar: a2)));

  testRuntimeTypeEquality(true, (a1, a2), (a3, a4));
  testRuntimeTypeEquality(false, (a1, a2), (a1, a2, a3));
  testRuntimeTypeEquality(false, (a1, a2), (a1, b2));
  testRuntimeTypeEquality(true, (a1, a2, foo: b1), (foo: b2, a5, a4));
  testRuntimeTypeEquality(false, (a1, a2, foo: b1), (bar: b2, a5, a4));
  testRuntimeTypeEquality(true, (foo: a1, bar: a2), (bar: a3, foo: a4));
  testRuntimeTypeEquality(false, (foo: a1, bar: a2), (a1, foo: a2));
  testRuntimeTypeEquality(false, (a1, a2), a3);
  testRuntimeTypeEquality(false, (a1, a2), 'hey');
  testRuntimeTypeEquality(false, (a1, a2), [a1, a2]);
}
