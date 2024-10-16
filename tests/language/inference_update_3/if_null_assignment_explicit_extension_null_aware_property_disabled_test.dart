// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the absence of the functionality proposed in
// https://github.com/dart-lang/language/issues/1618#issuecomment-1507241494
// when the `inference-update-3` language feature is not enabled, using if-null
// assignments whose target is a null-aware access to an extension property,
// using explicit extension syntax.

// @dart=3.3

import 'package:expect/static_type_helper.dart';

/// Ensures a context type of `Iterable<T>?` for the operand, or `Iterable<_>?`
/// if no type argument is supplied.
Object? contextIterableQuestion<T>(Iterable<T>? x) => x;

class A {}

class B1<T> implements A {}

class B2<T> implements A {}

class C1<T> implements B1<T>, B2<T> {}

class C2<T> implements B1<T>, B2<T> {}

class CallableClass<T> {
  T call() => throw '';
}

extension Extension on String {
  C1<int> Function()? get pC1IntFunctionQuestion => null;
  set pC1IntFunctionQuestion(Function? value) {}
  double? get pDoubleQuestion => null;
  set pDoubleQuestion(Object? value) {}
  Function? get pFunctionQuestion => null;
  set pFunctionQuestion(Function? value) {}
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
}

main() {
  var s = '' as String?;

  // - An if-null assignment `e` of the form `e1 ??= e2` with context type K is
  //   analyzed as follows:
  //
  //   - Let T1 be the read type of `e1`. This is the static type that `e1`
  //     would have as an expression with a context type schema of `_`.
  //   - Let T2 be the type of `e2` inferred with context type J, where:
  //     - If the lvalue is a local variable, J is the current (possibly
  //       promoted) type of the variable.
  //     - Otherwise, J is the write type `e1`. This is the type schema that the
  //       setter associated with `e1` imposes on its single argument (or, for
  //       the case of indexed assignment, the type schema that `operator[]=`
  //       imposes on its second argument).
  {
    // Check the context type of `e`.
    // ignore: dead_null_aware_expression
    Extension(s)?.pString ??= contextType('')
      ..expectStaticType<Exactly<Object?>>();

    Extension(s)?.pStringQuestion ??= contextType('')
      ..expectStaticType<Exactly<String?>>();
  }

  //   - Let J' be the unpromoted write type of `e1`, defined as follows:
  //     - If `e1` is a local variable, J' is the declared (unpromoted) type of
  //       `e1`.
  //     - Otherwise J' = J.
  //   - Let T2' be the coerced type of `e2`, defined as follows:
  //     - If T2 is a subtype of J', then T2' = T2 (no coercion is needed).
  //     - Otherwise, if T2 can be coerced to a some other type which *is* a
  //       subtype of J', then apply that coercion and let T2' be the type
  //       resulting from the coercion.
  //     - Otherwise, it is a compile-time error.
  //   - Let T be UP(NonNull(T1), T2').
  //   - Let S be the greatest closure of K.
  //   - If T <: S, then the type of `e` is T.
  //     (Testing this case here. Otherwise continued below.)
  {
    // This example has:
    // - K = Object?
    // - T1 = int?
    // - T2' = double
    // Which implies:
    // - T = num
    // - S = Object?
    // We have:
    // - T <: S
    // Therefore the type of `e` is T = num.
    // (Which becomes num? after null shorting completes.)
    var d = 2.0;
    context<Object?>(
        (Extension(s)?.pIntQuestion ??= d)..expectStaticType<Exactly<num?>>());

    // This example has:
    // - K = Iterable<_>?
    // - T1 = Iterable<int>?
    // - T2' = Iterable<double>
    // Which implies:
    // - T = Iterable<num>
    // - S = Iterable<Object?>?
    // We have:
    // - T <: S
    // Therefore the type of `e` is T = Iterable<num>.
    // (Which becomes Iterable<num>? after null shorting completes.)
    var iterableDouble = <double>[] as Iterable<double>;
    contextIterableQuestion((Extension(s)?.pIterableIntQuestion ??=
        iterableDouble)
      ..expectStaticType<Exactly<Iterable<num>?>>());

    // This example has:
    // - K = Function?
    // - T1 = Function?
    // - T2' = int Function()
    //    (coerced from T2=CallableClass<int>)
    // Which implies:
    // - T = Function
    // - S = Function?
    // We have:
    // - T <: S
    // Therefore the type of `e` is T = Function.
    // (Which becomes Function? after null shorting completes.)
    var callableClassInt = CallableClass<int>();
    context<Function?>((Extension(s)?.pFunctionQuestion ??= callableClassInt)
      ..expectStaticType<Exactly<Function?>>());
  }

  //   - Otherwise, if NonNull(T1) <: S and T2' <: S, and `inference-update-3`
  //     is enabled, then the type of `e` is S.
  {
    // This example has:
    // - K = Iterable<num>?
    // - T1 = Iterable<int>?
    // - T2' = List<num>
    // Which implies:
    // - T = Object
    // - S = Iterable<num>?
    // We have:
    // - T <!: S
    // - NonNull(T1) <: S
    // - T2' <: S
    // However, inference-update-3 is not enabled.
    // Therefore the type of `e` is T = Object.
    // (Which becomes Object? after null shorting completes.)
    var listNum = <num>[];
    Object? o;
    o = [0] as Object?;
    if (o is Iterable<num>?) {
      // We avoid having a compile-time error because `o` can be demoted.
      o = (Extension(s)?.pIterableIntQuestion ??= listNum)
        ..expectStaticType<Exactly<Object?>>();
    }

    // This example has:
    // - K = B1<int> Function()?
    // - T1 = C1<int> Function()?
    // - T2' = C2<int> Function()
    //    (coerced from T2=CallableClass<C2<int>>)
    // Which implies:
    // - T = A Function()
    // - S = B1<int> Function()?
    // We have:
    // - T <!: S
    // - NonNull(T1) <: S
    // - T2' <: S
    // However, inference-update-3 is not enabled.
    // Therefore the type of `e` is T = A Function().
    // (Which becomes A Function()? after null shorting completes.)
    var callableClassC2Int = CallableClass<C2<int>>();
    o = (() => B1<int>()) as Object?;
    if (o is B1<int> Function()?) {
      // We avoid having a compile-time error because `o` can be demoted.
      o = (Extension(s)?.pC1IntFunctionQuestion ??= callableClassC2Int)
        ..expectStaticType<Exactly<A Function()?>>();
    }
  }

  //   - Otherwise, the type of `e` is T.
  {
    var d = 2.0;
    Object? o;
    var intQuestion = null as int?;
    o = 0 as Object?;
    if (o is int?) {
      // This example has:
      // - K = int?
      // - T1 = int?
      // - T2' = double
      // Which implies:
      // - T = num
      // - S = int?
      // We have:
      // - T <!: S
      // - NonNull(T1) <: S
      // - T2' <!: S
      // The fact that T2' <!: S precludes using S as static type.
      // Therefore the type of `e` is T = num.
      // (Which becomes num? after null shorting completes.)
      // We avoid having a compile-time error because `o` can be demoted.
      o = (Extension(s)?.pIntQuestion ??= d)..expectStaticType<Exactly<num?>>();
    }
    o = 0 as Object?;
    if (o is int?) {
      // This example has:
      // - K = int?
      // - T1 = double?
      // - T2' = int?
      // Which implies:
      // - T = num?
      // - S = int?
      // We have:
      // - T <!: S
      // - NonNull(T1) <!: S
      // - T2' <: S
      // The fact that NonNull(T1) <!: S precludes using S as static type.
      // Therefore the type of `e` is T = num?.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (Extension(s)?.pDoubleQuestion ??= intQuestion)
        ..expectStaticType<Exactly<num?>>();
    }
    o = '' as Object?;
    if (o is String?) {
      // This example has:
      // - K = String?
      // - T1 = int?
      // - T2' = double
      // Which implies:
      // - T = num
      // - S = String?
      // We have:
      // - T <!: S
      // - NonNull(T1) <!: S
      // - T2' <!: S
      // The fact that NonNull(T1) <!: S and T2' <!: S precludes using S as
      // static type.
      // Therefore the type of `e` is T = num.
      // (Which becomes num? after null shorting completes.)
      // We avoid having a compile-time error because `o` can be demoted.
      o = (Extension(s)?.pIntQuestion ??= d)..expectStaticType<Exactly<num?>>();
    }

    var callableClassC2Int = CallableClass<C2<int>>();
    o = (() => C1<int>()) as Object?;
    if (o is C1<int> Function()?) {
      // This example has:
      // - K = C1<int> Function()?
      // - T1 = C1<int> Function()?
      // - T2' = C2<int> Function()
      //    (coerced from T2=CallableClass<C2<int>>)
      // Which implies:
      // - T = A Function()
      // - S = C1<int> Function()?
      // We have:
      // - T <!: S
      // - NonNull(T1) <: S
      // - T2' <!: S
      // The fact that T2' <!: S precludes using S as static type.
      // Therefore the type of `e` is T = A Function().
      // (Which becomes A Function()? after null shorting completes.)
      // We avoid having a compile-time error because `o` can be demoted.
      o = (Extension(s)?.pC1IntFunctionQuestion ??= callableClassC2Int)
        ..expectStaticType<Exactly<A Function()?>>();
    }

    o = (() => C2<int>()) as Object?;
    if (o is C2<int> Function()?) {
      // This example has:
      // - K = C2<int> Function()?
      // - T1 = C1<int> Function()?
      // - T2' = C2<int> Function()
      //    (coerced from T2=CallableClass<C2<int>>)
      // Which implies:
      // - T = A Function()
      // - S = C2<int> Function()?
      // We have:
      // - T <!: S
      // - NonNull(T1) <!: S
      // - T2' <: S
      // The fact that NonNull(T1) <!: S precludes using S as static type.
      // Therefore the type of `e` is T = A Function().
      // (Which becomes A Function()? after null shorting completes.)
      // We avoid having a compile-time error because `o` can be demoted.
      o = (Extension(s)?.pC1IntFunctionQuestion ??= callableClassC2Int)
        ..expectStaticType<Exactly<A Function()?>>();
    }

    o = 0 as Object?;
    if (o is int?) {
      // This example has:
      // - K = int?
      // - T1 = C1<int> Function()?
      // - T2' = C2<int> Function()
      //    (coerced from T2=CallableClass<C2<int>>)
      // Which implies:
      // - T = A Function()
      // - S = int?
      // We have:
      // - T <!: S
      // - NonNull(T1) <!: S
      // - T2' <: S
      // The fact that NonNull(T1) <!: S precludes using S as static type.
      // Therefore the type of `e` is T = A Function().
      // (Which becomes A Function()? after null shorting completes.)
      // We avoid having a compile-time error because `o` can be demoted.
      o = (Extension(s)?.pC1IntFunctionQuestion ??= callableClassC2Int)
        ..expectStaticType<Exactly<A Function()?>>();
    }
  }
}
