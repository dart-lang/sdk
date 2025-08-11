// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies the rules for demotion and promotion to types of interest,
// as specified in https://github.com/dart-lang/language/pull/4370.

import 'package:expect/static_type_helper.dart';

// If a variable has multiple outstanding promotions, and a value is assigned
// whose static type is a subtype of some outstanding promotions but not others,
// the outstanding promotions that don't satisfy the subtype relationship are
// cancelled.
void partialDemotion() {
  var x = 0 as Object;
  x as num; // Promotes to `num`
  x as int; // Promotes to `int`
  x.expectStaticType<Exactly<int>>();
  x = 1.0; // Cancels promotion to `int`
  x.expectStaticType<Exactly<num>>();
}

// If a variable has multiple outstanding promotions, and a value is assigned
// whose static type is not a subtype of any of the outstanding promotions, then
// all the outstanding promotions are canelled.
void fullDemotion() {
  var x = 0 as Object;
  x as num; // Promotes to `num`
  x as int; // Promotes to `int`
  x.expectStaticType<Exactly<int>>();
  x = ''; // Cancels promotions
  x.expectStaticType<Exactly<Object>>();
}

// If a variable's declared type is T, then NonNull(T) is a type of interest.
void toiNonNullDeclaredType() {
  var x = 0 as num?; // `num` is a type of interest.
  x.expectStaticType<Exactly<num?>>();
  x = 0; // Promotes to `num`
  x.expectStaticType<Exactly<num>>();
}

// Assigning a type that has not been explicitly tested does not promote.
void toiUntestedType() {
  var x = 0 as Object;
  x.expectStaticType<Exactly<Object>>();
  x = 0; // Does not promote.
  x.expectStaticType<Exactly<Object>>();
}

// Assigning a type that has been explicitly tested promotes.
void toiTestedType() {
  var x = 0 as Object;
  if (x is int) {} // `int` is now a type of interest.
  x.expectStaticType<Exactly<Object>>();
  x = 0; // Promotes to `int`
  x.expectStaticType<Exactly<int>>();
}

// A type test using type T causes NonNull(T) to become a type of interest.
void toiNonNullTestedType() {
  var x = 0 as Object;
  if (x is int?) {} // `int` is now a type of interest.
  x.expectStaticType<Exactly<Object>>();
  x = 0; // Promotes to `int`
  x.expectStaticType<Exactly<int>>();
}

// When selecting among the types of interest that are candidates for promotion,
// if exactly one type is a subtype of all the others, it is chosen.
void toiSubtypeOfOthers() {
  var x = 0 as Object;
  if (x is List<num>) {} // `List<num>` is now a type of interest.
  if (x is List<Object>) {} // `List<Object>` is now a type of interest.
  x.expectStaticType<Exactly<Object>>();
  x = <int>[];
  // Since `List<num> <: List<Object>`, `x` is promoted to `List<num>`.
  x.expectStaticType<Exactly<List<num>>>();
}

// When selecting among the types of interest that are candidates for promotion,
// if more than one type is a subtype of all the others, then no
// type-of-interest promotion occurs.
void toiNoPreferredType() {
  var x = 0 as Object;
  if (x is List<Object?>) {} // `List<Object?> is now a type of interest.
  if (x is List<dynamic>) {} // `List<dynamic> is now a type of interest.
  x.expectStaticType<Exactly<Object>>();
  x = <int>[];
  // Since `List<Object?>` and `List<dynamic>` are mutual subtypes, neither is
  // preferred, so no type-of-interest promotion occurs.
  x.expectStaticType<Exactly<Object>>();
}

// When selecting among the types of interest that are candidates for promotion,
// if one of the types of interest matches the static type of the assigned value
// exactly, then that type is chosen even if there are other candidate types
// that are a subtype of all the others.
void toiExactMatch() {
  var x = 0 as Object;
  if (x is List<Object?>) {} // `List<Object?> is now a type of interest.
  if (x is List<dynamic>) {} // `List<dynamic> is now a type of interest.
  x.expectStaticType<Exactly<Object>>();
  x = <dynamic>[0];
  // Since `List<dynamic>` matches a type of interest exactly, type-of-interest
  // promotion occurs.
  x.expectStaticType<Exactly<List<dynamic>>>();
  // Since the `expectStaticType` machinery can't distinguish `dynamic` from
  // `Object?`, do something that is not allowed for `List<Object?>`:
  x.first.abs();
}

// When selecting among the types of interest that are candidates for promotion,
// only supertypes of the written type are considered.
void toiSupertypeOfWritten() {
  var x = 0 as Object;
  if (x is num) {} // `num` is now a type of interest.
  if (x is String) {} // `String` is now a type of interest.
  x.expectStaticType<Exactly<Object>>();
  x = 0; // Promotes to `num`, since `int` is not a subtype of `String`
  x.expectStaticType<Exactly<num>>();
}

// When selecting among the types of interest that are candidates for promotion,
// only subtypes of the declared type are considered.
//
// Note that this test would have failed prior to the fix for
// https://github.com/dart-lang/sdk/issues/60620.
void toiSubtypeOfDeclared() {
  var x = <Object>[];
  if (x is List<num>) {} // `List<num>` is now a type of interest.
  if (x is List<int?>) {} // `List<int?>` is now a type of interest.
  x.expectStaticType<Exactly<List<Object>>>();
  x = <int>[];
  // `x1` is now promoted to `List<num>`, since `List<int>` is not a subtype of
  // `List<Object>`.
  x.expectStaticType<Exactly<List<num>>>();
}

main() {
  partialDemotion();
  fullDemotion();
  toiNonNullDeclaredType();
  toiUntestedType();
  toiTestedType();
  toiNonNullTestedType();
  toiSubtypeOfOthers();
  toiNoPreferredType();
  toiExactMatch();
  toiSupertypeOfWritten();
  toiSubtypeOfDeclared();
}
