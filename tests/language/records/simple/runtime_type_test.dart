// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code as governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=records

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

main() {
  Expect.equals(getType1(true), bool);
  Expect.equals(getType1(false), getType2<bool>());
  Expect.equals(getType1(1), getType2<int>());
  Expect.equals(getType1((true, 3)), getType2<(bool, int)>());
  Expect.equals(getType1((foo: true, bar: 2)), getType2<({int bar, bool foo})>());
  Expect.equals(getType1((1, foo: true, false, bar: 2)), getType2<(int, bool, {int bar, bool foo})>());

  testRuntimeTypeEquality(true, (1, 2), (3, 4));
  testRuntimeTypeEquality(false, (1, 2), (1, 2, 3));
  testRuntimeTypeEquality(false, (1, 2), (1, false));
  testRuntimeTypeEquality(true, (1, 2, foo: true), (foo: false, 5, 4));
  testRuntimeTypeEquality(false, (1, 2, foo: true), (bar: false, 5, 4));
  testRuntimeTypeEquality(true, (foo: 1, bar: 2), (bar: 3, foo: 4));
  testRuntimeTypeEquality(false, (foo: 1, bar: 2), (1, foo: 2));
  testRuntimeTypeEquality(false, (1, 2), 3);
  testRuntimeTypeEquality(false, (1, 2), 'hey');
  testRuntimeTypeEquality(false, (1, 2), [1, 2]);
}
