// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests elimination of type casts.
// This test requires sound null safety.

class A<T> {
  const A();
}

class B<T> extends A<T> {
  testT1(x) => x as T;
  testT2negative(x) => x as T;
  testT3(x) => x as T;
  testNullableT1(x) => x as T?;
  testNullableT2(x) => x as T?;
}

class C1 {}

class C2 {}

class D<T> extends A<T> {
  final int id;
  const D(this.id);
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

// Regression test: union of two SetTypes containing distinct non-identical
// ConcreteType instances of D<int> (from two separate `new D<int>()` sites)
// must preserve D<int>'s type arguments instead of widening to raw D.
dynamic makeSet1(bool cond) => cond ? new D<int>(1) : new C1();
dynamic makeSet2(bool cond) => cond ? new D<int>(2) : new C2();
testSetUnionOfGenericAllocations(bool c1, bool c2) =>
    ((c1 ? makeSet1(c2) : makeSet2(c2)) as D) as A<num>;

// Tests for generic constants and unions of generic constants with same typeArgs.
testConstDOfInt(x) => x as A<num>;
testUnionOfTwoConstsSameTypeArgs(bool cond) =>
    (cond ? const D<int>(1) : const D<int>(2)) as A<num>;
testUnionOfConstAndNewSameTypeArgs(bool cond) =>
    (cond ? const D<int>(1) : new D<int>(2)) as A<num>;
testUnionOfConstAndNewDifferentTypeArgsNegative(bool cond) =>
    (cond ? const D<int>(1) : new D<int?>(2)) as A<num>;

dynamic makeConstSet1(bool cond) => cond ? const D<int>(1) : new C1();
dynamic makeConstSet2(bool cond) => cond ? const D<int>(2) : new C2();
testSetUnionOfConstsSameTypeArgs(bool c1, bool c2) =>
    ((c1 ? makeConstSet1(c2) : makeConstSet2(c2)) as D) as A<num>;
testSetUnionWithConstSameTypeArgs(bool c1, bool c2) =>
    ((c1 ? makeConstSet1(c2) : const D<int>(2)) as D) as A<num>;
testSetUnionWithNewSameTypeArgs(bool c1, bool c2) =>
    ((c1 ? makeConstSet1(c2) : new D<int>(2)) as D) as A<num>;

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

  final cond = int.parse('1') == 1;
  testSetUnionOfGenericAllocations(cond, !cond);
  testConstDOfInt(const D<int>(1));
  testUnionOfTwoConstsSameTypeArgs(cond);
  testUnionOfConstAndNewSameTypeArgs(cond);
  testUnionOfConstAndNewDifferentTypeArgsNegative(cond);
  testSetUnionOfConstsSameTypeArgs(cond, !cond);
  testSetUnionWithConstSameTypeArgs(cond, !cond);
  testSetUnionWithNewSameTypeArgs(cond, !cond);
}
