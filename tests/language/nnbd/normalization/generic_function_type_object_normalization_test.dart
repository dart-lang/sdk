// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'type_builder.dart';

// Tests for runtime type object normalization.

// Check that two objects have equal runtime types,
// compared in any order.
void checkTypeEquals2(Object? a, Object? b) {
  checkEquals2(a.runtimeType, b.runtimeType);
}

// Check that two objects have unequal runtime types,
// compared in any order.
void checkTypeNotEquals2(Object? a, Object? b) {
  checkNotEquals2(a.runtimeType, b.runtimeType);
}

// Check that three objects have equal runtime types,
// compared in combination and any order.
void checkTypeEquals3(Object? a, Object? b, Object? c) {
  checkTypeEquals2(a, b);
  checkTypeEquals2(a, c);
  checkTypeEquals2(b, c);
}

// Check that three objects have unequal runtime types,
// compared in combination and any order.
void checkTypeNotEquals3(Object? a, Object? b, Object? c) {
  checkTypeNotEquals2(a, b);
  checkTypeNotEquals2(a, c);
  checkTypeNotEquals2(b, c);
}

// Tests of generic function types.

class SimpleBoundTests<T> {
  // These are equal if `T` is equivalent to a top type or Object
  T f1<S extends FutureOr<T>>() => throw "Unused";
  T f2<R extends T>() => throw "Unused";

  // These are equal if `T` is equivalent to Never or Null
  T g1<S extends FutureOr<T>?>() => throw "Unused";
  T g2<R extends Future<T>?>() => throw "Unused";

  // These are equal if `T` is nullable
  T h1<S extends FutureOr<T>?>() => throw "Unused";
  T h2<R extends FutureOr<T>>() => throw "Unused";

  // If `T` is a top type, check that the appropriate
  // equalities and disequalities hold.
  static void checkAtTopType<T>() {
    var a = SimpleBoundTests<T>();
    checkTypeEquals2(a.f1, a.f2);
    checkTypeNotEquals2(a.g1, a.g2);
    checkTypeEquals2(a.h1, a.h2);
  }

  // Check the top type related equalites and inequalities
  // at various top types.
  static void checkTopTypes() {
    checkAtTopType<Object?>();
    checkAtTopType<void>();
    checkAtTopType<dynamic>();
    checkAtTopType<FutureOr<Object?>>();
  }

  // Check that the types of the methods above are equal or not at
  // a bottom type
  static void checkAtBottomType<T>() {
    var a = SimpleBoundTests<T>();
    checkTypeNotEquals2(a.f1, a.f2);
    checkTypeEquals2(a.g1, a.g2);
    if (null is T) {
      checkTypeEquals2(a.h1, a.h2);
    } else {
      checkTypeNotEquals2(a.h1, a.h2);
    }
  }

  // Check that the types of the methods above are equal or not at
  // the bottom types
  static void checkBottomTypes() {
    checkAtBottomType<Null>();
    checkAtBottomType<Never>();
    checkAtBottomType<Never?>();
  }

  // Check that the methods above have different types given
  // a non-top, non-nullable type.
  static void checkAtNonNullableType<T extends Object>() {
    var a = SimpleBoundTests<T>();
    checkTypeNotEquals2(a.f1, a.f2);
    checkTypeNotEquals2(a.g1, a.g2);
    checkTypeNotEquals2(a.h1, a.h2);
  }

  // Check that the methods above have different types for
  // several non-top non-nullable types.
  static void checkNonNullableTypes() {
    checkAtNonNullableType<int>();
    checkAtNonNullableType<String>();
    checkAtNonNullableType<Iterable<int>>();
    checkAtNonNullableType<Future<Object>>();
  }

  // Check that the methods above are equal or not given
  // a non-top nullable type.
  static void checkAtNullableType<T>() {
    var a = SimpleBoundTests<T>();
    checkTypeNotEquals2(a.f1, a.f2);
    checkTypeNotEquals2(a.g1, a.g2);
    checkTypeEquals2(a.h1, a.h2);
  }

  // Check that the methods above are equal or not for
  // several non-top nullable types.
  static void checkNullableTypes() {
    checkAtNullableType<int?>();
    checkAtNullableType<String?>();
    checkAtNullableType<Iterable<int>?>();
    checkAtNullableType<Future<Object>?>();
  }

  static void check() {
    checkTopTypes();
    checkBottomTypes();
    checkNonNullableTypes();
    checkNullableTypes();
  }
}

class NeverTests<T> {
  T f1<S extends T>(T x) => throw "Unused";
  S f2<S extends T>(Object? x) => throw "Unused";
  Never f3<S extends T>(Object? x) => throw "Unused";

  R g1<S extends T, R extends S>(List<S> x) => throw "Unused";
  Never g2<S extends T, R extends S>(List<Never> x) => throw "Unused";

  FutureOr<R> h1<S extends T, R extends S>(S? x) => throw "Unused";
  Future<Never> h2<S extends T, R extends S>(Null x) => throw "Unused";

  void Function<S0 extends FutureOr<R>, S1 extends R, S2 extends R?>()
      i1<R>() =>
          <T0 extends FutureOr<R>, T1 extends R, T2 extends R?>() {};

  void Function<S0 extends Future<Never>, S1 extends Never, S2 extends Null>()
      i2<R>() =>
          <R0 extends Future<Never>, R1 extends Never, R2 extends Null>() {};
}

void neverBoundTests() {
  {
    var o = NeverTests<Never>();
    checkTypeEquals3(o.f1, o.f2, o.f3);
    checkTypeEquals2(o.g1, o.g2);
    checkTypeEquals2(o.h1, o.h2);
    checkTypeEquals2(o.i1<Never>(), o.i2<Never>());
    checkTypeNotEquals2(o.i1<Null>(), o.i2<Null>());
  }
  {
    var o = NeverTests<Null>();
    checkTypeNotEquals3(o.f1, o.f2, o.f3);
    checkTypeNotEquals2(o.g1, o.g2);
    checkTypeNotEquals2(o.h1, o.h2);
    checkTypeEquals2(o.i1<Never>(), o.i2<Never>());
    checkTypeNotEquals2(o.i1<Null>(), o.i2<Null>());
  }
}

void fBoundedTests() {
  void f1<T extends FutureOr<T>>() {}
  void f2<S extends FutureOr<S>>() {}

  checkTypeEquals2(f1, f2);

  void g1<T extends List<S>, S extends T>() {}
  void g2<T0 extends List<S0>, S0 extends T0>() {}

  checkTypeEquals2(g1, g2);

  void h1<T extends FutureOr<T?>?>() {}
  void h2<S extends FutureOr<S?>>() {}

  checkTypeEquals2(h1, h2);
}

void main() {
  SimpleBoundTests.check();
  neverBoundTests();
  fBoundedTests();
}
