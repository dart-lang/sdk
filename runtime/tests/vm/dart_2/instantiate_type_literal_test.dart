// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9
// VMOptions=--show-internal-names

import 'package:expect/expect.dart';

import 'instantiate_type_literal_nnbd_helper.dart';

main(List<String> args) {
  print('Expected:\n$expectedTable');
  print('Actual:\n${generateTable()}');
  Expect.equals(expectedTable, generateTable());
}

const String expectedTable = '''
T* with int? = int?
T* with int  = int*
T* with int* = int*
T  with int? = int?
T  with int  = int
T  with int* = int*
T? with int? = int?
T? with int  = int?
T? with int* = int?

T* with FutureOr<int>   = FutureOr<int>*
T* with FutureOr<int>?  = FutureOr<int>?
T* with FutureOr<int?>  = FutureOr<int?>*
T* with FutureOr<int?>? = FutureOr<int?>*
T  with FutureOr<int>   = FutureOr<int>
T  with FutureOr<int>?  = FutureOr<int>?
T  with FutureOr<int?>  = FutureOr<int?>
T  with FutureOr<int?>? = FutureOr<int?>
T? with FutureOr<int>   = FutureOr<int>?
T? with FutureOr<int>?  = FutureOr<int>?
T? with FutureOr<int?>  = FutureOr<int?>
T? with FutureOr<int?>? = FutureOr<int?>

T* with void (() => void)? = (() => void)?
T* with void (() => void)  = (() => void)*
T* with void (() => void)* = (() => void)*
T  with void (() => void)? = (() => void)?
T  with void (() => void)  = () => void
T  with void (() => void)* = (() => void)*
T? with void (() => void)? = (() => void)?
T? with void (() => void)  = (() => void)?
T? with void (() => void)* = (() => void)?
''';

String generateTable() {
  final sb = StringBuffer();
  sb.writeln('T* with int? = $legacyTWithNullableInt');
  sb.writeln('T* with int  = $legacyTWithNonNullableInt');
  sb.writeln('T* with int* = $legacyTWithLegacyInt');
  sb.writeln('T  with int? = $nonNullableTNullableInt');
  sb.writeln('T  with int  = $nonNullableTNonNullableInt');
  sb.writeln('T  with int* = $nonNullableTWithLegacyInt');
  sb.writeln('T? with int? = $nullableTNullableInt');
  sb.writeln('T? with int  = $nullableTNonNullableInt');
  sb.writeln('T? with int* = $nullableTWithLegacyInt');
  sb.writeln('');
  sb.writeln('T* with FutureOr<int>   = $legacyTFutureOrInt');
  sb.writeln('T* with FutureOr<int>?  = $legacyTNullableFutureOrInt');
  sb.writeln('T* with FutureOr<int?>  = $legacyTFutureOrNullableInt');
  sb.writeln('T* with FutureOr<int?>? = $legacyTNullableFutureOrNullableInt');
  sb.writeln('T  with FutureOr<int>   = $nonNullableTFutureOrInt');
  sb.writeln('T  with FutureOr<int>?  = $nonNullableTNullableFutureOrInt');
  sb.writeln('T  with FutureOr<int?>  = $nonNullableTFutureOrNullableInt');
  sb.writeln(
      'T  with FutureOr<int?>? = $nonNullableTNullableFutureOrNullableInt');
  sb.writeln('T? with FutureOr<int>   = $nullableTFutureOrInt');
  sb.writeln('T? with FutureOr<int>?  = $nullableTNullableFutureOrInt');
  sb.writeln('T? with FutureOr<int?>  = $nullableTFutureOrNullableInt');
  sb.writeln('T? with FutureOr<int?>? = $nullableTNullableFutureOrNullableInt');
  sb.writeln('');
  sb.writeln('T* with void (() => void)? = $legacyTWithNullableVoidFunction');
  sb.writeln(
      'T* with void (() => void)  = $legacyTWithNonNullableVoidFunction');
  sb.writeln('T* with void (() => void)* = $legacyTWithLegacyVoidFunction');
  sb.writeln('T  with void (() => void)? = $nonNullableTNullableVoidFunction');
  sb.writeln(
      'T  with void (() => void)  = $nonNullableTNonNullableVoidFunction');
  sb.writeln(
      'T  with void (() => void)* = $nonNullableTWithLegacyVoidFunction');
  sb.writeln('T? with void (() => void)? = $nullableTNullableVoidFunction');
  sb.writeln('T? with void (() => void)  = $nullableTNonNullableVoidFunction');
  sb.writeln('T? with void (() => void)* = $nullableTWithLegacyVoidFunction');
  return '$sb';
}

final Type legacyTWithLegacyInt = legacyT<int>();
final Type legacyTWithLegacyVoidFunction = legacyT<void Function()>();
final Type nonNullableTWithLegacyInt = nonNullableT<int>();
final Type nonNullableTWithLegacyVoidFunction = nonNullableT<void Function()>();
final Type nullableTWithLegacyInt = nullableT<int>();
final Type nullableTWithLegacyVoidFunction = nullableT<void Function()>();

Type legacyT<T>() => T;
