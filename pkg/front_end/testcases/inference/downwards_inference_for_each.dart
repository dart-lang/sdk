// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

abstract class MyStream<T> extends Stream<T> {
  factory MyStream() => null;
}

T F<T>() => null;

Future f() async {
  dynamic d;
  Object o;
  for (var /*@type=dynamic*/ x in /*@typeArgs=dynamic*/ F()) {}
  for (dynamic x in /*@typeArgs=Iterable<dynamic>*/ F()) {}
  for (Object x in /*@typeArgs=Iterable<Object>*/ F()) {}
  for (d in /*@typeArgs=dynamic*/ F()) {}
  for (o in /*@typeArgs=dynamic*/ F()) {}
  await for (var /*@type=dynamic*/ x in /*@typeArgs=dynamic*/ F()) {}
  await for (dynamic x in /*@typeArgs=Stream<dynamic>*/ F()) {}
  await for (Object x in /*@typeArgs=Stream<Object>*/ F()) {}
  await for (d in /*@typeArgs=dynamic*/ F()) {}
  await for (o in /*@typeArgs=dynamic*/ F()) {}
}

Future main() async {
  for (int x in /*@typeArgs=int*/ [1, 2, 3]) {}
  for (num x in /*@typeArgs=num*/ [1, 2, 3]) {}
  for (var /*@type=int*/ x in /*@typeArgs=int*/ [1, 2, 3]) {}
  await for (int x in new /*@typeArgs=int*/ MyStream()) {}
  await for (var /*@type=int*/ x in new MyStream<int>()) {}
}
