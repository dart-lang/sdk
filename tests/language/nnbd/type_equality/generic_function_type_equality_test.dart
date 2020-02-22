// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'generic_function_type_equality_legacy_lib.dart' as legacy;
import 'generic_function_type_equality_null_safe_lib.dart';

void fn<T>() => null;
void fn2<R>() => null;
T voidToT<T>() => null as T;
S voidToS<S>() => null as S;
void positionalTToVoid<T>(T i) => null;
void positionalSToVoid<S>(S i) => null;
void positionalNullableTToVoid<T>(T? i) => null;
void positionalNullableSToVoid<S>(S? i) => null;
void optionalTToVoid<T>([T i]) => null;
void optionalSToVoid<S>([S i]) => null;
void optionalNullableTToVoid<T>([T? i]) => null;
void optionalNullableSToVoid<S>([S? i]) => null;
void namedTToVoid<T>({T i}) => null;
void namedSToVoid<S>({S i}) => null;
void namedNullableTToVoid<T>({T? i}) => null;
void namedNullableSToVoid<S>({S? i}) => null;
void requiredTToVoid<T>({required T i}) => null;
void requiredSToVoid<S>({required S i}) => null;
void requiredNullableTToVoid<T>({required T? i}) => null;
void requiredNullableSToVoid<S>({required S? i}) => null;

void positionalTToVoidWithBound<T extends B>(T i) => null;
void optionalTToVoidWithBound<T extends B>([T i]) => null;
void namedTToVoidWithBound<T extends B>({T i}) => null;

class A<T extends B> {
  void fn(T i) => null;
}

main() {
  // Same functions with different names.
  Expect.equals(fn.runtimeType, fn2.runtimeType);
  Expect.equals(voidToT.runtimeType, voidToT.runtimeType);
  Expect.equals(positionalTToVoid.runtimeType, positionalSToVoid.runtimeType);
  Expect.equals(positionalNullableTToVoid.runtimeType,
      positionalNullableSToVoid.runtimeType);
  Expect.equals(optionalTToVoid.runtimeType, optionalSToVoid.runtimeType);
  Expect.equals(
      optionalNullableTToVoid.runtimeType, optionalNullableSToVoid.runtimeType);
  Expect.equals(namedTToVoid.runtimeType, namedSToVoid.runtimeType);
  Expect.equals(
      namedNullableTToVoid.runtimeType, namedNullableSToVoid.runtimeType);
  Expect.equals(requiredTToVoid.runtimeType, requiredSToVoid.runtimeType);
  Expect.equals(
      requiredNullableTToVoid.runtimeType, requiredNullableSToVoid.runtimeType);

  // Default type bounds are not equal. T extends Object? vs T extends Object*
  Expect.notEquals(fn.runtimeType, legacy.fn.runtimeType);
  Expect.notEquals(voidToT.runtimeType, legacy.voidToR.runtimeType);
  Expect.notEquals(
      positionalTToVoid.runtimeType, legacy.positionalRToVoid.runtimeType);
  Expect.notEquals(
      optionalTToVoid.runtimeType, legacy.optionalRToVoid.runtimeType);
  Expect.notEquals(namedTToVoid.runtimeType, legacy.namedRToVoid.runtimeType);

  // Type arguments in methods tear-offs from null safe libraries become Object?
  // and Object* from legacy libraries and are not equal.
  Expect.notEquals(A().fn.runtimeType, legacy.A().fn.runtimeType);
  Expect.notEquals(A().fn.runtimeType, legacy.rawAFnTearoff.runtimeType);
  Expect.notEquals(A<C>().fn.runtimeType, legacy.A<C>().fn.runtimeType);

  // Same signatures but one is from a legacy library.
  Expect.equals(positionalTToVoidWithBound.runtimeType,
      legacy.positionalTToVoidWithBound.runtimeType);
  Expect.equals(optionalTToVoidWithBound.runtimeType,
      legacy.optionalTToVoidWithBound.runtimeType);
  Expect.equals(namedTToVoidWithBound.runtimeType,
      legacy.namedTToVoidWithBound.runtimeType);

  // Required named arguments are not equal to named arguments.
  Expect.notEquals(namedTToVoid.runtimeType, requiredTToVoid.runtimeType);
  Expect.notEquals(
      namedNullableTToVoid.runtimeType, requiredNullableTToVoid.runtimeType);
  Expect.notEquals(
      requiredTToVoid.runtimeType, legacy.namedRToVoid.runtimeType);
}
