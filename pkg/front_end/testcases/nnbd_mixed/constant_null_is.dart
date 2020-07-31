// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'constant_null_is_lib.dart';

final bool isWeakMode = const <Null>[] is List<Object>;

const c0 = null is int?;
const c1 = null is int;
const c2 = null is Null;
const c3 = null is Never?;
const c4 = null is Never;
const c5 = null is FutureOr<int?>;
const c6 = null is FutureOr<int>;
const c7 = null is FutureOr<int>?;
const c8 = null is FutureOr<Null>;
const c9 = null is FutureOr<Null>?;
const c10 = null is FutureOr<Never>;
const c11 = null is FutureOr<Never?>;
const c12 = null is FutureOr<Never>?;
const e1 = const Class<int>.constructor1(null);
const e2 = const Class<int?>.constructor1(null);
const e3 = const Class<Null>.constructor1(null);
const e4 = const Class<int>.constructor2(null);
const e5 = const Class<int?>.constructor2(null);
const e6 = const Class<Null>.constructor2(null);
const e7 = const Class<int>.constructor3(null);
const e8 = const Class<int?>.constructor3(null);
const e9 = const Class<Null>.constructor3(null);
const e10 = const Class<int>.constructor4(null);
const e11 = const Class<int?>.constructor4(null);
const e12 = const Class<Null>.constructor4(null);

class Class<T> {
  final bool field;

  const Class.constructor1(value) : field = value is T;
  const Class.constructor2(value) : field = value is T?;
  const Class.constructor3(value) : field = value is Class<T>;
  const Class.constructor4(value) : field = value is Class<T>?;
}

main() {
  expect(null is int?, c0, "null is int?");
  expect(null is int, c1, "null is int");
  expect(null is Null, c2, "null is Null");
  expect(null is Never?, c3, "null is Never?");
  expect(null is Never, c4, "null is Never");
  expect(null is FutureOr<int?>, c5, "null is FutureOr<int?>");
  expect(null is FutureOr<int>, c6, "null is FutureOr<int>");
  expect(null is FutureOr<int>?, c7, "null is FutureOr<int>?");
  expect(null is FutureOr<Null>, c8, "null is FutureOr<Null>");
  expect(null is FutureOr<Null>?, c9, "null is FutureOr<Null>?");
  expect(null is FutureOr<Never>, c10, "null is FutureOr<Never>");
  expect(null is FutureOr<Never?>, c11, "null is FutureOr<Never?>");
  expect(null is FutureOr<Never>?, c12, "null is FutureOr<Never>?");
  expect(new Class<int>.constructor1(null).field, e1.field,
      "Class<int>.constructor1(null).field");
  expect(true, new Class<int?>.constructor1(null).field,
      "new Class<int?>.constructor1(null).field");
  // const Class<int?> is evaluated as const Class<int*> in weak mode:
  expect(!isWeakMode, e2.field, "const Class<int?>.constructor1(null).field");
  expect(new Class<Null>.constructor1(null).field, e3.field,
      "Class<Null>.constructor1(null).field");
  expect(new Class<int>.constructor2(null).field, e4.field,
      "Class<int>.constructor2(null).field");
  expect(true, new Class<int?>.constructor2(null).field,
      "new Class<int?>.constructor2(null).field");
  // const Class<int?> is evaluated as const Class<int*> in weak mode:
  expect(new Class<int?>.constructor2(null).field, e5.field,
      "Class<int?>.constructor2(null).field");
  expect(new Class<Null>.constructor2(null).field, e6.field,
      "Class<Null>.constructor2(null).field");
  expect(new Class<int>.constructor3(null).field, e7.field,
      "Class<int>.constructor3(null).field");
  expect(new Class<int?>.constructor3(null).field, e8.field,
      "Class<int?>.constructor3(null).field");
  expect(new Class<int?>.constructor3(null).field, e8.field,
      "Class<int?>.constructor3(null).field");
  expect(new Class<Null>.constructor3(null).field, e9.field,
      "Class<Null>.constructor3(null).field");
  expect(new Class<int>.constructor4(null).field, e10.field,
      "Class<int>.constructor4(null).field");
  expect(new Class<int?>.constructor4(null).field, e11.field,
      "Class<int?>.constructor4(null).field");
  expect(new Class<Null>.constructor4(null).field, e12.field,
      "Class<Null>.constructor4(null).field");
  test();
}

expect(expected, actual, String message) {
  if (expected != actual)
    throw 'Expected $expected, actual $actual for $message';
}
