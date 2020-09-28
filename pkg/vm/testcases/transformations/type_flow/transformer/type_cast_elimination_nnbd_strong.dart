// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests elimination of type casts.
// This test requires non-nullable experiment and NNBD strong mode.

// @dart = 2.10

class A<T> {}

class B<T> extends A<T> {
  testT1(x) => x as T;
  testT2negative(x) => x as T;
  testT3(x) => x as T;
  testNullableT1(x) => x as T?;
  testNullableT2(x) => x as T?;
}

testInt1(x) => x as int;
testInt2negative(x) => x as int;
testNullableInt1(x) => x as int?;
testNullableInt2(x) => x as int?;
testDynamic(x) => x as dynamic;
testObjectNegative(x) => x as Object;
testNullableObject(x) => x as Object?;
testAOfNum1(x) => x as A<num>;
testAOfNum2negative(x) => x as A<num>;
testAOfNum3negative(x) => x as A<num>;
testAOfNullableNum(x) => x as A<num?>;
testNullableAOfNum(x) => x as A<num>?;
testNullableAOfNumNegative(x) => x as A<num>?;
testNullableAOfNullableNum(x) => x as A<num?>?;

void main() {
  testInt1(42);
  testInt2negative(null);
  testNullableInt1(42);
  testNullableInt2(null);
  testDynamic('hi');
  testObjectNegative(null);
  testNullableObject(null);
  testAOfNum1(new B<int>());
  testAOfNum2negative(new B<int?>());
  testAOfNum3negative(null);
  testAOfNullableNum(new B<int?>());
  testNullableAOfNum(null);
  testNullableAOfNumNegative(new B<int?>());
  testNullableAOfNullableNum(new B<int?>());
  new B<int>().testT1(42);
  new B<int>().testT2negative(null);
  new B<int?>().testT3(null);
  new B<int>().testNullableT1(42);
  new B<int>().testNullableT2(null);
}
