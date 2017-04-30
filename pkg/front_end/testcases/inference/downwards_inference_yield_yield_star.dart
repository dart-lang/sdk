// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

abstract class MyStream<T> extends Stream<T> {
  factory MyStream() => null;
}

Stream<List<int>> foo() async* {
  yield /*@typeArgs=int*/ [];
  yield /*error:YIELD_OF_INVALID_TYPE*/ /*@typeArgs=dynamic*/ new MyStream();
  yield* /*error:YIELD_OF_INVALID_TYPE*/ /*@typeArgs=dynamic*/ [];
  yield* /*@typeArgs=List<int>*/ new MyStream();
}

Iterable<Map<int, int>> bar() sync* {
  yield /*@typeArgs=int, int*/ {};
  yield /*error:YIELD_OF_INVALID_TYPE*/ /*@typeArgs=dynamic*/ new List();
  yield* /*error:YIELD_OF_INVALID_TYPE*/ /*@typeArgs=dynamic, dynamic*/ {};
  yield* /*@typeArgs=Map<int, int>*/ new List();
}
