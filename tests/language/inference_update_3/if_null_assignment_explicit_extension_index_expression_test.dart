// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the functionality proposed in
// https://github.com/dart-lang/language/issues/1618#issuecomment-1507241494,
// using if-null assignments whose target is an ordinary index expression that
// refers to operators defined in an extension, using explicit extension syntax.

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

/// Class that can be the target of `[]` and `[]=` operations. [ReadType] and
/// [WriteType] are the read and write types of the `[]` and `[]=` operators,
/// respectively.
///
/// Note that the `[]` and `[]=` operators are defined in an extension.
class Indexable<ReadType, WriteType> {
  final ReadType _value;

  Indexable(this._value);
}

extension Extension<ReadType, WriteType> on Indexable<ReadType, WriteType> {
  ReadType operator [](int index) => _value;

  operator []=(int index, WriteType value) {}
}

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
    // ignore: dead_null_aware_expression
    Extension(Indexable<String, Object?>(''))[0] ??= contextType('')
      ..expectStaticType<Exactly<Object?>>();

    Extension(Indexable<String?, String?>(null))[0] ??= contextType('')
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
    context<Object>((Extension(Indexable<int?, Object?>(null))[0] ??= d)
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
    contextIterable((Extension(Indexable<Iterable<int>?, Object?>(null))[0] ??=
        iterableDouble)
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
    context<Function>((Extension(Indexable<Function?, Function?>(null))[0] ??=
        callableClassInt)
      ..expectStaticType<Exactly<Function>>());
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
    var c2Double = C2<double>();
    contextB1((Extension(Indexable<C1<int>?, Object?>(null))[0] ??= c2Double)
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
    contextB1<Object>((Extension(Indexable<C1<int>?, Object?>(null))[0] ??=
        c2Double)
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
    context<Iterable<num>>(
        (Extension(Indexable<Iterable<int>?, Object?>(null))[0] ??= listNum)
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
    context<B1<int> Function()>(
        (Extension(Indexable<C1<int> Function()?, Function?>(null))[0] ??=
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
      o = (Extension(Indexable<int?, Object?>(null))[0] ??= d)
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
      o = (Extension(Indexable<double?, Object?>(null))[0] ??= intQuestion)
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
      o = (Extension(Indexable<int?, Object?>(null))[0] ??= d)
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
      o = (Extension(Indexable<C1<int> Function()?, Function?>(null))[0] ??=
          callableClassC2Int)
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
      o = (Extension(Indexable<C1<int> Function()?, Function?>(null))[0] ??=
          callableClassC2Int)
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
      o = (Extension(Indexable<C1<int> Function()?, Function?>(null))[0] ??=
          callableClassC2Int)
        ..expectStaticType<Exactly<A Function()>>();
    }
  }
}
