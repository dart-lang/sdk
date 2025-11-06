// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:async';

abstract class MyStream<T> extends Stream<T> {
  factory MyStream() => throw '';
}

T F<T>() => throw '';

Future f() async {
  dynamic d;
  Object o;
  for (var x in F()) {}
  for (dynamic x in F()) {}
  for (Object x in F()) {}
  for (d in F()) {}
  for (o in F()) {}
  await for (var x in F()) {}
  await for (dynamic x in F()) {}
  await for (Object x in F()) {}
  await for (d in F()) {}
  await for (o in F()) {}
}

Future main() async {
  for (int x in [1, 2, 3]) {}
  for (num x in [1, 2, 3]) {}
  for (var x in [1, 2, 3]) {}
  await for (int x in new MyStream()) {}
  await for (var x in new MyStream<int>()) {}
}
