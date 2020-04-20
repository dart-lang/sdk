// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

// Testing that i2b and checks for correct super-boundedness are applied
// to type arguments, taking the variance of type parameters into account.

// Standard type comparison support.

typedef F<X> = void Function<Y extends X>();
F<X> toF<X>(X x) => null;

// Material specific to this test.

typedef Fcov<X> = X Function();
typedef Fcon<X> = Function(X);
typedef Finv<X> = X Function(X);

class Acov<X extends Fcov<Y>, Y> {}

class Acon<X extends Fcon<Y>, Y> {}

class Ainv<X extends Finv<Y>, Y> {}

typedef FcovBound<X extends num> = X Function();
typedef FconBound<X extends num> = Function(X);
typedef FinvBound<X extends num> = X Function(X);

class AcovBound<X extends FcovBound<Y>, Y extends num> {}

class AconBound<X extends FconBound<Y>, Y extends num> {}

class AinvBound<X extends FinvBound<Y>, Y extends num> {}

class A<X> {}

typedef FcovCyclicBound<X extends A<X>> = X Function();
typedef FconCyclicBound<X extends A<X>> = Function(X);
typedef FinvCyclicBound<X extends A<X>> = X Function(X);

class AcovCyclicBound<X extends FcovCyclicBound<Y>, Y extends A<Y>> {}

class AconCyclicBound<X extends FconCyclicBound<Y>, Y extends A<Y>> {}

class AinvCyclicBound<X extends FinvCyclicBound<Y>, Y extends A<Y>> {}

typedef FcovCyclicCoBound<X extends Function(X)> = X Function();
typedef FconCyclicCoBound<X extends Function(X)> = Function(X);
typedef FinvCyclicCoBound<X extends Function(X)> = X Function(X);

class AcovCyclicCoBound<X extends FcovCyclicCoBound<Y>, Y extends Function(Y)> {
}

class AconCyclicCoBound<X extends FconCyclicCoBound<Y>, Y extends Function(Y)> {
}

class AinvCyclicCoBound<X extends FinvCyclicCoBound<Y>, Y extends Function(Y)> {
}

class B<X> {}

void testTypeAliasAsTypeArgument() {
  // I2b: Use bounds (Fcov<Y>, dynamic), then replace covariant occurrence
  // (of `Y` in `Acov<Fcov<Y>, _>`) by `Y`s value `dynamic`. Resulting type
  // `Acov<Fcov<dynamic>, dynamic>` is regular-bounded.
  Acov source1;
  var fsource1 = toF(source1);
  F<Acov<Fcov<dynamic>, dynamic>> target1 = fsource1;

  // I2b: Use bounds (Fcon<Y>, dynamic), then replace contravariant occurrence
  // (of `Y` in `Acon<Fcon<Y>, _>`) by `Null`. Resulting type
  // is super-bounded: Acon<Fcon<Object>, Null> is regular-bounded.
  Acon source2;
  var fsource2 = toF(source2);
  F<Acon<Fcon<Null>, dynamic>> target2 = fsource2;

  // I2b: Use bounds (Finv<Y>, dynamic) then replace invariant occurrence
  // (of `Y` in `Ainv<Finv<Y>, _>`) by `Y`s value `dynamic`. Resulting type
  // `Ainv<Finv<dynamic>, dynamic>` is regular-bounded.
  Ainv source3;
  var fsource3 = toF(source3);
  F<Ainv<Finv<dynamic>, dynamic>> target3 = fsource3;

  // I2b: Use bounds (FcovBound<Y>, num), then replace covariant occurrence
  // (of `Y` in `AcovBound<FcovBound<Y>, _>`) by `Y`s value `num`.
  // Resulting type `AcovBound<FcovBound<num>, num>` is regular-bounded.
  AcovBound source4;
  var fsource4 = toF(source4);
  F<AcovBound<FcovBound<num>, num>> target4 = fsource4;

  // I2b: Use bounds (FconBound<Y>, num), then replace contravariant occurrence
  // of `Y` in `AconBound<FconBound<Y>, _>` by `Null`. Resulting type is
  // super-bounded: AconBound<FconBound<Object>, num> is regular-bounded.
  AconBound source5;
  var fsource5 = toF(source5);
  F<AconBound<FconBound<Null>, num>> target5 = fsource5;

  // I2b: Use bounds (FinvBound<Y>, num), then replace invariant occurrence
  // of `Y` in `AinvBound<FinvBound<Y>, _>` by `Y`s value `num`. Resulting
  // type `AinvBound<FinvBound<num>, num>` is regular-bounded.
  AinvBound source6;
  var fsource6 = toF(source6);
  F<AinvBound<FinvBound<num>, num>> target6 = fsource6;

  // I2b: Use bounds (FcovCyclicBound<Y>, A<Y>), then break cycle {Y} by
  // replacing covariant occurrence of `Y` in `AcovCyclicBound<_, A<Y>>`
  // by `dynamic`; then replace covariant occurrence of `Y` in
  // `AcovCyclicBound<FcovCyclicBound<Y>, _>` by `Y`s value `A<dynamic>`.
  // Resulting type `AcovCyclicBound<FcovCyclicBound<A<dynamic>>, A<dynamic>>>`
  // is regular-bounded.
  AcovCyclicBound source7;
  var fsource7 = toF(source7);
  F<AcovCyclicBound<FcovCyclicBound<A<dynamic>>, A<dynamic>>> target7 =
      fsource7;

  // I2b: Use bounds (FconCyclicBound<Y>, A<Y>), then break cycle {Y} by
  // replacing covariant occurrence of `Y` in `AconCyclicBound<_, A<Y>>`
  // by `dynamic`; then replace contravariant occurrence of `Y` in
  // `AconCyclicBound<FconCyclicBound<Y>, _>` by `Null`.
  // Resulting type `AconCyclicBound<FconCyclicBound<Null>, A<dynamic>>>` is
  // super-bounded because `AconCyclicBound<FconCyclicBound<Object>, A<Null>>>`
  // is regular-bounded.
  AconCyclicBound source8;
  var fsource8 = toF(source8);
  F<AconCyclicBound<FconCyclicBound<Null>, A<dynamic>>> target8 = fsource8;

  // I2b: Use bounds (FinvCyclicBound<Y>, A<Y>), then break cycle {Y} by
  // replacing covariant occurrence of `Y` in `AinvCyclicBound<_, A<Y>>`
  // by `dynamic`; then replace invariant occurrence of `Y` in
  // `AinvCyclicBound<FinvCyclicBound<Y>, _>` by `Y`s value `A<dynamic>`.
  // Resulting type `AinvCyclicBound<FinvCyclicBound<A<dynamic>>, A<dynamic>>>`
  // looks regular-bounded, but contains `FinvCyclicBound<A<dynamic>>` which
  // is not well-bounded.
  AinvCyclicBound source9; //# 01: compile-time error
  // var fsource9 = toF(source9);
  // F<AinvCyclicBound<FinvCyclicBound<A<dynamic>>, A<dynamic>>> target9 =
  //     fsource9;

  // I2b: Use bounds (FcovCyclicCoBound<Y>, Function(Y)), then break cycle {Y}
  // by replacing contravariant occurrence of `Y` in
  // `AcovCyclicCoBound<_, Function(Y)>` by `Null`; then replace covariant
  // occurrence of `Y` in `AcovCyclicCoBound<FcovCyclicCoBound<Y>, _>` by `Y`s
  // value `Function(Null)`. Resulting type
  // `AcovCyclicCoBound<FcovCyclicCoBound<Function(Null)>, Function(Null)>`
  // is regular-bounded, with subterm `FcovCyclicCoBound<Function(Null)>` which
  // is super-bounded because `FcovCyclicCoBound<Function(Object)>` is
  // regular-bounded.
  AcovCyclicCoBound source10;
  var fsource10 = toF(source10);
  F<AcovCyclicCoBound<FcovCyclicCoBound<Function(Null)>, Function(Null)>>
      target10 = fsource10;

  // I2b: Use bounds (FconCyclicCoBound<Y>, Function(Y)), then break cycle {Y}
  // by replacing contravariant occurrence of `Y` in
  // `AconCyclicCoBound<_, Function(Y)>` by `Null`; then replace contravariant
  // occurrence of `Y` in `AconCyclicCoBound<FconCyclicCoBound<Y>, _>` by
  // `Null`. Resulting type
  // `AconCyclicCoBound<FconCyclicCoBound<Null>, Function(Null)>` is
  // super-bounded because
  // `AconCyclicCoBound<FconCyclicCoBound<Object>, Function(Object)>` is
  // regular-bounded.
  AconCyclicCoBound source11;
  var fsource11 = toF(source11);
  F<AconCyclicCoBound<FconCyclicCoBound<Null>, Function(Null)>> target11 =
      fsource11;

  // I2b: Use bounds (FinvCyclicCoBound<Y>, Function(Y)), then break cycle {Y}
  // by replacing contravariant occurrence of `Y` in
  // `AinvCyclicCoBound<_, Function(Y)>` by `Null`; then replace invariant
  // occurrence of `Y` in `AinvCyclicCoBound<FinvCyclicCoBound<Y>, _>` by `Y`s
  // value `Function(Null)`.
  // Resulting type
  // `AinvCyclicCoBound<FinvCyclicCoBound<Function(Null)>, Function(Null)>>`
  // looks regular-bounded, but contains `FinvCyclicCoBound<Function(Null)>`
  // which is not well-bounded.
  AinvCyclicCoBound source12; //# 02: compile-time error
  // var fsource12 = toF(source12);
  // F<AinvCyclicCoBound<FinvCyclicCoBound<Function(Null)>, Function(Null)>>
  //     target12 = fsource12;
}

void testNested() {
  // Everything gets the same treatment when the cases from `testTopLevel`
  // are duplicated at the nested level in a covariant position.

  B<Acov> source1;
  var fsource1 = toF(source1);
  F<B<Acov<Fcov<dynamic>, dynamic>>> target1 = fsource1;

  B<Acon> source2;
  var fsource2 = toF(source2);
  F<B<Acon<Fcon<Null>, dynamic>>> target2 = fsource2;

  B<Ainv> source3;
  var fsource3 = toF(source3);
  F<B<Ainv<Finv<dynamic>, dynamic>>> target3 = fsource3;

  B<AcovBound> source4;
  var fsource4 = toF(source4);
  F<B<AcovBound<FcovBound<num>, num>>> target4 = fsource4;

  B<AconBound> source5;
  var fsource5 = toF(source5);
  F<B<AconBound<FconBound<Null>, num>>> target5 = fsource5;

  B<AinvBound> source6;
  var fsource6 = toF(source6);
  F<B<AinvBound<FinvBound<num>, num>>> target6 = fsource6;

  B<AcovCyclicBound> source7;
  var fsource7 = toF(source7);
  F<B<AcovCyclicBound<FcovCyclicBound<A<dynamic>>, A<dynamic>>>> target7 =
      fsource7;

  B<AconCyclicBound> source8;
  var fsource8 = toF(source8);
  F<B<AconCyclicBound<FconCyclicBound<Null>, A<dynamic>>>> target8 = fsource8;

  B<AinvCyclicBound> source9; //# 03: compile-time error
  // var fsource9 = toF(source9);
  // F<B<AinvCyclicBound<FinvCyclicBound<A<dynamic>>, A<dynamic>>>> target9 =
  //    fsource9;

  B<AcovCyclicCoBound> source10;
  var fsource10 = toF(source10);
  F<B<AcovCyclicCoBound<FcovCyclicCoBound<Function(Null)>, Function(Null)>>>
      target10 = fsource10;

  B<AconCyclicCoBound> source11;
  var fsource11 = toF(source11);
  F<B<AconCyclicCoBound<FconCyclicCoBound<Null>, Function(Null)>>> target11 =
      fsource11;

  B<AinvCyclicCoBound> source12; //# 04: compile-time error
  // var fsource12 = toF(source12);
  // F<B<AinvCyclicCoBound<FinvCyclicCoBound<Function(Null)>, Function(Null)>>>
  //     target12 = fsource12;
}

main() {
  testTypeAliasAsTypeArgument();
  testNested();
}
