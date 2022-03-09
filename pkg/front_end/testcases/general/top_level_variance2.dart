// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing that instantiate-to-bound and super-bounded types take the
// variance of formal type parameters into account when a type alias is
// used as a raw type.

// Standard type comparison support.

typedef F<X> = void Function<Y extends X>();
F<X> toF<X>(X x) => throw '';

// Material specific to this test.

typedef Fcov<X> = X Function();
typedef Fcon<X> = Function(X);
typedef Finv<X> = X Function(X);

typedef FcovBound<X extends num> = X Function();
typedef FconBound<X extends num> = Function(X);
typedef FinvBound<X extends num> = X Function(X);

class A<X> {}

typedef FcovCyclicBound<X extends A<X>> = X Function();
typedef FconCyclicBound<X extends A<X>> = Function(X);
typedef FinvCyclicBound<X extends A<X>> = X Function(X);

typedef FcovCyclicCoBound<X extends Function(X)> = X Function();
typedef FconCyclicCoBound<X extends Function(X)> = Function(X);
typedef FinvCyclicCoBound<X extends Function(X)> = X Function(X);

class B<X> {}

void testTopLevel(
    Fcov source1,
    Fcon source2,
    Finv source3,
    FcovBound source4,
    FconBound source5,
    FinvBound source6,
    FcovCyclicBound source7,
    FconCyclicBound source8,
    FcovCyclicCoBound source10,
    FconCyclicCoBound source11,
    FinvCyclicCoBound source12) {
  // I2b initial value for a covariant type parameter w/o bound: dynamic.
  var fsource1 = toF(source1);
  F<Fcov<dynamic>> target1 = fsource1;

  // I2b initial value for a contravariant type parameter w/o bound: dynamic.
  var fsource2 = toF(source2);
  F<Fcon<dynamic>> target2 = fsource2;

  // I2b initial value for an invariant type parameter w/o bound: dynamic.
  var fsource3 = toF(source3);
  F<Finv<dynamic>> target3 = fsource3;

  // I2b initial value for a covariant type parameter: bound.
  var fsource4 = toF(source4);
  F<FcovBound<num>> target4 = fsource4;

  // I2b initial value for a contravariant type parameter: bound.
  var fsource5 = toF(source5);
  F<FconBound<num>> target5 = fsource5;

  // I2b initial value for an invariant type parameter: bound.
  var fsource6 = toF(source6);
  F<FinvBound<num>> target6 = fsource6;

  // I2b for a covariant type parameter w F-bound: Use bound, then break
  // cycle by replacing covariant occurrence by `dynamic`. Resulting type
  // is super-bounded: FcovCyclicBound<A<Null>> is regular-bounded.
  var fsource7 = toF(source7);
  F<FcovCyclicBound<A<dynamic>>> target7 = fsource7;

  // I2b for a contravariant type parameter w F-bound: Use bound, then break
  // cycle by replacing contravariant occurrence by `Never`. Resulting type
  // is super-bounded: FconCyclicBound<A<Object>> is regular-bounded.
  var fsource8 = toF(source8);
  F<FconCyclicBound<A<Never>>> target8 = fsource8;

  // I2b for an invariant type parameter w F-bound: Use bound, then break
  // cycle by replacing invariant occurrence by `dynamic`. Resulting type is
  // _not_ super-bounded: FinvCyclicBound<A<dynamic>> not regular-bounded.
  FinvCyclicBound source9; //# 01: compile-time error
  // var fsource9 = toF(source9);
  // F<FinvCyclicBound<A<dynamic>>> target9 = fsource9;

  // I2b for a covariant type parameter w F-bound: Use bound, then break
  // cycle by replacing contravariant occurrence by `Never`. Resulting type
  // is super-bounded: FcovCyclicBound<Function(Object)> is regular-bounded.
  var fsource10 = toF(source10);
  F<FcovCyclicCoBound<Function(Never)>> target10 = fsource10;

  // I2b for a contravariant type parameter w F-bound: Use bound, then break
  // cycle by replacing covariant occurrence by `dynamic`. Resulting type
  // FconCyclicCoBound<Function(dynamic)> is regular-bounded.
  var fsource11 = toF(source11);
  F<FconCyclicCoBound<Function(dynamic)>> target11 = fsource11;

  // I2b for an invariant type parameter w F-bound: Use bound, then break
  // cycle by replacing invariant occurrence by `dynamic`. Resulting type
  // F<FinvCyclicCoBound<Function(dynamic)>> is regular-bounded.
  var fsource12 = toF(source12);
  F<FinvCyclicCoBound<Function(dynamic)>> target12 = fsource12;
}

void testNested(
    B<Fcov> source1,
    B<Fcon> source2,
    B<Finv> source3,
    B<FcovBound> source4,
    B<FconBound> source5,
    B<FinvBound> source6,
    B<FcovCyclicBound> source7,
    B<FconCyclicBound> source8,
    B<FcovCyclicCoBound> source10,
    B<FconCyclicCoBound> source11,
    B<FinvCyclicCoBound> source12) {
  // Everything gets the same treatment when the cases from
  // `testTopLevel` are duplicated at the nested level.

  var fsource1 = toF(source1);
  F<B<Fcov<dynamic>>> target1 = fsource1;

  var fsource2 = toF(source2);
  F<B<Fcon<dynamic>>> target2 = fsource2;

  var fsource3 = toF(source3);
  F<B<Finv<dynamic>>> target3 = fsource3;

  var fsource4 = toF(source4);
  F<B<FcovBound<num>>> target4 = fsource4;

  var fsource5 = toF(source5);
  F<B<FconBound<num>>> target5 = fsource5;

  var fsource6 = toF(source6);
  F<B<FinvBound<num>>> target6 = fsource6;

  var fsource7 = toF(source7);
  F<B<FcovCyclicBound<A<dynamic>>>> target7 = fsource7;

  var fsource8 = toF(source8);
  F<B<FconCyclicBound<A<Never>>>> target8 = fsource8;

  B<FinvCyclicBound> source9; //# 02: compile-time error
  // var fsource9 = toF(source9);
  // F<B<FinvCyclicBound<A<dynamic>>>> target9 = fsource9;

  var fsource10 = toF(source10);
  F<B<FcovCyclicCoBound<Function(Never)>>> target10 = fsource10;

  var fsource11 = toF(source11);
  F<B<FconCyclicCoBound<Function(dynamic)>>> target11 = fsource11;

  var fsource12 = toF(source12);
  F<B<FinvCyclicCoBound<Function(dynamic)>>> target12 = fsource12;
}

main() {}
