// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:async';

abstract class MyStream<T> extends Stream<T> {
  factory MyStream() => throw '';
}

Stream<List<int>> foo() async* {
  yield [];
  yield /*error:YIELD_OF_INVALID_TYPE*/ new MyStream();
  yield* /*error:YIELD_OF_INVALID_TYPE*/ [];
  yield* new MyStream();
}

Iterable<Map<int, int>> bar() sync* {
  yield new Map();
  yield /*error:YIELD_OF_INVALID_TYPE*/ [];
  yield* /*error:YIELD_OF_INVALID_TYPE*/ new Map();
  yield* [];
}

main() {}
