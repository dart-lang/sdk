// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the functionality proposed in
// https://github.com/dart-lang/language/issues/1618#issuecomment-1507241494,
// using if-null assignments whose target is a null-aware access to an extension
// property.

// SharedOptions=--enable-experiment=inference-update-3

import '../static_type_helper.dart';

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

/// Ensures a context type of `B1<T>?` for the operand, or `B1<_>?` if no type
/// argument is supplied.
Object? contextB1Question<T>(B1<T>? x) => x;

extension on String {
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
}

main() {
  var s = '' as String?;

  // - An if-null assignment `E` of the form `e1 ??= e2` with context type `K`
  //   is analyzed as follows:
  //
  //   - Let `T1` be the read type of `e1`. This is the static type that `e1`
  //     would have as an expression with a context type schema of `_`.
  //   - Let `T2` be the type of `e2` inferred with context type `J`, where:
  //     - If the lvalue is a local variable, `J` is the current (possibly
  //       promoted) type of the variable.
  //     - Otherwise, `J` is the write type `e1`. This is the type schema that
  //       the setter associated with `e1` imposes on its single argument (or,
  //       for the case of indexed assignment, the type schema that
  //       `operator[]=` imposes on its second argument).
  {
    // Check the context type of `e`.
    // ignore: dead_null_aware_expression
    s?.pString ??= contextType('')..expectStaticType<Exactly<Object?>>();

    s?.pStringQuestion ??= contextType('')
      ..expectStaticType<Exactly<String?>>();
  }

  //   - Let `J'` be the unpromoted write type of `e1`, defined as follows:
  //     - If `e1` is a local variable, `J'` is the declared (unpromoted) type
  //       of `e1`.
  //     - Otherwise `J' = J`.
  //   - Let `T2'` be the coerced type of `e2`, defined as follows:
  //     - If `T2` is a subtype of `J'`, then `T2' = T2` (no coercion is
  //       needed).
  //     - Otherwise, if `T2` can be coerced to a some other type which *is* a
  //       subtype of `J'`, then apply that coercion and let `T2'` be the type
  //       resulting from the coercion.
  //     - Otherwise, it is a compile-time error.
  //   - Let `T` be `UP(NonNull(T1), T2')`.
  //   - Let `S` be the greatest closure of `K`.
  //   - If `T <: S`, then the type of `E` is `T`.
  {
    // K=Object?, T1=int?, and T2'=double, therefore T=num and S=Object?, so T
    // <: S, and hence the type of E is num (which becomes num? after null
    // shorting completes).
    var d = 2.0;
    context<Object?>(
        (s?.pIntQuestion ??= d)..expectStaticType<Exactly<num?>>());

    // K=Iterable<_>?, T1=Iterable<int>?, and T2'=Iterable<double>, therefore
    // T=Iterable<num> and S=Iterable<Object?>?, so T <: S, and hence the type
    // of E is Iterable<num> (which becomes Iterable<num>? after null shorting
    // completes).
    var iterableDouble = <double>[] as Iterable<double>;
    contextIterableQuestion((s?.pIterableIntQuestion ??= iterableDouble)
      ..expectStaticType<Exactly<Iterable<num>?>>());

    // K=Function?, T1=Function?, and T2'=int Function() (coerced from
    // T2=CallableClass<int>), therefore T=Function and S=Function?, so T <: S,
    // and hence the type of E is Function (which becomes Function? after null
    // shorting completes).
    var callableClassInt = CallableClass<int>();
    context<Function?>((s?.pFunctionQuestion ??= callableClassInt)
      ..expectStaticType<Exactly<Function?>>());
  }

  //   - Otherwise, if `NonNull(T1) <: S` and `T2' <: S`, then the type of `E`
  //     is `S`.
  {
    // K=B1<_>?, T1=C1<int>?, and T2'=C2<double>, therefore T=A and
    // S=B1<Object?>?, so T is not <: S, but NonNull(T1) <: S and T2' <: S,
    // hence the type of E is B1<Object?> (which becomes B1<Object?>? after null
    // shorting completes).
    var c2Double = C2<double>();
    contextB1Question((s?.pC1IntQuestion ??= c2Double)
      ..expectStaticType<Exactly<B1<Object?>?>>());

    // K=B1<Object>?, T1=C1<int>?, and T2'=C2<double>, therefore T=A and
    // S=B1<Object>?, so T is not <: S, but NonNull(T1) <: S and T2' <: S, hence
    // the type of E is B1<Object> (which becomes B1<Object>? after null
    // shorting completes).
    contextB1Question<Object>((s?.pC1IntQuestion ??= c2Double)
      ..expectStaticType<Exactly<B1<Object>?>>());

    // K=Iterable<num>?, T1=Iterable<int>?, and T2'=List<num>, therefore
    // T=Object and S=Iterable<num>?, so T is not <: S, but NonNull(T1) <: S and
    // T2' <: S, hence the type of E is Iterable<num> (which becomes
    // Iterable<num>? after null shorting completes).
    var listNum = <num>[];
    context<Iterable<num>?>((s?.pIterableIntQuestion ??= listNum)
      ..expectStaticType<Exactly<Iterable<num>?>>());

    // K=B1<int> Function()?, T1=C1<int> Function()?, and T2'=C2<int> Function()
    // (coerced from T2=CallableClass<C2<int>>), therefore T=A Function() and
    // S=B1<int> Function()?, so T is not <: S, but NonNull(T1) <: S and T2' <:
    // S, hence the type of E is B1<int> Function() (which becomes B1<int>
    // Function()? after null shorting completes).
    var callableClassC2Int = CallableClass<C2<int>>();
    context<B1<int> Function()?>((s?.pC1IntFunctionQuestion ??=
        callableClassC2Int)
      ..expectStaticType<Exactly<B1<int> Function()?>>());
  }

  //   - Otherwise, the type of `E` is `T`.
  {
    var d = 2.0;
    var o = 0 as Object?;
    var intQuestion = null as int?;
    if (o is int?) {
      // K=int?, T1=int?, and T2'=double, therefore T=num and S=int?, so T is
      // not <: S. NonNull(T1) <: S, but T2' is not <: S. Hence the type of E is
      // num (which becomes num? after null shorting completes).
      // We avoid having a compile-time error because `o` can be demoted.
      o = (s?.pIntQuestion ??= d)..expectStaticType<Exactly<num?>>();
    }
    o = 0 as Object?;
    if (o is int?) {
      // K=int?, T1=double?, and T2'=int?, therefore T=num? and S=int?, so T is
      // not <: S. T2' <: S, but NonNull(T1) is not <: S. Hence the type of E is
      // num?.
      // We avoid having a compile-time error because `o` can be demoted.
      o = (s?.pDoubleQuestion ??= intQuestion)
        ..expectStaticType<Exactly<num?>>();
    }
    o = '' as Object?;
    if (o is String?) {
      // K=String?, T1=int?, and T2'=double, therefore T=num and S=String?, so
      // none of T, NonNull(T1), nor T2' are <: S. Hence the type of E is num
      // (which becomes num? after null shorting completes).
      // We avoid having a compile-time error because `o` can be demoted.
      o = (s?.pIntQuestion ??= d)..expectStaticType<Exactly<num?>>();
    }

    var callableClassC2Int = CallableClass<C2<int>>();
    o = (() => C1<int>()) as Object?;
    if (o is C1<int> Function()?) {
      // K=C1<int> Function()?, T1=C1<int> Function()?, and T2'=C2<int>
      // Function() (coerced from T2=CallableClass<C2<int>>), therefore T=A
      // Function() and S=C1<int> Function()?, so T is not <: S. NonNull(T1) <:
      // S, but T2' is not <: S. Hence the type of E is A Function() (which
      // becomes A Function()? after null shorting completes).
      // We avoid having a compile-time error because `o` can be demoted.
      o = (s?.pC1IntFunctionQuestion ??= callableClassC2Int)
        ..expectStaticType<Exactly<A Function()?>>();
    }

    o = (() => C2<int>()) as Object?;
    if (o is C2<int> Function()?) {
      // K=C2<int> Function()?, T1=C1<int> Function()?, and T2'=C2<int>
      // Function() (coerced from T2=CallableClass<C2<int>>), therefore T=A
      // Function() and S=C2<int> Function()?, so T is not <: S. T2' <: S, but
      // NonNull(T1) is not <: S. Hence the type of E is A Function() (which
      // becomes A Function()? after null shorting completes).
      // We avoid having a compile-time error because `o` can be demoted.
      o = (s?.pC1IntFunctionQuestion ??= callableClassC2Int)
        ..expectStaticType<Exactly<A Function()?>>();
    }

    o = 0 as Object?;
    if (o is int?) {
      // K=int?, T1=C1<int> Function()?, and T2'=C2<int> Function() (coerced
      // from T2=CallableClass<C2<int>>), therefore T=A Function() and S=int?,
      // so T is not <: S. T2' <: S, but NonNull(T1) is not <: S. Hence the type
      // of E is A Function() (which becomes A Function()? after null shorting
      // completes).
      // We avoid having a compile-time error because `o` can be demoted.
      o = (s?.pC1IntFunctionQuestion ??= callableClassC2Int)
        ..expectStaticType<Exactly<A Function()?>>();
    }
  }
}
