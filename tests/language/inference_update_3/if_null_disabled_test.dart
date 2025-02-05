// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the absence of the functionality proposed in
// https://github.com/dart-lang/language/issues/1618#issuecomment-1507241494
// when the `inference-update-3` language feature is not enabled, using if-null
// expressions.

// @dart=3.3

import 'package:expect/static_type_helper.dart';

/// Ensures a context type of `_` for the operand, if no type argument is
/// supplied.
Object? contextUnknown<T>(T x) => x;

/// Ensures a context type of `Iterable<T>` for the operand, or `Iterable<_>` if
/// no type argument is supplied.
Object? contextIterable<T>(Iterable<T> x) => x;

main() {
  // - An if-null expression `e` of the form `e1 ?? e2` with context type K is
  //   analyzed as follows:
  //
  //   - Let T1 be the type of `e1` inferred with context type K?.
  {
    // Check the context type of `e1`:
    // - Where the context is established using a function call argument.
    context<num?>((contextType(1)..expectStaticType<Exactly<num?>>()) ?? 2);
    context<num>((contextType(1)..expectStaticType<Exactly<num?>>()) ?? 2);

    // - Where the context is established using local variable promotion.
    Object? o;
    o = 0 as Object?;
    if (o is num?) {
      o = (contextType(1)..expectStaticType<Exactly<num?>>()) ?? 2;
    }
    o = 0 as Object?;
    if (o is num) {
      o = (contextType(1)..expectStaticType<Exactly<num?>>()) ?? 2;
    }
  }

  //   - Let T2 be the type of `e2` inferred with context type J, where:
  //     - If K is `_`, J = T1.
  {
    // Check the context type of `e2`.
    var string = '';
    var stringQuestion = null as String?;
    contextUnknown(
        // ignore: dead_null_aware_expression
        string ?? (contextType('')..expectStaticType<Exactly<String>>()));
    contextUnknown(stringQuestion ??
        (contextType('')..expectStaticType<Exactly<String?>>()));
  }

  //     - Otherwise, J = K.
  {
    var intQuestion = null as int?;
    context<num?>(
        intQuestion ?? (contextType(2)..expectStaticType<Exactly<num?>>()));
    context<num>(
        intQuestion ?? (contextType(2)..expectStaticType<Exactly<num>>()));
  }

  //   - Let T be UP(NonNull(T1), T2).
  //   - Let S be the greatest closure of K.
  //   - If T <: S, then the type of `e` is T.
  //     (Testing this case here. Otherwise continued below.)
  {
    // This example has:
    // - K = Object
    // - T1 = int?
    // - T2 = double
    // Which implies:
    // - T = num
    // - S = Object
    // We have:
    // - T <: S
    // Therefore the type of `e` is T = num.
    var intQuestion = null as int?;
    var d = 2.0;
    context<Object>((intQuestion ?? d)..expectStaticType<Exactly<num>>());

    // This example has:
    // - K = Iterable<_>
    // - T1 = Iterable<int>?
    // - T2 = Iterable<double>
    // Which implies:
    // - T = Iterable<num>
    // - S = Iterable<Object?>
    // We have:
    // - T <: S
    // Therefore the type of `e` is T = Iterable<num>.
    var iterableIntQuestion = null as Iterable<int>?;
    var iterableDouble = <double>[] as Iterable<double>;
    contextIterable((iterableIntQuestion ?? iterableDouble)
      ..expectStaticType<Exactly<Iterable<num>>>());
  }

  //   - Otherwise, if NonNull(T1) <: S and T2 <: S, and `inference-update-3` is
  //     enabled, then the type of `e` is S.
  {
    // This example has:
    // - K = Iterable<num>
    // - T1 = Iterable<int>?
    // - T2 = List<num>
    // Which implies:
    // - T = Object
    // - S = Iterable<num>
    // We have:
    // - T <!: S
    // - NonNull(T1) <: S
    // - T2 <: S
    // However, inference-update-3 is not enabled.
    // Therefore the type of `e` is T = Object.
    var iterableIntQuestion = null as Iterable<int>?;
    var listNum = <num>[];
    Object? o;
    o = [0] as Object?;
    if (o is Iterable<num>) {
      // We avoid having a compile-time error because `o` can be demoted.
      o = (iterableIntQuestion ?? listNum)..expectStaticType<Exactly<Object>>();
    }
  }

  //   - Otherwise, the type of `e` is T.
  {
    var intQuestion = null as int?;
    var d = 2.0;
    Object? o;
    var doubleQuestion = null as double?;
    o = 0 as Object?;
    if (o is int?) {
      // This example has:
      // - K = int?
      // - T1 = int?
      // - T2 = double
      // Which implies:
      // - T = num
      // - S = int?
      // We have:
      // - T <!: S
      // - NonNull(T1) <: S
      // - T2 <!: S
      // The fact that T2 <!: S precludes using S as static type.
      // Therefore the type of `e` is T = num.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (intQuestion ?? d)..expectStaticType<Exactly<num>>();
    }
    o = 0 as Object?;
    if (o is int?) {
      // This example has:
      // - K = int?
      // - T1 = double?
      // - T2 = int?
      // Which implies:
      // - T = num?
      // - S = int?
      // We have:
      // - T <!: S
      // - NonNull(T1) <!: S
      // - T2 <: S
      // The fact that NonNull(T1) <!: S precludes using S as static type.
      // Therefore the type of `e` is T = num?.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (doubleQuestion ?? intQuestion)..expectStaticType<Exactly<num?>>();
    }
    o = '' as Object?;
    if (o is String?) {
      // This example has:
      // - K = String?
      // - T1 = int?
      // - T2 = double
      // Which implies:
      // - T = num
      // - S = String?
      // We have:
      // - T <!: S
      // - NonNull(T1) <!: S
      // - T2 <!: S
      // The fact that NonNull(T1) <!: S and T2 <!: S precludes using S as
      // static type.
      // Therefore the type of `e` is T = num.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (intQuestion ?? d)..expectStaticType<Exactly<num>>();
    }
  }
}
