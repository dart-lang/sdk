// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'constant_null_is_lib.dart';

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
  test();
}

expect(expected, actual, String message) {
  if (expected != actual)
    throw 'Expected $expected, actual $actual for $message';
}
