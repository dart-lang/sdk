// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

import 'dart:async';
import 'constant_null_is.dart';

const d0 = null is int;
const d1 = null is Null;
//const d2 = null is FutureOr<Null>;
//const d3 = null is Never;
const d4 = const Class<int>.constructor1(null);
const d5 = const Class<Null>.constructor1(null);
const d6 = const Class<int>.constructor2(null);
const d7 = const Class<Null>.constructor2(null);
const d8 = const Class<int>.constructor3(null);
const d9 = const Class<Null>.constructor3(null);
const d10 = const Class<int>.constructor4(null);
const d11 = const Class<Null>.constructor4(null);

test() {
  expect(null is int, d0, "null is int (opt-out)");
  expect(null is Null, d1, "null is Null");
  //expect(null is FutureOr<Null>, d2, "null is FutureOr<Null> (opt-out)");
  //expect(null is Never, d3, "null is Never (opt-out)");
  expect(new Class<int>.constructor1(null).field, d4.field,
      "Class<int>.constructor1(null).field (opt-out)");
  expect(new Class<Null>.constructor1(null).field, d5.field,
      "Class<Null>.constructor1(null).field (opt-out)");
  expect(new Class<int>.constructor2(null).field, d6.field,
      "Class<int>.constructor2(null).field (opt-out)");
  expect(new Class<Null>.constructor2(null).field, d7.field,
      "Class<Null>.constructor2(null).field (opt-out)");
  expect(new Class<int>.constructor3(null).field, d8.field,
      "Class<int>.constructor3(null).field (opt-out)");
  expect(new Class<Null>.constructor3(null).field, d9.field,
      "Class<Null>.constructor3(null).field (opt-out)");
  expect(new Class<int>.constructor4(null).field, d10.field,
      "Class<int>.constructor4(null).field (opt-out)");
  expect(new Class<Null>.constructor4(null).field, d11.field,
      "Class<Null>.constructor4(null).field (opt-out)");
}
