// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the behavior of the enhanced promotion chain join algorithm
// (https://github.com/dart-lang/language/issues/4757), when enabled, for
// promotions of properties whose unpromoted type changes because the target of
// the property access is promoted.
//
// When a property is promoted, and the last type in its promotion chain isn't a
// subtype of the property's unpromoted type (because the target of the property
// access was promoted), any types in its promotion chain that the new promoted
// type is not a strict subtype of are discarded, so that the promotion chain
// remains valid and the join algorithm doesn't depend on the order of the
// control flow paths being joined. See
// https://github.com/dart-lang/sdk/issues/64799.

import 'dart:async';

import 'package:expect/static_type_helper.dart';

class C<T> {
  final T? _f;
  C(this._f);
}

void thenIntElseNum(C<Object?> x, bool b) {
  if (b) {
    if (x._f is! int) return;
    if (x is! C<String>) return;
    if (x._f == null) return;
  } else {
    if (x._f is! num) return;
    if (x is! C<String>) return;
    if (x._f == null) return;
  }
  x._f.expectStaticType<Exactly<String>>();
}

void thenNumElseInt(C<Object?> x, bool b) {
  if (b) {
    if (x._f is! num) return;
    if (x is! C<String>) return;
    if (x._f == null) return;
  } else {
    if (x._f is! int) return;
    if (x is! C<String>) return;
    if (x._f == null) return;
  }
  x._f.expectStaticType<Exactly<String>>();
}

void thenIntElseNothing(C<Object?> x, bool b) {
  if (b) {
    if (x._f is! int) return;
    if (x is! C<String>) return;
    if (x._f == null) return;
  } else {
    if (x is! C<String>) return;
    if (x._f == null) return;
  }
  x._f.expectStaticType<Exactly<String>>();
}

void thenNothingElseInt(C<Object?> x, bool b) {
  if (b) {
    if (x is! C<String>) return;
    if (x._f == null) return;
  } else {
    if (x._f is! int) return;
    if (x is! C<String>) return;
    if (x._f == null) return;
  }
  x._f.expectStaticType<Exactly<String>>();
}

void supertypePromotionKept(C<Object?> x) {
  if (x._f is! num) return;
  if (x is C<int>) {
    // `num` isn't a subtype of `int?`, so `x._f` isn't promoted here.
    x._f.expectStaticType<Exactly<int?>>();
    if (x._f == null) return;
    // `int` is a strict subtype of `num`, so the promotion to `num` is kept in
    // the promotion chain.
    x._f.expectStaticType<Exactly<int>>();
  }
  // Therefore it survives the join.
  x._f.expectStaticType<Exactly<num>>();
}

void stalePromotionsPartiallyDiscarded(C<Object?> x) {
  if (x._f is! Object) return;
  if (x._f is! int) return;
  if (x is C<String>) {
    // `int` isn't a subtype of `String?`, so `x._f` isn't promoted here.
    x._f.expectStaticType<Exactly<String?>>();
    if (x._f == null) return;
    // `String` is a strict subtype of `Object` but not of `int`, so the
    // promotion chain is now `[Object, String]`.
    x._f.expectStaticType<Exactly<String>>();
  }
  // Joining `[Object, String]` with `[Object, int]` produces `[Object]`.
  x._f.expectStaticType<Exactly<Object>>();
}

abstract interface class A {}

abstract interface class B {}

class AB implements A, B {}

void unrelatedPromotionLostAfterJoin(C<Object?> x) {
  if (x._f is! A) return;
  if (x is C<B> && x._f != null) {
    // The promotion chain is now `[B]`, since `B` is not a strict subtype of
    // `A`.
    x._f.expectStaticType<Exactly<B>>();
  }
  // Joining `[B]` with `[A]` produces `[]`. (When the
  // promotion-chain-intersection-join feature is disabled, the promotion
  // chain in the "then" branch is `[A, B]`, so the promotion to `A` is kept.)
  x._f.expectStaticType<Exactly<Object?>>();
}

// The following tests verify that the promotion chain of a property is not
// filtered when a pattern promotes it multiple times without its target being
// promoted. In this situation, the promotions performed by later subpatterns
// (or `switch` cases) are not computed relative to the promotions performed by
// earlier ones, so they might not be strict subtypes of them.

class D {
  final Object? _f;
  D(this._f);
}

class Super {}

class Sub extends Super {}

void logicalAndPatternWithUnrelatedTypes(D d, bool b) {
  if (b) {
    if (d._f is! A) return;
  } else {
    if (d._f case A() && B()) {
    } else {
      return;
    }
  }
  d._f.expectStaticType<Exactly<A>>();
}

void logicalAndPatternWithSubtypeThenSupertype(D d, bool b) {
  if (b) {
    if (d._f is! Sub) return;
  } else {
    if (d._f case Sub() && Super()) {
    } else {
      return;
    }
  }
  d._f.expectStaticType<Exactly<Sub>>();
}

class E {
  final FutureOr<num>? _f;
  E(this._f);
}

void switchCases(E e, bool b) {
  if (b) {
    if (e._f == null) return;
  } else {
    switch (e._f) {
      case null:
        return;
      case Future<num>():
        return;
      default:
        break;
    }
  }
  e._f.expectStaticType<Exactly<FutureOr<num>>>();
}

void main() {
  for (var x in [
    C<Object?>(null),
    C<Object?>(0),
    C<int>(0),
    C<String>(''),
    C<Object?>(AB()),
    C<B>(AB()),
  ]) {
    for (var b in [true, false]) {
      thenIntElseNum(x, b);
      thenNumElseInt(x, b);
      thenIntElseNothing(x, b);
      thenNothingElseInt(x, b);
    }
    supertypePromotionKept(x);
    stalePromotionsPartiallyDiscarded(x);
    unrelatedPromotionLostAfterJoin(x);
  }
  for (var d in [D(null), D(0), D(AB()), D(Sub()), D(Super())]) {
    for (var b in [true, false]) {
      logicalAndPatternWithUnrelatedTypes(d, b);
      logicalAndPatternWithSubtypeThenSupertype(d, b);
    }
  }
  for (var e in [E(null), E(0), E(Future<num>.value(0))]) {
    for (var b in [true, false]) {
      switchCases(e, b);
    }
  }
}
