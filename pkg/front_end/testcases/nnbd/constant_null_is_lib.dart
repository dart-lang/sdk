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

test() {
  expect(null is int, d0, "null is int (opt-out)");
  expect(null is Null, d1, "null is Null");
  //expect(null is FutureOr<Null>, d2, "null is FutureOr<Null> (opt-out)");
  //expect(null is Never, d3, "null is Never (opt-out)");
}
