// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.17

import 'dart:async';

import 'instantiate_type_literal_test.dart';

final Type legacyTWithNullableInt = legacyT<int?>();
final Type legacyTWithNullableVoidFunction = legacyT<void Function()?>();
final Type legacyTWithNonNullableInt = legacyT<int>();
final Type legacyTWithNonNullableVoidFunction = legacyT<void Function()>();
final Type nonNullableTNullableInt = nonNullableT<int?>();
final Type nonNullableTNullableVoidFunction = nonNullableT<void Function()?>();
final Type nonNullableTNonNullableInt = nonNullableT<int>();
final Type nonNullableTNonNullableVoidFunction =
    nonNullableT<void Function()>();
final Type nullableTNullableInt = nullableT<int?>();
final Type nullableTNullableVoidFunction = nullableT<void Function()?>();
final Type nullableTNonNullableInt = nullableT<int>();
final Type nullableTNonNullableVoidFunction = nullableT<void Function()>();
final Type nonNullableTFutureOrInt = nonNullableT<FutureOr<int>>();
final Type nonNullableTNullableFutureOrInt = nonNullableT<FutureOr<int>?>();
final Type nonNullableTFutureOrNullableInt = nonNullableT<FutureOr<int?>>();
final Type nonNullableTNullableFutureOrNullableInt =
    nonNullableT<FutureOr<int?>?>();
final Type nullableTFutureOrInt = nullableT<FutureOr<int>>();
final Type nullableTNullableFutureOrInt = nullableT<FutureOr<int>?>();
final Type nullableTFutureOrNullableInt = nullableT<FutureOr<int?>>();
final Type nullableTNullableFutureOrNullableInt = nullableT<FutureOr<int?>?>();

final Type legacyTFutureOrInt = legacyT<FutureOr<int>>();
final Type legacyTNullableFutureOrInt = legacyT<FutureOr<int>?>();
final Type legacyTFutureOrNullableInt = legacyT<FutureOr<int?>>();
final Type legacyTNullableFutureOrNullableInt = legacyT<FutureOr<int?>?>();

Type nullableT<T>() => MakeNullable<T>;
Type nonNullableT<T>() => T;
typedef MakeNullable<T> = T?;
