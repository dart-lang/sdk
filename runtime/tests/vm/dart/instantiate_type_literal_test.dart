// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--show-internal-names

import 'dart:async';

import 'package:expect/expect.dart';

main(List<String> args) {
  print('Expected:\n$expectedTable');
  print('Actual:\n${generateTable()}');
  Expect.equals(expectedTable, generateTable());
}

const String expectedTable = '''
T  with int? = int?
T  with int  = int
T? with int? = int?
T? with int  = int?

T  with FutureOr<int>   = FutureOr<int>
T  with FutureOr<int>?  = FutureOr<int>?
T  with FutureOr<int?>  = FutureOr<int?>
T  with FutureOr<int?>? = FutureOr<int?>
T? with FutureOr<int>   = FutureOr<int>?
T? with FutureOr<int>?  = FutureOr<int>?
T? with FutureOr<int?>  = FutureOr<int?>
T? with FutureOr<int?>? = FutureOr<int?>

T  with void (() => void)? = (() => void)?
T  with void (() => void)  = () => void
T? with void (() => void)? = (() => void)?
T? with void (() => void)  = (() => void)?
''';

String generateTable() {
  final sb = StringBuffer();
  sb.writeln('T  with int? = $nonNullableTNullableInt');
  sb.writeln('T  with int  = $nonNullableTNonNullableInt');
  sb.writeln('T? with int? = $nullableTNullableInt');
  sb.writeln('T? with int  = $nullableTNonNullableInt');
  sb.writeln('');
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
  sb.writeln('T  with void (() => void)? = $nonNullableTNullableVoidFunction');
  sb.writeln(
      'T  with void (() => void)  = $nonNullableTNonNullableVoidFunction');
  sb.writeln('T? with void (() => void)? = $nullableTNullableVoidFunction');
  sb.writeln('T? with void (() => void)  = $nullableTNonNullableVoidFunction');
  return '$sb';
}

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

Type nullableT<T>() => MakeNullable<T>;
Type nonNullableT<T>() => T;
typedef MakeNullable<T> = T?;
