// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the functionality proposed in
// https://github.com/dart-lang/language/issues/1618#issuecomment-1507241494,
// using if-null assignments whose target is a property of the current
// extension, accessed through explicit `this` using explicit extension syntax.

import 'package:expect/static_type_helper.dart';

/// Ensures a context type of `Iterable<T>` for the operand, or `Iterable<_>` if
/// no type argument is supplied.
Object? contextIterable<T>(Iterable<T> x) => x;

class A {}

class B1<T> implements A {}

class B2<T> implements A {}

class C1<T> implements B1<T>, B2<T> {}

class C2<T> implements B1<T>, B2<T> {}

class CallableClass<T> {
  T call() => throw '';
}

/// Ensures a context type of `B1<T>` for the operand, or `B1<_>` if no type
/// argument is supplied.
Object? contextB1<T>(B1<T> x) => x;

extension Extension on String {
  C1<int> Function()? get pC1IntFunctionQuestion => null;
  set pC1IntFunctionQuestion(Function? value) {}
  C1<int>? get pC1IntQuestion => null;
  set pC1IntQuestion(Object? value) {}
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

  test() {
    // - An if-null assignment `e` of the form `e1 ??= e2` with context type K
    //   is analyzed as follows:
    //
    //   - Let T1 be the read type of `e1`. This is the static type that `e1`
    //     would have as an expression with a context type schema of `_`.
    //   - Let T2 be the type of `e2` inferred with context type J, where:
    //     - If the lvalue is a local variable, J is the current (possibly
    //       promoted) type of the variable.
    //     - Otherwise, J is the write type `e1`. This is the type schema that
    //       the setter associated with `e1` imposes on its single argument (or,
    //       for the case of indexed assignment, the type schema that
    //       `operator[]=` imposes on its second argument).
    {
      // Check the context type of `e`.
      // ignore: dead_null_aware_expression
      Extension(this).pString ??= contextType('')
        ..expectStaticType<Exactly<Object?>>();

      Extension(this).pStringQuestion ??= contextType('')
        ..expectStaticType<Exactly<String?>>();
    }

    //   - Let J' be the unpromoted write type of `e1`, defined as follows:
    //     - If `e1` is a local variable, J' is the declared (unpromoted) type
    //       of `e1`.
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
      // - K = Object
      // - T1 = int?
      // - T2' = double
      // Which implies:
      // - T = num
      // - S = Object
      // We have:
      // - T <: S
      // Therefore the type of `e` is T = num.
      var d = 2.0;
      context<Object>((Extension(this).pIntQuestion ??= d)
        ..expectStaticType<Exactly<num>>());

      // This example has:
      // - K = Iterable<_>
      // - T1 = Iterable<int>?
      // - T2' = Iterable<double>
      // Which implies:
      // - T = Iterable<num>
      // - S = Iterable<Object?>
      // We have:
      // - T <: S
      // Therefore the type of `e` is T = Iterable<num>.
      var iterableDouble = <double>[] as Iterable<double>;
      contextIterable((Extension(this).pIterableIntQuestion ??= iterableDouble)
        ..expectStaticType<Exactly<Iterable<num>>>());

      // This example has:
      // - K = Function
      // - T1 = Function?
      // - T2' = int Function()
      //    (coerced from T2=CallableClass<int>)
      // Which implies:
      // - T = Function
      // - S = Function
      // We have:
      // - T <: S
      // Therefore the type of `e` is T = Function.
      var callableClassInt = CallableClass<int>();
      context<Function>((Extension(this).pFunctionQuestion ??= callableClassInt)
        ..expectStaticType<Exactly<Function>>());
    }

    //   - Otherwise, if NonNull(T1) <: S and T2' <: S, then the type of `e` is
    //     S.
    {
      // This example has:
      // - K = B1<_>
      // - T1 = C1<int>?
      // - T2' = C2<double>
      // Which implies:
      // - T = A
      // - S = B1<Object?>
      // We have:
      // - T <!: S
      // - NonNull(T1) <: S
      // - T2' <: S
      // Therefore the type of `e` is S = B1<Object?>.
      var c2Double = C2<double>();
      contextB1((Extension(this).pC1IntQuestion ??= c2Double)
        ..expectStaticType<Exactly<B1<Object?>>>());

      // This example has:
      // - K = B1<Object>
      // - T1 = C1<int>?
      // - T2' = C2<double>
      // Which implies:
      // - T = A
      // - S = B1<Object>
      // We have:
      // - T <!: S
      // - NonNull(T1) <: S
      // - T2' <: S
      // Therefore the type of `e` is S = B1<Object>.
      contextB1<Object>((Extension(this).pC1IntQuestion ??= c2Double)
        ..expectStaticType<Exactly<B1<Object>>>());

      // This example has:
      // - K = Iterable<num>
      // - T1 = Iterable<int>?
      // - T2' = List<num>
      // Which implies:
      // - T = Object
      // - S = Iterable<num>
      // We have:
      // - T <!: S
      // - NonNull(T1) <: S
      // - T2' <: S
      // Therefore the type of `e` is S = Iterable<num>.
      var listNum = <num>[];
      context<Iterable<num>>((Extension(this).pIterableIntQuestion ??= listNum)
        ..expectStaticType<Exactly<Iterable<num>>>());

      // This example has:
      // - K = B1<int> Function()
      // - T1 = C1<int> Function()?
      // - T2' = C2<int> Function()
      //    (coerced from T2=CallableClass<C2<int>>)
      // Which implies:
      // - T = A Function()
      // - S = B1<int> Function()
      // We have:
      // - T <!: S
      // - NonNull(T1) <: S
      // - T2' <: S
      // Therefore the type of `e` is S = B1<int> Function().
      var callableClassC2Int = CallableClass<C2<int>>();
      context<B1<int> Function()>((Extension(this).pC1IntFunctionQuestion ??=
          callableClassC2Int)
        ..expectStaticType<Exactly<B1<int> Function()>>());
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
        // We avoid having a compile-time error because `o` can be demoted.
        o = (Extension(this).pIntQuestion ??= d)
          ..expectStaticType<Exactly<num>>();
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
        o = (Extension(this).pDoubleQuestion ??= intQuestion)
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
        // We avoid having a compile-time error because `o` can be demoted.
        o = (Extension(this).pIntQuestion ??= d)
          ..expectStaticType<Exactly<num>>();
      }

      var callableClassC2Int = CallableClass<C2<int>>();
      o = (() => C1<int>()) as Object?;
      if (o is C1<int> Function()) {
        // This example has:
        // - K = C1<int> Function()
        // - T1 = C1<int> Function()?
        // - T2' = C2<int> Function()
        //    (coerced from T2=CallableClass<C2<int>>)
        // Which implies:
        // - T = A Function()
        // - S = C1<int> Function()
        // We have:
        // - T <!: S
        // - NonNull(T1) <: S
        // - T2' <!: S
        // The fact that T2' <!: S precludes using S as static type.
        // Therefore the type of `e` is T = A Function().
        // We avoid having a compile-time error because `o` can be demoted.
        o = (Extension(this).pC1IntFunctionQuestion ??= callableClassC2Int)
          ..expectStaticType<Exactly<A Function()>>();
      }

      o = (() => C2<int>()) as Object?;
      if (o is C2<int> Function()) {
        // This example has:
        // - K = C2<int> Function()
        // - T1 = C1<int> Function()?
        // - T2' = C2<int> Function()
        //    (coerced from T2=CallableClass<C2<int>>)
        // Which implies:
        // - T = A Function()
        // - S = C2<int> Function()
        // We have:
        // - T <!: S
        // - NonNull(T1) <!: S
        // - T2' <: S
        // The fact that NonNull(T1) <!: S precludes using S as static type.
        // Therefore the type of `e` is T = A Function().
        // We avoid having a compile-time error because `o` can be demoted.
        o = (Extension(this).pC1IntFunctionQuestion ??= callableClassC2Int)
          ..expectStaticType<Exactly<A Function()>>();
      }

      o = 0 as Object?;
      if (o is int) {
        // This example has:
        // - K = int
        // - T1 = C1<int> Function()?
        // - T2' = C2<int> Function()
        //    (coerced from T2=CallableClass<C2<int>>)
        // Which implies:
        // - T = A Function()
        // - S = int
        // We have:
        // - T <!: S
        // - NonNull(T1) <!: S
        // - T2' <: S
        // The fact that NonNull(T1) <!: S precludes using S as static type.
        // Therefore the type of `e` is T = A Function().
        // We avoid having a compile-time error because `o` can be demoted.
        o = (Extension(this).pC1IntFunctionQuestion ??= callableClassC2Int)
          ..expectStaticType<Exactly<A Function()>>();
      }
    }
  }
}

main() {
  ''.test();
}
