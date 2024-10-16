// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the functionality proposed in
// https://github.com/dart-lang/language/issues/1618#issuecomment-1507241494,
// using if-null assignments whose target is a local variable.

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

main() {
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
    var string = '';
    // ignore: dead_null_aware_expression
    string ??= contextType('')..expectStaticType<Exactly<String>>();

    var numQuestion = null as num?;
    numQuestion ??= contextType(0)..expectStaticType<Exactly<num?>>();

    if (numQuestion is int?) {
      numQuestion ??= contextType(0)..expectStaticType<Exactly<int?>>();
    }
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
    // - K = Object
    // - T1 = int?
    // - T2' = double
    // Which implies:
    // - T = num
    // - S = Object
    // We have:
    // - T <: S
    // Therefore the type of `e` is T = num.
    Object? local1;
    var d = 2.0;
    local1 = null as Object?;
    if (local1 is int?) {
      // We avoid having a compile-time error because `local1` can be demoted.
      context<Object>((local1 ??= d)..expectStaticType<Exactly<num>>());
    }

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
    local1 = null as Object?;
    if (local1 is Iterable<int>?) {
      // We avoid having a compile-time error because `local1` can be demoted.
      contextIterable((local1 ??= iterableDouble)
        ..expectStaticType<Exactly<Iterable<num>>>());
    }

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
    Function? local2;
    var callableClassInt = CallableClass<int>();
    local2 = null as Function?;
    context<Function>(
        (local2 ??= callableClassInt)..expectStaticType<Exactly<Function>>());

    // Verify that the RHS is not coerced to the promoted type.
    // This example has:
    // - K = Object
    // - T1 = Function?
    // - T2' = CallableClass<int>
    // Which implies:
    // - T = Object
    // - S = Object
    // We have:
    // - T <: S
    // Therefore the type of `e` is T = Object.
    local1 = null as Object?;
    if (local1 is Function?) {
      // We avoid having a compile-time error because `local1` can be demoted.
      context<Object>(
          (local1 ??= callableClassInt)..expectStaticType<Exactly<Object>>());
    }
  }

  //   - Otherwise, if NonNull(T1) <: S and T2' <: S, then the type of `e` is S.
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
    Object? local1;
    var c2Double = C2<double>();
    local1 = null as Object?;
    if (local1 is C1<int>?) {
      // We avoid having a compile-time error because `local1` can be demoted.
      contextB1(
          (local1 ??= c2Double)..expectStaticType<Exactly<B1<Object?>>>());
    }

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
    local1 = null as Object?;
    if (local1 is C1<int>?) {
      // We avoid having a compile-time error because `local1` can be demoted.
      contextB1<Object>(
          (local1 ??= c2Double)..expectStaticType<Exactly<B1<Object>>>());
    }

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
    local1 = null as Object?;
    if (local1 is Iterable<int>?) {
      // We avoid having a compile-time error because `local1` can be demoted.
      context<Iterable<num>>(
          (local1 ??= listNum)..expectStaticType<Exactly<Iterable<num>>>());
    }

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
    Function? local2;
    var callableClassC2Int = CallableClass<C2<int>>();
    local2 = null as Function?;
    if (local2 is C1<int> Function()?) {
      // We avoid having a compile-time error because `local2` can be demoted.
      context<B1<int> Function()>((local2 ??= callableClassC2Int)
        ..expectStaticType<Exactly<B1<int> Function()>>());
    }
  }

  //   - Otherwise, the type of `e` is T.
  {
    Object? local1;
    var d = 2.0;
    Object? o;
    var intQuestion = null as int?;
    local1 = null as Object?;
    o = 0 as Object?;
    if (local1 is int? && o is int?) {
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
      // We avoid having a compile-time error because `local1` and `o` can be
      // demoted.
      o = (local1 ??= d)..expectStaticType<Exactly<num>>();
    }
    local1 = null as Object?;
    o = 0 as Object?;
    if (local1 is double? && o is int?) {
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
      // We avoid having a compile-time error because `local1` and `o` can be
      // demoted.
      o = (local1 ??= intQuestion)..expectStaticType<Exactly<num?>>();
    }
    local1 = null as Object?;
    o = '' as Object?;
    if (local1 is int? && o is String?) {
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
      // We avoid having a compile-time error because `local1` and `o` can be
      // demoted.
      o = (local1 ??= d)..expectStaticType<Exactly<num>>();
    }

    Function? local2;
    var callableClassC2Int = CallableClass<C2<int>>();
    local2 = null as Function?;
    o = (() => C1<int>()) as Object?;
    if (local2 is C1<int> Function()? && o is C1<int> Function()) {
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
      // We avoid having a compile-time error because `local2` and `o` can be
      // demoted.
      o = (local2 ??= callableClassC2Int)
        ..expectStaticType<Exactly<A Function()>>();
    }

    local2 = null as Function?;
    o = (() => C2<int>()) as Object?;
    if (local2 is C1<int> Function()? && o is C2<int> Function()) {
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
      // We avoid having a compile-time error because `local2` and `o` can be
      // demoted.
      o = (local2 ??= callableClassC2Int)
        ..expectStaticType<Exactly<A Function()>>();
    }

    local2 = null as Function?;
    o = 0 as Object?;
    if (local2 is C1<int> Function()? && o is int) {
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
      // We avoid having a compile-time error because `local2` and `o` can be
      // demoted.
      o = (local2 ??= callableClassC2Int)
        ..expectStaticType<Exactly<A Function()>>();
    }
  }
}
