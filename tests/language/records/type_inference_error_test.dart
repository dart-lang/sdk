// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test the rules for record literal type inference specified in
/// https://github.com/dart-lang/language/blob/main/accepted/3.0/records/feature-specification.md#type-inference.
///
/// This test is a companion to `type_inference_test.dart`. In all the cases
/// where `type_inference_test.dart` expects the static type of something to be
/// `Object?`, this test verifies that the static type is really `Object?` (and
/// not `dynamic`) by attempting to dynamically invoke it.

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
  //   - Let Ri be the greatest closure of Ki
  //   - If Si is a subtype of Ri then let Ti be Si
  //
  // (The type of E is (T1, ..., Tn, {d1 : T{n+1}, ...., dm : T{n+m}}))
  {
    // - Ki=_ and Si=Object?, so Ri=Object? and Si <: Ri; thus Ti=Si=Object?.
    var objQ = 0 as Object?;
    contextRecordUnknown((objQ,)
      ..expectStaticType<Exactly<(Object?,)>>()
      ..$1.abs());
    //     ^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The method 'abs' isn't defined for the class 'Object?'.
    contextRecordNamedUnknown((f1: objQ)
      ..expectStaticType<Exactly<({Object? f1})>>()
      ..f1.abs());
    //     ^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The method 'abs' isn't defined for the class 'Object?'.

    // - Ki=dynamic and Si=Object?, so Ri=dynamic and Si <: Ri; thus
    //   Ti=Si=Object?.
    context<(dynamic,)>((objQ,)
      ..expectStaticType<Exactly<(Object?,)>>()
      ..$1.abs());
    //     ^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The method 'abs' isn't defined for the class 'Object?'.
    context<({dynamic f1})>((f1: objQ)
      ..expectStaticType<Exactly<({Object? f1})>>()
      ..f1.abs());
    //     ^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The method 'abs' isn't defined for the class 'Object?'.

    // - Ki=Object? and Si=Object?, so Ri=Object? and Si <: Ri; thus
    //   Ti=Si=Object?.
    context<(Object?,)>((objQ,)
      ..expectStaticType<Exactly<(Object?,)>>()
      ..$1.abs());
    //     ^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The method 'abs' isn't defined for the class 'Object?'.
    context<({Object? f1})>((f1: objQ)
      ..expectStaticType<Exactly<({Object? f1})>>()
      ..f1.abs());
    //     ^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe] The method 'abs' isn't defined for the class 'Object?'.
  }

  //   - Otherwise, if Si is dynamic, then we insert an implicit cast on ei to
  //     Ri, and let Ti be Ri
  {
    // - Ki=List<_> and Si=dynamic, so Ri=List<Object?>; thus Ti=List<Object?>.
    // TODO(paulberry): investigate why CFE doesn't produce the expected errors
    // here; it apparently is producing a type of `List<dynamic>`.
    var d = [1] as dynamic;
    contextRecordListOfUnknown((d,)
      ..expectStaticType<Exactly<(List<Object?>,)>>()
      ..$1.first.abs());
    //           ^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    contextRecordNamedListOfUnknown((f1: d)
      ..expectStaticType<Exactly<({List<Object?> f1})>>()
      ..f1.first.abs);
    //           ^^^
    // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  }

  // (No error tests are needed to cover the remaining of the spec text--this is
  // all adequately tested by `type_inference_test.dart`.)
  //
  //   - Otherwise, if Si is coercible to Ri (via some sequence of call method
  //     tearoff or implicit generic instantiation coercions), then we insert
  //     the appropriate implicit coercion(s) on ei. Let Ti be the type of the
  //     resulting coerced value (which must be a subtype of Ri, possibly
  //     proper).
  //   - Otherwise, let Ti be Si.

  // If K is any other type schema:
  //
  // - Each ei is inferred with context type schema _ to have type Ti
  // - The type of E is (T1, ..., Tn, {d1 : T{n+1}, ...., dm : T{n+m}})
}
