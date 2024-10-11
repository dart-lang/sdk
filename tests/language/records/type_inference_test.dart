// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test the rules for record literal type inference specified in
/// https://github.com/dart-lang/language/blob/main/accepted/3.0/records/feature-specification.md#type-inference.

import 'package:expect/static_type_helper.dart';

/// When invoked without explicit type parameters, causes its argument to be
/// analyzed with a context of `(_,)`.
void contextRecordUnknown<T>((T,) x) {}

/// When invoked without explicit type parameters, causes its argument to be
/// analyzed with a context of `({_ f1})`.
void contextRecordNamedUnknown<T>(({T f1}) x) {}

/// When invoked without explicit type parameters, causes its argument to be
/// analyzed with a context of `(List<_>,)`.
void contextRecordListOfUnknown<T>((List<T>,) x) {}

/// When invoked without explicit type parameters, causes its argument to be
/// analyzed with a context of `({List<_> f1})`.
void contextRecordNamedListOfUnknown<T>(({List<T> f1}) x) {}

/// When invoked without explicit type parameters, causes its argument to be
/// analyzed with a context of `(Iterable<_>,)`.
void contextRecordIterableOfUnknown<T>((Iterable<T>,) x) {}

/// When invoked without explicit type parameters, causes its argument to be
/// analyzed with a context of `({Iterable<_> f1})`.
void contextRecordNamedIterableOfUnknown<T>(({Iterable<T> f1}) x) {}

/// When invoked without explicit type parameters, causes its argument to be
/// analyzed with a context of `(_ Function(),)`.
void contextRecordFunctionReturningUnknown<T>((T Function(),) x) {}

/// When invoked without explicit type parameters, causes its argument to be
/// analyzed with a context of `({_ Function() f1})`.
void contextRecordNamedFunctionReturningUnknown<T>(({T Function() f1}) x) {}

class C {
  int call() => 0;
}

main() {
  // Given a type schema K and a record expression E of the general form (e1,
  // ..., en, d1 : e{n+1}, ..., dm : e{n+m}) inference proceeds as follows.
  //
  // If K is a record type schema of the form (K1, ..., Kn, {d1 : K{n+1}, ....,
  // dm : K{n+m}}) then:
  //
  // - Each ei is inferred with context type schema Ki to have type Si
  {
    // Ordinary contexts
    context<(int, String, {double f1, num f2})>((
      contextType(1)..expectStaticType<Exactly<int>>(),
      contextType('')..expectStaticType<Exactly<String>>(),
      f1: contextType(1.0)..expectStaticType<Exactly<double>>(),
      f2: contextType(1)..expectStaticType<Exactly<num>>()
    ));

    // Check that unknown contexts are properly propagated down:
    // - Positional field
    contextRecordListOfUnknown(
        ([1, 2],)..expectStaticType<Exactly<(List<int>,)>>());
    // - Named field
    contextRecordNamedListOfUnknown(
        (f1: [1, 2])..expectStaticType<Exactly<({List<int> f1})>>());
  }

  //   - Let Ri be the greatest closure of Ki
  //   - If Si is a subtype of Ri then let Ti be Si
  //
  // (The type of E is (T1, ..., Tn, {d1 : T{n+1}, ...., dm : T{n+m}}))
  {
    // - Ki=Iterable<_> and Si=List<int>, so Ri=Iterable<Object?> and Si <: Ri;
    //   thus Ti=Si=List<int>.
    contextRecordIterableOfUnknown(
        (<int>[],)..expectStaticType<Exactly<(List<int>,)>>());
    contextRecordNamedIterableOfUnknown(
        (f1: <int>[])..expectStaticType<Exactly<({List<int> f1})>>());

    // - Ki=_ and Si=dynamic, so Ri=Object? and Si <: Ri; thus Ti=Si=dynamic.
    var d = 0 as dynamic;
    contextRecordUnknown((d,)
      ..expectStaticType<Exactly<(dynamic,)>>()
      // Double check that it's truly `dynamic` (and not `Object?`) using a
      // dynamic invocation.
      ..$1.abs());
    contextRecordNamedUnknown((f1: d)
      ..expectStaticType<Exactly<({dynamic f1})>>()
      ..f1.abs());

    // - Ki=_ and Si=Object?, so Ri=Object? and Si <: Ri; thus Ti=Si=Object?.
    var objQ = 0 as Object?;
    contextRecordUnknown((objQ,)..expectStaticType<Exactly<(Object?,)>>());
    contextRecordNamedUnknown(
        (f1: objQ)..expectStaticType<Exactly<({Object? f1})>>());

    // - Ki=dynamic and Si=dynamic, so Ri=dynamic and Si <: Ri; thus
    //   Ti=Si=dynamic.
    context<(dynamic,)>((d,)
      ..expectStaticType<Exactly<(dynamic,)>>()
      ..$1.abs());
    context<({dynamic f1})>((f1: d)
      ..expectStaticType<Exactly<({dynamic f1})>>()
      ..f1.abs());

    // - Ki=dynamic and Si=Object?, so Ri=dynamic and Si <: Ri; thus
    //   Ti=Si=Object?.
    context<(dynamic,)>((objQ,)..expectStaticType<Exactly<(Object?,)>>());
    context<({dynamic f1})>(
        (f1: objQ)..expectStaticType<Exactly<({Object? f1})>>());

    // - Ki=Object? and Si=dynamic, so Ri=Object? and Si <: Ri; thus
    //   Ti=Si=dynamic.
    context<(Object?,)>((d,)
      ..expectStaticType<Exactly<(dynamic,)>>()
      ..$1.abs());
    context<({Object? f1})>((f1: d)
      ..expectStaticType<Exactly<({dynamic f1})>>()
      ..f1.abs());

    // - Ki=Object? and Si=Object?, so Ri=Object? and Si <: Ri; thus
    //   Ti=Si=Object?.
    context<(Object?,)>((objQ,)..expectStaticType<Exactly<(Object?,)>>());
    context<({Object? f1})>(
        (f1: objQ)..expectStaticType<Exactly<({Object? f1})>>());
  }

  //   - Otherwise, if Si is dynamic, then we insert an implicit cast on ei to
  //     Ri, and let Ti be Ri
  {
    // - Ki=List<_> and Si=dynamic, so Ri=List<Object?>; thus Ti=List<Object?>.
    var d = [1] as dynamic;
    contextRecordListOfUnknown(
        (d,)..expectStaticType<Exactly<(List<Object?>,)>>());
    contextRecordNamedListOfUnknown(
        (f1: d)..expectStaticType<Exactly<({List<Object?> f1})>>());
  }

  //   - Otherwise, if Si is coercible to Ri (via some sequence of call method
  //     tearoff or implicit generic instantiation coercions), then we insert
  //     the appropriate implicit coercion(s) on ei. Let Ti be the type of the
  //     resulting coerced value (which must be a subtype of Ri, possibly
  //     proper).
  {
    // - Ki=_ Function() and Si=C, so Ri=Object? Function(); thus Ti=int
    //   Function().
    contextRecordFunctionReturningUnknown(
        (C(),)..expectStaticType<Exactly<(int Function(),)>>());
    contextRecordNamedFunctionReturningUnknown(
        (f1: C())..expectStaticType<Exactly<({int Function() f1})>>());
  }

  //   - Otherwise, let Ti be Si.
  {
    // - Ki=int and Si=String, so Ri=int; thus Ti=String.
    var o = (1,) as Object;
    if (o is (int,)) {
      o = ('',)..expectStaticType<Exactly<(String,)>>();
    }
    o = (f1: 1) as Object;
    if (o is ({int f1})) {
      o = (f1: '')..expectStaticType<Exactly<({String f1})>>();
    }
  }

  // If K is any other type schema:
  //
  // - Each ei is inferred with context type schema _ to have type Ti
  // - The type of E is (T1, ..., Tn, {d1 : T{n+1}, ...., dm : T{n+m}})
  {
    var o = '' as Object;
    var one = 1 as Object;
    if (o is String) {
      // Note: intuitively, it seems like this should be
      // `contextType(1)..expectStaticType<Exactly<dynamic>>()`, to verify that
      // the context is `_` (because `_` gets transformed to `dynamic` by
      // generic method type inference). But that wouldn't work, because then
      // `expectStaticType` would be dispatched dynamically (bypassing the
      // extension method), causing a runtime error.
      //
      // So instead, we verify that the field has a context of `_` using
      // `contextType(one)..abs()`. Using `one` instead of `1` ensures that
      // there's no way for the static type of `contextType(one)` to be `int`
      // (because none of the types involved in type inference is `int`);
      // therefore the only way for `..abs()` to be allowed at compile-time is
      // if `contextType` got inferred as `contextType<dynamic>`.
      o = (contextType(one)..abs(),);
    }
    o = '' as Object;
    if (o is String) {
      o = (f1: contextType(one)..abs());
    }
    o = ('',) as Object;
    if (o is (String,)) {
      o = (f1: contextType(one)..abs());
    }
    o = (f1: '') as Object;
    if (o is ({String f1})) {
      o = (contextType(one)..abs(),);
    }
    o = (f1: '') as Object;
    if (o is ({String f1})) {
      o = (f2: contextType(one)..abs());
    }
    o = (f1: '', f2: '') as Object;
    if (o is ({String f1, String f2})) {
      o = (f1: contextType(one)..abs());
    }
    o = (f1: '') as Object;
    if (o is ({String f1})) {
      o = (f1: contextType(one)..abs(), f2: contextType(one)..abs());
    }
    o = ('', '') as Object;
    if (o is (String, String)) {
      o = (contextType(one)..abs(),);
    }
    o = ('',) as Object;
    if (o is (String,)) {
      o = (contextType(one)..abs(), contextType(one)..abs());
    }
  }
}
