// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the absence of the functionality proposed in
// https://github.com/dart-lang/language/issues/1618#issuecomment-1507241494
// when the `inference-update-3` language feature is not enabled, using if-null
// assignments whose target is a property of the current extension, accessed
// through implicit `this`.

// @dart=3.3

import '../static_type_helper.dart';

/// Ensures a context type of `Iterable<T>` for the operand, or `Iterable<_>` if
/// no type argument is supplied.
Object? contextIterable<T>(Iterable<T> x) => x;

extension on String {
  double? get pDoubleQuestion => null;
  set pDoubleQuestion(Object? value) {}
  int? get pIntQuestion => null;
  set pIntQuestion(Object? value) {}
  Iterable<int>? get pIterableIntQuestion => null;
  set pIterableIntQuestion(Object? value) {}
  String get pString => '';
  set pString(Object? value) {}
  String? get pStringQuestion => null;
  // Note: for most of the tests below, the write type of the setter doesn't
  // matter (which is why all the setters above use a write type of `Object?`).
  // But we need at least one test case where the write type is something
  // different, to make sure it's properly reflected in the context for the
  // right hand side of `??=`. So for this setter we use a write type of
  // `String?`.
  set pStringQuestion(String? value) {}

  test() {
    // - An if-null assignment `E` of the form `lvalue ??= e` with context type
    //   `K` is analyzed as follows:
    //
    //   - Let `T1` be the read type of the lvalue.
    //   - Let `T2` be the type of `e` inferred with context type `J`, where:
    //     - If the lvalue is a local variable, `J` is the promoted type of the
    //       variable.
    //     - Otherwise, `J` is the write type of the lvalue.
    {
      // Check the context type of `e`.
      // ignore: dead_null_aware_expression
      pString ??= contextType('')..expectStaticType<Exactly<Object?>>();

      pStringQuestion ??= contextType('')..expectStaticType<Exactly<String?>>();
    }

    //   - Let `T` be `UP(NonNull(T1), T2)`.
    //   - Let `S` be the greatest closure of `K`.
    //   - If `T <: S`, then the type of `E` is `T`.
    {
      // K=Object, T1=int?, and T2=double, therefore T=num and S=Object, so T <:
      // S, and hence the type of E is num.
      var d = 2.0;
      context<Object>((pIntQuestion ??= d)..expectStaticType<Exactly<num>>());

      // K=Iterable<_>, T1=Iterable<int>?, and T2=Iterable<double>, therefore
      // T=Iterable<num> and S=Iterable<Object?>, so T <: S, and hence the type
      // of E is Iterable<num>.
      var iterableDouble = <double>[] as Iterable<double>;
      contextIterable((pIterableIntQuestion ??= iterableDouble)
        ..expectStaticType<Exactly<Iterable<num>>>());
    }

    //   - Otherwise, if `NonNull(T1) <: S` and `T2 <: S`, then the type of `E`
    //     is `S` if `inference-update-3` is enabled, else the type of `E` is
    //     `T`.
    {
      // K=Iterable<num>, T1=Iterable<int>?, and T2=List<num>, therefore
      // T=Object and S=Iterable<num>, so T is not <: S, but NonNull(T1) <: S
      // and T2 <: S, hence the type of E is Object.
      var listNum = <num>[];
      var o = [0] as Object?;
      if (o is Iterable<num>) {
        // We avoid having a compile-time error because `o` can be demoted.
        o = (pIterableIntQuestion ??= listNum)
          ..expectStaticType<Exactly<Object>>();
      }
    }

    //   - Otherwise, the type of `E` is `T`.
    {
      var d = 2.0;
      var o = 0 as Object?;
      var intQuestion = null as int?;
      if (o is int?) {
        // K=int?, T1=int?, and T2=double, therefore T=num and S=int?, so T is
        // not <: S. NonNull(T1) <: S, but T2 is not <: S. Hence the type of E
        // is num.
        // We avoid having a compile-time error because `o` can be demoted.
        o = (pIntQuestion ??= d)..expectStaticType<Exactly<num>>();
      }
      o = 0 as Object?;
      if (o is int?) {
        // K=int?, T1=double?, and T2=int?, therefore T=num? and S=int?, so T is
        // not <: S. T2 <: S, but NonNull(T1) is not <: S. Hence the type of E
        // is num?.
        // We avoid having a compile-time error because `o` can be demoted.
        o = (pDoubleQuestion ??= intQuestion)
          ..expectStaticType<Exactly<num?>>();
      }
      o = '' as Object?;
      if (o is String?) {
        // K=String?, T1=int?, and T2=double, therefore T=num and S=String?, so
        // none of T, NonNull(T1), nor T2 are <: S. Hence the type of E is num.
        // We avoid having a compile-time error because `o` can be demoted.
        o = (pIntQuestion ??= d)..expectStaticType<Exactly<num>>();
      }
    }
  }
}

main() {
  ''.test();
}
