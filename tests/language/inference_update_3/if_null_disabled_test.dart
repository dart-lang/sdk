// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the absence of the functionality proposed in
// https://github.com/dart-lang/language/issues/1618#issuecomment-1507241494
// when the `inference-update-3` language feature is not enabled, using if-null
// expressions.

// @dart=3.3

import '../static_type_helper.dart';

/// Ensures a context type of `_` for the operand, if no type argument is
/// supplied.
Object? contextUnknown<T>(T x) => x;

/// Ensures a context type of `Iterable<T>` for the operand, or `Iterable<_>` if
/// no type argument is supplied.
Object? contextIterable<T>(Iterable<T> x) => x;

main() {
  // - An if-null expression `E` of the form `e1 ?? e2` with context type `K` is
  //   analyzed as follows:
  //
  //   - Let `T1` be the type of `e1` inferred with context type `K?`.
  {
    // Check the context type of `e1`:
    // - Where the context is established using a function call argument.
    context<num?>((contextType(1)..expectStaticType<Exactly<num?>>()) ?? 2);
    context<num>((contextType(1)..expectStaticType<Exactly<num?>>()) ?? 2);

    // - Where the context is established using local variable promotion.
    var o = 0 as Object?;
    if (o is num?) {
      o = (contextType(1)..expectStaticType<Exactly<num?>>()) ?? 2;
    }
    o = 0 as Object?;
    if (o is num) {
      o = (contextType(1)..expectStaticType<Exactly<num?>>()) ?? 2;
    }
  }

  //   - Let `T2` be the type of `e2` inferred with context type `J`, where:
  //     - If `K` is `_`, `J = T1`.
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

  //     - Otherwise, `J = K`.
  {
    var intQuestion = null as int?;
    context<num?>(
        intQuestion ?? (contextType(2)..expectStaticType<Exactly<num?>>()));
    context<num>(
        intQuestion ?? (contextType(2)..expectStaticType<Exactly<num>>()));
  }

  //   - Let `T` be `UP(NonNull(T1), T2)`.
  //   - Let `S` be the greatest closure of `K`.
  //   - If `T <: S`, then the type of `E` is `T`.
  {
    // K=Object, T1=int?, and T2=double, therefore T=num and S=Object, so T <:
    // S, and hence the type of E is num.
    var intQuestion = null as int?;
    var d = 2.0;
    context<Object>((intQuestion ?? d)..expectStaticType<Exactly<num>>());

    // K=Iterable<_>, T1=Iterable<int>?, and T2=Iterable<double>, therefore
    // T=Iterable<num> and S=Iterable<Object?>, so T <: S, and hence the type of
    // E is Iterable<num>.
    var iterableIntQuestion = null as Iterable<int>?;
    var iterableDouble = <double>[] as Iterable<double>;
    contextIterable((iterableIntQuestion ?? iterableDouble)
      ..expectStaticType<Exactly<Iterable<num>>>());
  }

  //   - Otherwise, if `NonNull(T1) <: S` and `T2 <: S`, then the type of `E` is
  //     `S` if `inference-update-3` is enabled, else the type of `E` is `T`.
  {
    // K=Iterable<num>, T1=Iterable<int>?, and T2=List<num>, therefore T=Object
    // and S=Iterable<num>, so T is not <: S, but NonNull(T1) <: S and T2 <: S,
    // hence the type of E is Object.
    var iterableIntQuestion = null as Iterable<int>?;
    var listNum = <num>[];
    var o = [0] as Object?;
    if (o is Iterable<num>) {
      // We avoid having a compile-time error because `o` can be demoted.
      o = (iterableIntQuestion ?? listNum)..expectStaticType<Exactly<Object>>();
    }
  }

  //   - Otherwise, the type of `E` is `T`.
  {
    var intQuestion = null as int?;
    var d = 2.0;
    var o = 0 as Object?;
    var doubleQuestion = null as double?;
    if (o is int?) {
      // K=int?, T1=int?, and T2=double, therefore T=num and S=int?, so T is not
      // <: S. NonNull(T1) <: S, but T2 is not <: S. Hence the type of E is num.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (intQuestion ?? d)..expectStaticType<Exactly<num>>();
    }
    o = 0 as Object?;
    if (o is int?) {
      // K=int?, T1=double?, and T2=int?, therefore T=num? and S=int?, so T is
      // not <: S. T2 <: S, but NonNull(T1) is not <: S. Hence the type of E is
      // num?.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (doubleQuestion ?? intQuestion)..expectStaticType<Exactly<num?>>();
    }
    o = '' as Object?;
    if (o is String?) {
      // K=String?, T1=int?, and T2=double, therefore T=num and S=String?, so
      // none of T, NonNull(T1), nor T2 are <: S. Hence the type of E is num.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (intQuestion ?? d)..expectStaticType<Exactly<num>>();
    }
  }
}
