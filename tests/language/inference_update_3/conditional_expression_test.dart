// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the functionality proposed in
// https://github.com/dart-lang/language/issues/1618#issuecomment-1507241494,
// using conditional expressions.

// SharedOptions=--enable-experiment=inference-update-3

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

test(bool b) {
  // - A conditional expression `E` of the form `b ? e1 : e2` with context type
  //   `K` is analyzed as follows:
  //
  //   - Let `T1` be the type of `e1` inferred with context type `K`.
  //   - Let `T2` be the type of `e2` inferred with context type `K`.
  {
    // Check the context type of `e1` and `e2`:
    // - Where the context is established using a function call argument.
    context<String>(b
        ? (contextType('')..expectStaticType<Exactly<String>>())
        : (contextType('')..expectStaticType<Exactly<String>>()));

    // - Where the context is established using local variable promotion.
    var o = '' as Object?;
    if (o is String) {
      o = b
          ? (contextType('')..expectStaticType<Exactly<String>>())
          : (contextType('')..expectStaticType<Exactly<String>>());
    }
  }

  //   - Let `T` be `UP(T1, T2)`.
  //   - Let `S` be the greatest closure of `K`.
  //   - If `T <: S`, then the type of `E` is `T`.
  {
    // K=Object, T1=int, and T2=double, therefore T=num and S=Object, so T <: S,
    // and hence the type of E is num.
    var i = 1;
    var d = 2.0;
    context<Object>((b ? i : d)..expectStaticType<Exactly<num>>());

    // K=Iterable<_>, T1=Iterable<int>, and T2=Iterable<double>, therefore
    // T=Iterable<num> and S=Iterable<Object?>, so T <: S, and hence the type of
    // E is Iterable<num>.
    var iterableInt = <int>[] as Iterable<int>;
    var iterableDouble = <double>[] as Iterable<double>;
    contextIterable((b ? iterableInt : iterableDouble)
      ..expectStaticType<Exactly<Iterable<num>>>());
  }

  //   - Otherwise, if `T1 <: S` and `T2 <: S`, then the type of `E` is `S`.
  {
    // K=B1<_>, T1=C1<int>, and T2=C2<double>, therefore T=A and S=B1<Object?>,
    // so T is not <: S, but T1 <: S and T2 <: S, hence the type of E is
    // B1<Object?>.
    var c1Int = C1<int>();
    var c2Double = C2<double>();
    contextB1((b ? c1Int : c2Double)..expectStaticType<Exactly<B1<Object?>>>());

    // K=B1<Object>, T1=C1<int>, and T2=C2<double>, therefore T=A and
    // S=B1<Object>, so T is not <: S, but T1 <: S and T2 <: S, hence the type
    // of E is B1<Object>.
    contextB1<Object>(
        (b ? c1Int : c2Double)..expectStaticType<Exactly<B1<Object>>>());

    // K=Iterable<num>, T1=Iterable<int>, and T2=List<num>, therefore T=Object
    // and S=Iterable<num>, so T is not <: S, but T1 <: S and T2 <: S, hence the
    // type of E is Iterable<num>.
    var iterableInt = <int>[] as Iterable<int>;
    var listNum = <num>[];
    context<Iterable<num>>((b ? iterableInt : listNum)
      ..expectStaticType<Exactly<Iterable<num>>>());
  }

  //   - Otherwise, the type of `E` is `T`.
  {
    var i = 1;
    var o = '' as Object?;
    var d = 2.0;
    if (o is String?) {
      // K=String?, T1=Null, and T2=int, therefore T=int? and S=String?, so T is
      // not <: S. T1 <: S, but T2 is not <: S. Hence the type of E is int?.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (b ? null : i)..expectStaticType<Exactly<int?>>();
    }
    o = '' as Object?;
    if (o is String?) {
      // K=String?, T1=int, and T2=Null, therefore T=int? and S=String?, so T is
      // not <: S. T2 <: S, but T1 is not <: S. Hence the type of E is int?.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (b ? i : null)..expectStaticType<Exactly<int?>>();
    }
    o = '' as Object?;
    if (o is String?) {
      // K=String?, T1=int, and T2=double, therefore T=num and S=String?, so
      // none of T, T1, nor T2 are <: S. Hence the type of E is num.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (b ? i : d)..expectStaticType<Exactly<num>>();
    }
  }
}

main() {
  test(true);
  test(false);
}
