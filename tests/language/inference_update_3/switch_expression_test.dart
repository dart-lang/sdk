// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the functionality proposed in
// https://github.com/dart-lang/language/issues/1618#issuecomment-1507241494,
// using switch expressions.

import '../static_type_helper.dart';

/// Ensures a context type of `Iterable<T>` for the operand, or `Iterable<_>` if
/// no type argument is supplied.
Object? contextIterable<T>(Iterable<T> x) => x;

class A {}

class B1<T> implements A {}

class B2<T> implements A {}

class C1<T> implements B1<T>, B2<T> {}

class C2<T> implements B1<T>, B2<T> {}

/// Ensures a context type of `B1<T>` for the operand, or `B1<_>` if no type
/// argument is supplied.
Object? contextB1<T>(B1<T> x) => x;

test(int i) {
  // The static type of a switch expression `e` of the form `switch (e0) { p1 =>
  // e1, p2 => e2, ... pn => en }` with context type K is computed as follows:
  //
  // - The scrutinee (`e0`) is first analyzed with context type `_`.
  // - If the switch expression has no cases, its static type is `Never`.
  // - Otherwise, for each case `pi => ei`, let Ti be the type of `ei` inferred
  //   with context type K.
  {
    // Check the context type of each `ei`:
    // - Where the context is established using a function call argument.
    context<String>(switch (i) {
      0 => (contextType('')..expectStaticType<Exactly<String>>()),
      1 => (contextType('')..expectStaticType<Exactly<String>>()),
      _ => (contextType('')..expectStaticType<Exactly<String>>())
    });

    // - Where the context is established using local variable promotion.
    Object? o;
    o = '' as Object?;
    if (o is String) {
      o = switch (i) {
        0 => (contextType('')..expectStaticType<Exactly<String>>()),
        1 => (contextType('')..expectStaticType<Exactly<String>>()),
        _ => (contextType('')..expectStaticType<Exactly<String>>())
      };
    }
  }

  // - Let T be the least upper bound of the static types of all the case
  //   expressions.
  // - Let S be the greatest closure of K.
  // - If T <: S, then the type of `e` is T.
  {
    // This example has:
    // - K = Object
    // - T1 = int
    // - T2 = double
    // Which implies:
    // - T = num
    // - S = Object
    // We have:
    // - T <: S
    // Therefore the type of `e` is T = num.
    var d = 2.0;
    context<Object>(
        (switch (i) { 0 => i, _ => d })..expectStaticType<Exactly<num>>());

    // This example has:
    // - K = Iterable<_>
    // - T1 = Iterable<int>
    // - T2 = Iterable<double>
    // Which implies:
    // - T = Iterable<num>
    // - S = Iterable<Object?>
    // We have:
    // - T <: S
    // Therefore the type of `e` is T = Iterable<num>.
    var iterableInt = <int>[] as Iterable<int>;
    var iterableDouble = <double>[] as Iterable<double>;
    contextIterable((switch (i) { 0 => iterableInt, _ => iterableDouble })
      ..expectStaticType<Exactly<Iterable<num>>>());
  }

  // - Otherwise, if Ti <: S for all i, then the type of `e` is S.
  {
    // This example has:
    // - K = B1<_>
    // - T1 = C1<int>
    // - T2 = C2<double>
    // Which implies:
    // - T = A
    // - S = B1<Object?>
    // We have:
    // - T <!: S
    // - T1 <: S
    // - T2 <: S
    // Therefore the type of `e` is S = B1<Object?>.
    var c1Int = C1<int>();
    var c2Double = C2<double>();
    contextB1((switch (i) { 0 => c1Int, _ => c2Double })
      ..expectStaticType<Exactly<B1<Object?>>>());

    // This example has:
    // - K = B1<Object>
    // - T1 = C1<int>
    // - T2 = C2<double>
    // Which implies:
    // - T = A
    // - S = B1<Object>
    // We have:
    // - T <!: S
    // - T1 <: S
    // - T2 <: S
    // Therefore the type of `e` is S = B1<Object>.
    contextB1<Object>((switch (i) { 0 => c1Int, _ => c2Double })
      ..expectStaticType<Exactly<B1<Object>>>());

    // This example has:
    // - K = Iterable<num>
    // - T1 = Iterable<int>
    // - T2 = List<num>
    // Which implies:
    // - T = Object
    // - S = Iterable<num>
    // We have:
    // - T <!: S
    // - T1 <: S
    // - T2 <: S
    // Therefore the type of `e` is S = Iterable<num>.
    var iterableInt = <int>[] as Iterable<int>;
    var listNum = <num>[];
    context<Iterable<num>>((switch (i) { 0 => iterableInt, _ => listNum })
      ..expectStaticType<Exactly<Iterable<num>>>());
  }

  // - Otherwise, the type of `e` is T.
  {
    Object? o;
    var d = 2.0;
    o = '' as Object?;
    if (o is String?) {
      // This example has:
      // - K = String?
      // - T1 = Null
      // - T2 = int
      // Which implies:
      // - T = int?
      // - S = String?
      // We have:
      // - T <!: S
      // - T1 <: S
      // - T2 <!: S
      // The fact that T2 <!: S precludes using S as static type.
      // Therefore the type of `e` is T = int?.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (switch (i) { 0 => null, _ => i })..expectStaticType<Exactly<int?>>();
    }
    o = '' as Object?;
    if (o is String?) {
      // This example has:
      // - K = String?
      // - T1 = int
      // - T2 = Null
      // Which implies:
      // - T = int?
      // - S = String?
      // We have:
      // - T <!: S
      // - T1 <!: S
      // - T2 <: S
      // The fact that T1 <!: S precludes using S as static type.
      // Therefore the type of `e` is T = int?.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (switch (i) { 0 => i, _ => null })..expectStaticType<Exactly<int?>>();
    }
    o = '' as Object?;
    if (o is String?) {
      // This example has:
      // - K = String?
      // - T1 = int
      // - T2 = double
      // Which implies:
      // - T = num
      // - S = String?
      // We have:
      // - T <!: S
      // - T1 <!: S
      // - T2 <!: S
      // The fact that T1 <!: S and T2 <!: S precludes using S as static type.
      // Therefore the type of `e` is T = num.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (switch (i) { 0 => i, _ => d })..expectStaticType<Exactly<num>>();
    }
  }
}

main() {
  test(0);
  test(1);
  test(2);
}
