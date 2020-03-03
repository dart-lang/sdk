// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

import 'function_type_equality_legacy_lib.dart' as legacy;

void fn() => null;
void fn2() => null;
int voidToInt() => 42;
int voidToInt2() => 42;
int? voidToNullableInt() => 42;
int? voidToNullableInt2() => 42;
void positionalIntToVoid(int i) => null;
void positionalNullableIntToVoid(int? i) => null;
void positionalNullableIntToVoid2(int? i) => null;
void optionalIntToVoid([int i]) => null;
void optionalIntToVoid2([int i]) => null;
void optionalNullableIntToVoid([int? i]) => null;
void optionalNullableIntToVoid2([int? i]) => null;
void namedIntToVoid({int i}) => null;
void namedIntToVoid2({int i}) => null;
void namedNullableIntToVoid({int? i}) => null;
void namedNullableIntToVoid2({int? i}) => null;
void requiredIntToVoid({required int i}) => null;
void requiredIntToVoid2({required int i}) => null;
void requiredNullableIntToVoid({required int? i}) => null;
void requiredNullableIntToVoid2({required int? i}) => null;
void gn(bool b, [int i]) => null;
void hn(bool b, {int i}) => null;

main() {
  // Same functions with different names.
  Expect.equals(fn.runtimeType, fn2.runtimeType);
  Expect.equals(voidToInt.runtimeType, voidToInt2.runtimeType);
  Expect.equals(voidToNullableInt.runtimeType, voidToNullableInt2.runtimeType);
  Expect.equals(positionalNullableIntToVoid.runtimeType,
      positionalNullableIntToVoid2.runtimeType);
  Expect.equals(optionalIntToVoid.runtimeType, optionalIntToVoid2.runtimeType);
  Expect.equals(optionalNullableIntToVoid.runtimeType,
      optionalNullableIntToVoid2.runtimeType);
  Expect.equals(namedIntToVoid.runtimeType, namedIntToVoid2.runtimeType);
  Expect.equals(
      namedNullableIntToVoid.runtimeType, namedNullableIntToVoid2.runtimeType);
  Expect.equals(requiredIntToVoid.runtimeType, requiredIntToVoid2.runtimeType);
  Expect.equals(requiredNullableIntToVoid.runtimeType,
      requiredNullableIntToVoid2.runtimeType);

  // Same signatures but one is from a legacy library.
  Expect.equals(fn.runtimeType, legacy.fn.runtimeType);
  Expect.equals(voidToInt.runtimeType, legacy.voidToInt.runtimeType);
  Expect.equals(
      positionalIntToVoid.runtimeType, legacy.positionalIntToVoid.runtimeType);
  Expect.equals(
      optionalIntToVoid.runtimeType, legacy.optionalIntToVoid.runtimeType);
  Expect.equals(namedIntToVoid.runtimeType, legacy.namedIntToVoid.runtimeType);
  Expect.equals(gn.runtimeType, legacy.gn.runtimeType);
  Expect.equals(hn.runtimeType, legacy.hn.runtimeType);

  // Nullable types are not equal to legacy types.
  Expect.notEquals(positionalNullableIntToVoid.runtimeType,
      legacy.positionalIntToVoid.runtimeType);
  Expect.notEquals(optionalNullableIntToVoid.runtimeType,
      legacy.optionalIntToVoid.runtimeType);
  Expect.notEquals(
      namedNullableIntToVoid.runtimeType, legacy.namedIntToVoid.runtimeType);
  Expect.notEquals(voidToNullableInt.runtimeType, legacy.voidToInt.runtimeType);

  // Required named arguments are not equal to named arguments.
  Expect.notEquals(requiredIntToVoid.runtimeType, namedIntToVoid.runtimeType);
  Expect.notEquals(
      requiredIntToVoid.runtimeType, legacy.namedIntToVoid.runtimeType);
}
